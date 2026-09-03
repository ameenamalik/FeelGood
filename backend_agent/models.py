from __future__ import annotations
from typing import List, Optional, Literal
from pydantic import BaseModel, Field

class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str

class ExtractedCheckIn(BaseModel):
    energy: Optional[Literal["low", "steady", "strong"]] = None
    time_budget: Optional[
        Literal[
            "fiveMinutes",
            "aLittle",
            "fifteenMinutes",
            "twentyMinutes",
            "twentyFiveMinutes",
            "some",
            "thirtyFiveMinutes",
            "fortyMinutes",
            "plenty",
        ]
    ] = None
    place: Optional[Literal["stayingIn", "happyToGoOut", "atTheGym"]] = None
    body: Optional[Literal["sore", "stiff", "stressed", "cramping", "good"]] = None
    intent: Optional[Literal["energize", "strengthen", "calm", "mobilize", "joy"]] = None
    quick_filter: Optional[Literal["shorter", "gentler", "moreEnergizing", "canNotLeave"]] = None

class QuickReplyAction(BaseModel):
    id: str
    label: str
    symbol: Optional[str] = None
    action_type: Literal[
        "commit_to_today",
        "ask_why",
        "swap_routine",
        "filter_gentler",
        "filter_shorter",
        "filter_more_energizing",
        "filter_staying_in",
        "start_session",
        "custom_prompt"
    ]
    payload: Optional[str] = None

class StructuredRecommendation(BaseModel):
    session_id: str
    title: str
    subtitle: str
    duration_min: int
    intensity: Literal["gentle", "moderate", "dynamic"]
    course: Literal["appetizer", "main", "side", "dessert", "special"]
    reason: str
    tags: List[str] = Field(default_factory=list)
    equipment: Optional[List[str]] = None
    target_area: Optional[str] = None

class StructuredChatResponse(BaseModel):
    message: str
    intent: Literal[
        "new_routine_request",
        "inquiry",
        "acknowledgment",
        "refinement",
        "action_trigger",
        "general_check_in"
    ]
    phase: Literal[
        "greeting",
        "needs_discovery",
        "recommendation_active",
        "routine_committed",
        "inquiry_active"
    ]
    recommendation: Optional[StructuredRecommendation] = None
    quick_replies: List[QuickReplyAction] = Field(default_factory=list)
    extracted_check_in: Optional[ExtractedCheckIn] = None

class ChatPayload(BaseModel):
    prompt: str
    subscriber_id: str
    history: Optional[List[ChatMessage]] = Field(default_factory=list)
    current_time_budget: Optional[str] = None
    active_session_id: Optional[str] = None
