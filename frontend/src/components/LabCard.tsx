import React from 'react'
import { MapPin, User, ExternalLink, Star } from 'lucide-react'
import type { ResearchLabSearchResult } from '../types'

interface LabCardProps {
  lab: ResearchLabSearchResult
  onClick?: (lab: ResearchLabSearchResult) => void
}

const LabCard: React.FC<LabCardProps> = ({ lab, onClick }) => {
  const handleClick = () => {
    if (onClick) {
      onClick(lab)
    }
  }

  const handleUrlClick = (e: React.MouseEvent) => {
    e.stopPropagation()
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
      className="bg-white border border-gray-200 rounded-lg p-6 hover:shadow-lg transition-all duration-200 cursor-pointer hover:border-blue-300"
      onClick={handleClick}
    >
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
        <p className="text-gray-600 text-sm leading-relaxed">
          {truncateText(lab.research_content, 200)}
        </p>
      </div>

      {/* フッター部分 */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="bg-blue-50 text-blue-700 px-3 py-1 rounded-full text-xs font-medium">
            {lab.research_field}
          </span>
          <span className="bg-gray-50 text-gray-600 px-3 py-1 rounded-full text-xs">
            {lab.region}
          </span>
        </div>
        
        {lab.lab_url && (
          <a 
            href={lab.lab_url} 
            target="_blank" 
            rel="noopener noreferrer"
            onClick={handleUrlClick}
            className="flex items-center text-blue-600 hover:text-blue-800 text-sm font-medium transition-colors"
          >
            <ExternalLink className="h-4 w-4 mr-1" />
            研究室サイト
          </a>
        )}
      </div>
    </div>
  )
}

export default LabCard