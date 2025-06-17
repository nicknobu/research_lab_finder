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
