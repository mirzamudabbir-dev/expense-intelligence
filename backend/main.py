from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import analytics, budget

app = FastAPI(title="Spent API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
app.include_router(budget.router, prefix="/budget", tags=["budget"])


@app.get("/health")
def health():
    return {"status": "ok"}
