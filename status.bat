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
