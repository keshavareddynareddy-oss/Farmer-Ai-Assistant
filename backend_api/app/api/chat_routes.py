from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.services.chatbot_service import chat_with_assistant

router = APIRouter()


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=500)
    session_id: str | None = Field(default=None, max_length=100)
    language: str | None = Field(default=None, max_length=10)
    context: dict | None = None


@router.post("/chat")
def chat(payload: ChatRequest) -> dict:
    return chat_with_assistant(
        message=payload.message,
        session_id=payload.session_id,
        language=payload.language,
        context=payload.context,
    )
