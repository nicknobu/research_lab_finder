"""
データローダー - 初期データの読み込み
"""
import logging
from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models import University, ResearchLab

logger = logging.getLogger(__name__)

async def load_initial_data():
    """初期データの読み込み"""
    try:
        db = SessionLocal()
        
        # 既にデータがある場合はスキップ
        existing_labs = db.query(ResearchLab).count()
        if existing_labs > 0:
            logger.info(f"既に {existing_labs} 件の研究室データが存在します")
            db.close()
            return
        
        # サンプルデータの挿入
        sample_universities = [
            {"name": "東京大学", "type": "national", "prefecture": "東京都", "region": "関東"},
            {"name": "京都大学", "type": "national", "prefecture": "京都府", "region": "関西"},
            {"name": "大阪大学", "type": "national", "prefecture": "大阪府", "region": "関西"},
            {"name": "名古屋大学", "type": "national", "prefecture": "愛知県", "region": "中部"},
            {"name": "九州大学", "type": "national", "prefecture": "福岡県", "region": "九州"},
        ]
        
        for uni_data in sample_universities:
            existing_uni = db.query(University).filter(University.name == uni_data["name"]).first()
            if not existing_uni:
                university = University(**uni_data)
                db.add(university)
        
        db.commit()
        
        # 研究室データの挿入
        sample_labs = [
            {
                "university_id": 1,
                "name": "免疫制御学教室",
                "professor_name": "田中太郎",
                "research_theme": "T細胞免疫応答の制御機構",
                "research_content": "がん免疫療法の開発を目指した基礎研究を行っています。T細胞の活性化機構を解明し、新しい治療法の開発に取り組んでいます。"
            },
            {
                "university_id": 2,
                "name": "分子腫瘍学研究室",
                "professor_name": "佐藤花子",
                "research_theme": "がん細胞の増殖機構",
                "research_content": "がん細胞の分子メカニズムを解明し、新しい診断法と治療法の開発を目指しています。"
            },
            {
                "university_id": 3,
                "name": "再生医学研究所",
                "professor_name": "山田次郎",
                "research_theme": "幹細胞を用いた再生療法",
                "research_content": "幹細胞技術を活用した組織再生療法の研究を行っています。"
            }
        ]
        
        for lab_data in sample_labs:
            lab = ResearchLab(**lab_data)
            db.add(lab)
        
        db.commit()
        db.close()
        
        logger.info("初期データの読み込みが完了しました")
        
    except Exception as e:
        logger.error(f"初期データの読み込みに失敗しました: {e}")
        if 'db' in locals():
            db.close()
        raise