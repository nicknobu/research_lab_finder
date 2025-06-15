# backend/app/database.py
from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import StaticPool
import logging

from app.config import settings

logger = logging.getLogger(__name__)

# SQLAlchemy設定
engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    echo=settings.DEBUG,  # SQL文をログ出力（開発時のみ）
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


# データベースセッション依存性
def get_db() -> Session:
    """データベースセッションを取得"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def init_db():
    """データベース初期化"""
    try:
        # pgvector拡張の有効化確認
        with engine.connect() as conn:
            # pgvector拡張を作成（存在しない場合）
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            conn.commit()
            logger.info("✅ pgvector extension enabled")
        
        # テーブル作成
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created")
        
        # データ初期化の確認
        await check_and_load_initial_data()
        
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
        raise


async def check_and_load_initial_data():
    """初期データの確認と読み込み"""
    from app.models import University, ResearchLab
    from app.utils.data_loader import load_initial_data
    
    try:
        with SessionLocal() as db:
            # 大学データの確認
            university_count = db.query(University).count()
            lab_count = db.query(ResearchLab).count()
            
            if university_count == 0 or lab_count == 0:
                logger.info("Loading initial data...")
                await load_initial_data(db)
                logger.info("✅ Initial data loaded successfully")
            else:
                logger.info(f"Data already exists: {university_count} universities, {lab_count} labs")
                
    except Exception as e:
        logger.error(f"❌ Failed to load initial data: {e}")
        raise


# データベース接続テスト
def test_connection():
    """データベース接続テスト"""
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT 1"))
            return result.fetchone() is not None
    except Exception as e:
        logger.error(f"Database connection test failed: {e}")
        return False