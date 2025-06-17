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
