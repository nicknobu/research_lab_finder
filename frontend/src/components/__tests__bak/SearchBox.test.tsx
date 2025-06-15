// frontend/src/components/__tests__/SearchBox.test.tsx
import React from 'react'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom'
import SearchBox from '../SearchBox'

describe('SearchBox', () => {
  const mockOnChange = jest.fn()
  const mockOnSearch = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders with placeholder text', () => {
    render(
      <SearchBox
        value=""
        onChange={mockOnChange}
        onSearch={mockOnSearch}
        placeholder="テスト用プレースホルダー"
      />
    )

    expect(screen.getByPlaceholderText('テスト用プレースホルダー')).toBeInTheDocument()
  })

  it('calls onChange when user types', async () => {
    const user = userEvent.setup()
    
    render(
      <SearchBox
        value=""
        onChange={mockOnChange}
        onSearch={mockOnSearch}
      />
    )

    const input = screen.getByRole('textbox')
    await user.type(input, 'がん治療')

    expect(mockOnChange).toHaveBeenCalledTimes(4) // 'が', 'ん', '治', '療'
  })

  it('calls onSearch when form is submitted', async () => {
    const user = userEvent.setup()
    
    render(
      <SearchBox
        value="がん治療の研究"
        onChange={mockOnChange}
        onSearch={mockOnSearch}
      />
    )

    const form = screen.getByRole('textbox').closest('form')
    if (form) {
      fireEvent.submit(form)
    }

    expect(mockOnSearch).toHaveBeenCalledWith('がん治療の研究')
  })

  it('shows clear button when there is text', () => {
    render(
      <SearchBox
        value="テストテキスト"
        onChange={mockOnChange}
        onSearch={mockOnSearch}
      />
    )

    expect(screen.getByRole('button', { name: /clear/i })).toBeInTheDocument()
  })

  it('clears input when clear button is clicked', async () => {
    const user = userEvent.setup()
    
    render(
      <SearchBox
        value="テストテキスト"
        onChange={mockOnChange}
        onSearch={mockOnSearch}
      />
    )

    const clearButton = screen.getByRole('button', { name: /clear/i })
    await user.click(clearButton)

    expect(mockOnChange).toHaveBeenCalledWith('')
  })
})

// frontend/src/components/__tests__/LabCard.test.tsx
import React from 'react'
import { render, screen, fireEvent } from '@testing-library/react'
import '@testing-library/jest-dom'
import { LabCard, LabCardData } from '../SearchBox'

const mockLabData: LabCardData = {
  id: 1,
  name: 'テスト研究室',
  professor_name: 'テスト教授',
  university_name: 'テスト大学',
  prefecture: '東京都',
  region: '関東',
  research_theme: 'テスト研究テーマ',
  research_content: 'これはテスト用の研究内容です。',
  research_field: '免疫学',
  similarity_score: 0.85,
  lab_url: 'https://test-lab.example.com'
}

describe('LabCard', () => {
  const mockOnClick = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders lab information correctly', () => {
    render(<LabCard lab={mockLabData} onClick={mockOnClick} />)

    expect(screen.getByText('テスト研究室')).toBeInTheDocument()
    expect(screen.getByText('テスト教授')).toBeInTheDocument()
    expect(screen.getByText('テスト大学')).toBeInTheDocument()
    expect(screen.getByText('テスト研究テーマ')).toBeInTheDocument()
    expect(screen.getByText('免疫学')).toBeInTheDocument()
    expect(screen.getByText('85%')).toBeInTheDocument()
  })

  it('calls onClick when card is clicked', () => {
    render(<LabCard lab={mockLabData} onClick={mockOnClick} />)

    const card = screen.getByRole('button')
    fireEvent.click(card)

    expect(mockOnClick).toHaveBeenCalledWith(mockLabData)
  })

  it('opens external link when research site button is clicked', () => {
    // window.open をモック
    const mockOpen = jest.fn()
    Object.assign(window, {
      open: mockOpen
    })

    render(<LabCard lab={mockLabData} onClick={mockOnClick} />)

    const linkButton = screen.getByText('研究室サイト')
    fireEvent.click(linkButton)

    expect(mockOpen).toHaveBeenCalledWith('https://test-lab.example.com', '_blank')
  })

  it('handles missing professor name gracefully', () => {
    const labDataWithoutProfessor = { ...mockLabData, professor_name: undefined }
    
    render(<LabCard lab={labDataWithoutProfessor} onClick={mockOnClick} />)

    expect(screen.getByText('教授名未登録')).toBeInTheDocument()
  })
})

// frontend/src/utils/__tests__/api.test.ts
import { rest } from 'msw'
import { setupServer } from 'msw/node'
import { searchLabs, getLabDetail, healthCheck } from '../api'
import type { SearchResponse, ResearchLab } from '../../types'

