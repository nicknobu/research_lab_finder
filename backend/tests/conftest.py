# backend/tests/conftest.py
import pytest
import asyncio
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.database import Base, get_db
from app.models import University, ResearchLab
from app.core.semantic_search import search_engine

# テスト用データベース設定
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(scope="session")
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    
    # テストデータの作成
    test_university = University(
        name="テスト大学",
        type="private",
        prefecture="東京都",
        region="関東"
    )
    db.add(test_university)
    db.commit()
    db.refresh(test_university)
    
    test_lab = ResearchLab(
        university_id=test_university.id,
        name="テスト研究室",
        professor_name="テスト教授",
        department="テスト学部",
        research_theme="テスト研究テーマ",
        research_content="これはテスト用の研究内容です。免疫学に関する研究を行っています。",
        research_field="免疫学",
        speciality="テスト専門分野",
        keywords="テスト,免疫学,研究",
        lab_url="https://test-lab.example.com"
    )
    db.add(test_lab)
    db.commit()
    
    yield db
    
    db.close()
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def mock_openai_embedding(monkeypatch):
    """OpenAI API呼び出しをモック化"""
    def mock_embedding(text):
        # テスト用の固定ベクトル（1536次元）
        return [0.1] * 1536
    
    monkeypatch.setattr(search_engine, "get_embedding", lambda text: mock_embedding(text))


# backend/tests/test_api.py
import pytest
from fastapi.testclient import TestClient


