"""
研究室ドメインオブジェクト
ビジネスロジックとドメインルールを実装
"""

import re
from datetime import datetime
from typing import Dict, List, Optional, Set
from dataclasses import dataclass, field
from enum import Enum

from scraper.config.interfaces import (
    ResearchLabData, 
    ResearchField, 
    FacultyType,
    UniversityInfo
)


class ImmuneRelevanceLevel(Enum):
    """免疫関連度レベル"""
    NONE = "none"           # 関連なし (0.0-0.2)
    LOW = "low"             # 低関連 (0.2-0.4)  
    MEDIUM = "medium"       # 中関連 (0.4-0.6)
    HIGH = "high"           # 高関連 (0.6-0.8)
    VERY_HIGH = "very_high" # 極高関連 (0.8-1.0)
    
    @classmethod
    def from_score(cls, score: float) -> 'ImmuneRelevanceLevel':
        """スコアからレベルを判定"""
        if score < 0.2:
            return cls.NONE
        elif score < 0.4:
            return cls.LOW
        elif score < 0.6:
            return cls.MEDIUM
        elif score < 0.8:
            return cls.HIGH
        else:
            return cls.VERY_HIGH


class ResearchLabStatus(Enum):
    """研究室状態"""
    ACTIVE = "active"       # アクティブ
    INACTIVE = "inactive"   # 非アクティブ
    ARCHIVED = "archived"   # アーカイブ済み
    PENDING = "pending"     # 審査中


@dataclass(frozen=True)
class ContactInfo:
    """連絡先情報値オブジェクト"""
    email: Optional[str] = None
    phone: Optional[str] = None
    fax: Optional[str] = None
    office_location: Optional[str] = None
    postal_code: Optional[str] = None
    address: Optional[str] = None
    
    def __post_init__(self) -> None:
        """バリデーション"""
        if self.email and not self._is_valid_email(self.email):
            raise ValueError(f"無効なメールアドレス: {self.email}")
        
        if self.phone and not self._is_valid_phone(self.phone):
            raise ValueError(f"無効な電話番号: {self.phone}")
    
    @staticmethod
    def _is_valid_email(email: str) -> bool:
        """メールアドレス妥当性チェック"""
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return bool(re.match(pattern, email))
    
    @staticmethod  
    def _is_valid_phone(phone: str) -> bool:
        """電話番号妥当性チェック（日本の番号形式）"""
        # ハイフンや括弧を除去
        cleaned = re.sub(r'[^\d]', '', phone)
        # 10桁または11桁の数字
        return len(cleaned) in [10, 11] and cleaned.isdigit()
    
    @property
    def has_contact_info(self) -> bool:
        """連絡先情報の有無"""
        return any([self.email, self.phone, self.office_location])


@dataclass(frozen=True)
class ResearchKeywords:
    """研究キーワード値オブジェクト"""
    primary_keywords: Set[str] = field(default_factory=set)
    secondary_keywords: Set[str] = field(default_factory=set)
    immune_keywords: Set[str] = field(default_factory=set)
    agriculture_keywords: Set[str] = field(default_factory=set)  # 新規追加
    veterinary_keywords: Set[str] = field(default_factory=set)   # 新規追加
    
    def __post_init__(self) -> None:
        """キーワード正規化"""
        # 空文字や短すぎるキーワードを除去
        for attr_name in ['primary_keywords', 'secondary_keywords', 
                         'immune_keywords', 'agriculture_keywords', 
                         'veterinary_keywords']:
            keywords = getattr(self, attr_name)
            cleaned = {kw.strip().lower() for kw in keywords 
                      if kw and len(kw.strip()) >= 2}
            object.__setattr__(self, attr_name, cleaned)
    
    @property
    def all_keywords(self) -> Set[str]:
        """全キーワード取得"""
        return (self.primary_keywords | self.secondary_keywords | 
                self.immune_keywords | self.agriculture_keywords |
                self.veterinary_keywords)
    
    @property
    def keyword_count(self) -> int:
        """キーワード総数"""
        return len(self.all_keywords)
    
    def has_immune_keywords(self) -> bool:
        """免疫関連キーワード存在チェック"""
        return len(self.immune_keywords) > 0
    
    def has_agriculture_keywords(self) -> bool:
        """農学関連キーワード存在チェック（新規追加）"""
        return len(self.agriculture_keywords) > 0
    
    def has_veterinary_keywords(self) -> bool:
        """獣医学関連キーワード存在チェック（新規追加）"""
        return len(self.veterinary_keywords) > 0


