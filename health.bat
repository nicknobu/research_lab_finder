@echo off
echo 🏥 システムヘルスチェック
echo.

echo === バックエンドAPI ===
curl -s http://localhost:8000/health && echo ✅ バックエンドAPI正常 || echo ❌ バックエンドAPI異常

echo.
echo === フロントエンド ===
curl -s http://localhost:3000 >nul && echo ✅ フロントエンド正常 || echo ❌ フロントエンド異常