def test_health_check(client: TestClient):
    """ヘルスチェックエンドポイントのテスト"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "message" in data
    assert "version" in data


def test_root_redirect(client: TestClient):
    """ルートエンドポイントのリダイレクトテスト"""
    response = client.get("/", allow_redirects=False)
    assert response.status_code == 307
    assert "/docs" in response.headers["location"]


class TestSearchAPI:
    """検索APIのテスト"""
    
    def test_search_valid_query(self, client: TestClient, mock_openai_embedding):
        """有効なクエリでの検索テスト"""
        search_data = {
            "query": "免疫学の研究をしたい",
            "limit": 10,
            "min_similarity": 0.5
        }
        
        response = client.post("/api/search/", json=search_data)
        assert response.status_code == 200
        
        data = response.json()
        assert "query" in data
        assert "total_results" in data
        assert "search_time_ms" in data
        assert "results" in data
        assert data["query"] == search_data["query"]
    
    def test_search_empty_query(self, client: TestClient):
        """空のクエリでの検索テスト"""
        search_data = {
            "query": "",
            "limit": 10
        }
        
        response = client.post("/api/search/", json=search_data)
        assert response.status_code == 422  # バリデーションエラー
    
    def test_search_with_filters(self, client: TestClient, mock_openai_embedding):
        """フィルター付き検索テスト"""
        search_data = {
            "query": "研究",
            "limit": 10,
            "region_filter": ["関東"],
            "field_filter": ["免疫学"],
            "min_similarity": 0.3
        }
        
        response = client.post("/api/search/", json=search_data)
        assert response.status_code == 200
    
    def test_get_search_suggestions(self, client: TestClient):
        """検索候補取得テスト"""
        response = client.get("/api/search/suggestions?q=免疫&limit=5")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
    
    def test_get_popular_searches(self, client: TestClient):
        """人気検索取得テスト"""
        response = client.get("/api/search/popular?limit=10")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)


class TestLabsAPI:
    """研究室APIのテスト"""
    
    def test_get_labs(self, client: TestClient):
        """研究室一覧取得テスト"""
        response = client.get("/api/labs/")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
    
    def test_get_lab_detail_valid_id(self, client: TestClient, db):
        """有効IDでの研究室詳細取得テスト"""
        response = client.get("/api/labs/1")
        assert response.status_code == 200
        
        data = response.json()
        assert "id" in data
        assert "name" in data
        assert "research_content" in data
        assert "university" in data
    
    def test_get_lab_detail_invalid_id(self, client: TestClient):
        """無効IDでの研究室詳細取得テスト"""
        response = client.get("/api/labs/99999")
        assert response.status_code == 404
    
    def test_get_labs_with_filters(self, client: TestClient):
        """フィルター付き研究室一覧取得テスト"""
        response = client.get("/api/labs/?research_field=免疫学&region=関東")
        assert response.status_code == 200


class TestUniversitiesAPI:
    """大学APIのテスト"""
    
    def test_get_universities(self, client: TestClient):
        """大学一覧取得テスト"""
        response = client.get("/api/labs/universities/")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
    
    def test_get_regions(self, client: TestClient):
        """地域一覧取得テスト"""
        response = client.get("/api/universities/regions")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
    
    def test_get_research_fields(self, client: TestClient):
        """研究分野一覧取得テスト"""
        response = client.get("/api/universities/research-fields")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)
    
    def test_get_statistics(self, client: TestClient):
        """統計情報取得テスト"""
        response = client.get("/api/universities/statistics")
        assert response.status_code == 200
        
        data = response.json()
        assert "total_universities" in data
        assert "total_labs" in data
        assert "labs_by_region" in data
        assert "labs_by_field" in data


# backend/tests/test_semantic_search.py
import pytest
from unittest.mock import AsyncMock, patch
from app.core.semantic_search import SemanticSearchEngine


class TestSemanticSearchEngine:
    """セマンティック検索エンジンのテスト"""
    
    @pytest.fixture
    def search_engine(self):
        return SemanticSearchEngine()
    
    @pytest.mark.asyncio
    async def test_get_embedding_success(self, search_engine):
        """埋め込みベクトル生成成功テスト"""
        with patch('openai.Embedding.create') as mock_create:
            mock_create.return_value = {
                'data': [{'embedding': [0.1] * 1536}]
            }
            
            result = await search_engine.get_embedding("テストテキスト")
            assert len(result) == 1536
            assert result[0] == 0.1
    
    @pytest.mark.asyncio
    async def test_get_embedding_empty_text(self, search_engine):
        """空テキストでの埋め込みベクトル生成テスト"""
        with pytest.raises(ValueError):
            await search_engine.get_embedding("")
    
    @pytest.mark.asyncio
    async def test_search_labs(self, search_engine, db, mock_openai_embedding):
        """研究室検索テスト"""
        results, search_time = await search_engine.search_labs(
            db=db,
            query="免疫学の研究",
            limit=10
        )
        
        assert isinstance(results, list)
        assert search_time > 0


# backend/tests/test_models.py
import pytest
from app.models import University, ResearchLab


class TestModels:
    """データベースモデルのテスト"""
    
    def test_university_creation(self, db):
        """大学モデル作成テスト"""
        university = University(
            name="テスト大学2",
            type="national",
            prefecture="京都府", 
            region="関西"
        )
        
        db.add(university)
        db.commit()
        db.refresh(university)
        
        assert university.id is not None
        assert university.name == "テスト大学2"
        assert university.type == "national"
    
    def test_research_lab_creation(self, db):
        """研究室モデル作成テスト"""
        # 大学を先に作成
        university = University(
            name="テスト大学3",
            type="private",
            prefecture="大阪府",
            region="関西"
        )
        db.add(university)
        db.commit()
        db.refresh(university)
        
        # 研究室作成
        lab = ResearchLab(
            university_id=university.id,
            name="テスト研究室2",
            professor_name="テスト教授2",
            research_theme="テストテーマ2",
            research_content="テスト内容2",
            research_field="工学"
        )
        
        db.add(lab)
        db.commit()
        db.refresh(lab)
        
        assert lab.id is not None
        assert lab.university_id == university.id
        assert lab.name == "テスト研究室2"
    
    def test_university_research_labs_relationship(self, db):
        """大学-研究室リレーションシップテスト"""
        university = db.query(University).first()
        
        assert university is not None
        assert len(university.research_labs) > 0
        
        lab = university.research_labs[0]
        assert lab.university.id == university.id


# backend/pytest.ini
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --tb=short
    --strict-markers
    --disable-warnings
markers =
    slow: marks tests as slow
    integration: marks tests as integration tests
    unit: marks tests as unit tests