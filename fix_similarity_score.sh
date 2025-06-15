#!/bin/bash

echo "🔧 類似度スコア表示を修正中..."

# LabCard.tsx の類似度スコア処理を修正
cat > frontend/src/components/LabCard.tsx << 'EOF'
import React from 'react'
import { MapPin, User, ExternalLink, Star } from 'lucide-react'
import type { ResearchLabSearchResult } from '../types'

interface LabCardProps {
  lab: ResearchLabSearchResult
  onClick?: (lab: ResearchLabSearchResult) => void
}

const LabCard: React.FC<LabCardProps> = ({ lab, onClick }) => {
  const handleClick = () => {
    console.log('🏢 LabCard クリック:', lab.name, lab.id)
    if (onClick) {
      onClick(lab)
    } else {
      console.log('⚠️ onClick が設定されていません')
    }
  }

  const handleUrlClick = (e: React.MouseEvent) => {
    e.stopPropagation()
    console.log('🔗 外部リンククリック:', lab.lab_url)
  }

  // 類似度スコアの正規化と安全な処理
  const getSafeScore = (score: number | undefined | null): number => {
    if (typeof score !== 'number' || isNaN(score)) {
      console.log('⚠️ 無効なスコア:', score, '→ デフォルト値 0.5 を使用')
      return 0.5 // デフォルト値
    }
    // 0-1の範囲に正規化
    if (score > 1) return score / 100 // 100スケールの場合
    if (score < 0) return 0
    return score
  }

  const safeScore = getSafeScore(lab.similarity_score)
  const scorePercentage = Math.round(safeScore * 100)

  const getMatchColor = (score: number) => {
    if (score >= 80) return 'bg-green-100 text-green-800'
    if (score >= 60) return 'bg-blue-100 text-blue-800'
    if (score >= 40) return 'bg-yellow-100 text-yellow-800'
    return 'bg-gray-100 text-gray-800'
  }

  const truncateText = (text: string, maxLength: number) => {
    if (!text) return ''
    if (text.length <= maxLength) return text
    return text.substring(0, maxLength) + '...'
  }

  return (
    <div 
      className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-lg transition-all duration-200 cursor-pointer hover:border-blue-300 hover:bg-blue-50"
      onClick={handleClick}
    >
      {/* デバッグ情報 */}
      <div className="mb-2 text-xs text-gray-400 border-b border-gray-100 pb-2">
        🔍 デバッグ: ID={lab.id} | スコア={lab.similarity_score}→{scorePercentage}% | クリックで詳細画面へ
      </div>

      {/* ヘッダー部分 */}
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h3 className="text-xl font-semibold text-gray-900 mb-2">
            {lab.name || '研究室名未設定'}
          </h3>
          <div className="flex items-center text-gray-600 mb-1">
            <User className="h-4 w-4 mr-2" />
            <span className="font-medium">{lab.professor_name || '教授名未設定'}</span>
          </div>
          <div className="flex items-center text-gray-600">
            <MapPin className="h-4 w-4 mr-2" />
            <span>{lab.university_name || '大学名未設定'} • {lab.prefecture || '地域未設定'}</span>
          </div>
        </div>
        
        {/* マッチ度スコア - 修正版 */}
        <div className={`px-3 py-1 rounded-full text-sm font-medium ${getMatchColor(scorePercentage)}`}>
          <div className="flex items-center">
            <Star className="h-3 w-3 mr-1" />
            {scorePercentage}%
          </div>
        </div>
      </div>

      {/* 研究テーマ */}
      <div className="mb-3">
        <h4 className="font-semibold text-gray-800 mb-1">研究テーマ</h4>
        <p className="text-gray-700 text-sm">
          {truncateText(lab.research_theme || '研究テーマ未設定', 100)}
        </p>
      </div>

      {/* 研究内容 */}
      <div className="mb-4">
        <h4 className="font-semibold text-gray-800 mb-1">研究内容</h4>
        <p className="text-gray-600 text-sm">
          {truncateText(lab.research_content || '研究内容未設定', 150)}
        </p>
      </div>

      {/* フッター */}
      <div className="flex items-center justify-between pt-3 border-t border-gray-100">
        <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm font-medium">
          {lab.research_field || '分野未設定'}
        </span>
        
        {lab.lab_url && (
          <button
            onClick={handleUrlClick}
            className="flex items-center text-blue-600 hover:text-blue-800 text-sm font-medium"
          >
            <ExternalLink className="h-4 w-4 mr-1" />
            研究室サイト
          </button>
        )}
      </div>
    </div>
  )
}

export default LabCard
EOF

echo "✅ LabCard.tsx のスコア処理を修正しました"

# API のモックデータも修正
echo "🔧 API のモックデータを修正中..."
cat > frontend/src/utils/api.ts << 'EOF'
// API基底URL
const API_BASE_URL = (import.meta as any)?.env?.VITE_API_BASE_URL || 'http://localhost:8000'

// 基本的な型定義
export interface ResearchLab {
  id: number
  name: string
  professor_name: string
  department: string
  research_theme: string
  research_content: string
  research_field: string
  speciality: string
  keywords: string
  lab_url?: string
  university: {
    id: number
    name: string
    type: string
    prefecture: string
    region: string
    created_at: string
  }
  created_at: string
  updated_at: string
}

