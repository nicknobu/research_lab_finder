// frontend/src/types/index.ts
export interface University {
  id: number
  name: string
  type: 'national' | 'public' | 'private'
  prefecture: string
  region: string
  created_at: string
}

export interface ResearchLab {
  id: number
  university_id: number
  name: string
  professor_name?: string
  department?: string
  research_theme: string
  research_content: string
  research_field: string
  speciality?: string
  keywords?: string
  lab_url?: string
  university: University
  created_at: string
  updated_at: string
}

export interface ResearchLabSearchResult {
  id: number
  name: string
  professor_name?: string
  department?: string
  research_theme: string
  research_content: string
  research_field: string
  speciality?: string
  keywords?: string
  lab_url?: string
  university_name: string
  prefecture: string
  region: string
  similarity_score: number
}

export interface SearchRequest {
  query: string
  limit?: number
  region_filter?: string[]
  field_filter?: string[]
  min_similarity?: number
}

export interface SearchResponse {
  query: string
  total_results: number
  search_time_ms: number
  results: ResearchLabSearchResult[]
}

export interface SearchSuggestion {
  text: string
  category: string
}

export interface ApiError {
  error: string
  message: string
  details?: Record<string, any>
}

// frontend/src/utils/api.ts
import axios, { AxiosResponse } from 'axios'
import type { 
  SearchRequest, 
  SearchResponse, 
  ResearchLab, 
  University,
  SearchSuggestion,
  ApiError
} from '../types'

// API基底URL
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'

// Axiosインスタンス作成
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// レスポンスインターセプター（エラーハンドリング）
apiClient.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error) => {
    if (error.response) {
      // サーバーエラーレスポンス
      const apiError: ApiError = error.response.data
      throw new Error(apiError.message || 'サーバーエラーが発生しました')
    } else if (error.request) {
      // ネットワークエラー
      throw new Error('ネットワークエラー：サーバーに接続できません')
    } else {
      // その他のエラー
      throw new Error('予期しないエラーが発生しました')
    }
  }
)

// === 検索API ===

/**
 * セマンティック検索実行
 */
export const searchLabs = async (request: SearchRequest): Promise<SearchResponse> => {
  const response = await apiClient.post<SearchResponse>('/api/search/', request)
  return response.data
}

/**
 * 検索候補取得
 */
export const getSearchSuggestions = async (
  query: string, 
  limit: number = 10
): Promise<SearchSuggestion[]> => {
  const response = await apiClient.get<SearchSuggestion[]>('/api/search/suggestions', {
    params: { q: query, limit }
  })
  return response.data
}

/**
 * 人気検索クエリ取得
 */
export const getPopularSearches = async (limit: number = 10): Promise<string[]> => {
  const response = await apiClient.get<string[]>('/api/search/popular', {
    params: { limit }
  })
  return response.data
}

/**
 * 検索統計情報取得
 */
export const getSearchStats = async (): Promise<Record<string, any>> => {
  const response = await apiClient.get<Record<string, any>>('/api/search/stats')
  return response.data
}

// === 研究室API ===

/**
 * 研究室詳細取得
 */
export const getLabDetail = async (labId: number): Promise<ResearchLab> => {
  const response = await apiClient.get<ResearchLab>(`/api/labs/${labId}`)
  return response.data
}

/**
 * 研究室一覧取得
 */
export const getLabs = async (params: {
  skip?: number
  limit?: number
  research_field?: string
  region?: string
  university_name?: string
}): Promise<ResearchLab[]> => {
  const response = await apiClient.get<ResearchLab[]>('/api/labs/', { params })
  return response.data
}

/**
 * 類似研究室取得
 */
export const getSimilarLabs = async (
  labId: number, 
  limit: number = 5
): Promise<ResearchLab[]> => {
  const response = await apiClient.get<ResearchLab[]>(`/api/labs/similar/${labId}`, {
    params: { limit }
  })
  return response.data
}

// === 大学API ===

/**
 * 大学一覧取得
 */
export const getUniversities = async (params: {
  skip?: number
  limit?: number
  region?: string
  university_type?: string
}): Promise<University[]> => {
  const response = await apiClient.get<University[]>('/api/labs/universities/', { params })
  return response.data
}

/**
 * 大学詳細取得
 */
export const getUniversityDetail = async (universityId: number): Promise<University> => {
  const response = await apiClient.get<University>(`/api/labs/universities/${universityId}`)
  return response.data
}

/**
 * 大学所属研究室取得
 */
export const getUniversityLabs = async (
  universityId: number,
  params: {
    skip?: number
    limit?: number
  } = {}
): Promise<ResearchLab[]> => {
  const response = await apiClient.get<ResearchLab[]>(
    `/api/labs/universities/${universityId}/labs`, 
    { params }
  )
  return response.data
}

// === ヘルスチェック ===

/**
 * APIヘルスチェック
 */
export const healthCheck = async (): Promise<{ status: string; message: string; version: string }> => {
  const response = await apiClient.get('/health')
  return response.data
}

// エクスポート
export default apiClient