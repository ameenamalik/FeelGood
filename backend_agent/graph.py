import os
from typing import Dict, Any, List, Optional
from .models import (
    ChatPayload,
    StructuredChatResponse,
    StructuredRecommendation,
    QuickReplyAction,
    ExtractedCheckIn,
)
from .catalog import retrieve_best_session, load_catalog

def classify_intent_and_state(prompt: str, history_len: int) -> tuple[str, str]:
    text = prompt.lower().strip()
    
    # Acknowledgment
    if text in ["k", "ok", "okay", "yes", "sounds good", "perfect", "let's do it", "looks good", "great", "done"]:
        return "acknowledgment", "routine_committed"
    
    # Inquiry / Why
    if "why" in text or "what is" in text or "explain" in text or "how does" in text or "what if" in text:
        return "inquiry", "inquiry_active"
    
    # Refinement / Quick Pivot
    if any(w in text for w in ["shorter", "gentler", "easier", "harder", "energiz", "stand", "sit", "floor", "bed", "not today", "something else"]):
        return "refinement", "recommendation_active"
        
    # Action Trigger
    if "add to today" in text or "swap" in text or "start" in text:
        return "action_trigger", "routine_committed"
    
    # New routine request or check-in
    if any(w in text for w in ["min", "tired", "back", "sore", "stiff", "tight", "breath", "flow", "yoga", "stretch", "morning", "night"]):
        return "new_routine_request", "recommendation_active"
        
    return "general_check_in", "needs_discovery" if history_len == 0 else "recommendation_active"

def extract_check_in(text: str) -> ExtractedCheckIn:
    lower = text.lower()
    energy = None
    if any(w in lower for w in ["tired", "exhaust", "empty", "low", "drain", "sleepy"]):
        energy = "low"
    elif any(w in lower for w in ["energ", "strong", "pump", "power"]):
        energy = "strong"
    elif any(w in lower for w in ["steady", "ok", "fine", "good"]):
        energy = "steady"
        
    time_budget = None
    if "5 min" in lower or "five min" in lower:
        time_budget = "fiveMinutes"
    elif "10 min" in lower or "ten min" in lower:
        time_budget = "aLittle"
    elif "15 min" in lower or "fifteen min" in lower:
        time_budget = "fifteenMinutes"
    elif "20 min" in lower or "twenty min" in lower:
        time_budget = "twentyMinutes"
    elif "30 min" in lower or "thirty min" in lower:
        time_budget = "some"
    elif "45 min" in lower or "hour" in lower:
        time_budget = "plenty"
        
    place = None
    if "gym" in lower:
        place = "atTheGym"
    elif any(w in lower for w in ["outside", "outdoor", "walk", "park"]):
        place = "happyToGoOut"
    elif any(w in lower for w in ["home", "stay in", "staying in", "mat", "floor", "bed"]):
        place = "stayingIn"
        
    body = None
    if any(w in lower for w in ["sore", "ache", "hurt"]):
        body = "sore"
    elif any(w in lower for w in ["stiff", "tight", "tension"]):
        body = "stiff"
    elif any(w in lower for w in ["stress", "anxious", "wound up", "wired"]):
        body = "stressed"
    elif "good" in lower:
        body = "good"
        
    quick_filter = None
    if "shorter" in lower:
        quick_filter = "shorter"
    elif "gentler" in lower or "easier" in lower:
        quick_filter = "gentler"
    elif "energiz" in lower:
        quick_filter = "moreEnergizing"
    elif "stay" in lower:
        quick_filter = "canNotLeave"
        
    return ExtractedCheckIn(
        energy=energy,
        time_budget=time_budget,
        place=place,
        body=body,
        quick_filter=quick_filter
    )

