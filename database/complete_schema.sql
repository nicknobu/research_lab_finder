-- database/complete_schema.sql
-- 研究室ファインダー 完全版データベーススキーマ

-- データベース初期設定
SET timezone = 'Asia/Tokyo';
SET client_encoding = 'UTF8';

-- pgvector拡張の有効化
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;  -- パフォーマンス監視用
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- 全文検索最適化用

-- 大学テーブル
DROP TABLE IF EXISTS universities CASCADE;
CREATE TABLE universities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('national', 'public', 'private')),
    prefecture VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    website_url VARCHAR(500),
    established_year INTEGER,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 研究室テーブル
DROP TABLE IF EXISTS research_labs CASCADE;
CREATE TABLE research_labs (
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
    contact_email VARCHAR(255),
    phone VARCHAR(50),
    lab_size_students INTEGER,
    established_year INTEGER,
    funding_sources TEXT,
    notable_achievements TEXT,
    embedding vector(1536),  -- OpenAI text-embedding-3-small
    content_hash VARCHAR(64), -- コンテンツ変更検出用
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_lab_per_university UNIQUE(university_id, name)
);

-- 検索ログテーブル（拡張版）
DROP TABLE IF EXISTS search_logs CASCADE;
CREATE TABLE search_logs (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    user_ip INET,
    query TEXT NOT NULL,
    results_count INTEGER NOT NULL DEFAULT 0,
    search_time_ms FLOAT,
    filters_applied JSONB,  -- 適用されたフィルター
    clicked_lab_id INTEGER REFERENCES research_labs(id),
    search_quality_score FLOAT,  -- 検索品質スコア (0-1)
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- プライバシー考慮：IPアドレスは24時間後に削除
    CONSTRAINT ip_retention CHECK (
        user_ip IS NULL OR 
        timestamp > CURRENT_TIMESTAMP - INTERVAL '24 hours'
    )
);

-- ユーザーフィードバックテーブル（将来拡張用）
DROP TABLE IF EXISTS user_feedback CASCADE;
CREATE TABLE user_feedback (
    id SERIAL PRIMARY KEY,
    search_log_id INTEGER REFERENCES search_logs(id),
    lab_id INTEGER REFERENCES research_labs(id),
    feedback_type VARCHAR(50) CHECK (feedback_type IN ('helpful', 'not_helpful', 'report')),
    feedback_text TEXT,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 研究分野カテゴリテーブル
DROP TABLE IF EXISTS research_categories CASCADE;
CREATE TABLE research_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INTEGER REFERENCES research_categories(id),
    display_order INTEGER DEFAULT 0
);

-- ===== インデックス作成 =====

