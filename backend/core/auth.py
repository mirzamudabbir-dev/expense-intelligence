from urllib.parse import urlparse

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwk as jose_jwk, jwt

from core.config import settings

bearer = HTTPBearer()

# Strip any path (e.g. /rest/v1/) so the JWKS URL is always correct.
_base = f"{urlparse(settings.SUPABASE_URL).scheme}://{urlparse(settings.SUPABASE_URL).netloc}"
_JWKS: list = httpx.get(f"{_base}/auth/v1/.well-known/jwks.json", timeout=10).json()["keys"]


def _get_key(kid: str):
    for k in _JWKS:
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
