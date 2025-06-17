#!/bin/bash

echo "🏗️ Infrastructure層（技術基盤）を実装中..."

# ==================== 1. HTTP基盤実装 ====================
echo "🌐 HTTP基盤を実装中..."

# レート制限器
cat > scraper/infrastructure/http/rate_limiter.py << 'EOF'
"""
非同期レート制限器
大学サーバーへの負荷を適切に制御
"""

import asyncio
import time
from typing import Dict, Optional
from dataclasses import dataclass

from scraper.config.interfaces import RateLimiterInterface


@dataclass
class RateLimitConfig:
    """レート制限設定"""
    requests_per_second: float = 0.5
    burst_limit: int = 3
    window_size: int = 60


class TokenBucketRateLimiter:
    """
    トークンバケットアルゴリズムによるレート制限
    大学別に個別のレート制限を適用
    """
    
    def __init__(self, config: RateLimitConfig):
        self._config = config
        self._buckets: Dict[str, Dict] = {}
        self._lock = asyncio.Lock()
    
    async def acquire(self, domain: str = "default") -> None:
        """
        リクエスト許可を取得
        
        Args:
            domain: 対象ドメイン（大学別制限用）
        """
        async with self._lock:
            now = time.time()
            
            if domain not in self._buckets:
                self._buckets[domain] = {
                    'tokens': self._config.burst_limit,
                    'last_refill': now
                }
            
            bucket = self._buckets[domain]
            
            # トークンの補充
            time_passed = now - bucket['last_refill']
            tokens_to_add = time_passed * self._config.requests_per_second
            bucket['tokens'] = min(
                self._config.burst_limit,
                bucket['tokens'] + tokens_to_add
            )
            bucket['last_refill'] = now
            
            # トークンが不足している場合は待機
            if bucket['tokens'] < 1:
                wait_time = (1 - bucket['tokens']) / self._config.requests_per_second
                await asyncio.sleep(wait_time)
                bucket['tokens'] = 0
            else:
                bucket['tokens'] -= 1
    
    def get_delay(self, domain: str = "default") -> float:
        """次のリクエストまでの推奨待機時間を取得"""
        if domain not in self._buckets:
            return 0.0
        
        bucket = self._buckets[domain]
        if bucket['tokens'] >= 1:
            return 0.0
        
        return (1 - bucket['tokens']) / self._config.requests_per_second
    
    def reset_bucket(self, domain: str) -> None:
        """指定ドメインのバケットをリセット"""
        if domain in self._buckets:
            del self._buckets[domain]


class AdaptiveRateLimiter:
    """
    適応的レート制限器
    サーバーレスポンスに基づいて動的に制限を調整
    """
    
    def __init__(self, base_config: RateLimitConfig):
        self._base_config = base_config
        self._current_rate = base_config.requests_per_second
        self._success_count = 0
        self._error_count = 0
        self._last_adjustment = time.time()
        self._bucket_limiter = TokenBucketRateLimiter(base_config)
    
    async def acquire(self, domain: str = "default") -> None:
        """適応的レート制限でリクエスト許可を取得"""
        # 現在のレートでトークンバケット制限
        await self._bucket_limiter.acquire(domain)
        
        # 定期的にレート調整
        await self._adjust_rate_if_needed()
    
    async def _adjust_rate_if_needed(self) -> None:
        """エラー率に基づいてレートを調整"""
        now = time.time()
        
        # 1分ごとに調整
        if now - self._last_adjustment < 60:
            return
        
        total_requests = self._success_count + self._error_count
        if total_requests < 10:  # 十分なサンプルがない場合はスキップ
            return
        
        error_rate = self._error_count / total_requests
        
        if error_rate > 0.1:  # エラー率10%超過でレート削減
            self._current_rate *= 0.8
            print(f"⚠️ レート制限強化: {self._current_rate:.2f} req/s (エラー率: {error_rate:.2%})")
        elif error_rate < 0.02:  # エラー率2%未満でレート緩和
            self._current_rate = min(
                self._current_rate * 1.1,
                self._base_config.requests_per_second * 2  # 最大で基準値の2倍まで
            )
            print(f"✅ レート制限緩和: {self._current_rate:.2f} req/s")
        
        # カウンターリセット
        self._success_count = 0
        self._error_count = 0
        self._last_adjustment = now
        
        # バケット設定更新
        new_config = RateLimitConfig(
            requests_per_second=self._current_rate,
            burst_limit=self._base_config.burst_limit,
            window_size=self._base_config.window_size
        )
        self._bucket_limiter = TokenBucketRateLimiter(new_config)
    
    def record_success(self) -> None:
        """成功を記録"""
        self._success_count += 1
    
    def record_error(self) -> None:
        """エラーを記録"""
        self._error_count += 1
