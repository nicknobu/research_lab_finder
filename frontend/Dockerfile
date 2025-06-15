# frontend/Dockerfile
FROM node:20-alpine3.20

# セキュリティ更新とクリーンアップ
RUN apk update && apk upgrade && \
    apk add --no-cache \
    curl \
    dumb-init && \
    rm -rf /var/cache/apk/*

# 非root ユーザーの作成
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 作業ディレクトリの設定
WORKDIR /app

# package.jsonのみをコピー（package-lock.jsonは除外）
COPY package.json ./

# 所有権を変更
RUN chown -R nextjs:nodejs /app

# 非rootユーザーに切り替え
USER nextjs

# 依存関係の完全インストール（package-lock.jsonを再生成）
RUN npm cache clean --force && \
    npm install && \
    npm cache clean --force

# アプリケーションコードをコピー
COPY --chown=nextjs:nodejs . .

# ポート番号の公開
EXPOSE 3000

# ヘルスチェック（非root実行）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# dumb-initを使用してセキュアな起動
ENTRYPOINT ["dumb-init", "--"]

# 開発サーバーの起動
CMD ["npm", "run", "dev"]