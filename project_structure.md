# 研究室検索システム - プロジェクト構造

```
research_lab_finder/
├── README.md
├── docker-compose.yml
├── .env.example
├── .gitignore
│
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── database.py
│   │   ├── models.py
│   │   ├── schemas.py
│   │   ├── crud.py
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── endpoints/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── search.py
│   │   │   │   ├── labs.py
│   │   │   │   └── universities.py
│   │   │   └── deps.py
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── semantic_search.py
│   │   │   └── embeddings.py
│   │   └── utils/
│   │       ├── __init__.py
│   │       └── data_loader.py
│   ├── data/
│   │   ├── immune_research_labs_50.csv
│   │   └── init_data.py
│   └── tests/
│       ├── __init__.py
│       ├── test_search.py
│       └── test_api.py
│
├── frontend/
│   ├── package.json
│   ├── package-lock.json
│   ├── tsconfig.json
│   ├── tailwind.config.js
│   ├── vite.config.ts
│   ├── index.html
│   ├── public/
│   │   └── favicon.ico
│   └── src/
│       ├── main.tsx
│       ├── App.tsx
│       ├── index.css
│       ├── components/
│       │   ├── SearchBox.tsx
│       │   ├── LabCard.tsx
│       │   ├── FilterPanel.tsx
│       │   ├── LoadingSpinner.tsx
│       │   └── ErrorMessage.tsx
│       ├── pages/
│       │   ├── Home.tsx
│       │   ├── SearchResults.tsx
│       │   └── LabDetail.tsx
│       ├── hooks/
│       │   ├── useSearch.ts
│       │   └── useApi.ts
│       ├── types/
│       │   └── index.ts
│       ├── utils/
│       │   └── api.ts
│       └── store/
│           └── searchStore.ts
│
├── database/
│   ├── init.sql
│   ├── schema.sql
│   └── seed.sql
│
└── scripts/
    ├── setup.sh
    ├── run_dev.sh
    ├── build.sh
    └── deploy.sh
```

## 主要コンポーネント

### バックエンド (FastAPI + PostgreSQL + pgvector)
- **FastAPI**: RESTful API
- **PostgreSQL**: メインデータベース
- **pgvector**: ベクトル検索拡張
- **OpenAI**: セマンティック検索

### フロントエンド (React + TypeScript + Tailwind CSS)
- **React 18**: UIフレームワーク
- **TypeScript**: 型安全性
- **Tailwind CSS**: スタイリング
- **Vite**: ビルドツール
- **Zustand**: 状態管理

### インフラ
- **Docker**: コンテナ化
- **docker-compose**: 開発環境
- **PostgreSQL + pgvector**: データベース

## 開発フロー

1. **環境構築**: `docker-compose up -d`
2. **バックエンド開発**: FastAPI + データベース
3. **フロントエンド開発**: React UI
4. **統合テスト**: API連携確認
5. **デプロイ**: 本番環境構築