export interface ResearchLabSearchResult {
  id: number
  name: string
  professor_name: string
  department: string
  research_theme: string
  research_content: string
  research_field: string
  speciality: string
  keywords: string
  lab_url?: string
  university_name: string
  prefecture: string
  region: string
  similarity_score: number
}

export interface SearchRequest {
  query: string
  limit?: number
  region_filter?: string[]
  field_filter?: string[]
  min_similarity?: number
}

export interface SearchResponse {
  query: string
  total_results: number
  search_time_ms: number
  results: ResearchLabSearchResult[]
}

// APIクライアント関数
export const searchLabs = async (request: SearchRequest): Promise<SearchResponse> => {
  const response = await fetch(`${API_BASE_URL}/api/search/`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(request),
  })

  if (!response.ok) {
    throw new Error(`検索エラー: ${response.status}`)
  }

  return response.json()
}

export const getLabDetail = async (labId: number): Promise<ResearchLab> => {
  const response = await fetch(`${API_BASE_URL}/api/labs/${labId}`)

  if (!response.ok) {
    throw new Error(`研究室詳細取得エラー: ${response.status}`)
  }

  return response.json()
}

// 類似研究室取得（API + モック実装）- スコア修正版
export const getSimilarLabs = async (labId: number): Promise<ResearchLabSearchResult[]> => {
  // 開発環境用のモックデータ（スコア修正）
  const mockSimilarLabs: ResearchLabSearchResult[] = [
    {
      id: labId + 1000,
      name: "関連研究室A",
      professor_name: "関連教授A",
      department: "関連学部A",
      research_theme: "同様の研究テーマに取り組んでいます",
      research_content: "類似した研究内容を扱っています。最新の技術を用いて研究を推進中です。",
      research_field: "免疫学",
      speciality: "関連専門分野",
      keywords: "関連,キーワード,研究",
      university_name: "関連大学A",
      prefecture: "東京都",
      region: "関東",
      similarity_score: 0.78, // 0-1の範囲で正規化
      lab_url: "https://example.com"
    },
    {
      id: labId + 2000,
      name: "関連研究室B", 
      professor_name: "関連教授B",
      department: "関連学部B",
      research_theme: "別の角度から同じ分野を研究",
      research_content: "異なるアプローチで同分野を研究しています。国際的な共同研究も実施中です。",
      research_field: "免疫学",
      speciality: "関連専門分野B",
      keywords: "研究,関連,分野",
      university_name: "関連大学B",
      prefecture: "神奈川県", 
      region: "関東",
      similarity_score: 0.72 // 0-1の範囲で正規化
    },
    {
      id: labId + 3000,
      name: "関連研究室C",
      professor_name: "関連教授C", 
      department: "関連学部C",
      research_theme: "最新技術を活用した研究",
      research_content: "先端技術による研究アプローチを採用。産学連携にも力を入れています。",
      research_field: "生物学",
      speciality: "関連専門分野C",
      keywords: "最新,技術,研究",
      university_name: "関連大学C",
      prefecture: "大阪府",
      region: "関西", 
      similarity_score: 0.68 // 0-1の範囲で正規化
    }
  ]

  // 実際のAPIを試す
  try {
    const response = await fetch(`${API_BASE_URL}/api/labs/similar/${labId}`)
    if (response.ok) {
      const data = await response.json()
      console.log('類似研究室APIから取得:', data)
      
      // APIから取得したデータのスコアも正規化
      const normalizedData = data.map((lab: any) => ({
        ...lab,
        similarity_score: typeof lab.similarity_score === 'number' && !isNaN(lab.similarity_score) 
          ? lab.similarity_score 
          : 0.5 // デフォルト値
      }))
      
      return normalizedData
    }
  } catch (error) {
    console.log('類似研究室API未実装のため、モックデータを使用:', error)
  }

  // APIが未実装の場合はモックデータを返す
  return new Promise((resolve) => {
    setTimeout(() => {
      console.log('モック類似研究室データを返します (スコア修正版)')
      resolve(mockSimilarLabs)
    }, 800) // 実際のAPI呼び出しをシミュレート
  })
}

export const healthCheck = async () => {
  const response = await fetch(`${API_BASE_URL}/health`)
  
  if (!response.ok) {
    throw new Error(`ヘルスチェックエラー: ${response.status}`)
  }

  return response.json()
}
EOF

echo "✅ API のモックデータを修正しました"

echo ""
echo "🎉 類似度スコア表示の修正が完了しました！"
echo ""
echo "📋 修正内容:"
echo "  ✅ NaN スコアの安全な処理"
echo "  ✅ 0-1 範囲への正規化"
echo "  ✅ デフォルト値の設定"
echo "  ✅ デバッグ情報の改善"
echo "  ✅ エラーハンドリングの強化"
echo ""
echo "🔍 期待される変化:"
echo "  「NaN%」→「78%」「72%」「68%」のように正常表示"
echo "  デバッグ情報でスコア変換過程を確認可能"