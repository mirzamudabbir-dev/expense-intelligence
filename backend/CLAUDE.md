# claude.md — FastAPI Backend

You are building the Python FastAPI backend for "Spent".  
Responsibility: Analytics aggregation only. CRUD happens via Supabase SDK in Flutter.  
Auth: Validate Supabase JWT on every request.

---

## Project Structure

```
backend/
├── main.py
├── requirements.txt
├── .env
├── core/
│   ├── config.py          # Settings via pydantic-settings
│   ├── auth.py            # JWT validation middleware
│   └── database.py        # Supabase client (service role)
├── routers/
│   ├── analytics.py       # /analytics/* endpoints
│   └── budget.py          # /budget/* endpoints
└── schemas/
    ├── analytics.py
    └── budget.py
```

---

## requirements.txt

```
fastapi==0.111.0
uvicorn[standard]==0.29.0
python-dotenv==1.0.1
pydantic-settings==2.2.1
supabase==2.4.3
python-jose[cryptography]==3.3.0
httpx==0.27.0
```

---

## main.py

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import analytics, budget

app = FastAPI(title="Spent API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Tighten in production
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
app.include_router(budget.router, prefix="/budget", tags=["budget"])

@app.get("/health")
def health():
    return {"status": "ok"}
```

---

## core/config.py

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str
    SUPABASE_JWT_SECRET: str    # From Supabase Dashboard → Settings → API → JWT Secret

    class Config:
        env_file = ".env"

settings = Settings()
```

---

## core/auth.py — JWT Validation

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from core.config import settings

bearer = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer)) -> str:
    """Validates Supabase JWT and returns user_id (sub claim)."""
    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated",
        )
        user_id: str = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )
```

---

## core/database.py

```python
from supabase import create_client, Client
from core.config import settings

def get_supabase() -> Client:
    return create_client(
        settings.SUPABASE_URL,
        settings.SUPABASE_SERVICE_ROLE_KEY,  # Service role bypasses RLS
    )

supabase: Client = get_supabase()
```

---

## routers/analytics.py

```python
from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.database import supabase
from schemas.analytics import MonthlyAnalyticsResponse, WeeklyTrendResponse

router = APIRouter()

@router.get("/monthly", response_model=MonthlyAnalyticsResponse)
async def monthly_analytics(
    month: int,
    year: int,
    user_id: str = Depends(get_current_user),
):
    # Total for month
    total_res = supabase.rpc("get_monthly_total", {
        "p_user_id": user_id, "p_month": month, "p_year": year
    }).execute()

    # Category breakdown
    cats_res = supabase.from_("expenses").select("category_id, amount").eq(
        "user_id", user_id
    ).execute()
    # Filter in Python (simpler than complex RPC for MVP)
    from datetime import date
    expenses = [
        e for e in cats_res.data
        # This approach works but for production use RPC or filtered query
    ]

    # Better: use direct SQL via RPC
    breakdown_res = supabase.rpc("get_category_breakdown", {
        "p_user_id": user_id, "p_month": month, "p_year": year
    }).execute()

    daily_res = supabase.rpc("get_daily_trend", {
        "p_user_id": user_id
    }).execute()

    monthly_compare_res = supabase.rpc("get_monthly_comparison", {
        "p_user_id": user_id
    }).execute()

    return MonthlyAnalyticsResponse(
        total=total_res.data or 0,
        category_breakdown=breakdown_res.data or [],
        daily_trend=daily_res.data or [],
        monthly_comparison=monthly_compare_res.data or [],
    )

@router.get("/summary")
async def summary(user_id: str = Depends(get_current_user)):
    """Top category, daily average, this month total."""
    # Use Supabase RPCs defined in claude_supabase.md
    pass
```

---

## Supabase RPCs to Create

Add these in Supabase SQL editor so FastAPI can call `.rpc()`:

```sql
-- get_monthly_total
CREATE OR REPLACE FUNCTION get_monthly_total(p_user_id UUID, p_month INT, p_year INT)
RETURNS NUMERIC AS $$
  SELECT COALESCE(SUM(amount), 0)
  FROM expenses
  WHERE user_id = p_user_id
    AND EXTRACT(MONTH FROM date) = p_month
    AND EXTRACT(YEAR FROM date) = p_year;
