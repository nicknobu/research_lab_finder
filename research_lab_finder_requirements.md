# 研究室検索サイト - 要件定義書

## 1. プロジェクト概要

### 1.1 アプリケーション名
**研究室ファインダー**（仮称）

### 1.2 基本コンセプト
中学生の漠然とした興味から全国の大学研究室をAIでレコメンドする統合検索プラットフォーム

### 1.3 目的・解決する課題
- **課題**: 中学生が大学の研究内容を知るには個々の研究室サイトを訪問する必要がある
- **解決**: 1つのプラットフォームで全国の研究室を網羅的に検索・レコメンド可能に
- **価値**: 中学生の将来の進路選択と学習意欲向上を支援

### 1.4 対象ユーザー
- **メインユーザー**: 中学生（全学年）
- **サブユーザー**: 保護者

## 2. 機能要件

### 2.1 MVP機能（Phase 1: 2か月以内）

#### 2.1.1 興味・関心入力機能
- **概要**: 中学生が興味・関心を自由なテキストで入力
- **入力方式**: 単語または文章での自由入力
- **例**: 「宇宙」「ロボット」「将来、地球温暖化を解決したい」「ゲームを作りたい」
- **UI**: シンプルな検索ボックス + 入力例の表示

#### 2.1.2 セマンティック検索機能
- **概要**: 入力された興味を研究内容とセマンティック検索でマッチング
- **技術**: OpenAI Embeddings API + ベクトル検索
- **処理フロー**:
  1. ユーザー入力をベクトル化
  2. 研究内容ベクトルとの類似度計算
  3. 推奨度順にソート・表示

#### 2.1.3 研究室情報表示機能
- **表示項目**:
  - 研究室名
  - 大学名・学部名
  - 研究テーマ・概要
  - 研究分野（カテゴリ）
  - 研究室URL（詳細情報へのリンク）
  - 推奨度スコア
- **表示形式**: カード形式のリスト表示

#### 2.1.4 基本フィルタリング機能
- **地域絞り込み**: 関東、関西、東海、九州など
- **研究分野絞り込み**: 物理学、化学、生物学、工学、情報科学など

### 2.2 Phase 2機能（MVP後に実装）
- お気に入り・ブックマーク機能
- 類似研究室提案機能
- 入試情報表示機能（試験方法、学部定員）
- 詳細な研究室情報（写真、動画等）

## 3. 技術要件

### 3.1 アーキテクチャ
- **プラットフォーム**: Webアプリケーション（レスポンシブデザイン）
- **構成**: SPA（Single Page Application）

### 3.2 技術スタック

#### 3.2.1 フロントエンド
- **フレームワーク**: React 18 + TypeScript
- **UIライブラリ**: Tailwind CSS
- **状態管理**: React Query + Zustand
- **ビルドツール**: Vite

#### 3.2.2 バックエンド
- **フレームワーク**: Python 3.11 + FastAPI
- **データベース**: PostgreSQL + pgvector（ベクトル検索）
- **認証**: 不要（MVP版）
- **API設計**: RESTful API

#### 3.2.3 AI・データ処理
- **セマンティック検索**: OpenAI Embeddings API (text-embedding-3-small)
- **ベクトルDB**: PostgreSQL + pgvector（コスト効率重視）
- **スクレイピング**: Beautiful Soup 4 + Scrapy
- **データ処理**: pandas

#### 3.2.4 インフラ・デプロイ
- **フロントエンド**: Vercel（無料枠）
- **バックエンド**: Railway または Render（低コスト）
- **データベース**: Supabase（PostgreSQL + pgvector対応）

### 3.3 データソース

#### 3.3.1 対象大学
- **国公立大学**: 全国約170校
- **私立大学**: 偏差値上位50校
- **想定研究室数**: 1,000-2,000件

#### 3.3.2 収集データ項目
- 大学名・学部名・学科名
- 研究室名・教授名
- 研究テーマ・研究内容
- 研究分野（カテゴリ）
- 研究室URL
- 所在地（都道府県）

#### 3.3.3 データ更新頻度
- **更新周期**: 半年に1回
- **更新方法**: 自動スクレイピング + 手動チェック

## 4. 制約条件

### 4.1 開発期間
- **MVP開発期間**: 2か月
- **開発スケジュール**:
  - Week 1-2: 技術選定・環境構築・データ設計
  - Week 3-4: スクレイピング機能開発・データ収集
  - Week 5-6: バックエンドAPI開発・セマンティック検索実装
  - Week 7-8: フロントエンド開発・統合・テスト

