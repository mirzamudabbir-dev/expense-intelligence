"""
Tests for the FastAPI JWT auth middleware (core/auth.py).

The get_current_user dependency is tested in isolation using a minimal
FastAPI app — no real Supabase connection required.

Token lifecycle:
  - valid signed token   → 200 + user_id in body
  - missing header       → 403  (HTTPBearer rejects absent credentials)
  - wrong signature      → 401  (JWTError → "Could not validate credentials")
  - expired              → 401
  - wrong audience       → 401
  - missing sub claim    → 401  ("Invalid token")
  - garbage string       → 401
"""

from datetime import datetime, timedelta, timezone
from types import SimpleNamespace

import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from jose import jwt

from core.auth import get_current_user

# ── Constants ──────────────────────────────────────────────────────────────

TEST_SECRET = "test-jwt-secret-for-unit-tests-only"
TEST_USER_ID = "550e8400-e29b-41d4-a716-446655440000"

# ── Minimal test app ───────────────────────────────────────────────────────

_app = FastAPI()


@_app.get("/me")
def me(user_id: str = Depends(get_current_user)):
    return {"user_id": user_id}


_client = TestClient(_app)

# ── Helpers ────────────────────────────────────────────────────────────────


def _token(
    *,
    sub: str = TEST_USER_ID,
    aud: str = "authenticated",
    secret: str = TEST_SECRET,
    expired: bool = False,
    omit_sub: bool = False,
) -> str:
    now = datetime.now(timezone.utc)
    exp = now - timedelta(hours=1) if expired else now + timedelta(hours=1)
    payload: dict = {
        "aud": aud,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
    }
    if not omit_sub:
        payload["sub"] = sub
    return jwt.encode(payload, secret, algorithm="HS256")


# ── Fixtures ───────────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def _patch_jwt_secret(monkeypatch: pytest.MonkeyPatch) -> None:
    """Replace core.auth.settings with a fake that uses the test secret."""
    monkeypatch.setattr(
        "core.auth.settings",
        SimpleNamespace(SUPABASE_JWT_SECRET=TEST_SECRET),
    )


# ── Valid token ────────────────────────────────────────────────────────────


class TestValidToken:
    def test_returns_200_and_user_id(self) -> None:
        res = _client.get("/me", headers={"Authorization": f"Bearer {_token()}"})
        assert res.status_code == 200
        assert res.json() == {"user_id": TEST_USER_ID}

    def test_user_id_matches_sub_claim(self) -> None:
        other_id = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        res = _client.get("/me", headers={"Authorization": f"Bearer {_token(sub=other_id)}"})
        assert res.status_code == 200
        assert res.json()["user_id"] == other_id


# ── Missing / malformed credentials ───────────────────────────────────────


class TestMissingCredentials:
    def test_no_auth_header_returns_403(self) -> None:
        res = _client.get("/me")
        assert res.status_code == 403

    def test_empty_bearer_returns_403(self) -> None:
        res = _client.get("/me", headers={"Authorization": "Bearer "})
        assert res.status_code == 403

    def test_garbage_token_returns_401(self) -> None:
        res = _client.get("/me", headers={"Authorization": "Bearer not.a.jwt"})
        assert res.status_code == 401
        assert res.json()["detail"] == "Could not validate credentials"


# ── Token validation failures ──────────────────────────────────────────────


class TestInvalidToken:
    def test_wrong_signature_returns_401(self) -> None:
        token = _token(secret="totally-wrong-secret")
        res = _client.get("/me", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 401
        assert res.json()["detail"] == "Could not validate credentials"

    def test_expired_token_returns_401(self) -> None:
        token = _token(expired=True)
        res = _client.get("/me", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 401
        assert res.json()["detail"] == "Could not validate credentials"

    def test_wrong_audience_returns_401(self) -> None:
        token = _token(aud="anon")  # Supabase anon audience — should be rejected
        res = _client.get("/me", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 401
        assert res.json()["detail"] == "Could not validate credentials"

    def test_missing_sub_claim_returns_401(self) -> None:
        token = _token(omit_sub=True)
        res = _client.get("/me", headers={"Authorization": f"Bearer {token}"})
        assert res.status_code == 401
        assert res.json()["detail"] == "Invalid token"

    def test_tampered_payload_returns_401(self) -> None:
        """A valid token with its payload base64-flipped is rejected."""
        good = _token()
        header, _payload, sig = good.split(".")
        # flip last char of payload to corrupt it
        bad_payload = _payload[:-1] + ("A" if _payload[-1] != "A" else "B")
        tampered = f"{header}.{bad_payload}.{sig}"
        res = _client.get("/me", headers={"Authorization": f"Bearer {tampered}"})
        assert res.status_code == 401
