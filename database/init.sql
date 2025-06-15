-- database/init.sql
-- PostgreSQL + pgvector 初期化スクリプト

-- pgvector拡張の有効化
CREATE EXTENSION IF NOT EXISTS vector;

-- データベース設定
SET client_encoding = 'UTF8';
SET timezone = 'Asia/Tokyo';

-- 大学テーブル
CREATE TABLE IF NOT EXISTS universities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('national', 'public', 'private')),
    prefecture VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 研究室テーブル
CREATE TABLE IF NOT EXISTS research_labs (
    id SERIAL PRIMARY KEY,
    university_id INTEGER NOT NULL REFERENCES universities(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    professor_name VARCHAR(255),
    department VARCHAR(255),
    research_theme TEXT NOT NULL,
    research_content TEXT NOT NULL,
    research_field VARCHAR(100) NOT NULL,
    speciality TEXT,
    keywords TEXT,
    lab_url VARCHAR(500),
    embedding vector(1536), -- OpenAI text-embedding-3-small の次元数
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 検索ログテーブル
CREATE TABLE IF NOT EXISTS search_logs (
    id SERIAL PRIMARY KEY,
    query TEXT NOT NULL,
    results_count INTEGER NOT NULL,
    search_time_ms FLOAT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- インデックスの作成
CREATE INDEX IF NOT EXISTS idx_universities_name ON universities(name);
CREATE INDEX IF NOT EXISTS idx_universities_region ON universities(region);
CREATE INDEX IF NOT EXISTS idx_universities_prefecture ON universities(prefecture);

CREATE INDEX IF NOT EXISTS idx_research_labs_university_id ON research_labs(university_id);
CREATE INDEX IF NOT EXISTS idx_research_labs_name ON research_labs(name);
CREATE INDEX IF NOT EXISTS idx_research_labs_research_field ON research_labs(research_field);
CREATE INDEX IF NOT EXISTS idx_research_labs_created_at ON research_labs(created_at);

-- ベクトル検索用インデックス (HNSW)
CREATE INDEX IF NOT EXISTS idx_research_labs_embedding_hnsw 
ON research_labs USING hnsw (embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- フルテキスト検索用インデックス
CREATE INDEX IF NOT EXISTS idx_research_labs_content_fts 
ON research_labs USING gin(to_tsvector('japanese', research_content || ' ' || research_theme));

CREATE INDEX IF NOT EXISTS idx_search_logs_timestamp ON search_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_search_logs_query ON search_logs(query);

-- updated_at の自動更新トリガー
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_research_labs_updated_at 
    BEFORE UPDATE ON research_labs 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 統計情報の更新
ANALYZE universities;
ANALYZE research_labs;
ANALYZE search_logs;

-- サンプルデータ（開発用）
INSERT INTO universities (name, type, prefecture, region) VALUES
('東京大学', 'national', '東京都', '関東'),
('京都大学', 'national', '京都府', '関西'),
('大阪大学', 'national', '大阪府', '関西'),
('横浜市立大学', 'public', '神奈川県', '関東'),
('東京理科大学', 'private', '東京都', '関東')
ON CONFLICT DO NOTHING;

-- 権限設定
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO postgres;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO postgres;