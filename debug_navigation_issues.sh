#!/bin/bash

echo "🔍 ナビゲーション問題をデバッグ中..."

# 1. 検索機能のデバッグ版を作成
echo "📝 検索機能のデバッグ版を作成..."

# Home.tsx を確認・修正
cat > frontend/src/pages/Home.tsx << 'EOF'
import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, TrendingUp, BookOpen, Users, Target } from 'lucide-react'
import SearchBox from '../components/SearchBox'
import PopularSearches from '../components/PopularSearches'
import { searchLabs } from '../utils/api'
import type { SearchResponse } from '../types'

const Home: React.FC = () => {
  const navigate = useNavigate()
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSearch = async (query: string) => {
    console.log('🔍 検索開始:', query)
    setIsLoading(true)
    setError('')

    try {
      const searchResults: SearchResponse = await searchLabs({
        query,
        limit: 20
      })
      
      console.log('✅ 検索結果:', searchResults)
      
      // 検索結果を state で渡して SearchResults ページに遷移
      navigate('/search', {
        state: {
          results: searchResults,
          query: query
        }
      })
    } catch (err) {
      console.error('❌ 検索エラー:', err)
      const errorMessage = err instanceof Error ? err.message : '予期しないエラーが発生しました'
      setError(`検索中にエラーが発生しました: ${errorMessage}`)
    } finally {
      setIsLoading(false)
    }
  }

  const handleExampleSearch = (exampleQuery: string) => {
    console.log('📌 例題検索:', exampleQuery)
    if (exampleQuery && !isLoading) {
      handleSearch(exampleQuery)
    }
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
            AI技術で中学生にぴったりの研究室を見つけよう
          </p>
        </div>

        {/* 検索ボックス */}
        <div className="mb-12">
          <SearchBox 
            onSearch={handleSearch}
            placeholder="研究テーマや分野を入力してください（例：機械学習、がん治療、AI）"
          />
          
          {isLoading && (
            <div className="text-center mt-4">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-2"></div>
              <p className="text-gray-600">検索中...</p>
            </div>
          )}

          {error && (
            <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-red-700">{error}</p>
              <button 
                onClick={() => setError('')}
                className="mt-2 text-red-600 hover:text-red-800 text-sm underline"
              >
                エラーを閉じる
              </button>
            </div>
          )}
        </div>

        {/* 人気検索キーワード */}
        <PopularSearches onSearchClick={handleExampleSearch} />

        {/* 機能説明 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
          <div className="text-center p-6 bg-white rounded-lg shadow-sm">
            <Search className="h-12 w-12 text-blue-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">AI検索</h3>
            <p className="text-gray-600">最新のAI技術でキーワードから最適な研究室を発見</p>
          </div>
          
          <div className="text-center p-6 bg-white rounded-lg shadow-sm">
            <Target className="h-12 w-12 text-green-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">詳細情報</h3>
            <p className="text-gray-600">研究内容、教授情報、大学情報を詳しく表示</p>
          </div>
          
          <div className="text-center p-6 bg-white rounded-lg shadow-sm">
            <BookOpen className="h-12 w-12 text-purple-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">関連研究</h3>
            <p className="text-gray-600">類似した研究をしている他の研究室も表示</p>
          </div>
        </div>

        {/* フッター */}
        <div className="text-center text-gray-500 text-sm">
          <p>中学生向けAI駆動研究室検索システム</p>
          <p className="mt-2">
            💡 デバッグモード: コンソールで検索ログを確認できます
          </p>
        </div>
      </div>
    </div>
  )
}

export default Home
EOF

# 2. SearchResults.tsx のデバッグ版を作成
echo "📝 SearchResults.tsx のデバッグ版を作成..."
cat > frontend/src/pages/SearchResults.tsx << 'EOF'
import React, { useState, useEffect } from 'react'
import { useLocation, useNavigate, Link } from 'react-router-dom'
import { Search, ArrowLeft, Filter } from 'lucide-react'
import LabCard from '../components/LabCard'
import { searchLabs } from '../utils/api'
import type { SearchResponse, ResearchLabSearchResult, SearchRequest } from '../types'

