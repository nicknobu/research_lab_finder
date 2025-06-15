// API基底URL
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000'

// 基本的な型定義
export interface ResearchLab {
  id: number
  name: string
  professor_name: string
  department: string
  research_theme: string
  research_content: string
  research_field: string
  speciality: string
  keywords: string
  lab_url?: string
  university: {
    id: number
    name: string
    type: string
    prefecture: string
    region: string
    created_at: string
  }
  created_at: string
  updated_at: string
}

export interface ResearchLabSearchResult {
  id: number
  name: string
  professor_name: string
  department: string
  research_theme: string
  research_content: string
  research_field: string
  speciality: string
  keywords: string
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

// APIクライアント関数
export const searchLabs = async (request: SearchRequest): Promise<SearchResponse> => {
  const response = await fetch(`${API_BASE_URL}/api/search/`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(request),
  })

  if (!response.ok) {
    throw new Error(`検索エラー: ${response.status}`)
  }

  return response.json()
}

export const getLabDetail = async (labId: number): Promise<ResearchLab> => {
  const response = await fetch(`${API_BASE_URL}/api/labs/${labId}`)

  if (!response.ok) {
    throw new Error(`研究室詳細取得エラー: ${response.status}`)
  }

  return response.json()
}

export const getSimilarLabs = async (labId: number): Promise<ResearchLabSearchResult[]> => {
  const response = await fetch(`${API_BASE_URL}/api/labs/similar/${labId}`)

  if (!response.ok) {
    throw new Error(`類似研究室取得エラー: ${response.status}`)
  }

  return response.json()
}

export const healthCheck = async () => {
  const response = await fetch(`${API_BASE_URL}/health`)
  
  if (!response.ok) {
    throw new Error(`ヘルスチェックエラー: ${response.status}`)
  }

  return response.json()
}