class ResearchLab:
    """研究室ドメインエンティティ（リッチドメインモデル）"""
    
    def __init__(
        self,
        data: ResearchLabData,
        university_info: UniversityInfo,
        contact_info: Optional[ContactInfo] = None,
        keywords: Optional[ResearchKeywords] = None,
        status: ResearchLabStatus = ResearchLabStatus.ACTIVE
    ):
        self._data = data
        self._university_info = university_info
        self._contact_info = contact_info or ContactInfo()
        self._keywords = keywords or ResearchKeywords()
        self._status = status
        self._created_at = datetime.now()
        self._last_modified = datetime.now()
        
        # ドメインルール検証
        self._validate_domain_rules()
    
    def _validate_domain_rules(self) -> None:
        """ドメインルール検証"""
        # 基本情報必須チェック
        if not self._data.name.strip():
            raise ValueError("研究室名は必須です")
        
        if not self._data.professor_name.strip():
            raise ValueError("教授名は必須です")
        
        if not self._data.research_content.strip():
            raise ValueError("研究内容は必須です")
        
        # 研究内容の最小長チェック
        if len(self._data.research_content.strip()) < 10:
            raise ValueError("研究内容は10文字以上で入力してください")
        
        # 大学IDの整合性チェック
        if self._data.university_id != self._university_info.id:
            raise ValueError("大学IDが不整合です")
        
        # 農学・獣医学分野の整合性チェック（新規追加）
        if self._data.faculty in [FacultyType.AGRICULTURE, FacultyType.VETERINARY]:
            if not (self._data.animal_research or self._data.veterinary_focus):
                raise ValueError("農学・獣医学部の研究室は動物研究または獣医学フォーカスフラグが必要です")
    
    # プロパティ（読み取り専用）
    @property
    def id(self) -> Optional[int]:
        """研究室ID（永続化後に設定）"""
        return getattr(self._data, 'id', None)
    
    @property
    def name(self) -> str:
        """研究室名"""
        return self._data.name
    
    @property
    def professor_name(self) -> str:
        """教授名"""
        return self._data.professor_name
    
    @property
    def department(self) -> str:
        """所属学部・学科"""
        return self._data.department
    
    @property
    def faculty(self) -> FacultyType:
        """学部種別"""
        return self._data.faculty
    
    @property
    def research_content(self) -> str:
        """研究内容"""
        return self._data.research_content
    
    @property
    def research_theme(self) -> str:
        """研究テーマ"""
        return self._data.research_theme
    
    @property
    def research_field(self) -> ResearchField:
        """研究分野"""
        return self._data.research_field
    
    @property
    def university_info(self) -> UniversityInfo:
        """大学情報"""
        return self._university_info
    
    @property
    def contact_info(self) -> ContactInfo:
        """連絡先情報"""
        return self._contact_info
    
    @property
    def keywords(self) -> ResearchKeywords:
        """研究キーワード"""
        return self._keywords
    
    @property
    def status(self) -> ResearchLabStatus:
        """研究室状態"""
        return self._status
    
    @property
    def created_at(self) -> datetime:
        """作成日時"""
        return self._created_at
    
    @property
    def last_modified(self) -> datetime:
        """最終更新日時"""
        return self._last_modified
    
    @property
    def immune_relevance_score(self) -> Optional[float]:
        """免疫関連度スコア"""
        return self._data.immune_relevance_score
    
    @property
    def immune_relevance_level(self) -> Optional[ImmuneRelevanceLevel]:
        """免疫関連度レベル"""
        if self.immune_relevance_score is None:
            return None
        return ImmuneRelevanceLevel.from_score(self.immune_relevance_score)
    
    # 新規追加：農学・獣医学関連プロパティ
    @property
    def is_animal_research(self) -> bool:
        """動物研究フラグ"""
        return self._data.animal_research
    
    @property
    def is_veterinary_focus(self) -> bool:
        """獣医学フォーカスフラグ"""
        return self._data.veterinary_focus
    
    @property
    def is_agriculture_related(self) -> bool:
        """農学関連判定"""
        return (self.faculty in [FacultyType.AGRICULTURE, FacultyType.VETERINARY] or
                self.keywords.has_agriculture_keywords())
    
    @property
    def is_veterinary_related(self) -> bool:
        """獣医学関連判定"""
        return (self.faculty == FacultyType.VETERINARY or
                self.keywords.has_veterinary_keywords() or
                self.is_veterinary_focus)
    
    # ビジネスロジックメソッド
    def update_immune_score(self, score: float) -> None:
        """免疫関連度スコア更新"""
        if not 0.0 <= score <= 1.0:
            raise ValueError("免疫関連度スコアは0.0-1.0の範囲で指定してください")
        
        # データクラスは immutable なので新しいインスタンスを作成
        updated_data = ResearchLabData(
            name=self._data.name,
            professor_name=self._data.professor_name,
            department=self._data.department,
            faculty=self._data.faculty,
            research_content=self._data.research_content,
            research_theme=self._data.research_theme,
            research_field=self._data.research_field,
            university_id=self._data.university_id,
            speciality=self._data.speciality,
            keywords=self._data.keywords,
            lab_url=self._data.lab_url,
            contact_email=self._data.contact_email,
            phone_number=self._data.phone_number,
            immune_relevance_score=score,  # 更新
            last_updated=datetime.now(),
            animal_research=self._data.animal_research,
            veterinary_focus=self._data.veterinary_focus
        )
        
        object.__setattr__(self, '_data', updated_data)
        object.__setattr__(self, '_last_modified', datetime.now())
    
    def update_contact_info(self, contact_info: ContactInfo) -> None:
        """連絡先情報更新"""
        object.__setattr__(self, '_contact_info', contact_info)
        object.__setattr__(self, '_last_modified', datetime.now())
    
    def update_keywords(self, keywords: ResearchKeywords) -> None:
        """キーワード情報更新"""
        object.__setattr__(self, '_keywords', keywords)
        object.__setattr__(self, '_last_modified', datetime.now())
    
    def change_status(self, new_status: ResearchLabStatus) -> None:
        """状態変更"""
        if self._status == new_status:
            return  # 変更なし
        
        # 状態遷移ルールチェック
        self._validate_status_transition(new_status)
        
        object.__setattr__(self, '_status', new_status)
        object.__setattr__(self, '_last_modified', datetime.now())
    
    def _validate_status_transition(self, new_status: ResearchLabStatus) -> None:
        """状態遷移妥当性チェック"""
        valid_transitions = {
            ResearchLabStatus.PENDING: [ResearchLabStatus.ACTIVE, ResearchLabStatus.INACTIVE],
            ResearchLabStatus.ACTIVE: [ResearchLabStatus.INACTIVE, ResearchLabStatus.ARCHIVED],
            ResearchLabStatus.INACTIVE: [ResearchLabStatus.ACTIVE, ResearchLabStatus.ARCHIVED],
            ResearchLabStatus.ARCHIVED: []  # アーカイブ後は変更不可
        }
        
        if new_status not in valid_transitions.get(self._status, []):
            raise ValueError(
                f"無効な状態遷移: {self._status.value} -> {new_status.value}"
            )
    
    def is_highly_immune_relevant(self) -> bool:
        """高免疫関連度判定"""
        if self.immune_relevance_score is None:
            return False
        return self.immune_relevance_score >= 0.6
    
    def is_active(self) -> bool:
        """アクティブ状態判定"""
        return self._status == ResearchLabStatus.ACTIVE
    
    def has_complete_contact_info(self) -> bool:
        """完全な連絡先情報存在判定"""
        return (self.contact_info.has_contact_info and 
                self.contact_info.email is not None)
    
    def calculate_completeness_score(self) -> float:
        """情報完全性スコア計算（0.0-1.0）"""
        score = 0.0
        total_weight = 0.0
        
        # 基本情報（必須：重み高）
        if self.name: score += 0.2; total_weight += 0.2
        if self.professor_name: score += 0.2; total_weight += 0.2
        if self.research_content: score += 0.2; total_weight += 0.2
        
        # 詳細情報（重み中）
        if self._data.speciality: score += 0.1; total_weight += 0.1
        if self._data.lab_url: score += 0.1; total_weight += 0.1
        if self.keywords.keyword_count > 0: score += 0.1; total_weight += 0.1
        
        # 連絡先情報（重み低）
        if self.contact_info.has_contact_info: score += 0.05; total_weight += 0.05
        
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
    university_info: UniversityInfo,
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