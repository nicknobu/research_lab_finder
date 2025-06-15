// frontend/src/pages/Home.tsx
import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, BookOpen, Users, Award, ArrowRight } from 'lucide-react'

import SearchBox from '../components/SearchBox'
import PopularSearches from '../components/PopularSearches'
import FeatureCard from '../components/FeatureCard'

const Home: React.FC = () => {
  const navigate = useNavigate()
  const [searchQuery, setSearchQuery] = useState('')

  const handleSearch = (query: string) => {
    if (query.trim()) {
      navigate(`/search?q=${encodeURIComponent(query)}`)
    }
  }

  const features = [
    {
      icon: <Search className="h-8 w-8 text-blue-600" />,
      title: "AIによるセマンティック検索",
      description: "あなたの興味・関心を自由な文章で入力するだけで、関連する研究室を見つけられます"
    },
    {
      icon: <BookOpen className="h-8 w-8 text-green-600" />,
      title: "全国の研究室を網羅",
      description: "国公立・私立大学の主要な研究室情報を1つのプラットフォームで検索できます"
    },
    {
      icon: <Users className="h-8 w-8 text-purple-600" />,
      title: "中学生向けに最適化",
      description: "専門用語を使わずに、分かりやすい言葉で研究内容を説明しています"
    },
    {
      icon: <Award className="h-8 w-8 text-orange-600" />,
      title: "進路選択をサポート",
      description: "将来の学習方向性と大学選択の参考となる情報を提供します"
    }
  ]

  const popularSearches = [
    "がん治療の研究をしたい",
    "人工知能とロボットに興味がある", 
    "地球温暖化を解決したい",
    "新しい薬を開発したい",
    "宇宙の研究がしたい",
    "感染症の予防研究"
  ]

  return (
    <div className="space-y-16">
      {/* ヒーローセクション */}
      <section className="text-center space-y-8">
        <div className="space-y-4">
          <h1 className="text-5xl font-bold text-gray-900 leading-tight">
            研究室ファインダー
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            中学生のあなたの興味・関心から、全国の大学研究室をAIが推奨
          </p>
          <p className="text-lg text-gray-500 max-w-2xl mx-auto">
            「宇宙に興味がある」「病気を治したい」など、自由な言葉で検索してみてください
          </p>
        </div>

        {/* メイン検索ボックス */}
        <div className="max-w-2xl mx-auto">
          <SearchBox 
            value={searchQuery}
            onChange={setSearchQuery}
            onSearch={handleSearch}
            placeholder="例：がん治療の研究をしたい、ロボットに興味がある..."
            showSuggestions={true}
            autoFocus={true}
          />
        </div>

        {/* 人気検索 */}
        <PopularSearches 
          searches={popularSearches}
          onSearchClick={handleSearch}
        />
      </section>

      {/* 特徴セクション */}
      <section className="space-y-12">
        <div className="text-center space-y-4">
          <h2 className="text-3xl font-bold text-gray-900">
            なぜ研究室ファインダーなのか？
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            従来の研究室検索では不可能だった、あなたの興味に基づいた推奨システム
          </p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <FeatureCard 
              key={index}
              icon={feature.icon}
              title={feature.title}
              description={feature.description}
            />
          ))}
        </div>
      </section>

      {/* 使い方セクション */}
      <section className="bg-white rounded-2xl p-8 md:p-12 shadow-lg">
        <div className="text-center space-y-8">
          <h2 className="text-3xl font-bold text-gray-900">
            簡単3ステップで研究室を発見
          </h2>
          
          <div className="grid md:grid-cols-3 gap-8">
            <div className="space-y-4">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto">
                <span className="text-2xl font-bold text-blue-600">1</span>
              </div>
              <h3 className="text-xl font-semibold text-gray-900">
                興味を入力
              </h3>
              <p className="text-gray-600">
                「がんを治したい」「AIに興味がある」など、自由な言葉で興味・関心を入力
              </p>
            </div>

            <div className="space-y-4">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
                <span className="text-2xl font-bold text-green-600">2</span>
              </div>
              <h3 className="text-xl font-semibold text-gray-900">
                AI が分析
              </h3>
              <p className="text-gray-600">
                最新のAI技術があなたの興味を分析し、関連する研究分野を特定
              </p>
            </div>

            <div className="space-y-4">
              <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto">
                <span className="text-2xl font-bold text-purple-600">3</span>
              </div>
              <h3 className="text-xl font-semibold text-gray-900">
                研究室を発見
              </h3>
              <p className="text-gray-600">
                全国の大学から、あなたの興味にマッチする研究室を推奨順に表示
              </p>
            </div>
          </div>

          <div className="pt-8">
            <button 
              onClick={() => handleSearch("がん治療の研究をしたい")}
              className="inline-flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-8 py-4 rounded-xl font-semibold transition-colors text-lg"
            >
              今すぐ試してみる
              <ArrowRight className="h-5 w-5" />
            </button>
          </div>
        </div>
      </section>

      {/* 統計情報セクション */}
      <section className="bg-gradient-to-r from-indigo-600 to-blue-600 text-white rounded-2xl p-8 md:p-12">
        <div className="text-center space-y-8">
          <h2 className="text-3xl font-bold">
            豊富な研究室データベース
          </h2>
          
          <div className="grid md:grid-cols-3 gap-8">
            <div className="space-y-2">
              <div className="text-4xl font-bold">50+</div>
              <div className="text-lg opacity-90">研究室</div>
            </div>
            <div className="space-y-2">
              <div className="text-4xl font-bold">20+</div>
              <div className="text-lg opacity-90">大学</div>
            </div>
            <div className="space-y-2">
              <div className="text-4xl font-bold">10+</div>
              <div className="text-lg opacity-90">研究分野</div>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

export default Home