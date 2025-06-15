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
