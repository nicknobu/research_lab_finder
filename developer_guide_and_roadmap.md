# 研究室ファインダー 開発者ガイド & 拡張ロードマップ 🛠️

## 📋 開発者向けクイックスタート

### 前提条件
- Docker & Docker Compose
- Node.js 18+ (ローカル開発時)
- Python 3.11+ (ローカル開発時)
- OpenAI API Key

### 開発環境セットアップ
```bash
# 1. リポジトリクローン
git clone https://github.com/yourusername/research-lab-finder.git
cd research-lab-finder

# 2. 環境変数設定
cp .env.example .env
# OpenAI APIキーを設定

# 3. ワンクリックセットアップ
./scripts/one_click_deploy.sh --api-key YOUR_API_KEY

# 4. 開発用起動
./scripts/run_dev.sh
```

### 開発用コマンド
```bash
# ログ監視
docker-compose logs -f

# 個別サービス再起動
docker-compose restart backend
docker-compose restart frontend

# データベースリセット
./scripts/reset_data.sh

# テスト実行
docker-compose exec backend pytest
cd frontend && npm test

# 最終確認
./scripts/final_verification.sh
```

## 🏗️ アーキテクチャ詳細

### システム構成図
```
┌─────────────────┐    HTTP/JSON   ┌─────────────────┐
│   React SPA     │──────────────▶│  FastAPI        │
│   (Frontend)    │               │  (Backend)      │
│   TypeScript    │               │  Python         │
│   Tailwind CSS  │               └─────────────────┘
└─────────────────┘                        │
                                           │ SQL
                                           ▼
                                 ┌─────────────────┐
                                 │  PostgreSQL     │
                                 │  + pgvector     │
                                 │  (Database)     │
                                 └─────────────────┘
                                           ▲
                                           │ API
                                 ┌─────────────────┐
                                 │  OpenAI API     │
                                 │  (Embeddings)   │
                                 └─────────────────┘
```

### データフロー
1. **ユーザー入力** → React フロントエンド
2. **検索クエリ** → FastAPI バックエンド
3. **埋め込み生成** → OpenAI Embeddings API
4. **ベクトル検索** → PostgreSQL + pgvector
5. **結果返却** → JSON レスポンス
6. **UI表示** → React コンポーネント

### 技術スタック詳細

#### フロントエンド
- **React 18**: 関数コンポーネント + Hooks
- **TypeScript**: 型安全性確保
- **Tailwind CSS**: ユーティリティファーストCSS
- **React Query**: サーバー状態管理
- **Zustand**: クライアント状態管理
- **Vite**: 高速ビルドツール

#### バックエンド
- **FastAPI**: 非同期Pythonフレームワーク
- **SQLAlchemy**: ORM・データベース操作
- **Pydantic**: データバリデーション
- **Asyncio**: 非同期処理
- **OpenAI API**: セマンティック検索

#### データベース
- **PostgreSQL 15**: メインデータベース
- **pgvector**: ベクトル検索拡張
- **HNSW インデックス**: 高速近似最近傍探索

#### インフラ
- **Docker**: コンテナ化
- **nginx**: リバースプロキシ (本番)
- **GitHub Actions**: CI/CD

## 🔧 コード構造解説

### バックエンド構造
```
backend/
├── app/
│   ├── main.py              # FastAPIメインアプリ
│   ├── config.py            # 設定管理
│   ├── database.py          # DB接続・セッション
│   ├── models.py            # SQLAlchemyモデル
│   ├── schemas.py           # Pydanticスキーマ
│   ├── api/
│   │   └── endpoints/       # APIエンドポイント
│   │       ├── search.py    # 検索API
│   │       ├── labs.py      # 研究室API
│   │       └── admin.py     # 管理者API
│   ├── core/
│   │   └── semantic_search.py  # セマンティック検索エンジン
│   └── utils/
│       └── data_loader.py   # データ読み込み
└── tests/                   # テストコード
```

### フロントエンド構造
```
frontend/src/
├── components/              # 再利用可能コンポーネント
│   ├── SearchBox.tsx       # 検索ボックス
│   ├── LabCard.tsx         # 研究室カード
│   └── FilterPanel.tsx     # フィルターパネル
├── pages/                  # ページコンポーネント
│   ├── Home.tsx            # ホームページ
│   ├── SearchResults.tsx   # 検索結果ページ
│   └── LabDetail.tsx       # 研究室詳細ページ
├── hooks/                  # カスタムHooks
├── types/                  # TypeScript型定義
├── utils/                  # ユーティリティ関数
│   └── api.ts              # API クライアント
└── store/                  # 状態管理
```

