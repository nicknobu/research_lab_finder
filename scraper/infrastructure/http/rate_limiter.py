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
