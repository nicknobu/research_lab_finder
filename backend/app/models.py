# backend/app/models.py
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from pgvector.sqlalchemy import Vector

from app.database import Base
from app.config import settings


class University(Base):
    """大学モデル"""
    __tablename__ = "universities"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, index=True)
    type = Column(String(50), nullable=False)  # 'national', 'public', 'private'
    prefecture = Column(String(50), nullable=False, index=True)
    region = Column(String(50), nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # リレーション
    research_labs = relationship("ResearchLab", back_populates="university")
    
    def __repr__(self):
        return f"<University(id={self.id}, name='{self.name}', prefecture='{self.prefecture}')>"


class ResearchLab(Base):
    """研究室モデル"""
    __tablename__ = "research_labs"
    
    id = Column(Integer, primary_key=True, index=True)
    university_id = Column(Integer, ForeignKey("universities.id"), nullable=False)
    name = Column(String(255), nullable=False, index=True)
    professor_name = Column(String(255))
    department = Column(String(255))
    research_theme = Column(Text, nullable=False)
    research_content = Column(Text, nullable=False)
    research_field = Column(String(100), nullable=False, index=True)
    speciality = Column(Text)
    keywords = Column(Text)  # カンマ区切りのキーワード
    lab_url = Column(String(500))
    
    # ベクトル検索用の埋め込み
    embedding = Column(Vector(settings.EMBEDDING_DIMENSION))
    
    # メタデータ
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # リレーション
    university = relationship("University", back_populates="research_labs")
    
    def __repr__(self):
        return f"<ResearchLab(id={self.id}, name='{self.name}', professor='{self.professor_name}')>"


class SearchLog(Base):
    """検索ログモデル"""
    __tablename__ = "search_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    query = Column(Text, nullable=False)
    results_count = Column(Integer, nullable=False)
    search_time_ms = Column(Float)  # 検索時間（ミリ秒）
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    
    def __repr__(self):
        return f"<SearchLog(id={self.id}, query='{self.query[:50]}...', results={self.results_count})>"