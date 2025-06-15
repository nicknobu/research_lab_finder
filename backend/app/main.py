# backend/app/main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
import uvicorn
from contextlib import asynccontextmanager

from app.api.endpoints import search, labs, universities
from app.database import engine, init_db
from app.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    """アプリケーション起動・終了時の処理"""
    print("🚀 Starting Research Lab Finder API...")
    
    # データベース初期化
    await init_db()
    print("✅ Database initialized")
    
    yield
    
    print("🛑 Shutting down Research Lab Finder API...")


# FastAPIアプリケーション作成
app = FastAPI(
    title="Research Lab Finder API",
    description="中学生向け研究室検索システムのバックエンドAPI",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# ルーター登録
app.include_router(
    search.router,
    prefix="/api/search",
    tags=["search"]
)

app.include_router(
    labs.router,
    prefix="/api/labs",
    tags=["labs"]
)

app.include_router(
    universities.router,
    prefix="/api/universities",
    tags=["universities"]
)

# ルートエンドポイント
@app.get("/")
async def root():
    """ルートエンドポイント - APIドキュメントにリダイレクト"""
    return RedirectResponse(url="/docs")

@app.get("/health")
async def health_check():
    """ヘルスチェックエンドポイント"""
    return {
        "status": "healthy",
        "message": "Research Lab Finder API is running",
        "version": "1.0.0"
    }

# デバッグ用メイン関数
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )