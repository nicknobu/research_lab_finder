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
