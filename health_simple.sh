#!/bin/bash
echo "=== System Health Check ==="
echo ""

echo "Backend API:"
curl -s http://localhost:8000/health

echo ""
echo "Frontend:"
curl -s http://localhost:3000 >/dev/null && echo "OK" || echo "ERROR"

echo ""
echo "Import Test:"
python3 -c "
from scraper.config.interfaces import ResearchLabData
from scraper.domain.research_lab import ResearchLab
print('Import Success: Scraper module OK')
"