### 4.2 予算制約
- **開発予算**: 個人開発（最小構成）
- **運用コスト**: 月額3,000円以内
  - OpenAI API: 月額1,000-1,500円想定
  - インフラ: 月額1,000-1,500円想定

### 4.3 技術的制約

#### 4.3.1 法的・倫理的制約
- 各大学のrobots.txt遵守
- 利用規約の事前確認
- 適切なスクレイピング間隔（1-2秒）
- User-Agent設定、連絡先明記

#### 4.3.2 パフォーマンス制約
- 検索レスポンス時間: 3秒以内
- 同時接続数: 100ユーザー想定
- データ更新時間: 24時間以内

## 5. 成功の定義

### 5.1 技術的成功指標
- ✅ 対象大学の研究室データが取得できる
- ✅ 研究内容が適切に取得・構造化できる
- ✅ セマンティック検索が機能する
- ✅ 推奨度順でのリスト表示が実現できる

### 5.2 ユーザー体験成功指標
- 中学生が直感的に操作できるUI/UX
- 入力した興味に関連する研究室が適切に推奨される
- 研究室の詳細情報へスムーズにアクセスできる

## 6. リスク管理

### 6.1 技術リスク
- **スクレイピング対象サイトの構造変更**: 複数の収集方法の準備
- **API利用制限**: 予算オーバー時の代替手段（オープンソースモデル）
- **検索精度不足**: 検索アルゴリズムの調整・改善

### 6.2 法的リスク
- **著作権・利用規約違反**: 事前確認と適切な利用
- **データの取り扱い**: 個人情報は収集しない方針

## 7. 開発優先度

### 7.1 High Priority（MVP必須）
1. データ収集・構造化
2. セマンティック検索機能
3. 基本的なUI/UX
4. 研究室情報表示

### 7.2 Medium Priority（Phase 2）
1. フィルタリング機能強化
2. お気に入り機能
3. 入試情報表示

### 7.3 Low Priority（将来検討）
1. ユーザー登録・ログイン機能
2. 研究室評価・レビュー機能
3. 進路相談機能

## 8. 技術実装詳細

### 8.1 データベース設計

```sql
-- Universities table
CREATE TABLE universities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'national', 'public', 'private'
    prefecture VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Research labs table
CREATE TABLE research_labs (
    id SERIAL PRIMARY KEY,
    university_id INTEGER REFERENCES universities(id),
    name VARCHAR(255) NOT NULL,
    professor_name VARCHAR(255),
    department VARCHAR(255),
    research_theme TEXT NOT NULL,
    research_content TEXT NOT NULL,
    research_field VARCHAR(100) NOT NULL,
    lab_url VARCHAR(500),
    embedding vector(1536), -- OpenAI embedding dimension
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create vector similarity index
CREATE INDEX ON research_labs USING ivfflat (embedding vector_cosine_ops);
```

### 8.2 API設計

```python
# FastAPI endpoints
@app.post("/api/search")
async def search_labs(query: SearchQuery):
    """セマンティック検索API"""
    
@app.get("/api/labs/{lab_id}")
async def get_lab_detail(lab_id: int):
    """研究室詳細取得API"""
    
@app.get("/api/universities")
async def get_universities():
    """大学一覧取得API"""
    
@app.get("/api/fields")
async def get_research_fields():
    """研究分野一覧取得API"""
```

### 8.3 セマンティック検索フロー

```python
async def semantic_search(user_query: str, limit: int = 20):
    # 1. ユーザークエリをベクトル化
    query_embedding = await get_embedding(user_query)
    
    # 2. ベクトル類似度検索
    results = await db.execute(
        """
        SELECT *, 1 - (embedding <=> %s) as similarity
        FROM research_labs
        ORDER BY embedding <=> %s
        LIMIT %s
        """,
        [query_embedding, query_embedding, limit]
    )
    
    # 3. 結果を返す
    return results
```

## 9. 次のステップ

1. **技術検証**: セマンティック検索の精度テスト
2. **プロトタイプ開発**: 小規模データでのMVP構築
3. **データ収集開始**: 対象大学のスクレイピング実装
4. **MVP開発**: 本格的な開発着手

---

**作成日**: 2025年6月15日  
**バージョン**: 1.0  
**作成者**: AI駆動開発チーム