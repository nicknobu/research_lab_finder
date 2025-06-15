# 研究室ファインダー 🔬

中学生の興味・関心から全国の大学研究室をAIでレコメンドする統合検索プラットフォーム

## 🚀 クイックスタート

### 1. 環境準備

```bash
# リポジトリをクローン
git clone <your-repository-url>
cd research-lab-finder

# Python仮想環境作成
python -m venv venv

# 仮想環境を有効化
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

# 依存関係をインストール
pip install -r requirements.txt
```

### 2. 環境変数設定

```bash
# .envファイルを作成
cp .env.example .env

# .envファイルを編集してAPIキーを設定
# OPENAI_API_KEY=your-actual-openai-api-key-here
```

### 3. セマンティック検索プロトタイプ実行

```bash
python semantic_search_prototype.py
```

## 📁 プロジェクト構成

```
research-lab-finder/
├── semantic_search_prototype.py    # セマンティック検索技術検証
├── immune_research_scraper.py      # 免疫研究室スクレイピング
├── expanded_immune_labs_database.py # 50件研究室データベース
├── real_immune_scraper.py          # 実際のスクレイピング実装
├── requirements.txt                # Python依存関係
├── .env.example                   # 環境変数テンプレート
├── .env                          # 環境変数（.gitignoreに含まれる）
├── .gitignore                    # Git除外設定
└── README.md                     # このファイル
```

## 🔧 技術スタック

### 現在実装済み
- **セマンティック検索**: OpenAI Embeddings API + コサイン類似度
- **データ処理**: pandas, numpy
- **スクレイピング**: aiohttp, BeautifulSoup4
- **環境管理**: python-dotenv

### 将来実装予定
- **バックエンド**: FastAPI
- **データベース**: PostgreSQL + pgvector
- **フロントエンド**: React + TypeScript
- **デプロイ**: Vercel + Railway/Render

## 🧪 技術検証結果

セマンティック検索プロトタイプにより以下を確認：

✅ **動作確認済み**
- OpenAI Embeddings API との連携
- 中学生の自然な質問に対する適切な検索結果
- 実用的なレスポンス時間（1-3秒）
- コサイン類似度による関連度計算

📊 **テストクエリ例**
- 「アレルギーの治療法を研究したい」
- 「がんと免疫の関係について学びたい」
- 「腸内細菌と健康の関係に興味がある」

## 🎯 MVPロードマップ

### Phase 1: 技術検証 ✅ **完了**
- [x] セマンティック検索プロトタイプ
- [x] 免疫研究室データベース構築
- [x] スクレイピング基盤実装

### Phase 2: バックエンド開発 🚧 **進行中**
- [ ] PostgreSQL + pgvector 環境構築
- [ ] FastAPI プロジェクト初期化
- [ ] `/api/search` エンドポイント実装
- [ ] データベーススキーマ実装

### Phase 3: フロントエンド開発
- [ ] React + TypeScript プロジェクト初期化
- [ ] 基本検索UI作成
- [ ] レスポンシブデザイン実装

### Phase 4: 統合・デプロイ
- [ ] フロントエンド・バックエンド統合
- [ ] 本格的なデータ収集
- [ ] MVP デプロイ

## 🔑 API キー取得方法

1. [OpenAI Platform](https://platform.openai.com/) にアクセス
2. アカウント作成・ログイン
3. API Keys セクションで新しいキーを作成
4. `.env` ファイルに設定

## 💡 開発Tips

### デバッグモード
```bash
# ログレベルを DEBUG に設定
echo "LOG_LEVEL=DEBUG" >> .env
```

### API利用量確認
```bash
# OpenAI Usage ページで確認
# https://platform.openai.com/usage
```

### キャッシュクリア
```bash
# 埋め込みキャッシュをクリア（プログラム内で自動管理）
```

## 🤝 コントリビューション

1. Issue を作成して機能提案・バグ報告
2. Fork & Pull Request
3. テストコード追加推奨

## 📄 ライセンス

MIT License - 詳細は `LICENSE` ファイルを参照

## 📞 サポート

- Issues: GitHub Issues を使用
- Email: [your-email@example.com]
- Documentation: [プロジェクトWiki]

---

**次のステップ**: `python semantic_search_prototype.py` を実行して技術検証を開始！
