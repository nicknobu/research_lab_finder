#!/bin/bash
echo "=== Import Test ==="

python3 -c "
import sys
print(f'Python: {sys.version.split()[0]}')

try:
    from scraper.config.interfaces import ResearchLabData, FacultyType
    print('SUCCESS: scraper.config.interfaces')
except ImportError as e:
    print(f'ERROR: {e}')

try:
    from scraper.domain.research_lab import ResearchLab
    print('SUCCESS: scraper.domain.research_lab')
except ImportError as e:
    print(f'ERROR: {e}')
"
