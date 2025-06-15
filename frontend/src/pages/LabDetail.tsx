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

  useEffect(() => {
    if (id) {
      loadLabDetail(parseInt(id))
    }
  }, [id])

  const loadLabDetail = async (labId: number) => {
    setIsLoading(true)
    setError('')

    try {
      // 研究室詳細と類似研究室を並行取得
      const [labDetail, similar] = await Promise.all([
        getLabDetail(labId),
        getSimilarLabs(labId)
      ])

      setLab(labDetail)
      setSimilarLabs(similar)
    } catch (err) {
      console.error('研究室詳細取得エラー:', err)
      setError('研究室の詳細情報を取得できませんでした。')
    } finally {
      setIsLoading(false)
    }
  }

  const handleSimilarLabClick = (similarLab: ResearchLabSearchResult) => {
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
              シェア
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto p-6">
        {/* メイン情報カード */}
        <div className="bg-white rounded-lg shadow-lg p-8 mb-8">
          {/* ヘッダー */}
          <div className="border-b border-gray-200 pb-6 mb-6">
            <h1 className="text-3xl font-bold text-gray-900 mb-4">
              {lab.name}
            </h1>
            
            <div className="grid md:grid-cols-2 gap-4">
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
                  <p>{lab.university.name}</p>
                  <p className="text-sm text-gray-600">{lab.department}</p>
                </div>
              </div>
              
              <div className="flex items-center text-gray-700">
                <MapPin className="h-5 w-5 mr-3 text-blue-600" />
                <div>
                  <span className="font-medium">所在地</span>
                  <p>{lab.university.prefecture}</p>
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
        {similarLabs.length > 0 && (
          <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-6 flex items-center">
              <Star className="h-6 w-6 mr-2 text-yellow-500" />
              関連する研究室
            </h2>
            
            <div className="space-y-4">
              {similarLabs.map((similarLab) => (
                <LabCard
                  key={similarLab.id}
                  lab={similarLab}
                  onClick={handleSimilarLabClick}
                />
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default LabDetail