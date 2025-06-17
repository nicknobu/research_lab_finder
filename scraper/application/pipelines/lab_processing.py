"""
研究室データ処理パイプライン
データの統合・強化・品質管理
"""

import asyncio
from typing import List, Dict, Optional, Tuple
import logging
from datetime import datetime

from scraper.config.interfaces import ResearchLabData, DataValidationError
from scraper.domain.research_lab import ResearchLab, create_research_lab_from_data
from scraper.domain.university import University
from scraper.domain.keyword_analyzer import keyword_analyzer
from scraper.config.settings import quality_settings

logger = logging.getLogger(__name__)


class LabDataProcessor:
    """研究室データ処理パイプライン"""
    
    def __init__(self):
        self.processed_count = 0
        self.rejected_count = 0
        self.duplicate_count = 0
        self.enhanced_count = 0
    
    async def process_lab_data_batch(
        self, 
        raw_labs: List[ResearchLabData],
        university: University
    ) -> List[ResearchLab]:
        """研究室データのバッチ処理"""
        logger.info(f"🔄 {university.name}: {len(raw_labs)}件の研究室データ処理開始")
        
        # Step 1: 基本バリデーション
        validated_labs = await self._validate_basic_requirements(raw_labs)
        logger.info(f"📋 基本バリデーション: {len(validated_labs)}/{len(raw_labs)}件合格")
        
        # Step 2: 重複除去
        deduplicated_labs = await self._remove_duplicates(validated_labs)
        self.duplicate_count += len(validated_labs) - len(deduplicated_labs)
        logger.info(f"🔍 重複除去: {len(deduplicated_labs)}件（{self.duplicate_count}件除去）")
        
        # Step 3: データ強化
        enhanced_labs = await self._enhance_lab_data(deduplicated_labs, university)
        logger.info(f"⚡ データ強化: {len(enhanced_labs)}件")
        
        # Step 4: 品質フィルタリング
        quality_filtered_labs = await self._filter_by_quality(enhanced_labs)
        self.rejected_count += len(enhanced_labs) - len(quality_filtered_labs)
        logger.info(f"🎯 品質フィルタリング: {len(quality_filtered_labs)}件（{len(enhanced_labs) - len(quality_filtered_labs)}件除外）")
        
        # Step 5: ResearchLabエンティティ作成
        research_labs = await self._create_research_lab_entities(quality_filtered_labs, university)
        self.processed_count += len(research_labs)
        
        logger.info(f"✅ {university.name}: {len(research_labs)}件の研究室データ処理完了")
        return research_labs
    
    async def _validate_basic_requirements(self, labs: List[ResearchLabData]) -> List[ResearchLabData]:
        """基本要件バリデーション"""
        validated_labs = []
        
        for lab in labs:
            try:
                # 必須フィールドチェック
                if not lab.name or len(lab.name.strip()) < 3:
                    continue
                
                if not lab.professor_name or len(lab.professor_name.strip()) < 2:
                    continue
                
                if not lab.research_content or len(lab.research_content) < quality_settings.min_content_length:
                    continue
                
                # 研究内容の質チェック
                if not self._is_meaningful_content(lab.research_content):
                    continue
                
                validated_labs.append(lab)
                
            except Exception as e:
                logger.warning(f"基本バリデーション失敗: {e}")
                continue
        
        return validated_labs
    
    def _is_meaningful_content(self, content: str) -> bool:
        """研究内容が意味のあるコンテンツかチェック"""
        if not content:
            return False
        
        # 最小文字数チェック
        if len(content) < 50:
            return False
        
        # 意味のある単語の数をチェック
        meaningful_words = [
            '研究', 'research', '開発', 'development', '解析', 'analysis',
            '実験', 'experiment', '検討', '調査', 'investigation',
            '技術', 'technology', '手法', 'method', '理論', 'theory'
        ]
        
        word_count = sum(1 for word in meaningful_words if word.lower() in content.lower())
        return word_count >= 2
    
    async def _remove_duplicates(self, labs: List[ResearchLabData]) -> List[ResearchLabData]:
        """重複研究室の除去"""
        seen_signatures = set()
        unique_labs = []
        
        for lab in labs:
            # 重複判定のシグネチャ作成
            signature = self._create_lab_signature(lab)
            
            if signature not in seen_signatures:
                seen_signatures.add(signature)
                unique_labs.append(lab)
        
        return unique_labs
    
    def _create_lab_signature(self, lab: ResearchLabData) -> str:
        """研究室の重複判定用シグネチャ作成"""
        # 研究室名と教授名を正規化して結合
        normalized_name = self._normalize_text(lab.name)
        normalized_professor = self._normalize_text(lab.professor_name)
        
        return f"{normalized_name}#{normalized_professor}#{lab.university_id}"
    
    def _normalize_text(self, text: str) -> str:
        """テキストの正規化"""
        if not text:
            return ""
        
        # 小文字化、空白除去、記号除去
        import re
        normalized = re.sub(r'[^\w\s]', '', text.lower())
        normalized = re.sub(r'\s+', '', normalized)
        
        return normalized
    
    async def _enhance_lab_data(self, labs: List[ResearchLabData], university: University) -> List[ResearchLabData]:
        """データ強化処理"""
        enhanced_labs = []
        
        for lab in labs:
            try:
                enhanced_lab = await self._enhance_single_lab(lab, university)
                enhanced_labs.append(enhanced_lab)
                self.enhanced_count += 1
                
            except Exception as e:
                logger.warning(f"データ強化失敗 {lab.name}: {e}")
                # 強化に失敗してもオリジナルデータは保持
                enhanced_labs.append(lab)
        
        return enhanced_labs
    
    async def _enhance_single_lab(self, lab: ResearchLabData, university: University) -> ResearchLabData:
        """単一研究室のデータ強化"""
        enhanced_lab = lab
        
        # 免疫関連度分析
        if lab.research_content:
            analysis_result = keyword_analyzer.analyze_content(lab.research_content)
            
            enhanced_lab.immune_relevance_score = analysis_result.immune_relevance_score
            enhanced_lab.research_field = analysis_result.field_classification
            
            # キーワード統合
            if analysis_result.matched_keywords:
                existing_keywords = lab.keywords or ''
                new_keywords = ', '.join(analysis_result.matched_keywords)
                enhanced_lab.keywords = f"{existing_keywords}, {new_keywords}".strip(', ')
            
            # 動物種・植物種情報
            if analysis_result.animal_species:
                enhanced_lab.animal_species = ', '.join(analysis_result.animal_species)
            
            if analysis_result.plant_species:
                enhanced_lab.plant_species = ', '.join(analysis_result.plant_species)
        
        # 大学情報の統合
        enhanced_lab.university_id = university.info.id
        
        # メタデータの追加
        if not enhanced_lab.metadata:
            enhanced_lab.metadata = {}
        
        enhanced_lab.metadata.update({
            'processed_at': datetime.now().isoformat(),
            'university_tier': 1 if university.is_tier1_university() else 2 if university.is_tier2_university() else 3,
            'university_type': university.type.value,
            'university_region': university.region
        })
        
        return enhanced_lab
    
    async def _filter_by_quality(self, labs: List[ResearchLabData]) -> List[ResearchLabData]:
        """品質基準によるフィルタリング"""
        quality_labs = []
        
        for lab in labs:
            try:
                quality_score = self._calculate_quality_score(lab)
                
                # 品質スコアが基準を満たす場合のみ通す
                if quality_score >= 0.6:  # 60%以上の品質スコア
                    if not lab.metadata:
                        lab.metadata = {}
                    lab.metadata['quality_score'] = quality_score
                    quality_labs.append(lab)
                
            except Exception as e:
                logger.warning(f"品質評価失敗 {lab.name}: {e}")
                continue
        
        return quality_labs
    
    def _calculate_quality_score(self, lab: ResearchLabData) -> float:
        """データ品質スコア計算"""
        score = 0.0
        total_weight = 0.0
        
        # 基本情報の完全性（50%）
        if lab.name and len(lab.name) > 5:
            score += 0.2; total_weight += 0.2
        if lab.professor_name and len(lab.professor_name) > 2:
            score += 0.15; total_weight += 0.15
        if lab.research_content and len(lab.research_content) > 100:
            score += 0.15; total_weight += 0.15
        
        # 詳細情報の充実度（30%）
        if lab.keywords and len(lab.keywords.split(',')) >= 3:
            score += 0.15; total_weight += 0.15
        if lab.lab_url:
            score += 0.15; total_weight += 0.15
        
        # 免疫関連度（20%）
        if lab.immune_relevance_score and lab.immune_relevance_score >= quality_settings.min_immune_relevance_score:
            score += 0.2; total_weight += 0.2
        
        return score / total_weight if total_weight > 0 else 0.0
    
    async def _create_research_lab_entities(self, labs: List[ResearchLabData], university: University) -> List[ResearchLab]:
        """ResearchLabエンティティの作成"""
        research_labs = []
        
        for lab_data in labs:
            try:
                research_lab = create_research_lab_from_data(
                    data=lab_data,
                    university_info=university.info
                )
                research_labs.append(research_lab)
                
            except Exception as e:
                logger.error(f"ResearchLabエンティティ作成失敗 {lab_data.name}: {e}")
                continue
        
        return research_labs
    
    def get_processing_stats(self) -> Dict[str, int]:
        """処理統計を取得"""
        return {
            'processed_count': self.processed_count,
            'rejected_count': self.rejected_count,
            'duplicate_count': self.duplicate_count,
            'enhanced_count': self.enhanced_count
        }