## 🔍 主要機能の実装詳細

### セマンティック検索の仕組み

#### 1. 埋め込みベクトル生成
```python
# backend/app/core/semantic_search.py
async def get_embedding(self, text: str) -> List[float]:
    response = openai.Embedding.create(
        model="text-embedding-3-small",
        input=text
    )
    return response['data'][0]['embedding']
```

#### 2. ベクトル類似度検索
```sql
-- PostgreSQL + pgvector クエリ
SELECT 
    rl.*,
    1 - (rl.embedding <=> %s) as similarity_score
FROM research_labs rl
WHERE rl.embedding IS NOT NULL
ORDER BY rl.embedding <=> %s
LIMIT %s;
```

#### 3. 結果ランキング
- コサイン類似度による関連性スコア
- フィルター条件の適用
- 推奨度順ソート

### データベース最適化

#### インデックス戦略
```sql
-- ベクトル検索インデックス (HNSW)
CREATE INDEX idx_research_labs_embedding_hnsw 
ON research_labs USING hnsw (embedding vector_cosine_ops) 
WITH (m = 16, ef_construction = 64);

-- 複合インデックス
CREATE INDEX idx_labs_university_field 
ON research_labs(university_id, research_field);
```

#### パフォーマンス設定
```sql
-- PostgreSQL 最適化
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '16MB';
```

## 🧪 テスト戦略

### テストピラミッド
```
        ┌──────────────┐
        │  E2E Tests   │  (Playwright)
        │   (少数)      │
        └──────────────┘
      ┌────────────────────┐
      │ Integration Tests  │  (FastAPI TestClient)
      │     (中程度)        │
      └────────────────────┘
    ┌──────────────────────────┐
    │     Unit Tests           │  (Jest + pytest)
    │      (多数)              │
    └──────────────────────────┘
```

### テスト実行
```bash
# バックエンド単体テスト
docker-compose exec backend pytest -v

# フロントエンド単体テスト
cd frontend && npm test

# 統合テスト
python scripts/integration_test.py

# E2Eテスト
cd frontend && npx playwright test

# 最終確認
./scripts/final_verification.sh
```

## 📊 監視・運用

### メトリクス収集
- **応答時間**: 検索API の平均応答時間
- **スループット**: 1分間あたりの検索数
- **エラー率**: HTTP 5xx エラーの発生率
- **データベース**: クエリ実行時間、接続数

### ログ監視
```bash
# リアルタイムログ監視
docker-compose logs -f

# エラーログ抽出
docker-compose logs | grep ERROR

# パフォーマンス監視
./scripts/monitoring.sh
```

### アラート設定
```bash
# Discord通知設定例
if ! curl -f http://localhost:8000/health; then
    ./scripts/alert.sh "Backend service down"
fi
```

## 🚀 将来拡張ロードマップ

### Phase 1: 基盤強化 (1-3ヶ月)

#### 1.1 ユーザー体験向上
- [ ] **検索候補機能強化**
  - 入力補完機能
  - 検索履歴機能
  - 関連検索提案

- [ ] **結果表示改善**
  - 無限スクロール
  - 詳細フィルター（設立年、学生数等）
  - ソート機能（関連度、設立年等）

- [ ] **お気に入り機能**
  - ローカルストレージ活用
  - 比較機能
  - エクスポート機能

#### 1.2 データ拡充
- [ ] **研究室データ拡張**
  - 100+ 研究室に拡張
  - 全研究分野対応（工学、理学、医学等）
  - 研究成果・論文情報追加

- [ ] **メタデータ強化**
  - 研究室写真・動画
  - 教授略歴
  - 学生の声・体験談

#### 1.3 検索精度向上
- [ ] **AI モデル最適化**
  - ファインチューニング
  - 日本語特化最適化
  - ドメイン特化embedding

- [ ] **フィードバック学習**
  - ユーザー評価収集
  - クリック率による学習
  - 検索品質向上

### Phase 2: 機能拡張 (3-6ヶ月)

#### 2.1 パーソナライゼーション
- [ ] **ユーザー登録システム**
  - 安全な認証機能
  - プロファイル管理
  - プライバシー配慮

- [ ] **個人化推奨**
  - 興味分野学習
  - 個人向けダッシュボード
  - カスタマイズ可能UI

- [ ] **進路支援機能**
  - 学習パス提案
  - 関連科目推奨
  - 入試情報統合

#### 2.2 コミュニティ機能
- [ ] **質問・相談システム**
  - Q&A プラットフォーム
  - 研究者への質問機能
  - 学生同士の交流

