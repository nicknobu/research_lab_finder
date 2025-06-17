"""
研究室ドメインオブジェクト
ビジネスロジックと不変条件を管理
"""

from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from enum import Enum

from scraper.config.interfaces import (
    ResearchLabData, ResearchField, FacultyType,
    DataValidationError
)


class ResearchLabStatus(str, Enum):
    """研究室ステータス"""
    ACTIVE = "active"           # アクティブ
    INACTIVE = "inactive"       # 非アクティブ
    PENDING = "pending"         # 検証待ち
    REJECTED = "rejected"       # 却下


@dataclass
class ContactInfo:
    """連絡先情報"""
    email: Optional[str] = None
    phone: Optional[str] = None
    website: Optional[str] = None
    
    def has_contact_info(self) -> bool:
        """連絡先情報があるかチェック"""
        return any([self.email, self.phone, self.website])


@dataclass  
class ResearchKeywords:
    """研究キーワード管理"""
    raw_keywords: str = ""
    extracted_keywords: List[str] = field(default_factory=list)
    immune_keywords: List[str] = field(default_factory=list)
    animal_species: List[str] = field(default_factory=list)
    
    @property
    def keyword_count(self) -> int:
        """キーワード総数"""
        return len(self.extracted_keywords)
    
    @property
    def immune_keyword_count(self) -> int:
        """免疫関連キーワード数"""
        return len(self.immune_keywords)
    
    def add_keyword(self, keyword: str) -> None:
        """キーワード追加"""
        if keyword and keyword not in self.extracted_keywords:
            self.extracted_keywords.append(keyword)


class ResearchLab:
    """
    研究室エンティティ
    ビジネスルールと不変条件を保証
    """
    
    def __init__(
        self, 
        data: ResearchLabData,
        university_info: 'UniversityInfo',
        contact_info: Optional[ContactInfo] = None,
        keywords: Optional[ResearchKeywords] = None
    ):
        self._data = data
        self._university_info = university_info
        self._contact_info = contact_info or ContactInfo()
        self._keywords = keywords or ResearchKeywords()
        self._status = ResearchLabStatus.PENDING
        self._immune_relevance_score: Optional[float] = None
        
        # 作成時のバリデーション
        self._validate_required_fields()
    
    # プロパティアクセス
    @property
    def name(self) -> str:
        return self._data.name
    
    @property
    def professor_name(self) -> str:
        return self._data.professor_name
    
    @property
    def research_content(self) -> str:
        return self._data.research_content
    
    @property
    def research_field(self) -> str:
        return self._data.research_field
    
    @property
    def university_info(self) -> 'UniversityInfo':
        return self._university_info
    
    @property
    def contact_info(self) -> ContactInfo:
        return self._contact_info
    
    @property
    def keywords(self) -> ResearchKeywords:
        return self._keywords
    
    @property
    def status(self) -> ResearchLabStatus:
        return self._status
    
    @property
    def immune_relevance_score(self) -> Optional[float]:
        return self._immune_relevance_score
    
    # ビジネスメソッド
    def _validate_required_fields(self) -> None:
        """必須フィールドの検証"""
        required_fields = ['name', 'professor_name', 'research_content']
        
        for field_name in required_fields:
            value = getattr(self._data, field_name)
            if not value or (isinstance(value, str) and len(value.strip()) == 0):
                raise DataValidationError(f"Required field '{field_name}' is missing or empty")
    
    def update_immune_relevance_score(self, score: float) -> None:
        """免疫関連度スコアを更新"""
        if not 0.0 <= score <= 1.0:
            raise ValueError("Immune relevance score must be between 0.0 and 1.0")
        
        self._immune_relevance_score = score
        
        # スコアに基づいてステータス更新
        if score >= 0.7:
            self._status = ResearchLabStatus.ACTIVE
        elif score >= 0.3:
            self._status = ResearchLabStatus.PENDING
        else:
            self._status = ResearchLabStatus.REJECTED
    
    def add_animal_species(self, species: List[str]) -> None:
        """動物種情報を追加（農学・獣医学用）"""
        if self._data.faculty in ['agriculture', 'veterinary']:
            for species_name in species:
                if species_name not in self._keywords.animal_species:
                    self._keywords.animal_species.append(species_name)
    
    def is_agriculture_related(self) -> bool:
        """農学関連研究室かどうか"""
        agriculture_indicators = [
            'agriculture', '農学', 'veterinary', '獣医',
            'animal', '動物', 'livestock', '家畜',
            'food', '食品', 'nutrition', '栄養'
        ]
        
        content_lower = self.research_content.lower()
        return any(indicator in content_lower for indicator in agriculture_indicators)
    
    def is_medical_related(self) -> bool:
        """医学関連研究室かどうか"""
        medical_indicators = [
            'medical', '医学', 'medicine', 'clinical', '臨床',
            'patient', '患者', 'disease', '疾患', 'therapy', '治療'
        ]
        
        content_lower = self.research_content.lower()
        return any(indicator in content_lower for indicator in medical_indicators)
    
    def calculate_data_quality_score(self) -> float:
        """データ品質スコア計算"""
        score = 0.0
        total_weight = 0.0
        
        # 基本情報の完全性（重み高）
        if self.name and len(self.name) > 3: score += 0.2; total_weight += 0.2
        if self.professor_name: score += 0.2; total_weight += 0.2
        if self.research_content and len(self.research_content) > 50: score += 0.2; total_weight += 0.2
        
        # 詳細情報（重み中）
        if self._data.speciality: score += 0.1; total_weight += 0.1
        if self._data.lab_url: score += 0.1; total_weight += 0.1
        if self.keywords.keyword_count > 0: score += 0.1; total_weight += 0.1
        
        # 連絡先情報（重み低）
        if self.contact_info.has_contact_info(): score += 0.05; total_weight += 0.05
        
        # 免疫関連度（重み低）
        if self.immune_relevance_score is not None: score += 0.05; total_weight += 0.05
        
        return score / total_weight if total_weight > 0 else 0.0
    
    def to_research_lab_data(self) -> ResearchLabData:
        """ResearchLabDataに変換"""
        return self._data
    
    def __str__(self) -> str:
        return f"ResearchLab({self.name} - {self.professor_name}@{self.university_info.name})"
    
    def __repr__(self) -> str:
        return (f"ResearchLab(name='{self.name}', professor='{self.professor_name}', "
                f"university='{self.university_info.name}', status='{self.status.value}')")
    
    def __eq__(self, other) -> bool:
        if not isinstance(other, ResearchLab):
            return False
        return (self.name == other.name and 
                self.professor_name == other.professor_name and
                self.university_info.id == other.university_info.id)
    
    def __hash__(self) -> int:
        return hash((self.name, self.professor_name, self.university_info.id))


# ファクトリーメソッド
def create_research_lab_from_data(
    data: ResearchLabData,
    university_info: 'UniversityInfo',
    contact_info: Optional[ContactInfo] = None,
    keywords: Optional[ResearchKeywords] = None
) -> ResearchLab:
    """
    ResearchLabDataから研究室エンティティを作成
    
    Args:
        data: 研究室データ
        university_info: 大学情報
        contact_info: 連絡先情報（オプション）
        keywords: キーワード情報（オプション）
    
    Returns:
        ResearchLab: 研究室エンティティ
    """
    return ResearchLab(
        data=data,
        university_info=university_info,
        contact_info=contact_info,
        keywords=keywords
    )
