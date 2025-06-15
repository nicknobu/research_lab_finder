#!/bin/bash

echo "🔧 重複関数エラーを修正中..."

# 1. api.ts を正しく書き直し
echo "📝 api.ts を修正中..."
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

// 類似研究室取得（API + モック実装）
export const getSimilarLabs = async (labId: number): Promise<ResearchLabSearchResult[]> => {
  // 開発環境用のモックデータ
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
      similarity_score: 0.78,
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
      similarity_score: 0.72
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
      similarity_score: 0.68
    }
  ]

  // 実際のAPIを試す
  try {
    const response = await fetch(`${API_BASE_URL}/api/labs/similar/${labId}`)
    if (response.ok) {
      const data = await response.json()
      console.log('類似研究室APIから取得:', data)
      return data
    }
  } catch (error) {
    console.log('類似研究室API未実装のため、モックデータを使用:', error)
  }

  // APIが未実装の場合はモックデータを返す
  return new Promise((resolve) => {
    setTimeout(() => {
      console.log('モック類似研究室データを返します')
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

echo "✅ api.ts の重複関数を修正しました"

# 2. LabDetail.tsx も最新版に更新（getSimilarLabs呼び出しを修正）
echo "📝 LabDetail.tsx を更新中..."
cat > frontend/src/pages/LabDetail.tsx << 'EOF'
import React, { useState, useEffect } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { 
  ArrowLeft, 
  MapPin, 
  User, 
  ExternalLink, 
  Building, 
  BookOpen, 
  Target,
  Star,
  Share2
} from 'lucide-react'
import LabCard from '../components/LabCard'
import { getLabDetail, getSimilarLabs } from '../utils/api'
import type { ResearchLab, ResearchLabSearchResult } from '../types'

const LabDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  
  const [lab, setLab] = useState<ResearchLab | null>(null)
  const [similarLabs, setSimilarLabs] = useState<ResearchLabSearchResult[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string>('')
  const [similarLoading, setSimilarLoading] = useState(false)

  useEffect(() => {
    if (id) {
      loadLabDetail(parseInt(id))
    }
  }, [id])

  const loadLabDetail = async (labId: number) => {
    setIsLoading(true)
    setError('')

    try {
      // 研究室詳細を取得
      const labDetail = await getLabDetail(labId)
      setLab(labDetail)
      
      // 類似研究室を別途取得（エラーが発生しても詳細は表示する）
      loadSimilarLabs(labId)
    } catch (err) {
      console.error('研究室詳細取得エラー:', err)
      setError('研究室の詳細情報を取得できませんでした。')
    } finally {
      setIsLoading(false)
    }
  }

  const loadSimilarLabs = async (labId: number) => {
    setSimilarLoading(true)
    try {
      // 修正：引数は1つのみ（limit削除）
      const similar = await getSimilarLabs(labId)
      setSimilarLabs(similar)
      console.log('類似研究室を取得:', similar)
    } catch (err) {
      console.error('類似研究室取得エラー:', err)
      // 類似研究室の取得に失敗してもエラー表示はしない（メイン機能ではないため）
      setSimilarLabs([])
    } finally {
      setSimilarLoading(false)
    }
  }

  const handleSimilarLabClick = (similarLab: ResearchLabSearchResult) => {
    console.log('類似研究室クリック:', similarLab)
    navigate(`/lab/${similarLab.id}`)
  }

  const handleShareLab = async () => {
    if (navigator.share && lab) {
      try {
        await navigator.share({
          title: `${lab.name} - 研究室ファインダー`,
          text: `${lab.university.name} ${lab.name}の研究室情報`,
          url: window.location.href
        })
      } catch (err) {
        // シェア失敗時はURLをクリップボードにコピー
        navigator.clipboard.writeText(window.location.href)
        alert('URLをクリップボードにコピーしました')
      }
    } else if (lab) {
      // Web Share API非対応の場合はクリップボードにコピー
      navigator.clipboard.writeText(window.location.href)
      alert('URLをクリップボードにコピーしました')
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">研究室情報を読み込み中...</p>
        </div>
      </div>
    )
  }

  if (error || !lab) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 mb-4">
            <Target className="h-16 w-16 mx-auto" />
          </div>
          <h2 className="text-xl font-semibold text-gray-900 mb-2">
            研究室が見つかりませんでした
          </h2>
          <p className="text-gray-600 mb-6">
            {error || '指定された研究室の情報を取得できませんでした。'}
          </p>
          <Link 
            to="/"
            className="inline-flex items-center bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            ホームに戻る
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヘッダー */}
      <div className="bg-white border-b">
        <div className="max-w-4xl mx-auto p-6">
          <div className="flex items-center justify-between">
            <button 
              onClick={() => navigate(-1)}
              className="flex items-center text-blue-600 hover:text-blue-800"
            >
              <ArrowLeft className="h-5 w-5 mr-2" />
              戻る
            </button>
            
            <button
              onClick={handleShareLab}
              className="flex items-center text-gray-600 hover:text-gray-800"
            >
              <Share2 className="h-5 w-5 mr-2" />
              共有
            </button>
          </div>
        </div>
      </div>

      {/* メインコンテンツ */}
      <div className="max-w-4xl mx-auto p-6 space-y-8">
        {/* 研究室詳細 */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          {/* 基本情報 */}
          <div className="mb-6">
            <h1 className="text-3xl font-bold text-gray-900 mb-4">{lab.name}</h1>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <div className="flex items-center text-gray-700">
                <User className="h-5 w-5 mr-3 text-blue-600" />
                <div>
                  <span className="font-medium">教授</span>
                  <p className="text-lg">{lab.professor_name}</p>
                </div>
              </div>
              
              <div className="flex items-center text-gray-700">
                <Building className="h-5 w-5 mr-3 text-blue-600" />
                <div>
                  <span className="font-medium">所属</span>
                  <p className="text-lg">{lab.university.name}</p>
                  <p className="text-sm text-gray-600">{lab.department}</p>
                </div>
              </div>
              
              <div className="flex items-center text-gray-700">
                <MapPin className="h-5 w-5 mr-3 text-blue-600" />
                <div>
                  <span className="font-medium">地域</span>
                  <p className="text-lg">{lab.university.prefecture}</p>
                </div>
              </div>
              
              <div className="flex items-center text-gray-700">
                <BookOpen className="h-5 w-5 mr-3 text-blue-600" />
                <div>
                  <span className="font-medium">研究分野</span>
                  <span className="inline-block bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium ml-2">
                    {lab.research_field}
                  </span>
                </div>
              </div>
            </div>
          </div>

          {/* 研究テーマ */}
          <div className="mb-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-3 flex items-center">
              <Target className="h-5 w-5 mr-2 text-blue-600" />
              研究テーマ
            </h2>
            <p className="text-gray-800 text-lg leading-relaxed bg-blue-50 p-4 rounded-lg">
              {lab.research_theme}
            </p>
          </div>

          {/* 研究内容 */}
          <div className="mb-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-3">
              研究内容の詳細
            </h2>
            <div className="prose max-w-none">
              <p className="text-gray-700 leading-relaxed whitespace-pre-line">
                {lab.research_content}
              </p>
            </div>
          </div>

          {/* 専門性とキーワード */}
          {(lab.speciality || lab.keywords) && (
            <div className="mb-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-3">
                専門分野・キーワード
              </h2>
              
              {lab.speciality && (
                <div className="mb-3">
                  <span className="text-sm font-medium text-gray-600">専門性:</span>
                  <p className="text-gray-800 mt-1">{lab.speciality}</p>
                </div>
              )}
              
              {lab.keywords && (
                <div>
                  <span className="text-sm font-medium text-gray-600">キーワード:</span>
                  <div className="flex flex-wrap gap-2 mt-2">
                    {lab.keywords.split(',').map((keyword, index) => (
                      <span 
                        key={index}
                        className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm"
                      >
                        {keyword.trim()}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* 外部リンク */}
          {lab.lab_url && (
            <div className="border-t border-gray-200 pt-6">
              <a 
                href={lab.lab_url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
              >
                <ExternalLink className="h-5 w-5 mr-2" />
                研究室の公式サイトを見る
              </a>
            </div>
          )}
        </div>

        {/* 類似研究室 */}
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h2 className="text-2xl font-semibold text-gray-900 mb-6 flex items-center">
            <Star className="h-6 w-6 mr-2 text-yellow-500" />
            関連する研究室
          </h2>
          
          {similarLoading ? (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
              <p className="text-gray-600">関連研究室を検索中...</p>
            </div>
          ) : similarLabs.length > 0 ? (
            <div className="space-y-4">
              {similarLabs.map((similarLab) => (
                <LabCard
                  key={similarLab.id}
                  lab={similarLab}
                  onClick={handleSimilarLabClick}
                />
              ))}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500">
              <Star className="h-12 w-12 mx-auto mb-4 text-gray-300" />
              <p>関連する研究室が見つかりませんでした</p>
              <p className="text-sm mt-2">この研究室に似た研究をしている他の研究室を表示します</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default LabDetail
EOF

echo "✅ LabDetail.tsx を更新しました"

echo ""
echo "🎉 重複関数エラーを修正しました！"
echo ""
echo "📋 修正内容:"
echo "  ✅ api.ts の重複 getSimilarLabs 関数を解決"
echo "  ✅ モックデータ付きの類似研究室機能を実装"
echo "  ✅ LabDetail.tsx の関数呼び出しを修正"
echo "  ✅ エラーハンドリングとローディング状態を改善"
echo ""
echo "🚀 再度開発サーバーを起動して確認してください:"
echo "   cd frontend && npm run dev"