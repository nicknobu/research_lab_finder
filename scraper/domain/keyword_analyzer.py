"""
免疫関連度解析器
研究内容の免疫関連度を計算し、キーワードを抽出
"""

import re
import yaml
from pathlib import Path
from typing import List, Dict, Set, Tuple, Optional
from dataclasses import dataclass

from scraper.config.settings import scraping_settings


@dataclass
class KeywordAnalysisResult:
    """キーワード解析結果"""
    immune_relevance_score: float
    matched_keywords: List[str]
    animal_species: List[str]
    plant_species: List[str]
    research_techniques: List[str]
    field_classification: str


class ImmuneKeywordAnalyzer:
    """免疫関連キーワード解析器"""
    
    def __init__(self):
        self._medical_keywords: Dict[str, List[str]] = {}
        self._agriculture_keywords: Dict[str, List[str]] = {}
        self._animal_species_keywords: List[str] = []
        self._plant_species_keywords: List[str] = []
        self._technique_keywords: List[str] = []
        
        self._load_keywords()
    
    def _load_keywords(self) -> None:
        """キーワードファイルを読み込み"""
        keywords_dir = scraping_settings.keywords_dir
        
        # 医学系キーワード
        medical_file = keywords_dir / "medical_keywords.yaml"
        if medical_file.exists():
            with open(medical_file, 'r', encoding='utf-8') as f:
                self._medical_keywords = yaml.safe_load(f)
        
        # 農学系キーワード
        agriculture_file = keywords_dir / "agriculture_keywords.yaml"
        if agriculture_file.exists():
            with open(agriculture_file, 'r', encoding='utf-8') as f:
                self._agriculture_keywords = yaml.safe_load(f)
        
        # 動物種キーワード
        if 'animal_species' in self._agriculture_keywords:
            self._animal_species_keywords = self._agriculture_keywords['animal_species']
        
        # 植物種キーワード（プレースホルダー）
        self._plant_species_keywords = [
            '稲', 'rice', 'トマト', 'tomato', '大豆', 'soybean',
            '小麦', 'wheat', 'トウモロコシ', 'corn', 'maize'
        ]
        
        # 研究技術キーワード
        self._technique_keywords = [
            'PCR', 'qPCR', 'Western blot', 'ELISA', 'FACS',
            'RNA-seq', 'ChIP-seq', 'CRISPR', 'クローニング',
            '細胞培養', 'cell culture', 'in vitro', 'in vivo'
        ]
    
    def analyze_content(self, content: str) -> KeywordAnalysisResult:
        """
        研究内容を解析して免疫関連度とキーワードを抽出
        
        Args:
            content: 研究内容テキスト
        
        Returns:
            KeywordAnalysisResult: 解析結果
        """
        content_lower = content.lower()
        
        # 免疫関連キーワードのマッチング
        immune_score, matched_keywords = self._calculate_immune_score(content_lower)
        
        # 動物種の抽出
        animal_species = self._extract_animal_species(content_lower)
        
        # 植物種の抽出
        plant_species = self._extract_plant_species(content_lower)
        
        # 研究技術の抽出
        techniques = self._extract_research_techniques(content_lower)
        
        # 研究分野の分類
        field_classification = self._classify_research_field(
            content_lower, matched_keywords, animal_species, plant_species
        )
        
        return KeywordAnalysisResult(
            immune_relevance_score=immune_score,
            matched_keywords=matched_keywords,
            animal_species=animal_species,
            plant_species=plant_species,
            research_techniques=techniques,
            field_classification=field_classification
        )
    
    def _calculate_immune_score(self, content: str) -> Tuple[float, List[str]]:
        """免疫関連度スコアを計算"""
        matched_keywords = []
        total_score = 0.0
        
        # 医学系免疫キーワードのマッチング（重み高）
        for category, keywords in self._medical_keywords.items():
            category_matches = []
            for keyword in keywords:
                if keyword.lower() in content:
                    category_matches.append(keyword)
                    matched_keywords.append(keyword)
            
            # カテゴリ別の重み付け
            if category == 'basic_immunology':
                total_score += len(category_matches) * 0.3
            elif category == 'advanced_research':
                total_score += len(category_matches) * 0.25
            elif category == 'diseases_and_therapy':
                total_score += len(category_matches) * 0.2
            else:
                total_score += len(category_matches) * 0.15
        
        # 農学系免疫キーワードのマッチング（重み中）
        for category, keywords in self._agriculture_keywords.items():
            if category == 'animal_immunity':
                for keyword in keywords:
                    if keyword.lower() in content:
                        matched_keywords.append(keyword)
                        total_score += 0.2
        
        # スコアを0-1の範囲に正規化
        normalized_score = min(total_score / 3.0, 1.0)
        
        return normalized_score, list(set(matched_keywords))
    
    def _extract_animal_species(self, content: str) -> List[str]:
        """動物種を抽出"""
        found_species = []
        
        for species in self._animal_species_keywords:
            if species.lower() in content:
                found_species.append(species)
        
        return list(set(found_species))
    
    def _extract_plant_species(self, content: str) -> List[str]:
        """植物種を抽出"""
        found_species = []
        
        for species in self._plant_species_keywords:
            if species.lower() in content:
                found_species.append(species)
        
        return list(set(found_species))
    
    def _extract_research_techniques(self, content: str) -> List[str]:
        """研究技術を抽出"""
        found_techniques = []
        
        for technique in self._technique_keywords:
            if technique.lower() in content:
                found_techniques.append(technique)
        
        return list(set(found_techniques))
    
    def _classify_research_field(
        self, 
        content: str, 
        immune_keywords: List[str],
        animal_species: List[str],
        plant_species: List[str]
    ) -> str:
        """研究分野を分類"""
        
        # がん免疫学
        if any(kw in content for kw in ['cancer', 'がん', 'tumor', '腫瘍']):
            return 'がん免疫学'
        
        # アレルギー免疫学
        if any(kw in content for kw in ['allergy', 'アレルギー', 'atopic', 'ige']):
            return 'アレルギー免疫学'
        
        # 感染免疫学
        if any(kw in content for kw in ['infection', '感染', 'pathogen', 'virus', 'bacteria']):
            return '感染免疫学'
        
        # 自己免疫学
        if any(kw in content for kw in ['autoimmune', '自己免疫', 'lupus', 'rheumatoid']):
            return '自己免疫学'
        
        # 動物免疫学
        if animal_species and any(kw in content for kw in ['veterinary', '獣医', 'livestock']):
            return '動物免疫学'
        
        # 植物免疫学
        if plant_species and any(kw in content for kw in ['plant', '植物', 'crop']):
            return '植物免疫学'
        
        # 食品免疫学
        if any(kw in content for kw in ['food', '食品', 'nutrition', '栄養', 'probiotics']):
            return '食品免疫学'
        
        # デフォルトは基礎免疫学
        return '免疫学'
    
    def get_keyword_suggestions(self, partial_text: str, max_suggestions: int = 10) -> List[str]:
        """部分テキストからキーワード候補を提案"""
        suggestions = []
        partial_lower = partial_text.lower()
        
        # 全キーワードから部分マッチを検索
        all_keywords = []
        for keywords_dict in [self._medical_keywords, self._agriculture_keywords]:
            for keyword_list in keywords_dict.values():
                all_keywords.extend(keyword_list)
        
        for keyword in all_keywords:
            if partial_lower in keyword.lower() or keyword.lower().startswith(partial_lower):
                suggestions.append(keyword)
                if len(suggestions) >= max_suggestions:
                    break
        
        return suggestions


# グローバルインスタンス
keyword_analyzer = ImmuneKeywordAnalyzer()