const SearchResults: React.FC = () => {
  const location = useLocation()
  const navigate = useNavigate()
  
  const [results, setResults] = useState<SearchResponse | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string>('')
  const [query, setQuery] = useState('')

  console.log('🔍 SearchResults mounted, location:', location)
  console.log('📊 location.state:', location.state)

  // URLパラメータまたはlocation.stateから初期データを取得
  useEffect(() => {
    if (location.state?.results && location.state?.query) {
      // Home画面からの遷移の場合
      console.log('✅ Home からの遷移データを受信:', location.state)
      setResults(location.state.results)
      setQuery(location.state.query)
    } else {
      // URLパラメータからクエリを取得
      const params = new URLSearchParams(location.search)
      const queryParam = params.get('q')
      console.log('🔗 URL パラメータから取得:', queryParam)
      
      if (queryParam) {
        setQuery(queryParam)
        handleSearch(queryParam)
      } else {
        // クエリが無い場合はホームに戻る
        console.log('❌ クエリが見つからないため、ホームに戻ります')
        navigate('/')
      }
    }
  }, [location, navigate])

  const handleSearch = async (searchQuery: string) => {
    if (!searchQuery.trim()) return

    console.log('🔍 再検索実行:', searchQuery)
    setIsLoading(true)
    setError('')

    try {
      const searchRequest: SearchRequest = {
        query: searchQuery,
        limit: 20
      }

      const searchResults = await searchLabs(searchRequest)
      console.log('✅ 再検索結果:', searchResults)
      setResults(searchResults)
    } catch (err) {
      console.error('❌ 再検索エラー:', err)
      setError('検索中にエラーが発生しました。')
    } finally {
      setIsLoading(false)
    }
  }

  const handleNewSearch = async (e: React.FormEvent) => {
    e.preventDefault()
    if (query.trim()) {
      await handleSearch(query)
      // URLも更新
      navigate(`/search?q=${encodeURIComponent(query)}`, { replace: true })
    }
  }

  const handleLabClick = (lab: ResearchLabSearchResult) => {
    console.log('🏢 研究室クリック:', lab)
    console.log('🔗 遷移先:', `/lab/${lab.id}`)
    navigate(`/lab/${lab.id}`)
  }

  if (isLoading && !results) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">検索中...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* ヘッダー */}
      <div className="bg-white border-b">
        <div className="max-w-6xl mx-auto p-6">
          <div className="flex items-center mb-4">
            <Link 
              to="/" 
              className="flex items-center text-blue-600 hover:text-blue-800 mr-6"
            >
              <ArrowLeft className="h-5 w-5 mr-2" />
              戻る
            </Link>
            <h1 className="text-2xl font-bold text-gray-900">検索結果</h1>
          </div>
          
          {/* 再検索フォーム */}
          <form onSubmit={handleNewSearch} className="mb-4">
            <div className="relative max-w-2xl">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="検索キーワードを入力..."
                className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:border-blue-500"
              />
              <button
                type="submit"
                className="absolute right-2 top-1/2 transform -translate-y-1/2 bg-blue-600 text-white px-4 py-1.5 rounded hover:bg-blue-700"
              >
                検索
              </button>
            </div>
          </form>

          {/* 検索結果サマリー */}
          {results && (
            <div className="text-sm text-gray-600">
              <p>
                「<strong>{results.query}</strong>」の検索結果: 
                <strong className="text-blue-600 ml-1">{results.total_results}件</strong>
                <span className="ml-2">({results.search_time_ms}ms)</span>
              </p>
            </div>
          )}
        </div>
      </div>

      {/* メインコンテンツ */}
      <div className="max-w-6xl mx-auto p-6">
        <div className="flex gap-8">
          {/* 検索結果 */}
          <div className="flex-1">
            {error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
                <p className="text-red-700">{error}</p>
              </div>
            )}

            {isLoading ? (
              <div className="text-center py-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                <p className="text-gray-600">検索中...</p>
              </div>
            ) : results && results.results.length > 0 ? (
              <div className="space-y-4">
                <p className="text-gray-600 mb-4">
                  💡 デバッグ: 研究室カードをクリックすると詳細画面に遷移します
                </p>
                {results.results.map((lab) => (
                  <LabCard
                    key={lab.id}
                    lab={lab}
                    onClick={handleLabClick}
                  />
                ))}
              </div>
            ) : (
              <div className="text-center py-12">
                <div className="text-gray-400 mb-4">
                  <Search className="h-16 w-16 mx-auto" />
                </div>
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  検索結果が見つかりませんでした
                </h3>
                <p className="text-gray-600 mb-4">
                  別のキーワードで検索してみてください
                </p>
                <Link 
                  to="/"
                  className="inline-flex items-center text-blue-600 hover:text-blue-800 font-medium"
                >
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  ホームに戻る
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default SearchResults
EOF

# 3. LabCard.tsx のデバッグ版を作成
echo "📝 LabCard.tsx のデバッグ版を作成..."
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

  const getMatchColor = (score: number) => {
    if (score >= 0.8) return 'bg-green-100 text-green-800'
    if (score >= 0.6) return 'bg-blue-100 text-blue-800'
    if (score >= 0.4) return 'bg-yellow-100 text-yellow-800'
    return 'bg-gray-100 text-gray-800'
  }

  const truncateText = (text: string, maxLength: number) => {
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
        🔍 デバッグ: ID={lab.id} | クリックで詳細画面へ
      </div>

      {/* ヘッダー部分 */}
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h3 className="text-xl font-semibold text-gray-900 mb-2 line-clamp-2">
            {lab.name}
          </h3>
          <div className="flex items-center text-gray-600 mb-1">
            <User className="h-4 w-4 mr-2" />
            <span className="font-medium">{lab.professor_name}</span>
          </div>
          <div className="flex items-center text-gray-600">
            <MapPin className="h-4 w-4 mr-2" />
            <span>{lab.university_name} • {lab.prefecture}</span>
          </div>
        </div>
        
        {/* マッチ度スコア */}
        <div className={`px-3 py-1 rounded-full text-sm font-medium ${getMatchColor(lab.similarity_score)}`}>
          <div className="flex items-center">
            <Star className="h-3 w-3 mr-1" />
            {Math.round(lab.similarity_score * 100)}%
          </div>
        </div>
      </div>

      {/* 研究テーマ */}
      <div className="mb-3">
        <h4 className="font-semibold text-gray-800 mb-1">研究テーマ</h4>
        <p className="text-gray-700 text-sm">
          {truncateText(lab.research_theme, 100)}
        </p>
      </div>

      {/* 研究内容 */}
      <div className="mb-4">
        <h4 className="font-semibold text-gray-800 mb-1">研究内容</h4>
        <p className="text-gray-600 text-sm">
          {truncateText(lab.research_content, 150)}
        </p>
      </div>

      {/* フッター */}
      <div className="flex items-center justify-between pt-3 border-t border-gray-100">
        <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm font-medium">
          {lab.research_field}
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

echo "🎉 デバッグ版を作成しました！"
echo ""
echo "📋 デバッグ機能:"
echo "  ✅ コンソールログでの詳細トレース"
echo "  ✅ 検索・遷移・クリックの全過程を記録"
echo "  ✅ LabCard にデバッグ情報を表示"
echo "  ✅ エラーハンドリングの強化"
echo ""
echo "🔍 確認手順:"
echo "1. ブラウザの開発者ツール (F12) を開く"
echo "2. Console タブを表示"
echo "3. http://localhost:3000 で検索を実行"
echo "4. 各段階でのログを確認"
echo ""
echo "💡 期待されるログ:"
echo "  🔍 検索開始: [クエリ]"
echo "  ✅ 検索結果: [結果データ]"
echo "  🔍 SearchResults mounted"
echo "  🏢 LabCard クリック: [研究室名]"
echo "  🔗 遷移先: /lab/[ID]"