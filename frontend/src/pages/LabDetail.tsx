// frontend/src/pages/LabDetail.tsx
import React from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useQuery } from 'react-query'
import { 
  ArrowLeft, MapPin, User, ExternalLink, BookOpen, 
  Tag, Building, Mail, Globe, Users, Star
} from 'lucide-react'

import LoadingSpinner from '../components/LoadingSpinner'
import ErrorMessage from '../components/ErrorMessage'
import { LabCard } from '../components/SearchBox'
import { getLabDetail, getSimilarLabs } from '../utils/api'
import type { ResearchLab } from '../types'

const LabDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const labId = parseInt(id || '0')

  // 研究室詳細データ取得
  const {
    data: lab,
    isLoading: labLoading,
    error: labError
  } = useQuery<ResearchLab>(
    ['lab', labId],
    () => getLabDetail(labId),
    {
      enabled: !!labId,
      retry: 2,
    }
  )

  // 類似研究室データ取得
  const {
    data: similarLabs,
    isLoading: similarLoading,
  } = useQuery(
    ['similarLabs', labId],
    () => getSimilarLabs(labId),
    {
      enabled: !!labId,
      retry: 1,
    }
  )

  if (labLoading) {
    return (
      <div className="flex justify-center py-20">
        <LoadingSpinner size="large" />
      </div>
    )
  }

  if (labError || !lab) {
    return (
      <ErrorMessage 
        title="研究室情報が見つかりません"
        message="指定された研究室の情報を取得できませんでした。"
        onRetry={() => navigate('/')}
        retryText="ホームに戻る"
      />
    )
  }

  const keywords = lab.keywords ? lab.keywords.split(',').map(k => k.trim()) : []

  return (
    <div className="space-y-8">
      {/* 戻るボタン */}
      <button
        onClick={() => navigate(-1)}
        className="flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors"
      >
        <ArrowLeft className="h-4 w-4" />
        <span>戻る</span>
      </button>

      {/* 研究室メイン情報 */}
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        {/* ヘッダー */}
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-8">
          <div className="space-y-4">
            <div className="flex items-start justify-between">
              <div className="space-y-2">
                <h1 className="text-3xl font-bold">{lab.name}</h1>
                <div className="flex items-center gap-4 text-blue-100">
                  <div className="flex items-center gap-2">
                    <Building className="h-4 w-4" />
                    <span>{lab.university.name}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <MapPin className="h-4 w-4" />
                    <span>{lab.university.prefecture} | {lab.university.region}地域</span>
                  </div>
                </div>
              </div>
              
              {lab.lab_url && (
                <a
                  href={lab.lab_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-2 bg-white/20 hover:bg-white/30 px-4 py-2 rounded-lg transition-colors"
                >
                  <Globe className="h-4 w-4" />
                  <span>研究室サイト</span>
                  <ExternalLink className="h-4 w-4" />
                </a>
              )}
            </div>

            <div className="flex items-center gap-6 text-blue-100">
              {lab.professor_name && (
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4" />
                  <span>{lab.professor_name}</span>
                </div>
              )}
              {lab.department && (
                <div className="flex items-center gap-2">
                  <BookOpen className="h-4 w-4" />
                  <span>{lab.department}</span>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* 詳細情報 */}
        <div className="p-8 space-y-8">
          {/* 研究分野・専門領域 */}
          <div className="grid md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-3">研究分野</h3>
              <span className="inline-block bg-blue-100 text-blue-800 px-4 py-2 rounded-full font-medium">
                {lab.research_field}
              </span>
            </div>
            
            {lab.speciality && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">専門領域</h3>
                <p className="text-gray-700">{lab.speciality}</p>
              </div>
            )}
          </div>

          {/* 研究テーマ */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-3">研究テーマ</h3>
            <p className="text-xl text-gray-800 font-medium">{lab.research_theme}</p>
          </div>

          {/* 研究内容 */}
          <div>
            <h3 className="text-lg font-semibold text-gray-900 mb-4">研究内容</h3>
            <div className="prose max-w-none">
              <p className="text-gray-700 leading-relaxed text-lg">
                {lab.research_content}
              </p>
            </div>
          </div>

          {/* キーワード */}
          {keywords.length > 0 && (
            <div>
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                <Tag className="inline h-5 w-5 mr-2" />
                キーワード
              </h3>
              <div className="flex flex-wrap gap-2">
                {keywords.map((keyword, index) => (
                  <span
                    key={index}
                    className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm"
                  >
                    {keyword}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* 大学情報 */}
          <div className="bg-gray-50 rounded-lg p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">
              <Building className="inline h-5 w-5 mr-2" />
              大学情報
            </h3>
            <div className="grid md:grid-cols-3 gap-4">
              <div>
                <span className="text-sm text-gray-600">大学名</span>
                <p className="font-medium text-gray-900">{lab.university.name}</p>
              </div>
              <div>
                <span className="text-sm text-gray-600">所在地</span>
                <p className="font-medium text-gray-900">{lab.university.prefecture}</p>
              </div>
              <div>
                <span className="text-sm text-gray-600">種別</span>
                <p className="font-medium text-gray-900">
                  {lab.university.type === 'national' ? '国立大学' :
                   lab.university.type === 'public' ? '公立大学' : '私立大学'}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 類似研究室 */}
      {similarLabs && similarLabs.length > 0 && (
        <div className="space-y-6">
          <div className="flex items-center gap-3">
            <Users className="h-6 w-6 text-gray-600" />
            <h2 className="text-2xl font-bold text-gray-900">類似研究室</h2>
            <span className="text-gray-500">この研究室に興味がある方におすすめ</span>
          </div>

          {similarLoading ? (
            <div className="flex justify-center py-8">
              <LoadingSpinner />
            </div>
          ) : (
            <div className="grid gap-4">
              {similarLabs.slice(0, 3).map((similarLab) => (
                <LabCard
                  key={similarLab.id}
                  lab={{
                    ...similarLab,
                    university_name: similarLab.university?.name || '',
                    prefecture: similarLab.university?.prefecture || '',
                    region: similarLab.university?.region || '',
                    similarity_score: 0.8 // 類似研究室の場合は固定値
                  }}
                  onClick={(lab) => navigate(`/lab/${lab.id}`)}
                />
              ))}
            </div>
          )}
        </div>
      )}

      {/* アクションボタン */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <div className="text-center space-y-4">
          <h3 className="text-lg font-semibold text-gray-900">
            この研究室に興味を持ちましたか？
          </h3>
          <p className="text-gray-600">
            更に詳しい情報や入試情報については、大学の公式サイトをご確認ください
          </p>
          <div className="flex justify-center gap-4">
            {lab.lab_url && (
              <a
                href={lab.lab_url}
                target="_blank"
                rel="noopener noreferrer"
                className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-3 rounded-lg transition-colors flex items-center gap-2"
              >
                <Globe className="h-4 w-4" />
                研究室公式サイト
              </a>
            )}
            <button
              onClick={() => navigate('/')}
              className="bg-gray-100 hover:bg-gray-200 text-gray-700 px-6 py-3 rounded-lg transition-colors"
            >
              他の研究室も探す
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default LabDetail