from pydantic import BaseModel
from typing import Optional


class BudgetStatusResponse(BaseModel):
    month: int
    year: int
    limit: Optional[float]
    spent: float
    remaining: Optional[float]
    percentage: Optional[float]
