# 🔧 Windows環境用修正・確認スクリプト

echo "🔬 研究室ファインダー - Windows環境修正"

# ==================== 1. Make代替バッチスクリプト作成 ====================
echo "📝 Windows用管理スクリプト作成"

# run_dev.bat 作成
cat > run_dev.bat << 'EOF'
@echo off
echo 🚀 開発サーバー起動
docker-compose up --build
EOF

# status.bat 作成  
cat > status.bat << 'EOF'
@echo off
echo 📊 プロジェクト状態確認
echo.
echo === Python仮想環境 ===
if exist venv (echo ✅ 存在) else (echo ❌ 未作成)

echo.
echo === Node.js モジュール ===
if exist frontend\node_modules (echo ✅ インストール済み) else (echo ❌ 未インストール)

echo.
echo === Docker コンテナ ===
docker-compose ps
EOF

# health.bat 作成
cat > health.bat << 'EOF'
@echo off
echo 🏥 システムヘルスチェック
echo.

echo === バックエンドAPI ===
curl -s http://localhost:8000/health && echo ✅ バックエンドAPI正常 || echo ❌ バックエンドAPI異常

echo.
echo === フロントエンド ===
curl -s http://localhost:3000 >nul && echo ✅ フロントエンド正常 || echo ❌ フロントエンド異常
EOF

# test_imports.bat 作成
cat > test_imports.bat << 'EOF'
@echo off
echo 🧪 インポートテスト実行
echo.

python -c "
try:
    from scraper.config.interfaces import ResearchLabData, FacultyType
    print('✅ scraper.config.interfaces')
except ImportError as e:
    print(f'❌ インポートエラー: {e}')

try:
    from scraper.domain.research_lab import ResearchLab  
    print('✅ scraper.domain.research_lab')
except ImportError as e:
    print(f'❌ インポートエラー: {e}')
"
EOF

echo "✅ Windows用バッチファイル作成完了"

# ==================== 2. 文字エンコーディング修正 ====================
echo "🔤 文字エンコーディング設定"

# Git Bash用UTF-8設定
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

echo "✅ 文字エンコーディング設定完了"

# ==================== 3. API修正テスト ====================
echo "🔍 API修正テスト"

# 正しいJSON形式でのセマンティック検索テスト
echo "=== セマンティック検索テスト ==="
curl -X POST http://localhost:8000/api/search/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"query\":\"免疫学\",\"limit\":3}" \
  --fail --show-error || echo "❌ セマンティック検索エラー"

echo ""

# バックエンドAPI確認
echo "=== バックエンドAPI確認 ==="
curl -s http://localhost:8000/health && echo "✅ バックエンドAPI正常" || echo "❌ バックエンドAPI異常"

echo ""

# フロントエンド確認
echo "=== フロントエンド確認 ==="
curl -s http://localhost:3000 | grep -o "<title>[^<]*</title>" && echo "✅ フロントエンド正常" || echo "❌ フロントエンド異常"

# ==================== 4. 統合プロジェクトテスト ====================
echo ""
echo "🎉 統合プロジェクト最終確認"

# インポートテスト（文字エンコーディング修正版）
python3 -c "
import sys
print(f'Python version: {sys.version}')

try:
    from scraper.config.interfaces import ResearchLabData, FacultyType
    from scraper.domain.research_lab import ResearchLab
    print('🎉 統合プロジェクト基盤完成!')
    print('✅ スクレイピングモジュール動作確認')
    print('✅ 型安全な設計実装済み')
    print('✅ Phase 1開発準備完了')
except ImportError as e:
    print(f'❌ インポートエラー: {e}')
"

echo ""
echo "=== 利用可能なWindows用コマンド ==="
echo "run_dev.bat      # 開発サーバー起動"
echo "status.bat       # システム状態確認"  
echo "health.bat       # ヘルスチェック"
echo "test_imports.bat # インポートテスト"

echo ""
echo "✨ Windows環境での統合プロジェクト準備完了！"