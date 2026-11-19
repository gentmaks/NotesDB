"""ASGI application entry point."""

from fastapi import FastAPI

from app.api import router

app = FastAPI(title="NotesDB API", version="0.1.0")
app.include_router(router)
