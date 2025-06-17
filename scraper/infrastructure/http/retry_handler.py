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