$$ LANGUAGE sql SECURITY DEFINER;

-- get_category_breakdown
CREATE OR REPLACE FUNCTION get_category_breakdown(p_user_id UUID, p_month INT, p_year INT)
RETURNS TABLE(category_id TEXT, total NUMERIC) AS $$
  SELECT category_id, SUM(amount) as total
  FROM expenses
  WHERE user_id = p_user_id
    AND EXTRACT(MONTH FROM date) = p_month
    AND EXTRACT(YEAR FROM date) = p_year
  GROUP BY category_id
  ORDER BY total DESC;
$$ LANGUAGE sql SECURITY DEFINER;

-- get_daily_trend (last 7 days)
CREATE OR REPLACE FUNCTION get_daily_trend(p_user_id UUID)
RETURNS TABLE(day DATE, total NUMERIC) AS $$
  SELECT date as day, SUM(amount) as total
  FROM expenses
  WHERE user_id = p_user_id
    AND date >= CURRENT_DATE - INTERVAL '6 days'
  GROUP BY date
  ORDER BY date ASC;
$$ LANGUAGE sql SECURITY DEFINER;

-- get_monthly_comparison (last 6 months)
CREATE OR REPLACE FUNCTION get_monthly_comparison(p_user_id UUID)
RETURNS TABLE(month INT, year INT, total NUMERIC) AS $$
  SELECT 
    EXTRACT(MONTH FROM date)::INT as month,
    EXTRACT(YEAR FROM date)::INT as year,
    SUM(amount) as total
  FROM expenses
  WHERE user_id = p_user_id
    AND date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '5 months'
  GROUP BY month, year
  ORDER BY year, month;
$$ LANGUAGE sql SECURITY DEFINER;
```

---

## schemas/analytics.py

```python
from pydantic import BaseModel
from typing import List

class CategoryTotal(BaseModel):
    category_id: str
    total: float

class DailyTotal(BaseModel):
    day: str
    total: float

class MonthlyTotal(BaseModel):
    month: int
    year: int
    total: float

class MonthlyAnalyticsResponse(BaseModel):
    total: float
    category_breakdown: List[CategoryTotal]
    daily_trend: List[DailyTotal]
    monthly_comparison: List[MonthlyTotal]
```

---

## routers/budget.py

```python
from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.database import supabase

router = APIRouter()

@router.get("/status")
async def budget_status(month: int, year: int, user_id: str = Depends(get_current_user)):
    """Returns budget limit + amount spent for the month."""
    budget = supabase.from_("budgets").select("*").eq("user_id", user_id).eq(
        "month", month).eq("year", year).maybe_single().execute()

    spent = supabase.rpc("get_monthly_total", {
        "p_user_id": user_id, "p_month": month, "p_year": year
    }).execute()

    limit = budget.data["monthly_limit"] if budget.data else None
    total_spent = spent.data or 0

    return {
        "month": month,
        "year": year,
        "limit": limit,
        "spent": total_spent,
        "remaining": (limit - total_spent) if limit else None,
        "percentage": round((total_spent / limit * 100), 1) if limit else None,
    }
```

---

## .env (never commit)

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
SUPABASE_JWT_SECRET=your-jwt-secret-from-supabase-dashboard
```

---

## Running Locally

```bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

---

## Deployment (Simple)

Use Railway or Render (free tier works for MVP):
1. Connect GitHub repo
2. Set env vars in dashboard
3. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`

---

## API Endpoints Summary

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Health check |
| GET | `/analytics/monthly?month=&year=` | Full monthly analytics |
| GET | `/analytics/summary` | Top category, daily avg |
| GET | `/budget/status?month=&year=` | Budget vs spent |

**That's it. Keep it minimal.**

---

## What NOT to Do

- Do NOT add CRUD endpoints — Flutter uses Supabase SDK directly
- Do NOT add user management endpoints
- Do NOT add AI/ML endpoints
- Do NOT add caching (MVP) — add Redis later if needed
- Do NOT add background jobs or workers for MVP
