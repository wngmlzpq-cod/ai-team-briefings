$ErrorActionPreference = "Stop"
& .\.venv\Scripts\python.exe -m uvicorn src.ai_team.web.app:app --reload