def orchestrate_chat_turn(payload: ChatPayload) -> StructuredChatResponse:
    prompt = payload.prompt
    history = payload.history or []
    intent, phase = classify_intent_and_state(prompt, len(history))
    check_in = extract_check_in(prompt)
    
    # Target duration detection
    target_dur = 15
    if "2 min" in prompt.lower() or "2min" in prompt.lower():
        target_dur = 2
    elif "3 min" in prompt.lower() or "3min" in prompt.lower():
        target_dur = 3
    elif "5 min" in prompt.lower():
        target_dur = 5
    elif "10 min" in prompt.lower():
        target_dur = 10
    elif "20 min" in prompt.lower():
        target_dur = 20
    elif "30 min" in prompt.lower():
        target_dur = 30
        
    posture = None
    if "stand" in prompt.lower():
        posture = "standing"
    elif "sit" in prompt.lower():
        posture = "sitting"
    elif "floor" in prompt.lower() or "mat" in prompt.lower():
        posture = "floor"
        
    focus = None
    if "breath" in prompt.lower() or "box" in prompt.lower() or "calm" in prompt.lower():
        focus = "breath"
    elif "back" in prompt.lower() or "spine" in prompt.lower():
        focus = "back"
    elif "hip" in prompt.lower():
        focus = "hips"
    elif "shake" in prompt.lower() or "shoulder" in prompt.lower():
        focus = "mobility"
        
    intensity = "gentle"
    if "strong" in prompt.lower() or "dynamic" in prompt.lower() or "sweat" in prompt.lower():
        intensity = "dynamic"
    elif "moderate" in prompt.lower():
        intensity = "moderate"
        
    if intent == "inquiry":
        if "can't sit still" in prompt.lower() or "can not sit" in prompt.lower():
            message = "Then move first. This one's standing."
            session_data = {
                "id": "shake-it-out-3m",
                "title": "Shake it out",
                "subtitle": "Loose arms, loose jaw. Then we'll try the rest.",
                "durationMin": 3,
                "intensity": "gentle",
                "course": "side",
                "chips": ["Side", "3 min", "Standing"]
            }
        elif "why" in prompt.lower():
            message = "This sequence opens tight thoracic joints gently while keeping breath deep and steady."
            session_data = retrieve_best_session(target_duration=target_dur, focus=focus, posture=posture)
        else:
            message = "Here is how this session fits your movement today."
            session_data = retrieve_best_session(target_duration=target_dur, focus=focus, posture=posture)
    elif intent == "acknowledgment":
        message = "You're all set. Take your time, breathe deeply, and enjoy moving."
        session_data = None
    elif intent == "refinement":
        message = "Adjusted. Here is a lighter, shorter option that keeps things easy."
        session_data = retrieve_best_session(target_duration=target_dur if target_dur != 15 else 5, intensity="gentle", posture=posture)
    elif intent == "action_trigger":
        message = "Added to today's menu. Tap Start whenever you're ready."
        session_data = retrieve_best_session(target_duration=target_dur, focus=focus, posture=posture)
    else:
        message = "Wired, fifteen minutes, knees off the list. Start here." if "wired" in prompt.lower() else "Here's a gentle plan that fits your day."
        session_data = retrieve_best_session(target_duration=target_dur, intensity=intensity, focus=focus, posture=posture)
        
    recommendation = None
    if session_data:
        chips = session_data.get("chips", [])
        if not chips:
            chips = [
                session_data.get("course", "Main").capitalize(),
                f"{session_data.get('durationMin', 15)} min",
                (session_data.get("posture") or "Floor").capitalize()
            ]
        course_type = "main"
        if "appetizer" in [c.lower() for c in chips]:
            course_type = "appetizer"
        elif "side" in [c.lower() for c in chips]:
            course_type = "side"
        elif "dessert" in [c.lower() for c in chips]:
            course_type = "dessert"
            
        raw_intensity = str(session_data.get("intensity", "gentle")).lower()
        if raw_intensity in ["3", "dynamic", "high", "hard"]:
            normalized_intensity = "dynamic"
        elif raw_intensity in ["2", "moderate", "medium"]:
            normalized_intensity = "moderate"
        else:
            normalized_intensity = "gentle"

        recommendation = StructuredRecommendation(
            session_id=session_data.get("id", "session-1"),
            title=session_data.get("title", "Gentle Movement"),
            subtitle=session_data.get("subtitle", "Mindful pace for your day."),
            duration_min=session_data.get("durationMin", 15),
            intensity=normalized_intensity,
            course=course_type,
            reason=session_data.get("subtitle", "Selected for your focus today."),
            tags=chips
        )
        
    quick_replies = []
    if phase == "recommendation_active" or phase == "inquiry_active" or recommendation is not None:
        quick_replies = [
            QuickReplyAction(id="shorter", label="Something shorter", symbol="clock.arrow.circlepath", action_type="filter_shorter"),
            QuickReplyAction(id="why_this", label="Why this?", symbol="questionmark.circle", action_type="ask_why"),
            QuickReplyAction(id="not_today", label="Not today", symbol="xmark.circle", action_type="swap_routine"),
        ]
    elif phase == "routine_committed":
        quick_replies = [
            QuickReplyAction(id="start_now", label="Start now", symbol="play.fill", action_type="start_session"),
            QuickReplyAction(id="ask_more", label="What should I prepare?", symbol="sparkles", action_type="custom_prompt"),
        ]
    else:
        quick_replies = [
            QuickReplyAction(id="gentle_10m", label="10 min gentle reset", symbol="leaf", action_type="custom_prompt", payload="10 min gentle reset"),
            QuickReplyAction(id="standing_energy", label="Standing energy", symbol="bolt", action_type="custom_prompt", payload="Standing energy reset"),
            QuickReplyAction(id="stiff_back", label="Tight lower back", symbol="figure.mind.and.body", action_type="custom_prompt", payload="15m for tight lower back"),
        ]
        
    return StructuredChatResponse(
        message=message,
        intent=intent,
        phase=phase,
        recommendation=recommendation,
        quick_replies=quick_replies,
        extracted_check_in=check_in
    )