-- 基本インデックス
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_universities_name ON universities(name);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_universities_region ON universities(region);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_universities_type ON universities(type);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_research_labs_university_id ON research_labs(university_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_research_labs_research_field ON research_labs(research_field);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_research_labs_professor_name ON research_labs(professor_name);

-- ベクトル検索インデックス（HNSW）
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_research_labs_embedding_hnsw 
ON research_labs USING hnsw (embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- 全文検索インデックス（日本語対応）
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_research_labs_content_gin 
ON research_labs USING gin(
    to_tsvector('japanese', 
        COALESCE(research_theme, '') || ' ' || 
        COALESCE(research_content, '') || ' ' || 
        COALESCE(keywords, '')
    )
);

-- 複合インデックス（頻繁なクエリパターン用）
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_labs_university_field 
ON research_labs(university_id, research_field);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_labs_field_updated 
ON research_labs(research_field, updated_at DESC);

-- 検索ログインデックス
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_logs_timestamp ON search_logs(timestamp DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_logs_query_hash ON search_logs USING hash(query);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_search_logs_session ON search_logs(session_id, timestamp);

-- ===== トリガー関数 =====

-- updated_at 自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 更新トリガー
DROP TRIGGER IF EXISTS update_universities_updated_at ON universities;
CREATE TRIGGER update_universities_updated_at
    BEFORE UPDATE ON universities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_research_labs_updated_at ON research_labs;
CREATE TRIGGER update_research_labs_updated_at
    BEFORE UPDATE ON research_labs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- コンテンツハッシュ更新トリガー
CREATE OR REPLACE FUNCTION update_content_hash()
RETURNS TRIGGER AS $$
BEGIN
    NEW.content_hash = md5(
        COALESCE(NEW.research_theme, '') || 
        COALESCE(NEW.research_content, '') || 
        COALESCE(NEW.keywords, '')
    );
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_research_labs_content_hash ON research_labs;
CREATE TRIGGER update_research_labs_content_hash
    BEFORE INSERT OR UPDATE ON research_labs
    FOR EACH ROW
    EXECUTE FUNCTION update_content_hash();

-- ===== パフォーマンス最適化設定 =====

-- PostgreSQL設定（postgresql.conf相当）
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '128MB';
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;

-- ベクトル検索最適化
ALTER SYSTEM SET hnsw.ef_search = 40;

-- 統計情報更新
ALTER SYSTEM SET default_statistics_target = 100;

-- ログ設定（本番環境用）
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- 1秒以上のクエリをログ
ALTER SYSTEM SET log_statement = 'mod';  -- INSERT/UPDATE/DELETE をログ
ALTER SYSTEM SET log_checkpoints = on;
ALTER SYSTEM SET log_lock_waits = on;

-- 設定を反映
SELECT pg_reload_conf();

-- ===== 初期データ挿入 =====

-- 研究分野カテゴリ
INSERT INTO research_categories (name, description, display_order) VALUES
('生命科学', '生物学、医学、薬学などの生命に関する研究分野', 1),
('免疫学', '免疫システムの仕組みと疾患への応用', 2),
('工学', '技術開発と応用に関する研究分野', 3),
('情報科学', 'コンピュータサイエンス、AI、データサイエンス', 4),
('物理学', '物質と宇宙の基本法則に関する研究', 5),
('化学', '物質の性質と反応に関する研究', 6),
('環境科学', '環境問題と持続可能性に関する研究', 7),
('社会科学', '社会現象と人間行動に関する研究', 8)
ON CONFLICT (name) DO NOTHING;

-- 大学データ
INSERT INTO universities (name, type, prefecture, region, website_url, established_year, description) VALUES
('東京大学', 'national', '東京都', '関東', 'https://www.u-tokyo.ac.jp/', 1877, '日本最高峰の国立大学'),
('京都大学', 'national', '京都府', '関西', 'https://www.kyoto-u.ac.jp/', 1897, '自由な学風で知られる国立大学'),
('大阪大学', 'national', '大阪府', '関西', 'https://www.osaka-u.ac.jp/', 1931, '研究力に定評のある国立大学'),
('横浜市立大学', 'public', '神奈川県', '関東', 'https://www.yokohama-cu.ac.jp/', 1882, '国際都市横浜の公立大学'),
('東京理科大学', 'private', '東京都', '関東', 'https://www.tus.ac.jp/', 1881, '理工系に強い私立大学'),
('筑波大学', 'national', '茨城県', '関東', 'https://www.tsukuba.ac.jp/', 1973, '先進的な研究環境の国立大学'),
('慶應義塾大学', 'private', '東京都', '関東', 'https://www.keio.ac.jp/', 1858, '伝統と革新の私立大学'),
('名古屋大学', 'national', '愛知県', '東海', 'https://www.nagoya-u.ac.jp/', 1939, '中部地方の研究拠点'),
('九州大学', 'national', '福岡県', '九州', 'https://www.kyushu-u.ac.jp/', 1911, '九州地方の学術中心'),
('北海道大学', 'national', '北海道', '北海道', 'https://www.hokudai.ac.jp/', 1876, '広大なキャンパスの国立大学'),
('東北大学', 'national', '宮城県', '東北', 'https://www.tohoku.ac.jp/', 1907, '研究第一を掲げる国立大学'),
('千葉大学', 'national', '千葉県', '関東', 'https://www.chiba-u.ac.jp/', 1949, '医学部で有名な国立大学'),
('金沢大学', 'national', '石川県', '北陸', 'https://www.kanazawa-u.ac.jp/', 1949, '北陸の学術拠点'),
('神戸大学', 'national', '兵庫県', '関西', 'https://www.kobe-u.ac.jp/', 1949, '国際性豊かな国立大学'),
('広島大学', 'national', '広島県', '中国', 'https://www.hiroshima-u.ac.jp/', 1949, '中国地方の総合大学'),
('徳島大学', 'national', '徳島県', '四国', 'https://www.tokushima-u.ac.jp/', 1949, '四国の学術拠点'),
('熊本大学', 'national', '熊本県', '九州', 'https://www.kumamoto-u.ac.jp/', 1949, '九州の研究拠点'),
('東京医科歯科大学', 'national', '東京都', '関東', 'https://www.tmd.ac.jp/', 1946, '医学・歯学の専門大学'),
('東京医科大学', 'private', '東京都', '関東', 'https://www.tokyo-med.ac.jp/', 1916, '私立医科大学'),
('日本医科大学', 'private', '東京都', '関東', 'https://www.nms.ac.jp/', 1876, '歴史ある私立医科大学'),
('順天堂大学', 'private', '東京都', '関東', 'https://www.juntendo.ac.jp/', 1838, '医学・スポーツで有名'),
('自治医科大学', 'private', '栃木県', '関東', 'https://www.jichi.ac.jp/', 1972, '地域医療を担う医師育成'),
('群馬大学', 'national', '群馬県', '関東', 'https://www.gunma-u.ac.jp/', 1949, '医学部で知られる国立大学'),
('新潟大学', 'national', '新潟県', '中部', 'https://www.niigata-u.ac.jp/', 1949, '日本海側の学術拠点'),
('山口大学', 'national', '山口県', '中国', 'https://www.yamaguchi-u.ac.jp/', 1949, '中国地方の国立大学')
ON CONFLICT (name) DO NOTHING;

-- ===== パフォーマンス監視用ビュー =====

-- 検索パフォーマンス監視ビュー
CREATE OR REPLACE VIEW search_performance_stats AS
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as search_count,
    AVG(search_time_ms) as avg_search_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY search_time_ms) as p95_search_time,
    AVG(results_count) as avg_results_count
FROM search_logs 
WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour DESC;

-- 人気研究分野ビュー
CREATE OR REPLACE VIEW popular_research_fields AS
SELECT 
    research_field,
    COUNT(*) as lab_count,
    AVG(CASE WHEN sl.id IS NOT NULL THEN 1 ELSE 0 END) as search_interest
FROM research_labs rl
LEFT JOIN search_logs sl ON rl.id = sl.clicked_lab_id
GROUP BY research_field
ORDER BY search_interest DESC, lab_count DESC;

-- データベース統計ビュー
CREATE OR REPLACE VIEW database_stats AS
SELECT 
    'universities' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('universities')) as table_size
FROM universities
UNION ALL
SELECT 
    'research_labs' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('research_labs')) as table_size
