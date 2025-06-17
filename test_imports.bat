@echo off
echo 🧪 インポートテスト実行
echo.

python -c "
try:
    from scraper.config.interfaces import ResearchLabData, FacultyType
    print('✅ scraper.config.interfaces')
except ImportError as e:
    print(f'❌ インポートエラー: {e}')

try:
    from scraper.domain.research_lab import ResearchLab  
    print('✅ scraper.domain.research_lab')
except ImportError as e:
    print(f'❌ インポートエラー: {e}')
"
