from pydantic import BaseModel
from typing import List, Optional


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


class SummaryResponse(BaseModel):
    top_category: Optional[str]
    daily_average: float
    month_total: float
