import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, Users, Brain, Zap } from 'lucide-react'

// 型定義をインライン定義（import エラー回避）
interface SearchRequest {
  query: string
  limit?: number
  region_filter?: string[]
  field_filter?: string[]
  min_similarity?: number
}

interface SearchResponse {
  query: string
  total_results: number
  search_time_ms: number
  results: any[]
}

// API関数をインライン定義（エラーハンドリング強化）
const searchLabs = async (request: SearchRequest): Promise<SearchResponse> => {
  const API_BASE_URL = 'http://localhost:8000'
  
  try {
    const response = await fetch(`${API_BASE_URL}/api/search/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    })

    if (!response.ok) {
      throw new Error(`検索エラー: ${response.status} ${response.statusText}`)
    }

    const data = await response.json()
    return data
  } catch (error) {
    console.error('API呼び出しエラー:', error)
    throw error
  }
}

const Home: React.FC = () => {
  const [query, setQuery] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string>('')
  const [searchResults, setSearchResults] = useState<any[]>([])
  const [hasSearched, setHasSearched] = useState(false)
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!query?.trim()) {
      setError('検索キーワードを入力してください')
      return
    }

    setIsLoading(true)
    setError('')
    setHasSearched(false)

    try {
      const searchRequest: SearchRequest = {
        query: query.trim(),
        limit: 10
      }

      console.log('検索開始:', searchRequest)
      const results = await searchLabs(searchRequest)
      console.log('検索成功:', results)
      
      // 安全にresultsを設定
      if (results && Array.isArray(results.results)) {
        setSearchResults(results.results)
      } else {
        setSearchResults([])
      }
      setHasSearched(true)
      
    } catch (err) {
      console.error('検索エラー:', err)
      const errorMessage = err instanceof Error ? err.message : '予期しないエラーが発生しました'
      setError(`検索中にエラーが発生しました: ${errorMessage}`)
      setSearchResults([])
      setHasSearched(true)
    } finally {
      setIsLoading(false)
    }
  }

  const handleExampleSearch = (exampleQuery: string) => {
    if (exampleQuery && !isLoading) {
      setQuery(exampleQuery)
      setError('')
    }
  }

  // 安全なレンダリング関数
  const renderLabCard = (lab: any, index: number) => {
    if (!lab) return null

    const {
      name = '研究室名不明',
      professor_name = '教授名不明',
      university_name = '大学名不明',
      prefecture = '所在地不明',
      research_theme = '研究テーマ不明',
      research_content = '研究内容不明',
      research_field = '分野不明',
      similarity_score = 0,
      lab_url
    } = lab

    return (
      <div key={index} className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-shadow">
        <div className="flex justify-between items-start mb-3">
          <h3 className="text-xl font-semibold text-gray-900">{name}</h3>
          <span className="bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm font-medium">
            {Math.round((similarity_score || 0) * 100)}% マッチ
          </span>
        </div>
        
        <div className="mb-3">
          <p className="text-gray-700"><strong>教授:</strong> {professor_name}</p>
          <p className="text-gray-700"><strong>大学:</strong> {university_name}</p>
          <p className="text-gray-700"><strong>地域:</strong> {prefecture}</p>
        </div>
        
        <div className="mb-3">
          <h4 className="font-semibold text-gray-800 mb-1">研究テーマ:</h4>
          <p className="text-gray-700">{research_theme}</p>
        </div>
        
        <div className="mb-3">
          <h4 className="font-semibold text-gray-800 mb-1">研究内容:</h4>
          <p className="text-gray-600 text-sm">{research_content}</p>
        </div>
        
        <div className="flex items-center justify-between">
          <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm">
            {research_field}
          </span>
          {lab_url && (
            <a 
              href={lab_url} 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-blue-600 hover:text-blue-800 text-sm font-medium"
            >
              研究室サイト →
            </a>
          )}
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-50 p-8">
      <div className="max-w-4xl mx-auto">
        {/* ヘッダー */}
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-gray-900 mb-4">
            研究室<span className="text-blue-600">ファインダー</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8">
            中学生の興味・関心から、全国の大学研究室をAIが推奨
          </p>
        </div>

        {/* 検索フォーム */}
        <div className="bg-white rounded-2xl shadow-lg p-8 mb-8">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 h-6 w-6 text-gray-400" />
              <input
                type="text"
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value)
                  if (error) setError('')
                }}
                placeholder="研究したい分野を入力してください（例：がん治療、AI、環境問題）"
                className="w-full pl-12 pr-4 py-4 text-lg border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:outline-none disabled:bg-gray-100"
                disabled={isLoading}
              />
            </div>
            
            {error && (
              <div className="text-red-600 text-sm font-medium bg-red-50 p-3 rounded-lg">
                {error}
              </div>
            )}
            
            <button
              type="submit"
              disabled={isLoading || !query?.trim()}
              className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white py-4 rounded-xl font-semibold text-lg transition-colors"
            >
              {isLoading ? (
                <div className="flex items-center justify-center">
                  <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white mr-2"></div>
                  検索中...
                </div>
              ) : (
                '研究室を検索'
              )}
            </button>
          </form>

          {/* 検索例 */}
          <div className="mt-6">
            <p className="text-sm text-gray-600 mb-3">検索例:</p>
            <div className="flex flex-wrap gap-2">
              {[
                'がん治療の研究',
                '人工知能とロボット',
                '地球温暖化の解決',
                '免疫療法',
                '再生医療'
              ].map((example) => (
                <button
                  key={example}
                  onClick={() => handleExampleSearch(example)}
                  className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm hover:bg-blue-100 transition-colors disabled:opacity-50"
                  disabled={isLoading}
                  type="button"
                >
                  {example}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* 検索結果表示 */}
        {hasSearched && (
          <div className="bg-white rounded-2xl shadow-lg p-8 mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">
              検索結果 ({searchResults?.length || 0}件)
            </h2>
            
            {!searchResults || searchResults.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-600">検索結果が見つかりませんでした。</p>
                <p className="text-sm text-gray-500 mt-2">別のキーワードで検索してみてください。</p>
              </div>
            ) : (
              <div className="space-y-4">
                {searchResults.map((lab, index) => renderLabCard(lab, index))}
              </div>
            )}
          </div>
        )}

        {/* 特徴説明 */}
        <div className="grid md:grid-cols-3 gap-6">
          <div className="bg-white rounded-xl p-6 shadow-md">
            <div className="flex items-center mb-3">
              <Users className="h-8 w-8 text-blue-600 mr-3" />
              <h3 className="text-xl font-semibold">50+ 研究室</h3>
            </div>
            <p className="text-gray-600">全国の大学から厳選された研究室データベース</p>
          </div>
          
          <div className="bg-white rounded-xl p-6 shadow-md">
            <div className="flex items-center mb-3">
              <Brain className="h-8 w-8 text-blue-600 mr-3" />
              <h3 className="text-xl font-semibold">AI 推奨</h3>
            </div>
            <p className="text-gray-600">あなたの興味に最適な研究室をAIが発見</p>
          </div>
          
          <div className="bg-white rounded-xl p-6 shadow-md">
            <div className="flex items-center mb-3">
              <Zap className="h-8 w-8 text-blue-600 mr-3" />
              <h3 className="text-xl font-semibold">簡単検索</h3>
            </div>
            <p className="text-gray-600">自然な言葉で検索可能、専門用語不要</p>
          </div>
        </div>

        {/* フッター */}
        <div className="text-center mt-12 text-gray-500">
          <p>中学生の未来を拓く、AI駆動の研究室発見プラットフォーム</p>
        </div>
      </div>
    </div>
  )
}

export default Home