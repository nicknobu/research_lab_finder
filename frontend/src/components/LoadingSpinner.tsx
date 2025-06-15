// frontend/src/components/LoadingSpinner.tsx
import React from 'react'

interface LoadingSpinnerProps {
  size?: 'small' | 'medium' | 'large'
  className?: string
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ 
  size = 'medium', 
  className = '' 
}) => {
  const sizeClasses = {
    small: 'h-4 w-4',
    medium: 'h-8 w-8',
    large: 'h-12 w-12'
  }

  return (
    <div className={`flex items-center justify-center ${className}`}>
      <div 
        className={`animate-spin rounded-full border-2 border-gray-300 border-t-blue-600 ${sizeClasses[size]}`}
      />
    </div>
  )
}

// frontend/src/components/ErrorMessage.tsx
import React from 'react'
import { AlertCircle, RefreshCw } from 'lucide-react'

interface ErrorMessageProps {
  title?: string
  message: string
  onRetry?: () => void
  retryText?: string
  className?: string
}

const ErrorMessage: React.FC<ErrorMessageProps> = ({
  title = 'エラーが発生しました',
  message,
  onRetry,
  retryText = '再試行',
  className = ''
}) => {
  return (
    <div className={`bg-red-50 border border-red-200 rounded-lg p-6 ${className}`}>
      <div className="flex items-start gap-4">
        <AlertCircle className="h-6 w-6 text-red-600 flex-shrink-0 mt-0.5" />
        <div className="flex-1">
          <h3 className="font-semibold text-red-900 mb-2">{title}</h3>
          <p className="text-red-700 mb-4">{message}</p>
          {onRetry && (
            <button
              onClick={onRetry}
              className="flex items-center gap-2 bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded-lg transition-colors"
            >
              <RefreshCw className="h-4 w-4" />
              {retryText}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}

// frontend/src/components/FilterPanel.tsx
import React from 'react'
import { Filter, X } from 'lucide-react'

interface FilterPanelProps {
  filters: {
    region: string[]
    field: string[]
    minSimilarity: number
  }
  onChange: (filters: { region: string[]; field: string[]; minSimilarity: number }) => void
}

const FilterPanel: React.FC<FilterPanelProps> = ({ filters, onChange }) => {
  const regions = [
    '北海道', '東北', '関東', '中部', '北陸', '東海', 
    '関西', '中国', '四国', '九州'
  ]

  const researchFields = [
    '免疫学', '生物学', '医学', '薬学', '工学', '情報科学',
    '化学', '物理学', '数学', '心理学', '社会学'
  ]

  const handleRegionChange = (region: string, checked: boolean) => {
    const newRegions = checked
      ? [...filters.region, region]
      : filters.region.filter(r => r !== region)
    
    onChange({ ...filters, region: newRegions })
  }

  const handleFieldChange = (field: string, checked: boolean) => {
    const newFields = checked
      ? [...filters.field, field]
      : filters.field.filter(f => f !== field)
    
    onChange({ ...filters, field: newFields })
  }

  const handleSimilarityChange = (value: number) => {
    onChange({ ...filters, minSimilarity: value })
  }

  const clearAllFilters = () => {
    onChange({ region: [], field: [], minSimilarity: 0.5 })
  }

  const hasActiveFilters = filters.region.length > 0 || filters.field.length > 0 || filters.minSimilarity !== 0.5

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 space-y-6">
      {/* ヘッダー */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Filter className="h-5 w-5 text-gray-600" />
          <h3 className="font-semibold text-gray-900">フィルター</h3>
        </div>
        {hasActiveFilters && (
          <button
            onClick={clearAllFilters}
            className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 transition-colors"
          >
            <X className="h-4 w-4" />
            <span>クリア</span>
          </button>
        )}
      </div>

      {/* 類似度フィルター */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-3">
          最小類似度: {Math.round(filters.minSimilarity * 100)}%
        </label>
        <input
          type="range"
          min="0.3"
          max="1.0"
          step="0.1"
          value={filters.minSimilarity}
          onChange={(e) => handleSimilarityChange(parseFloat(e.target.value))}
          className="w-full"
        />
        <div className="flex justify-between text-xs text-gray-500 mt-1">
          <span>30%</span>
          <span>100%</span>
        </div>
      </div>

      {/* 地域フィルター */}
      <div>
        <h4 className="font-medium text-gray-900 mb-3">地域</h4>
        <div className="space-y-2 max-h-48 overflow-y-auto">
          {regions.map((region) => (
            <label key={region} className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={filters.region.includes(region)}
                onChange={(e) => handleRegionChange(region, e.target.checked)}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-sm text-gray-700">{region}</span>
            </label>
          ))}
        </div>
      </div>

      {/* 研究分野フィルター */}
      <div>
        <h4 className="font-medium text-gray-900 mb-3">研究分野</h4>
        <div className="space-y-2 max-h-48 overflow-y-auto">
          {researchFields.map((field) => (
            <label key={field} className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={filters.field.includes(field)}
                onChange={(e) => handleFieldChange(field, e.target.checked)}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-sm text-gray-700">{field}</span>
            </label>
          ))}
        </div>
      </div>
    </div>
  )
}

// frontend/src/components/Header.tsx
import React from 'react'
import { Link, useLocation } from 'react-router-dom'
import { Search, Home } from 'lucide-react'

const Header: React.FC = () => {
  const location = useLocation()

  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* ロゴ */}
          <Link 
            to="/" 
            className="flex items-center gap-3 font-bold text-xl text-gray-900 hover:text-blue-600 transition-colors"
          >
            <div className="bg-blue-600 text-white rounded-lg p-2">
              <Search className="h-5 w-5" />
            </div>
            研究室ファインダー
          </Link>

          {/* ナビゲーション */}
          <nav className="flex items-center gap-6">
            <Link
              to="/"
              className={`flex items-center gap-2 px-3 py-2 rounded-lg transition-colors ${
                location.pathname === '/'
                  ? 'bg-blue-50 text-blue-600'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
              }`}
            >
              <Home className="h-4 w-4" />
              <span>ホーム</span>
            </Link>
          </nav>
        </div>
      </div>
    </header>
  )
}

// frontend/src/components/Footer.tsx
import React from 'react'
import { Github, Mail } from 'lucide-react'

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-900 text-white mt-20">
      <div className="container mx-auto px-4 py-12">
        <div className="grid md:grid-cols-3 gap-8">
          {/* サービス情報 */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold">研究室ファインダー</h3>
            <p className="text-gray-400 text-sm leading-relaxed">
              中学生の興味・関心から全国の大学研究室をAIが推奨する
              セマンティック検索プラットフォーム
            </p>
          </div>

          {/* リンク */}
          <div className="space-y-4">
            <h4 className="font-medium">サービス</h4>
            <ul className="space-y-2 text-sm text-gray-400">
              <li>
                <a href="/" className="hover:text-white transition-colors">
                  研究室検索
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-white transition-colors">
                  使い方ガイド
                </a>
              </li>
              <li>
                <a href="#" className="hover:text-white transition-colors">
                  よくある質問
                </a>
              </li>
            </ul>
          </div>

          {/* 開発情報 */}
          <div className="space-y-4">
            <h4 className="font-medium">開発情報</h4>
            <div className="flex gap-4">
              <a
                href="https://github.com"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
              >
                <Github className="h-4 w-4" />
                <span className="text-sm">GitHub</span>
              </a>
              <a
                href="mailto:contact@example.com"
                className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors"
              >
                <Mail className="h-4 w-4" />
                <span className="text-sm">お問い合わせ</span>
              </a>
            </div>
          </div>
        </div>

        <div className="border-t border-gray-800 mt-8 pt-8 text-center text-sm text-gray-400">
          <p>&copy; 2025 研究室ファインダー. All rights reserved.</p>
        </div>
      </div>
    </footer>
  )
}

// frontend/src/components/ErrorBoundary.tsx
import React, { Component, ErrorInfo, ReactNode } from 'react'
import { AlertTriangle } from 'lucide-react'

interface Props {
  children: ReactNode
}

interface State {
  hasError: boolean
  error?: Error
}

class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false
  }

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error:', error, errorInfo)
  }

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg shadow-lg p-8 max-w-md w-full text-center">
            <AlertTriangle className="h-12 w-12 text-red-500 mx-auto mb-4" />
            <h1 className="text-xl font-semibold text-gray-900 mb-2">
              申し訳ございません
            </h1>
            <p className="text-gray-600 mb-6">
              予期しないエラーが発生しました。
              ページを再読み込みしてください。
            </p>
            <button
              onClick={() => window.location.reload()}
              className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors"
            >
              ページを再読み込み
            </button>
          </div>
        </div>
      )
    }

    return this.props.children
  }
}

export default LoadingSpinner
export { ErrorMessage, FilterPanel, Header, Footer, ErrorBoundary }