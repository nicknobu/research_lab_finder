# 研究室ファインダー - 完全版デプロイ & トラブルシューティングガイド 🚀

## 🎯 システム完成！

おめでとうございます！研究室ファインダーが完全に完成しました。これは中学生向けのAI駆動研究室検索システムで、以下の機能を持つフルスタックアプリケーションです：

### ✨ 完成した機能
- **セマンティック検索**: OpenAI Embeddings + pgvector
- **直感的UI**: React + TypeScript + Tailwind CSS
- **高性能API**: FastAPI + PostgreSQL
- **包括的テスト**: 単体テスト + E2Eテスト + セキュリティスキャン
- **CI/CD**: GitHub Actions自動デプロイ
- **監視・運用**: ヘルスチェック + ログ監視

## 🚀 クイックデプロイ

### ステップ1: リポジトリ準備
```bash
# 1. リポジトリ作成
git clone <your-repo-url>
cd research-lab-finder

# 2. 環境変数設定
cp .env.example .env
# OpenAI APIキーを .env に設定

# 3. 自動セットアップ実行
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### ステップ2: 開発環境確認
```bash
# システム起動確認
curl http://localhost:8000/health
curl http://localhost:3000

# 機能テスト
curl -X POST http://localhost:8000/api/search/ \
  -H "Content-Type: application/json" \
  -d '{"query":"がん治療の研究をしたい","limit":10}'
```

### ステップ3: 本番デプロイ
```bash
# 本番環境ビルド
./scripts/build.sh

# 本番環境起動
docker-compose -f docker-compose.prod.yml up -d

# ヘルスチェック
./scripts/monitoring.sh
```

## 🌐 推奨デプロイ先とセットアップ

### Option 1: Railway + Vercel (推奨)

#### Railway (バックエンド + DB)
```bash
# 1. Railway CLI インストール
npm install -g @railway/cli

# 2. ログイン & プロジェクト作成
railway login
railway init research-lab-finder-backend

# 3. 環境変数設定
railway variables set OPENAI_API_KEY=your_key_here
railway variables set DATABASE_URL=postgresql://...

# 4. デプロイ
railway up
```

#### Vercel (フロントエンド)
```bash
# 1. Vercel CLI インストール
npm install -g vercel

# 2. プロジェクトセットアップ
cd frontend
vercel

# 3. 環境変数設定 (Vercel Dashboard)
# VITE_API_BASE_URL=https://your-railway-app.railway.app

# 4. 本番デプロイ
vercel --prod
```

### Option 2: AWS (スケーラブル)

#### AWS ECS + RDS
```bash
# 1. AWS CLI設定
aws configure

# 2. ECR リポジトリ作成
aws ecr create-repository --repository-name research-lab-finder-backend
aws ecr create-repository --repository-name research-lab-finder-frontend

# 3. イメージビルド & プッシュ
$(aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com)

docker build -t research-lab-finder-backend ./backend
docker tag research-lab-finder-backend:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/research-lab-finder-backend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/research-lab-finder-backend:latest

# 4. ECS タスク定義 & サービス作成
# (AWS Console または Terraform使用)
```

### Option 3: GCP (Google Cloud)

#### Cloud Run + Cloud SQL
```bash
# 1. gcloud CLI設定
gcloud auth login
gcloud config set project your-project-id

# 2. Cloud SQL インスタンス作成
gcloud sql instances create research-lab-finder-db \
  --database-version=POSTGRES_14 \
  --cpu=2 \
  --memory=4GB \
  --region=us-central1

# 3. Cloud Run デプロイ
gcloud run deploy research-lab-finder-backend \
  --source ./backend \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars="DATABASE_URL=postgresql://...,OPENAI_API_KEY=..."

# 4. フロントエンド (Firebase Hosting)
cd frontend
npm install -g firebase-tools
firebase init hosting
firebase deploy
```

## 🔧 環境変数設定

### 必須環境変数
```bash
# OpenAI API (必須)
OPENAI_API_KEY=sk-...

