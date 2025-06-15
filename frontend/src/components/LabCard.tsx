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

  // 大学情報の安全な取得（修正版）
  const safeUniversityName = lab.university_name || '大学名未取得'
  const safePrefecture = lab.prefecture || '地域未取得'
  const safeProfessorName = lab.professor_name || '教授名未取得'

  return (
    <div 
      className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-lg transition-all duration-200 cursor-pointer hover:border-blue-300 hover:bg-blue-50"
      onClick={handleClick}
    >
      {/* ヘッダー部分 */}
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h3 className="text-xl font-semibold text-gray-900 mb-2">
            {lab.name || '研究室名未設定'}
          </h3>
          <div className="flex items-center text-gray-600 mb-1">
            <User className="h-4 w-4 mr-2" />
            <span className="font-medium">{safeProfessorName}</span>
          </div>
          <div className="flex items-center text-gray-600">
            <MapPin className="h-4 w-4 mr-2" />
            <span>{safeUniversityName} • {safePrefecture}</span>
          </div>
        </div>
        
        {/* マッチ度スコア */}
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
