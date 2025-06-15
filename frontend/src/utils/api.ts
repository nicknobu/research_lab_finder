// API基底URL
const API_BASE_URL = (import.meta as any)?.env?.VITE_API_BASE_URL || 'http://localhost:8000'

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

// 類似研究室取得（API + モック実装）- スコア修正版
export const getSimilarLabs = async (labId: number): Promise<ResearchLabSearchResult[]> => {
  // 開発環境用のモックデータ（スコア修正）
  const mockSimilarLabs: ResearchLabSearchResult[] = [
    {
      id: labId + 1000,
      name: "関連研究室A",
      professor_name: "関連教授A",
      department: "関連学部A",
      research_theme: "同様の研究テーマに取り組んでいます",
      research_content: "類似した研究内容を扱っています。最新の技術を用いて研究を推進中です。",
      research_field: "免疫学",
      speciality: "関連専門分野",
      keywords: "関連,キーワード,研究",
      university_name: "関連大学A",
      prefecture: "東京都",
      region: "関東",
      similarity_score: 0.78, // 0-1の範囲で正規化
      lab_url: "https://example.com"
    },
    {
      id: labId + 2000,
      name: "関連研究室B", 
      professor_name: "関連教授B",
      department: "関連学部B",
      research_theme: "別の角度から同じ分野を研究",
      research_content: "異なるアプローチで同分野を研究しています。国際的な共同研究も実施中です。",
      research_field: "免疫学",
      speciality: "関連専門分野B",
      keywords: "研究,関連,分野",
      university_name: "関連大学B",
      prefecture: "神奈川県", 
      region: "関東",
      similarity_score: 0.72 // 0-1の範囲で正規化
    },
    {
      id: labId + 3000,
      name: "関連研究室C",
      professor_name: "関連教授C", 
      department: "関連学部C",
      research_theme: "最新技術を活用した研究",
      research_content: "先端技術による研究アプローチを採用。産学連携にも力を入れています。",
      research_field: "生物学",
      speciality: "関連専門分野C",
      keywords: "最新,技術,研究",
      university_name: "関連大学C",
      prefecture: "大阪府",
      region: "関西", 
      similarity_score: 0.68 // 0-1の範囲で正規化
    }
  ]

  // 実際のAPIを試す
  try {
    const response = await fetch(`${API_BASE_URL}/api/labs/similar/${labId}`)
    if (response.ok) {
      const data = await response.json()
      console.log('類似研究室APIから取得:', data)
      
      // APIから取得したデータのスコアも正規化
      const normalizedData = data.map((lab: any) => ({
        ...lab,
        similarity_score: typeof lab.similarity_score === 'number' && !isNaN(lab.similarity_score) 
          ? lab.similarity_score 
          : 0.5 // デフォルト値
      }))
      
      return normalizedData
    }
  } catch (error) {
    console.log('類似研究室API未実装のため、モックデータを使用:', error)
  }

  // APIが未実装の場合はモックデータを返す
  return new Promise((resolve) => {
    setTimeout(() => {
      console.log('モック類似研究室データを返します (スコア修正版)')
      resolve(mockSimilarLabs)
    }, 800) // 実際のAPI呼び出しをシミュレート
  })
}

export const healthCheck = async () => {
  const response = await fetch(`${API_BASE_URL}/health`)
  
  if (!response.ok) {
    throw new Error(`ヘルスチェックエラー: ${response.status}`)
  }

  return response.json()
}