EOF

# HTTPクライアント
cat > scraper/infrastructure/http/http_client.py << 'EOF'
"""
堅牢なHTTPクライアント
再試行、タイムアウト、ユーザーエージェント管理
"""

import aiohttp
import asyncio
import logging
from typing import Optional, Dict, Any, Union
from urllib.parse import urljoin, urlparse
import random

from scraper.config.settings import scraping_settings
from scraper.infrastructure.http.rate_limiter import AdaptiveRateLimiter, RateLimitConfig
from scraper.infrastructure.http.retry_handler import RetryHandler

logger = logging.getLogger(__name__)


class ResearchLabHttpClient:
    """研究室スクレイピング専用HTTPクライアント"""
    
    def __init__(self):
        self._session: Optional[aiohttp.ClientSession] = None
        self._rate_limiter = AdaptiveRateLimiter(
            RateLimitConfig(
                requests_per_second=scraping_settings.requests_per_second,
                burst_limit=scraping_settings.concurrent_requests
            )
        )
        self._retry_handler = RetryHandler()
        self._user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        ]
    
    async def __aenter__(self):
        """非同期コンテキストマネージャー開始"""
        await self._ensure_session()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """非同期コンテキストマネージャー終了"""
        await self.close()
    
    async def _ensure_session(self) -> None:
        """セッションの確保"""
        if self._session is None or self._session.closed:
            timeout = aiohttp.ClientTimeout(total=scraping_settings.request_timeout)
            connector = aiohttp.TCPConnector(
                limit=scraping_settings.concurrent_requests,
                limit_per_host=2,  # 同一ホストへの同時接続数制限
                ttl_dns_cache=300,  # DNS キャッシュ
                use_dns_cache=True
            )
            
            self._session = aiohttp.ClientSession(
                timeout=timeout,
                connector=connector,
                headers={'User-Agent': random.choice(self._user_agents)}
            )
    
    async def get(
        self, 
        url: str, 
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> aiohttp.ClientResponse:
        """
        HTTPGETリクエスト（レート制限・再試行付き）
        
        Args:
            url: リクエストURL
            headers: 追加ヘッダー
            **kwargs: その他のaiohttp引数
        
        Returns:
            aiohttp.ClientResponse: レスポンス
        """
        await self._ensure_session()
        
        # ドメイン抽出
        domain = urlparse(url).netloc
        
        # レート制限適用
        await self._rate_limiter.acquire(domain)
        
        # リクエスト実行（再試行付き）
        return await self._retry_handler.execute_with_retry(
            self._make_request, url, headers, **kwargs
        )
    
    async def _make_request(
        self, 
        url: str, 
        headers: Optional[Dict[str, str]] = None,
        **kwargs
    ) -> aiohttp.ClientResponse:
        """実際のHTTPリクエスト実行"""
        request_headers = {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'ja,en-US;q=0.7,en;q=0.3',
            'Accept-Encoding': 'gzip, deflate',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        }
        
        if headers:
            request_headers.update(headers)
        
        logger.debug(f"Requesting: {url}")
        
        try:
            response = await self._session.get(url, headers=request_headers, **kwargs)
            
            # レスポンス状態記録
            if response.status < 400:
                self._rate_limiter.record_success()
                logger.debug(f"Success: {url} ({response.status})")
            else:
                self._rate_limiter.record_error()
                logger.warning(f"HTTP Error: {url} ({response.status})")
            
            return response
            
        except Exception as e:
            self._rate_limiter.record_error()
            logger.error(f"Request failed: {url} - {e}")
            raise
    
    async def get_text(self, url: str, encoding: str = 'utf-8', **kwargs) -> str:
        """HTMLテキストを取得"""
        response = await self.get(url, **kwargs)
        try:
            # レスポンスのエンコーディング検出
            if response.charset:
                encoding = response.charset
            
            content = await response.text(encoding=encoding)
            return content
        finally:
            response.close()
    
    async def get_multiple(
        self, 
        urls: list[str], 
        max_concurrent: int = 3
    ) -> list[Union[str, Exception]]:
        """複数URLの並行取得"""
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def fetch_single(url: str):
            async with semaphore:
                try:
                    return await self.get_text(url)
                except Exception as e:
                    logger.error(f"Failed to fetch {url}: {e}")
                    return e
        
        tasks = [fetch_single(url) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        return results
    
    async def close(self) -> None:
        """セッションクローズ"""
        if self._session and not self._session.closed:
            await self._session.close()
EOF

# 再試行ハンドラー
cat > scraper/infrastructure/http/retry_handler.py << 'EOF'
"""
堅牢な再試行機構
一時的なネットワークエラーとサーバーエラーに対応
"""

import asyncio
import logging
from typing import Any, Callable, TypeVar, Optional
import random
from functools import wraps

from scraper.config.settings import scraping_settings
from scraper.config.interfaces import ScrapingError

logger = logging.getLogger(__name__)

T = TypeVar('T')


class RetryHandler:
    """指数バックオフを使用した再試行ハンドラー"""
    
    def __init__(
        self,
        max_retries: int = None,
        base_delay: float = None,
        max_delay: float = 60.0,
        backoff_factor: float = 2.0,
        jitter: bool = True
    ):
        self.max_retries = max_retries or scraping_settings.retry_attempts
        self.base_delay = base_delay or scraping_settings.retry_delay
        self.max_delay = max_delay
        self.backoff_factor = backoff_factor
        self.jitter = jitter
    
    async def execute_with_retry(
        self,
        func: Callable[..., T],
        *args,
        **kwargs
    ) -> T:
        """
        指数バックオフによる再試行実行
        
        Args:
            func: 実行する関数
            *args: 関数の引数
            **kwargs: 関数のキーワード引数
        
        Returns:
            T: 関数の戻り値
        
        Raises:
            ScrapingError: 最大再試行回数に達した場合
        """
        last_exception = None
        
        for attempt in range(self.max_retries + 1):
            try:
                result = await func(*args, **kwargs)
                
                if attempt > 0:
                    logger.info(f"✅ Retry succeeded on attempt {attempt + 1}")
                
                return result
                
            except Exception as e:
                last_exception = e
                
                # 再試行不可能なエラーの場合は即座に失敗
                if not self._is_retryable_error(e):
                    logger.error(f"❌ Non-retryable error: {e}")
                    raise
                
                # 最終試行の場合は失敗
                if attempt >= self.max_retries:
                    logger.error(f"❌ Max retries ({self.max_retries}) exceeded")
                    break
                
                # 待機時間計算
                delay = self._calculate_delay(attempt)
                logger.warning(
                    f"⚠️ Attempt {attempt + 1} failed: {e}. "
                    f"Retrying in {delay:.2f}s..."
                )
                
                await asyncio.sleep(delay)
        
        # 全試行失敗
        raise ScrapingError(
            f"Failed after {self.max_retries} retries. Last error: {last_exception}"
        )
    
    def _is_retryable_error(self, error: Exception) -> bool:
        """エラーが再試行可能かどうかを判定"""
        import aiohttp
        
        # ネットワークエラーは再試行可能
        if isinstance(error, (
            aiohttp.ClientConnectionError,
            aiohttp.ClientTimeout,
            asyncio.TimeoutError,
            ConnectionError
        )):
            return True
        
        # HTTPエラーの場合はステータスコードで判定
        if isinstance(error, aiohttp.ClientResponseError):
            # 5xx エラー（サーバーエラー）は再試行可能
            if 500 <= error.status < 600:
                return True
            # 429 (Too Many Requests) も再試行可能
            if error.status == 429:
                return True
            # 4xx エラー（クライアントエラー）は再試行不可
            return False
        
        # その他の例外は再試行不可
        return False
    
    def _calculate_delay(self, attempt: int) -> float:
        """指数バックオフによる待機時間計算"""
        delay = self.base_delay * (self.backoff_factor ** attempt)
        delay = min(delay, self.max_delay)
        
        # ジッター追加（同時リクエストの分散）
        if self.jitter:
            delay *= (0.5 + random.random() * 0.5)
        
        return delay


def retry_on_failure(
    max_retries: int = 3,
    base_delay: float = 1.0,
    backoff_factor: float = 2.0
):
    """再試行デコレーター"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            handler = RetryHandler(
                max_retries=max_retries,
                base_delay=base_delay,
                backoff_factor=backoff_factor
            )
            return await handler.execute_with_retry(func, *args, **kwargs)
        return wrapper
    return decorator
EOF

echo "✅ HTTP基盤実装完了"

# ==================== 2. パーサー基盤実装 ====================
echo "📝 パーサー基盤を実装中..."

# 基底パーサー
cat > scraper/infrastructure/parsers/base_parser.py << 'EOF'
"""
HTML解析基底クラス
共通のパース機能を提供
"""

from abc import ABC, abstractmethod
from bs4 import BeautifulSoup, Tag
from typing import Dict, List, Optional, Union
import re
import logging

logger = logging.getLogger(__name__)


class BaseHtmlParser(ABC):
    """HTML解析基底クラス"""
    
    def __init__(self, encoding: str = 'utf-8'):
        self.encoding = encoding
        self._soup: Optional[BeautifulSoup] = None
    
    def parse_html(self, html_content: str) -> BeautifulSoup:
        """HTMLをパース"""
        self._soup = BeautifulSoup(html_content, 'lxml')
        return self._soup
    
    def find_by_text_patterns(
        self, 
        patterns: List[str], 
        tag_types: List[str] = None
    ) -> List[Tag]:
        """テキストパターンでタグを検索"""
        if not self._soup:
            return []
        
        found_tags = []
        tag_types = tag_types or ['div', 'p', 'span', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']
        
        for pattern in patterns:
            regex = re.compile(pattern, re.IGNORECASE)
            for tag_type in tag_types:
                tags = self._soup.find_all(tag_type, string=regex)
                found_tags.extend(tags)
        
        return found_tags
    
    def extract_text_content(self, element: Union[Tag, BeautifulSoup]) -> str:
        """要素からテキストを抽出（クリーニング付き）"""
        if not element:
            return ""
        
        # テキスト抽出
        text = element.get_text(separator=' ', strip=True)
        
        # クリーニング
        text = re.sub(r'\s+', ' ', text)  # 連続空白を単一空白に
        text = re.sub(r'\n+', '\n', text)  # 連続改行を単一改行に
        text = text.strip()
        
        return text
    
    def find_contact_info(self) -> Dict[str, str]:
        """連絡先情報を抽出"""
        contact_info = {}
        
        if not self._soup:
            return contact_info
        
        # メールアドレス検索
        email_pattern = r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
        text_content = self._soup.get_text()
        emails = re.findall(email_pattern, text_content)
        if emails:
            contact_info['email'] = emails[0]
        
        # 電話番号検索
        phone_patterns = [
            r'\b0\d{1,4}-\d{1,4}-\d{4}\b',  # 日本の電話番号
            r'\b\d{3}-\d{3}-\d{4}\b',       # 短縮形
            r'\b\(\d{3}\)\s*\d{3}-\d{4}\b'  # (03) 1234-5678
        ]
        
        for pattern in phone_patterns:
            phones = re.findall(pattern, text_content)
            if phones:
                contact_info['phone'] = phones[0]
                break
        
        return contact_info
    
    def find_links_by_text(self, link_texts: List[str]) -> List[str]:
        """指定テキストを含むリンクを検索"""
        if not self._soup:
            return []
        
        found_links = []
        for link_text in link_texts:
            links = self._soup.find_all('a', string=re.compile(link_text, re.IGNORECASE))
            for link in links:
                href = link.get('href')
                if href:
                    found_links.append(href)
        
        return found_links
    
    def extract_keywords_from_meta(self) -> List[str]:
        """metaタグからキーワードを抽出"""
        if not self._soup:
            return []
        
        keywords = []
        
        # meta keywords
        meta_keywords = self._soup.find('meta', {'name': 'keywords'})
        if meta_keywords and meta_keywords.get('content'):
            keywords.extend([kw.strip() for kw in meta_keywords['content'].split(',')])
        
        # meta description
        meta_desc = self._soup.find('meta', {'name': 'description'})
        if meta_desc and meta_desc.get('content'):
            # 簡単なキーワード抽出（カンマ区切りがある場合）
            desc_content = meta_desc['content']
            if ',' in desc_content:
                keywords.extend([kw.strip() for kw in desc_content.split(',')[:5]])
        
        return list(set(keywords))  # 重複除去
    
    @abstractmethod
    def extract_research_labs(self) -> List[Dict[str, str]]:
        """研究室情報を抽出（サブクラスで実装）"""
        pass
    
    def clean_professor_name(self, name: str) -> str:
        """教授名のクリーニング"""
        if not name:
            return ""
        
        # 敬称を除去
        name = re.sub(r'(教授|准教授|講師|助教|博士|Dr\.|Prof\.)', '', name)
        name = re.sub(r'\s+', ' ', name).strip()
        
        return name
    
    def clean_department_name(self, dept: str) -> str:
        """学部・学科名のクリーニング"""
        if not dept:
            return ""
        
        # 不要な文字を除去
        dept = re.sub(r'(学部|学科|研究科|専攻|分野|教室)', '', dept)
        dept = re.sub(r'\s+', ' ', dept).strip()
        
        return dept
    
    def extract_research_keywords(self, content: str) -> List[str]:
        """研究内容からキーワードを抽出"""
        if not content:
            return []
        
        # 一般的な研究キーワードパターン
        keyword_patterns = [
            r'([A-Za-z]+細胞)',  # XX細胞
            r'([A-Za-z]+療法)',  # XX療法
            r'([A-Za-z]+免疫)',  # XX免疫
            r'([A-Za-z]+学)',    # XX学
        ]
        
        keywords = []
        for pattern in keyword_patterns:
            matches = re.findall(pattern, content)
            keywords.extend(matches)
        
        return list(set(keywords))
EOF

# 研究内容パーサー
cat > scraper/infrastructure/parsers/content_parser.py << 'EOF'
"""
研究内容解析パーサー
大学サイトから研究室情報を抽出
"""

import re
from typing import Dict, List, Optional, Tuple
from bs4 import BeautifulSoup, Tag

from scraper.infrastructure.parsers.base_parser import BaseHtmlParser
from scraper.domain.keyword_analyzer import keyword_analyzer


class UniversityContentParser(BaseHtmlParser):
    """大学研究室コンテンツ解析パーサー"""
    
    def __init__(self, university_name: str):
        super().__init__()
        self.university_name = university_name
        self._research_lab_indicators = [
            '研究室', '研究院', '研究所', '研究センター',
            'laboratory', 'lab', 'research', 'center'
        ]
        self._professor_indicators = [
            '教授', '准教授', '講師', '助教',
            'professor', 'prof', 'dr', 'doctor'
        ]
    
    def extract_research_labs(self) -> List[Dict[str, str]]:
        """研究室情報を抽出"""
        if not self._soup:
            return []
        
        labs = []
        
        # 方法1: 研究室一覧ページを探す
        lab_list_sections = self._find_lab_list_sections()
        for section in lab_list_sections:
            labs.extend(self._extract_labs_from_section(section))
        
        # 方法2: 個別研究室ページへのリンクを探す
        lab_links = self._find_lab_links()
        for link_data in lab_links:
            labs.append(link_data)
        
        # 重複除去とデータ品質確認
        cleaned_labs = self._clean_and_validate_labs(labs)
        
        return cleaned_labs
    
    def _find_lab_list_sections(self) -> List[Tag]:
        """研究室一覧セクションを検索"""
        sections = []
        
        # 研究室一覧を示すヘッダーを検索
        header_patterns = [
            r'研究室.*一覧', r'研究.*分野', r'教員.*紹介',
            r'research.*lab', r'faculty.*member'
        ]
        
        for pattern in header_patterns:
            headers = self._soup.find_all(
                ['h1', 'h2', 'h3', 'h4'], 
                string=re.compile(pattern, re.IGNORECASE)
            )
            
            for header in headers:
                # ヘッダーの後の要素を取得
                section = header.find_next(['div', 'section', 'ul', 'table'])
                if section:
                    sections.append(section)
        
        return sections
    
    def _extract_labs_from_section(self, section: Tag) -> List[Dict[str, str]]:
        """セクションから研究室情報を抽出"""
        labs = []
        
        # テーブル形式
        if section.name == 'table':
            labs.extend(self._extract_from_table(section))
        
        # リスト形式
        elif section.name == 'ul':
            labs.extend(self._extract_from_list(section))
        
        # div形式
        else:
            labs.extend(self._extract_from_div_section(section))
        
        return labs
    
    def _extract_from_table(self, table: Tag) -> List[Dict[str, str]]:
        """テーブルから研究室情報を抽出"""
        labs = []
        rows = table.find_all('tr')
        
        for row in rows[1:]:  # ヘッダー行をスキップ
            cells = row.find_all(['td', 'th'])
            if len(cells) >= 2:
                lab_data = self._extract_lab_data_from_cells(cells)
                if lab_data:
                    labs.append(lab_data)
        
        return labs
    
    def _extract_from_list(self, ul_element: Tag) -> List[Dict[str, str]]:
        """リストから研究室情報を抽出"""
        labs = []
        items = ul_element.find_all('li')
        
        for item in items:
            text = self.extract_text_content(item)
            lab_data = self._parse_lab_text(text)
            
            # リンクがある場合はURLを追加
            link = item.find('a')
            if link and link.get('href'):
                lab_data['lab_url'] = link['href']
            
            if lab_data and lab_data.get('name'):
                labs.append(lab_data)
        
        return labs
    
    def _extract_from_div_section(self, section: Tag) -> List[Dict[str, str]]:
        """divセクションから研究室情報を抽出"""
        labs = []
        
        # 研究室らしいdivを検索
        lab_divs = section.find_all('div', class_=re.compile(r'lab|research|member'))
        
        for div in lab_divs:
            text = self.extract_text_content(div)
            lab_data = self._parse_lab_text(text)
            
            if lab_data and lab_data.get('name'):
                labs.append(lab_data)
        
        return labs
    
    def _extract_lab_data_from_cells(self, cells: List[Tag]) -> Optional[Dict[str, str]]:
        """テーブルセルから研究室データを抽出"""
        if len(cells) < 2:
            return None
        
        # 最初のセルは通常研究室名または教授名
        first_cell_text = self.extract_text_content(cells[0])
        second_cell_text = self.extract_text_content(cells[1])
        
        lab_data = {}
        
        # 研究室名または教授名を判定
        if any(indicator in first_cell_text for indicator in self._research_lab_indicators):
            lab_data['name'] = first_cell_text
            lab_data['professor_name'] = second_cell_text
        elif any(indicator in second_cell_text for indicator in self._professor_indicators):
            lab_data['professor_name'] = first_cell_text
            lab_data['name'] = second_cell_text
        else:
            # 判定できない場合は名前として扱う
            lab_data['name'] = first_cell_text
            lab_data['professor_name'] = second_cell_text
        
        # 追加セルがある場合
        if len(cells) > 2:
            lab_data['research_content'] = self.extract_text_content(cells[2])
        
        return lab_data
    
    def _parse_lab_text(self, text: str) -> Dict[str, str]:
        """テキストから研究室情報を解析"""
        lab_data = {
            'name': '',
            'professor_name': '',
            'research_content': text,
            'department': ''
        }
        
        # 研究室名パターン
        lab_name_patterns = [
            r'([^。]+研究室)',
            r'([^。]+研究院)',
            r'([^。]+研究所)',
            r'([^。]+Laboratory)',
            r'([^。]+Lab)'
        ]
        
        for pattern in lab_name_patterns:
            match = re.search(pattern, text)
            if match:
                lab_data['name'] = match.group(1).strip()
                break
        
        # 教授名パターン
        professor_patterns = [
            r'([^\s]+)\s*(教授|准教授|講師|助教)',
            r'(Prof\.|Dr\.)\s*([^\s]+)',
            r'教授[：:]\s*([^\s]+)'
        ]
        
        for pattern in professor_patterns:
            match = re.search(pattern, text)
            if match:
                if '教授' in pattern:
                    lab_data['professor_name'] = match.group(1).strip()
                else:
                    lab_data['professor_name'] = match.group(2).strip()
                break
        
        # 研究室名が見つからない場合は教授名から生成
        if not lab_data['name'] and lab_data['professor_name']:
            lab_data['name'] = f"{lab_data['professor_name']}研究室"
        
        return lab_data
    
    def _find_lab_links(self) -> List[Dict[str, str]]:
        """研究室ページへのリンクを検索"""
        links_data = []
        
        # 研究室リンクパターン
        link_patterns = [
            r'研究室', r'research', r'lab', r'教員'
        ]
        
        for pattern in link_patterns:
            links = self._soup.find_all('a', string=re.compile(pattern, re.IGNORECASE))
            
            for link in links:
                href = link.get('href')
                link_text = self.extract_text_content(link)
                
                if href and self._is_valid_lab_link(href, link_text):
                    lab_data = {
                        'name': link_text,
                        'lab_url': href,
                        'professor_name': '',
                        'research_content': '',
                        'department': ''
                    }
                    links_data.append(lab_data)
        
        return links_data
    
    def _is_valid_lab_link(self, href: str, link_text: str) -> bool:
        """有効な研究室リンクかどうかを判定"""
        # 無効なリンクパターン
        invalid_patterns = [
            r'\.pdf$', r'\.doc$', r'\.ppt$',  # ファイルリンク
            r'mailto:', r'tel:',              # メール・電話リンク
            r'javascript:', r'#'              # スクリプト・アンカー
        ]
        
        for pattern in invalid_patterns:
            if re.search(pattern, href, re.IGNORECASE):
                return False
        
        # 有効なリンクテキストパターン
        valid_text_patterns = [
            r'研究室', r'研究所', r'研究センター',
            r'laboratory', r'research', r'lab'
        ]
        
        return any(re.search(pattern, link_text, re.IGNORECASE) for pattern in valid_text_patterns)
    
    def _clean_and_validate_labs(self, labs: List[Dict[str, str]]) -> List[Dict[str, str]]:
        """研究室データのクリーニングと検証"""
        cleaned_labs = []
        seen_names = set()
        
        for lab in labs:
            # 必須フィールドチェック
            if not lab.get('name') or not lab.get('name').strip():
                continue
            
            # 重複チェック
            lab_name = lab['name'].strip()
            if lab_name in seen_names:
                continue
            seen_names.add(lab_name)
            
            # データクリーニング
            cleaned_lab = {
                'name': lab_name,
                'professor_name': self.clean_professor_name(lab.get('professor_name', '')),
                'research_content': lab.get('research_content', '').strip(),
                'department': self.clean_department_name(lab.get('department', '')),
                'lab_url': lab.get('lab_url', ''),
                'keywords': lab.get('keywords', '')
            }
            
            # 免疫関連度スコア計算
            if cleaned_lab['research_content']:
                analysis_result = keyword_analyzer.analyze_content(cleaned_lab['research_content'])
                cleaned_lab['immune_relevance_score'] = analysis_result.immune_relevance_score
                cleaned_lab['research_field'] = analysis_result.field_classification
                
                # キーワード統合
                if analysis_result.matched_keywords:
                    existing_keywords = cleaned_lab.get('keywords', '')
                    new_keywords = ', '.join(analysis_result.matched_keywords)
                    cleaned_lab['keywords'] = f"{existing_keywords}, {new_keywords}".strip(', ')
            
            cleaned_labs.append(cleaned_lab)
        
        return cleaned_labs
EOF

echo "✅ パーサー基盤実装完了"

echo ""
echo "🎉 Infrastructure層実装完了！"
echo ""
echo "📋 実装されたコンポーネント:"
echo "├── scraper/infrastructure/"
echo "│   ├── http/"
echo "│   │   ├── rate_limiter.py      # 適応的レート制限器"
echo "│   │   ├── http_client.py       # 堅牢なHTTPクライアント"
echo "│   │   └── retry_handler.py     # 指数バックオフ再試行"
echo "│   └── parsers/"
echo "│       ├── base_parser.py       # HTML解析基底クラス"
echo "│       └── content_parser.py    # 研究内容解析パーサー"
echo ""
echo "🏗️ Infrastructure層の特徴:"
echo "• レート制限：大学サーバーへの負荷制御"
echo "• 再試行機構：ネットワークエラー耐性"
echo "• 型安全性：完全な型ヒント"
echo "• 拡張性：新しいパーサーの容易な追加"
echo "• 堅牢性：エラーハンドリングと監視"
echo ""
echo "⚡ 次のステップ："
echo "1. Application層の実装"
echo "2. 統合テストの実行"
echo "3. 実際の大学サイトでのテスト"