- [ ] **レビュー・評価**
  - 研究室レビュー
  - 匿名評価システム
  - 信頼性スコア

#### 2.3 教育機関連携
- [ ] **学校向け機能**
  - 教師用ダッシュボード
  - 授業連携機能
  - 生徒進路追跡

- [ ] **大学連携**
  - 公式データ連携
  - リアルタイム情報更新
  - 見学申込み機能

### Phase 3: プラットフォーム拡張 (6-12ヶ月)

#### 3.1 対象拡張
- [ ] **高校生対応**
  - より詳細な研究情報
  - 大学院情報
  - 研究インターン情報

- [ ] **国際展開**
  - 英語版対応
  - 海外大学研究室
  - 多言語セマンティック検索

#### 3.2 AI機能強化
- [ ] **対話型AI**
  - チャットボット統合
  - 自然言語での詳細質問
  - 進路相談AI

- [ ] **予測分析**
  - 研究分野トレンド予測
  - 将来性分析
  - キャリアパス予測

#### 3.3 エコシステム構築
- [ ] **API プラットフォーム**
  - サードパーティ連携
  - 教育系アプリ統合
  - データ提供API

- [ ] **コンテンツ管理**
  - 研究者による情報更新
  - 自動データ収集
  - 品質管理システム

### Phase 4: 社会実装 (1年+)

#### 4.1 産業連携
- [ ] **企業研究所連携**
  - 企業研究室情報
  - インターンシップ情報
  - 産学連携プロジェクト

- [ ] **キャリア支援**
  - 就職情報統合
  - 業界分析
  - スキル需要予測

#### 4.2 政策・制度連携
- [ ] **教育政策支援**
  - 文科省データ連携
  - 教育効果測定
  - 政策提言機能

- [ ] **研究振興**
  - 研究資金情報
  - 共同研究促進
  - イノベーション支援

## 🛠️ 開発プロセス

### 開発フロー
1. **Issue 作成**: GitHub Issues でタスク管理
2. **ブランチ作成**: feature/issue-number-description
3. **開発・テスト**: ローカル環境で実装
4. **プルリクエスト**: レビュー依頼
5. **CI/CD**: 自動テスト・デプロイ
6. **リリース**: バージョンタグ付け

### コード品質基準
- **テストカバレッジ**: 80%以上
- **型安全性**: TypeScript strict モード
- **コードフォーマット**: Black (Python), Prettier (JS/TS)
- **ドキュメント**: docstring, JSDoc 必須
- **セキュリティ**: 自動脆弱性チェック

### リリース戦略
- **セマンティックバージョニング**: v1.0.0 形式
- **段階的リリース**: alpha → beta → stable
- **ホットフィックス**: 緊急修正用ブランチ
- **LTS版**: 長期サポート版提供

## 📝 コントリビューション

### 開発参加方法
1. **リポジトリフォーク**
2. **開発環境セットアップ**
3. **Issue 確認・選択**
4. **実装・テスト**
5. **プルリクエスト作成**

### コントリビューションガイドライン
- コード規約遵守
- 適切なテスト追加
- ドキュメント更新
- Breaking Changes の明記

## 🎯 技術的課題と解決策

### パフォーマンス最適化
- **課題**: 大量データでの検索速度
- **解決**: インデックス最適化、キャッシュ活用

### スケーラビリティ
- **課題**: ユーザー数増加への対応
- **解決**: マイクロサービス化、CDN活用

### AI精度向上
- **課題**: 検索結果の関連性
- **解決**: ファインチューニング、フィードバック学習

### データ品質
- **課題**: 情報の正確性・最新性
- **解決**: 自動更新システム、品質チェック

## 📞 開発者サポート

### ドキュメント
- API ドキュメント: http://localhost:8000/docs
- GitHub Wiki: 詳細な技術仕様
- Code Comments: インラインドキュメント

### コミュニケーション
- GitHub Discussions: 技術議論
- GitHub Issues: バグ報告・機能要求
- Pull Request: コードレビュー

### 開発環境サポート
- Docker 環境提供
- 開発用スクリプト完備
- CI/CD パイプライン整備

---

## 🌟 最後に

研究室ファインダーは、中学生の未来を拓く可能性を秘めたプロジェクトです。技術的な挑戦と社会的意義を両立させながら、継続的な改善を通じて、より多くの若者の進路選択を支援していきます。

開発に参加していただける方は、ぜひ GitHub リポジトリをご確認ください。一緒に素晴らしいシステムを構築していきましょう！

**Happy Coding! 🚀**

---
*最終更新: 2025年6月15日*  
*バージョン: 1.0.0*