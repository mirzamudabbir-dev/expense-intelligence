from typing import Optional
from fastapi import APIRouter, Depends
from core.auth import get_current_user
from core.database import supabase
from schemas.analytics import MonthlyAnalyticsResponse, SummaryResponse

router = APIRouter()


@router.get("/monthly", response_model=MonthlyAnalyticsResponse)
async def monthly_analytics(
    month: int,
    year: int,
    period: str = "month",
    user_id: str = Depends(get_current_user),
):
    total_res = supabase.rpc("get_monthly_total", {
        "p_user_id": user_id, "p_month": month, "p_year": year,
    }).execute()

    breakdown_res = supabase.rpc("get_category_breakdown", {
        "p_user_id": user_id, "p_month": month, "p_year": year,
    }).execute()

    if period == "year":
        trend_res = supabase.rpc("get_yearly_trend", {"p_user_id": user_id}).execute()
    else:
        trend_res = supabase.rpc("get_daily_trend", {"p_user_id": user_id}).execute()

    monthly_compare_res = supabase.rpc("get_monthly_comparison", {
        "p_user_id": user_id,
    }).execute()

    return MonthlyAnalyticsResponse(
        total=total_res.data or 0,
        category_breakdown=breakdown_res.data or [],
        daily_trend=trend_res.data or [],
        monthly_comparison=monthly_compare_res.data or [],
    )


@router.get("/summary", response_model=SummaryResponse)
async def summary(
    month: int,
    year: int,
    user_id: str = Depends(get_current_user),
):
    total_res = supabase.rpc("get_monthly_total", {
        "p_user_id": user_id, "p_month": month, "p_year": year,
    }).execute()

    breakdown_res = supabase.rpc("get_category_breakdown", {
        "p_user_id": user_id, "p_month": month, "p_year": year,
    }).execute()

    daily_res = supabase.rpc("get_daily_trend", {
        "p_user_id": user_id,
    }).execute()

    month_total: float = total_res.data or 0
    top_category: Optional[str] = (
        breakdown_res.data[0]["category_id"] if breakdown_res.data else None
    )
    daily_totals = [row["total"] for row in (daily_res.data or [])]
    daily_average = sum(daily_totals) / len(daily_totals) if daily_totals else 0.0

    return SummaryResponse(
        top_category=top_category,
        daily_average=round(daily_average, 2),
        month_total=month_total,
    )
