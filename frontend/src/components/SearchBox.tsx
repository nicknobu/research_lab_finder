// frontend/src/components/SearchBox.tsx
import React, { useState, useRef, useEffect } from 'react'
import { Search, X } from 'lucide-react'

interface SearchBoxProps {
  value: string
  onChange: (value: string) => void
  onSearch: (query: string) => void
  placeholder?: string
  showSuggestions?: boolean
  autoFocus?: boolean
}

const SearchBox: React.FC<SearchBoxProps> = ({
  value,
  onChange,
  onSearch,
  placeholder = "研究したい分野や興味のあることを入力してください...",
  showSuggestions = false,
  autoFocus = false
}) => {
  const [suggestions, setSuggestions] = useState<string[]>([])
  const [showSuggestionsList, setShowSuggestionsList] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (autoFocus && inputRef.current) {
      inputRef.current.focus()
    }
  }, [autoFocus])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (value.trim()) {
      onSearch(value.trim())
      setShowSuggestionsList(false)
    }
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value
    onChange(newValue)
    
    if (showSuggestions && newValue.length > 2) {
      // 簡単な検索候補（実際のAPIと連携する場合はここを修正）
      const mockSuggestions = [
        "がん治療の研究をしたい",
        "人工知能とロボットに興味がある",
        "地球温暖化を解決したい",
        "新しい薬を開発したい",
        "宇宙の研究がしたい",
        "感染症の予防研究"
      ].filter(suggestion => 
        suggestion.toLowerCase().includes(newValue.toLowerCase())
      )
      
      setSuggestions(mockSuggestions.slice(0, 5))
      setShowSuggestionsList(mockSuggestions.length > 0)
    } else {
      setShowSuggestionsList(false)
    }
  }

  const handleSuggestionClick = (suggestion: string) => {
    onChange(suggestion)
    onSearch(suggestion)
    setShowSuggestionsList(false)
  }

  const clearInput = () => {
    onChange('')
    setShowSuggestionsList(false)
    inputRef.current?.focus()
  }

  return (
    <div className="relative w-full">
      <form onSubmit={handleSubmit} className="relative">
        <div className="relative">
          <input
            ref={inputRef}
            type="text"
            value={value}
            onChange={handleInputChange}
            placeholder={placeholder}
            className="w-full pl-12 pr-12 py-4 text-lg border-2 border-gray-200 rounded-xl focus:border-blue-500 focus:outline-none transition-colors"
          />
          <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
          {value && (
            <button
              type="button"
              onClick={clearInput}
              className="absolute right-4 top-1/2 transform -translate-y-1/2 p-1 text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X className="h-4 w-4" />
            </button>
          )}
        </div>
      </form>

      {/* 検索候補リスト */}
      {showSuggestionsList && suggestions.length > 0 && (
        <div className="absolute top-full left-0 right-0 bg-white border border-gray-200 rounded-lg shadow-lg mt-2 z-10">
          {suggestions.map((suggestion, index) => (
            <button
              key={index}
              onClick={() => handleSuggestionClick(suggestion)}
              className="w-full text-left px-4 py-3 hover:bg-gray-50 transition-colors border-b border-gray-100 last:border-b-0"
            >
              <div className="flex items-center gap-3">
                <Search className="h-4 w-4 text-gray-400" />
                <span>{suggestion}</span>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

// frontend/src/components/LabCard.tsx
import React from 'react'
import { MapPin, User, ExternalLink, Star } from 'lucide-react'

export interface LabCardData {
  id: number
  name: string
  professor_name?: string
  university_name: string
  prefecture: string
  region: string
  research_theme: string
  research_content: string
  research_field: string
  similarity_score: number
  lab_url?: string
}

interface LabCardProps {
  lab: LabCardData
  onClick?: (lab: LabCardData) => void
}

const LabCard: React.FC<LabCardProps> = ({ lab, onClick }) => {
  const handleClick = () => {
    if (onClick) {
      onClick(lab)
    }
  }

  const handleExternalLink = (e: React.MouseEvent) => {
    e.stopPropagation()
    if (lab.lab_url) {
      window.open(lab.lab_url, '_blank')
    }
  }

  return (
    <div 
      className="bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow p-6 cursor-pointer border border-gray-200"
      onClick={handleClick}
    >
      {/* ヘッダー */}
      <div className="flex justify-between items-start mb-4">
        <div className="flex-1">
          <h3 className="text-xl font-semibold text-gray-900 mb-2 line-clamp-2">
            {lab.name}
          </h3>
          <div className="flex items-center gap-4 text-sm text-gray-600">
            <div className="flex items-center gap-1">
              <User className="h-4 w-4" />
              <span>{lab.professor_name || '教授名未登録'}</span>
            </div>
            <div className="flex items-center gap-1">
              <MapPin className="h-4 w-4" />
              <span>{lab.university_name}</span>
            </div>
          </div>
        </div>
        
        {/* 類似度スコア */}
        <div className="flex items-center gap-1 bg-blue-100 px-2 py-1 rounded-full">
          <Star className="h-4 w-4 text-blue-600" />
          <span className="text-sm font-medium text-blue-600">
            {Math.round(lab.similarity_score * 100)}%
          </span>
        </div>
      </div>

      {/* 研究テーマ */}
      <div className="mb-3">
        <span className="inline-block bg-gray-100 px-3 py-1 rounded-full text-sm font-medium text-gray-700">
          {lab.research_field}
        </span>
      </div>

      {/* 研究内容 */}
      <div className="mb-4">
        <h4 className="font-medium text-gray-900 mb-2">{lab.research_theme}</h4>
        <p className="text-gray-600 text-sm line-clamp-3">
          {lab.research_content}
        </p>
      </div>

      {/* フッター */}
      <div className="flex justify-between items-center pt-4 border-t border-gray-100">
        <div className="text-sm text-gray-500">
          {lab.prefecture} | {lab.region}地域
        </div>
        
        {lab.lab_url && (
          <button
            onClick={handleExternalLink}
            className="flex items-center gap-1 text-blue-600 hover:text-blue-700 text-sm font-medium transition-colors"
          >
            <span>研究室サイト</span>
            <ExternalLink className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  )
}

// frontend/src/components/PopularSearches.tsx
import React from 'react'
import { TrendingUp } from 'lucide-react'

interface PopularSearchesProps {
  searches: string[]
  onSearchClick: (query: string) => void
}

const PopularSearches: React.FC<PopularSearchesProps> = ({ searches, onSearchClick }) => {
  return (
    <div className="space-y-4">
      <div className="flex items-center justify-center gap-2 text-gray-600">
        <TrendingUp className="h-4 w-4" />
        <span className="text-sm font-medium">人気の検索</span>
      </div>
      
      <div className="flex flex-wrap justify-center gap-2">
        {searches.map((search, index) => (
          <button
            key={index}
            onClick={() => onSearchClick(search)}
            className="px-4 py-2 bg-white border border-gray-200 rounded-full text-sm text-gray-700 hover:bg-gray-50 hover:border-gray-300 transition-colors"
          >
            {search}
          </button>
        ))}
      </div>
    </div>
  )
}

// frontend/src/components/FeatureCard.tsx
import React from 'react'

interface FeatureCardProps {
  icon: React.ReactNode
  title: string
  description: string
}

const FeatureCard: React.FC<FeatureCardProps> = ({ icon, title, description }) => {
  return (
    <div className="text-center space-y-4 p-6 bg-white rounded-xl shadow-sm border border-gray-100">
      <div className="flex justify-center">
        {icon}
      </div>
      <h3 className="text-xl font-semibold text-gray-900">
        {title}
      </h3>
      <p className="text-gray-600 leading-relaxed">
        {description}
      </p>
    </div>
  )
}

export default SearchBox
export { LabCard, PopularSearches, FeatureCard }
export type { LabCardData }