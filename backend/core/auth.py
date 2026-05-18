from urllib.parse import urlparse
from typing import Optional

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwk as jose_jwk, jwt

from core.config import settings

bearer = HTTPBearer()

_jwks_cache: Optional[list] = None


def _get_jwks() -> list:
    global _jwks_cache
    if _jwks_cache is None:
        parsed = urlparse(settings.SUPABASE_URL)
        base = f"{parsed.scheme}://{parsed.netloc}"
        _jwks_cache = httpx.get(
            f"{base}/auth/v1/.well-known/jwks.json", timeout=10
        ).json()["keys"]
    return _jwks_cache


def _get_key(kid: str):
    for k in _get_jwks():
        if k.get("kid") == kid:
            return jose_jwk.construct(k)
    raise ValueError(f"No JWKS key with kid={kid!r}")


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
) -> str:
    try:
        header = jwt.get_unverified_header(credentials.credentials)
        key = _get_key(header["kid"])
        payload = jwt.decode(
            credentials.credentials,
            key,
            algorithms=["ES256"],
            audience="authenticated",
        )
        user_id: str = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except (JWTError, ValueError, KeyError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )
