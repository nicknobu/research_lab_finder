# frontend/Dockerfile
FROM node:18-alpine

# 作業ディレクトリの設定
WORKDIR /app

# パッケージファイルをコピー
COPY package*.json ./

# 依存関係のインストール
RUN npm install --no-optional && npm cache clean --force

# アプリケーションコードをコピー
COPY . .

# ポート番号の公開
EXPOSE 3000

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# 開発サーバーの起動
CMD ["npm", "run", "dev"]
FROM node:18-alpine

# 作業ディレクトリの設定
WORKDIR /app

# パッケージファイルをコピー
COPY package*.json ./

# npm cache のクリーンアップとより確実な依存関係インストール
RUN npm cache clean --force && \
    rm -rf node_modules package-lock.json && \
    npm install --no-optional && \
    npm cache clean --force

# アプリケーションコードをコピー
COPY . .

# ポート番号の公開
EXPOSE 3000

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# 開発サーバーの起動
CMD ["npm", "run", "dev"]