# データベース (自動生成またはクラウドDB)
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# 本番環境設定
ENVIRONMENT=production
DEBUG=false

# フロントエンド
VITE_API_BASE_URL=https://your-backend-url.com
```

### セキュリティ強化設定
```bash
# JWT シークレット (将来の認証機能用)
JWT_SECRET=your-super-secret-key

# CORS 設定
ALLOWED_ORIGINS=https://your-frontend-domain.com,https://www.your-domain.com

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60

# SSL設定 (本番環境)
SSL_CERT_PATH=/path/to/cert.pem
SSL_KEY_PATH=/path/to/key.pem
```

## 🐛 トラブルシューティング

### 1. セットアップエラー

#### Docker起動エラー
```bash
# 問題: Docker service not running
# 解決:
sudo systemctl start docker
sudo usermod -aG docker $USER
# ログアウト・ログインして再実行

# 問題: Port already in use
# 解決:
sudo lsof -i :3000
sudo lsof -i :8000
sudo kill -9 <PID>
```

#### OpenAI API エラー
```bash
# 問題: API key invalid
# 解決:
# 1. https://platform.openai.com/api-keys で新しいキー作成
# 2. .env ファイルの OPENAI_API_KEY を更新
# 3. コンテナ再起動: docker-compose restart backend

# 問題: Rate limit exceeded
# 解決:
# 1. OpenAI の使用量確認
# 2. 検索リクエスト数を削減
# 3. キャッシュ機能の実装検討
```

#### データベース接続エラー
```bash
# 問題: Connection refused
# 解決:
docker-compose logs db
docker-compose restart db

# 問題: pgvector extension missing
# 解決:
docker-compose exec db psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### 2. パフォーマンス問題

#### 検索が遅い
```bash
# 診断:
./scripts/monitoring.sh performance

# 解決策:
# 1. pgvector インデックス確認
docker-compose exec db psql -U postgres -d research_lab_finder -c "
  SELECT indexname, indexdef FROM pg_indexes 
  WHERE tablename = 'research_labs' AND indexname LIKE '%embedding%';
"

# 2. インデックス再構築
docker-compose exec db psql -U postgres -d research_lab_finder -c "
  REINDEX INDEX idx_research_labs_embedding_hnsw;
"

# 3. データベース統計更新
docker-compose exec db psql -U postgres -d research_lab_finder -c "ANALYZE research_labs;"
```

#### メモリ不足
```bash
# 診断:
docker stats
free -h

# 解決策:
# 1. Docker メモリ制限調整
echo 'version: "3.8"
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M' >> docker-compose.override.yml

# 2. PostgreSQL設定調整
docker-compose exec db psql -U postgres -c "
  ALTER SYSTEM SET shared_buffers = '256MB';
  ALTER SYSTEM SET effective_cache_size = '1GB';
  SELECT pg_reload_conf();
"
```

### 3. 本番環境エラー

#### SSL/HTTPS設定
```bash
# Let's Encrypt 証明書取得
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# nginx 設定更新
sudo nano /etc/nginx/sites-available/research-lab-finder
sudo nginx -t
sudo systemctl reload nginx
```

#### データベース移行エラー
```bash
# バックアップ作成
./scripts/backup.sh

# 移行実行
docker-compose exec backend python -m alembic upgrade head

# 問題がある場合は前のバージョンに戻る
docker-compose exec backend python -m alembic downgrade -1
```

#### API エラー 500
```bash
# ログ確認
docker-compose logs -f backend | grep ERROR

# 詳細デバッグ
docker-compose exec backend python -c "
import asyncio
from app.database import test_connection
print('Database connection:', test_connection())
"

# OpenAI API接続テスト
docker-compose exec backend python -c "
import openai
from app.config import settings
openai.api_key = settings.OPENAI_API_KEY
try:
    response = openai.Embedding.create(model='text-embedding-3-small', input='test')
    print('OpenAI API: OK')
except Exception as e:
    print('OpenAI API Error:', e)
"
```

