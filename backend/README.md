# NotesDB backend

This directory contains a small Python API scaffold. It currently has a basic
health endpoint; database, S3, and processing code can be added when the team is
ready to work on those pieces.

## Main files

- `app/main.py`: creates the FastAPI application.
- `app/api.py`: HTTP routes.
- `app/database.py`: planned MySQL connection and persistence code.
- `app/storage.py`: planned S3 integration.
- `app/worker.py`: planned background note processing.

## Run locally

From this directory, create and activate a virtual environment, install the
dependencies, and start the development server:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The API docs are available at `http://127.0.0.1:8000/docs`, and the basic
health endpoint is `http://127.0.0.1:8000/health`.

The API is intentionally small so the team can extend it one step at a time.
