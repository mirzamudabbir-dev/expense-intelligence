from typing import Optional
from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.database import supabase
from schemas.budget import BudgetStatusResponse

router = APIRouter()


@router.get("/status", response_model=BudgetStatusResponse)
async def budget_status(
    month: int,
    year: int,
    user_id: str = Depends(get_current_user),
):
    budget_res = supabase.from_("budgets").select("monthly_limit").eq(
        "user_id", user_id,
    ).eq("month", month).eq("year", year).maybe_single().execute()

    spent_res = supabase.rpc("get_monthly_total", {
        "p_user_id": user_id, "p_month": month, "p_year": year,
    }).execute()

    limit: Optional[float] = budget_res.data["monthly_limit"] if budget_res.data else None
    spent: float = spent_res.data or 0

    return BudgetStatusResponse(
        month=month,
        year=year,
        limit=limit,
        spent=spent,
        remaining=(limit - spent) if limit is not None else None,
        percentage=round(spent / limit * 100, 1) if limit else None,
    )