// MSW サーバー設定
const server = setupServer(
  rest.post('/api/search/', (req, res, ctx) => {
    const mockResponse: SearchResponse = {
      query: 'テストクエリ',
      total_results: 1,
      search_time_ms: 100,
      results: [{
        id: 1,
        name: 'テスト研究室',
        professor_name: 'テスト教授',
        university_name: 'テスト大学',
        prefecture: '東京都',
        region: '関東',
        research_theme: 'テスト研究テーマ',
        research_content: 'テスト研究内容',
        research_field: '免疫学',
        similarity_score: 0.85
      }]
    }
    return res(ctx.json(mockResponse))
  }),

  rest.get('/api/labs/1', (req, res, ctx) => {
    const mockLab: ResearchLab = {
      id: 1,
      university_id: 1,
      name: 'テスト研究室',
      professor_name: 'テスト教授',
      department: 'テスト学部',
      research_theme: 'テスト研究テーマ',
      research_content: 'テスト研究内容',
      research_field: '免疫学',
      university: {
        id: 1,
        name: 'テスト大学',
        type: 'private',
        prefecture: '東京都',
        region: '関東',
        created_at: '2024-01-01T00:00:00Z'
      },
      created_at: '2024-01-01T00:00:00Z',
      updated_at: '2024-01-01T00:00:00Z'
    }
    return res(ctx.json(mockLab))
  }),

  rest.get('/health', (req, res, ctx) => {
    return res(ctx.json({
      status: 'healthy',
      message: 'Test API is running',
      version: '1.0.0'
    }))
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('API Client', () => {
  describe('searchLabs', () => {
    it('returns search results successfully', async () => {
      const result = await searchLabs({
        query: 'テストクエリ',
        limit: 10
      })

      expect(result.query).toBe('テストクエリ')
      expect(result.total_results).toBe(1)
      expect(result.results).toHaveLength(1)
      expect(result.results[0].name).toBe('テスト研究室')
    })
  })

  describe('getLabDetail', () => {
    it('returns lab detail successfully', async () => {
      const result = await getLabDetail(1)

      expect(result.id).toBe(1)
      expect(result.name).toBe('テスト研究室')
      expect(result.university.name).toBe('テスト大学')
    })
  })

  describe('healthCheck', () => {
    it('returns health status successfully', async () => {
      const result = await healthCheck()

      expect(result.status).toBe('healthy')
      expect(result.message).toBe('Test API is running')
      expect(result.version).toBe('1.0.0')
    })
  })
})

// frontend/jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/src/setupTests.ts'],
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest',
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx'],
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.(ts|tsx)',
    '<rootDir>/src/**/*.(test|spec).(ts|tsx)',
  ],
  collectCoverageFrom: [
    'src/**/*.(ts|tsx)',
    '!src/**/*.d.ts',
    '!src/main.tsx',
    '!src/setupTests.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70,
    },
  },
}

// frontend/src/setupTests.ts
import '@testing-library/jest-dom'
import { configure } from '@testing-library/react'

// Configure testing library
configure({ testIdAttribute: 'data-testid' })

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: jest.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
})

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor() {}
  observe() {
    return null
  }
  disconnect() {
    return null
  }
  unobserve() {
    return null
  }
}

// E2Eテスト用の設定
// frontend/e2e/search.spec.ts
import { test, expect } from '@playwright/test'

test.describe('研究室検索システム E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:3000')
  })

  test('ホームページが正常に表示される', async ({ page }) => {
    await expect(page.locator('h1')).toContainText('研究室ファインダー')
    await expect(page.locator('input[type="text"]')).toBeVisible()
  })

  test('検索機能が正常に動作する', async ({ page }) => {
    // 検索クエリを入力
    await page.fill('input[type="text"]', 'がん治療の研究をしたい')
    
    // 検索実行
    await page.press('input[type="text"]', 'Enter')
    
    // 検索結果ページに遷移
    await expect(page).toHaveURL(/.*\/search\?q=.*/)
    
    // 検索結果が表示される
    await expect(page.locator('h1')).toContainText('検索結果')
  })

  test('人気検索からの検索が動作する', async ({ page }) => {
    // 人気検索ボタンをクリック
    await page.click('text=がん治療の研究をしたい')
    
    // 検索結果ページに遷移
    await expect(page).toHaveURL(/.*\/search\?q=.*/)
  })

  test('研究室詳細ページへの遷移が動作する', async ({ page }) => {
    // まず検索を実行
    await page.fill('input[type="text"]', '免疫学')
    await page.press('input[type="text"]', 'Enter')
    
    // 検索結果から研究室カードをクリック（最初の結果）
    await page.click('[data-testid="lab-card"]:first-child')
    
    // 研究室詳細ページに遷移
    await expect(page).toHaveURL(/.*\/lab\/\d+/)
    
    // 研究室詳細情報が表示される
    await expect(page.locator('[data-testid="lab-name"]')).toBeVisible()
  })

  test('フィルター機能が動作する', async ({ page }) => {
    // 検索実行
    await page.fill('input[type="text"]', '研究')
    await page.press('input[type="text"]', 'Enter')
    
    // フィルターパネルを開く
    await page.click('text=フィルター')
    
    // 地域フィルターを選択
    await page.check('text=関東')
    
    // 結果が更新されることを確認
    await expect(page.locator('[data-testid="search-results"]')).toBeVisible()
  })

  test('レスポンシブデザインが正常に動作する', async ({ page }) => {
    // モバイルサイズに設定
    await page.setViewportSize({ width: 375, height: 667 })
    
    // ページが正常に表示される
    await expect(page.locator('h1')).toBeVisible()
    await expect(page.locator('input[type="text"]')).toBeVisible()
    
    // ナビゲーションが適切に表示される
    await expect(page.locator('header')).toBeVisible()
  })
})

// frontend/playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
  webServer: {
    command: 'npm run dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
})