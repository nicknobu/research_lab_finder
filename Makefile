# 🔬 研究室ファインダー - 統合プロジェクト管理 Makefile

# ==================== 変数定義 ====================
PYTHON := python3
PIP := pip3
VENV := venv
REQUIREMENTS_DIR := requirements
BACKEND_DIR := backend
FRONTEND_DIR := frontend
SCRAPER_DIR := scraper

# 色付き出力
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# ==================== ヘルプ ====================
.PHONY: help
help: ## このヘルプメッセージを表示
	@echo "$(BLUE)🔬 研究室ファインダー - 統合プロジェクト管理$(NC)"
	@echo ""
	@echo "$(GREEN)利用可能なコマンド:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ==================== 環境セットアップ ====================
.PHONY: setup
setup: ## 開発環境の完全セットアップ
	@echo "$(GREEN)🚀 開発環境セットアップ開始$(NC)"
	$(MAKE) create-venv
	$(MAKE) install-all
	$(MAKE) setup-frontend
	@echo "$(GREEN)✅ セットアップ完了！$(NC)"

.PHONY: create-venv
create-venv: ## Python仮想環境作成
	@echo "$(BLUE)📦 Python仮想環境作成$(NC)"
	$(PYTHON) -m venv $(VENV)
	@echo "$(GREEN)✅ 仮想環境作成完了$(NC)"

.PHONY: activate
activate: ## 仮想環境有効化コマンド表示
	@echo "$(YELLOW)仮想環境を有効化してください:$(NC)"
	@echo "  source $(VENV)/Scripts/activate  # Windows"
	@echo "  source $(VENV)/bin/activate      # Linux/macOS"

# ==================== 依存関係管理 ====================
.PHONY: install-all
install-all: install-base install-backend install-scraper ## 全ての依存関係をインストール

.PHONY: install-base
install-base: ## 共通依存関係をインストール
	@echo "$(BLUE)📦 共通依存関係インストール$(NC)"
	$(PIP) install -r $(REQUIREMENTS_DIR)/base.txt
	@echo "$(GREEN)✅ 共通依存関係インストール完了$(NC)"

.PHONY: install-backend
install-backend: install-base ## バックエンド依存関係をインストール
	@echo "$(BLUE)📦 バックエンド依存関係インストール$(NC)"
	$(PIP) install -r $(REQUIREMENTS_DIR)/backend.txt
	@echo "$(GREEN)✅ バックエンド依存関係インストール完了$(NC)"

.PHONY: install-scraper
install-scraper: install-base ## スクレイピング依存関係をインストール
	@echo "$(BLUE)📦 スクレイピング依存関係インストール$(NC)"
	$(PIP) install -r $(REQUIREMENTS_DIR)/scraper.txt
	@echo "$(GREEN)✅ スクレイピング依存関係インストール完了$(NC)"

.PHONY: install-dev
install-dev: ## 開発・テスト依存関係をインストール
	@echo "$(BLUE)📦 開発・テスト依存関係インストール$(NC)"
	$(PIP) install -r $(REQUIREMENTS_DIR)/dev.txt
	@echo "$(GREEN)✅ 開発・テスト依存関係インストール完了$(NC)"

.PHONY: setup-frontend
setup-frontend: ## フロントエンド依存関係をインストール
	@echo "$(BLUE)📦 フロントエンド依存関係インストール$(NC)"
	cd $(FRONTEND_DIR) && npm install
	@echo "$(GREEN)✅ フロントエンド依存関係インストール完了$(NC)"

# ==================== 開発サーバー ====================
.PHONY: dev
dev: ## 開発サーバー起動（フル）
	@echo "$(GREEN)🚀 開発サーバー起動$(NC)"
	docker-compose up --build

.PHONY: dev-backend
dev-backend: ## バックエンドのみ起動
	@echo "$(BLUE)🔧 バックエンド開発サーバー起動$(NC)"
	cd $(BACKEND_DIR) && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

.PHONY: dev-frontend
dev-frontend: ## フロントエンドのみ起動
	@echo "$(BLUE)🎨 フロントエンド開発サーバー起動$(NC)"
	cd $(FRONTEND_DIR) && npm run dev

# ==================== スクレイピング ====================
.PHONY: scrape-test
scrape-test: ## テスト用スクレイピング実行
	@echo "$(BLUE)🕷️ テスト用スクレイピング実行$(NC)"
	$(PYTHON) -c "from scraper.config.interfaces import *; print('スクレイピングモジュール動作確認完了')"

# ==================== テスト ====================
.PHONY: test-imports
test-imports: ## インポートテスト実行
	@echo "$(BLUE)🧪 インポートテスト実行$(NC)"
	$(PYTHON) -c "from scraper.config.interfaces import ResearchLabData, FacultyType; print('✅ interfaces.py')"
	$(PYTHON) -c "from scraper.domain.research_lab import ResearchLab; print('✅ research_lab.py')"

# ==================== システム確認 ====================
.PHONY: status
status: ## プロジェクト状態表示
	@echo "$(BLUE)📊 プロジェクト状態$(NC)"
	@echo "$(YELLOW)Python仮想環境:$(NC)"
	@if [ -d "$(VENV)" ]; then echo "  ✅ 存在"; else echo "  ❌ 未作成"; fi
	@echo "$(YELLOW)Node.js モジュール:$(NC)"
	@if [ -d "$(FRONTEND_DIR)/node_modules" ]; then echo "  ✅ インストール済み"; else echo "  ❌ 未インストール"; fi
	@echo "$(YELLOW)Docker コンテナ:$(NC)"
	@docker-compose ps 2>/dev/null || echo "  ❌ Docker未起動"

.PHONY: health
health: ## システムヘルスチェック
	@echo "$(BLUE)🏥 システムヘルスチェック$(NC)"
	@curl -s http://localhost:8000/health && echo "✅ バックエンドAPI正常" || echo "❌ バックエンドAPI異常"
	@curl -s http://localhost:3000 >/dev/null && echo "✅ フロントエンド正常" || echo "❌ フロントエンド異常"

# ==================== Docker管理 ====================
.PHONY: docker-up
docker-up: ## Dockerコンテナ起動
	@echo "$(GREEN)🐳 Dockerコンテナ起動$(NC)"
	docker-compose up -d

.PHONY: docker-down
docker-down: ## Dockerコンテナ停止
	@echo "$(RED)🛑 Dockerコンテナ停止$(NC)"
	docker-compose down

.PHONY: docker-logs
docker-logs: ## Dockerログ表示
	@echo "$(BLUE)📋 Dockerログ表示$(NC)"
	docker-compose logs -f

# ==================== クリーンアップ ====================
.PHONY: clean
clean: ## 一時ファイル・キャッシュクリア
	@echo "$(BLUE)🧹 クリーンアップ実行$(NC)"
	find . -type d -name __pycache__ -delete 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ クリーンアップ完了$(NC)"

# ==================== デフォルトターゲット ====================
.DEFAULT_GOAL := help