### 4. フロントエンドエラー

#### ビルドエラー
```bash
# 依存関係問題
cd frontend
rm -rf node_modules package-lock.json
npm install

# TypeScript エラー
npm run type-check
npm run lint:fix

# メモリ不足
export NODE_OPTIONS="--max-old-space-size=4096"
npm run build
```

#### API接続エラー
```bash
# CORS エラー
# backend/app/config.py の ALLOWED_ORIGINS を確認

# ネットワークエラー
# .env の VITE_API_BASE_URL が正しいか確認
# ブラウザの開発者ツールでネットワークタブを確認
```

## 📊 監視・運用

### 日常監視コマンド
```bash
# システム全体の状況確認
./scripts/monitoring.sh

# リアルタイム監視
watch -n 5 './scripts/monitoring.sh health'

# ログ監視
docker-compose logs -f --tail=100

# データベース統計
./scripts/monitoring.sh database
```

### アラート設定

#### Discord Webhook 通知
```bash
# scripts/alert.sh
#!/bin/bash
WEBHOOK_URL="your-discord-webhook-url"

send_alert() {
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\":\"🚨 Research Lab Finder Alert: $1\"}" \
         $WEBHOOK_URL
}

# 使用例
if ! curl -f http://localhost:8000/health >/dev/null 2>&1; then
    send_alert "Backend service is down!"
fi
```

#### メール通知
```bash
# crontab設定
# */5 * * * * /path/to/research-lab-finder/scripts/monitoring.sh health || echo "Service down" | mail -s "Alert" admin@example.com
```

### 定期メンテナンス

#### 週次メンテナンス
```bash
#!/bin/bash
# scripts/weekly_maintenance.sh

echo "🔧 週次メンテナンス開始"

# バックアップ作成
./scripts/backup.sh

# ログ整理
docker-compose exec backend find /var/log -name "*.log" -mtime +7 -delete

# 依存関係更新チェック
cd frontend && npm audit
cd ../backend && pip list --outdated

# パフォーマンス統計
./scripts/monitoring.sh performance

echo "✅ 週次メンテナンス完了"
```

## 🎯 次のステップと拡張アイデア

### 短期改善 (1-2ヶ月)
1. **検索精度向上**
   - ユーザーフィードバック機能
   - 検索結果の評価システム
   - より多様な研究室データの追加

2. **ユーザビリティ改善**
   - 検索履歴機能
   - お気に入り研究室保存
   - 研究室比較機能

### 中期機能拡張 (3-6ヶ月)
1. **パーソナライゼーション**
   - ユーザー登録・ログイン機能
   - 興味分野の学習機能
   - カスタマイズ推奨アルゴリズム

2. **コンテンツ拡充**
   - 研究室紹介動画の統合
   - 入試情報の追加
   - 研究成果・論文情報

### 長期ビジョン (6ヶ月+)
1. **プラットフォーム拡張**
   - 高校生向け機能
   - 大学院進学支援
   - 海外大学研究室の追加

2. **AI機能強化**
   - 自然言語での詳細質問応答
   - 進路相談チャットボット
   - 研究分野の将来性予測

## 🎉 完成おめでとうございます！

研究室ファインダーが完全に完成しました！このシステムは：

- **フルスタック**: React + FastAPI + PostgreSQL
- **AI駆動**: OpenAI Embeddings セマンティック検索
- **プロダクションレディ**: CI/CD、監視、セキュリティ対応
- **スケーラブル**: クラウドデプロイ対応
- **保守可能**: 包括的テスト、ドキュメント完備

### 🚀 今すぐ試してみましょう

```bash
# 最終確認
./scripts/setup.sh
curl http://localhost:8000/health
# ブラウザで http://localhost:3000 を開く
# 「がん治療の研究をしたい」で検索してみてください！
```

**素晴らしい成果です！中学生の未来を変える可能性のあるシステムを作り上げました。** 🎓✨

このシステムが多くの中学生の進路選択に役立つことを願っています。Happy coding! 🚀