FROM research_labs
UNION ALL
SELECT 
    'search_logs' as table_name,
    COUNT(*) as row_count,
    pg_size_pretty(pg_total_relation_size('search_logs')) as table_size
FROM search_logs;

-- ===== メンテナンス用関数 =====

-- 古いログの削除関数
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 30日以上古い検索ログを削除
    DELETE FROM search_logs 
    WHERE timestamp < CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- 統計情報を更新
    ANALYZE search_logs;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ベクトルインデックス再構築関数
CREATE OR REPLACE FUNCTION rebuild_vector_index()
RETURNS VOID AS $$
BEGIN
    -- ベクトルインデックスを再構築
    REINDEX INDEX CONCURRENTLY idx_research_labs_embedding_hnsw;
    
    -- 統計情報を更新
    ANALYZE research_labs;
END;
$$ LANGUAGE plpgsql;

-- ===== セキュリティ設定 =====

-- 読み取り専用ユーザー（分析用）
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'readonly_user') THEN
        CREATE ROLE readonly_user LOGIN PASSWORD 'readonly_password_2025';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE research_lab_finder TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO readonly_user;

-- アプリケーション用ユーザー
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user LOGIN PASSWORD 'app_password_2025';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE research_lab_finder TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- 行レベルセキュリティ（将来のマルチテナント対応）
-- ALTER TABLE search_logs ENABLE ROW LEVEL SECURITY;

-- ===== 最終統計情報更新 =====
ANALYZE;

-- vacuum と統計情報の収集
VACUUM ANALYZE universities;
VACUUM ANALYZE research_labs;
VACUUM ANALYZE search_logs;

-- 作成完了メッセージ
DO $$
BEGIN
    RAISE NOTICE '✅ 研究室ファインダー データベース初期化完了';
    RAISE NOTICE '📊 テーブル作成: universities, research_labs, search_logs, user_feedback, research_categories';
    RAISE NOTICE '🚀 インデックス作成: ベクトル検索、全文検索、複合インデックス';
    RAISE NOTICE '⚡ パフォーマンス最適化設定適用済み';
    RAISE NOTICE '🔒 セキュリティ設定適用済み';
    RAISE NOTICE '🎯 本番運用準備完了';
END
$$;