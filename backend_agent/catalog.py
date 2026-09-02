import json
import os
from typing import List, Dict, Any, Optional

CATALOG_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "FeelGood",
    "Content",
    "catalog.json"
)

def load_catalog() -> List[Dict[str, Any]]:
    if os.path.exists(CATALOG_PATH):
        try:
            with open(CATALOG_PATH, "r", encoding="utf-8") as f:
                data = json.load(f)
                return data.get("sessions", [])
        except Exception:
            pass
    # Bundled fallback sessions if catalog path is unavailable
    return [
        {
            "id": "box-breathing-2m",
            "title": "Box breathing",
            "subtitle": "Four in, four hold, four out. Nothing to learn first.",
            "durationMin": 2,
            "intensity": "gentle",
            "focus": "breath",
            "posture": "sitting",
            "chips": ["Appetizer", "2 min", "Sitting"]
        },
        {
            "id": "shake-it-out-3m",
            "title": "Shake it out",
            "subtitle": "Loose arms, loose jaw. Then we'll try the rest.",
            "durationMin": 3,
            "intensity": "gentle",
            "focus": "mobility",
            "posture": "standing",
            "chips": ["Side", "3 min", "Standing"]
        },
        {
            "id": "morning-unwind-15m",
            "title": "Morning gentle reset",
            "subtitle": "Low to the mat, gentle twists, easing stiff joints.",
            "durationMin": 15,
            "intensity": "gentle",
            "focus": "back",
            "posture": "floor",
            "chips": ["Main", "15 min", "Floor"]
        },
        {
            "id": "hip-spine-release-20m",
            "title": "Hip & spine release",
            "subtitle": "Decompress tight glutes and hips without wrist strain.",
            "durationMin": 20,
            "intensity": "moderate",
            "focus": "hips",
            "posture": "floor",
            "chips": ["Main", "20 min", "Mat"]
        },
        {
            "id": "standing-vitality-10m",
            "title": "Standing vitality",
            "subtitle": "No mat needed. Quick reset to re-energize your posture.",
            "durationMin": 10,
            "intensity": "dynamic",
            "focus": "energy",
            "posture": "standing",
            "chips": ["Main", "10 min", "Standing"]
        }
    ]

def retrieve_best_session(
    target_duration: Optional[int] = None,
    intensity: Optional[str] = None,
    focus: Optional[str] = None,
    posture: Optional[str] = None,
    exclude_ids: Optional[List[str]] = None
) -> Dict[str, Any]:
    sessions = load_catalog()
    exclude = set(exclude_ids or [])
    
    scored: List[tuple[int, Dict[str, Any]]] = []
    for s in sessions:
        if s.get("id") in exclude:
            continue
        score = 0
        dur = s.get("durationMin", 15)
        if target_duration:
            diff = abs(dur - target_duration)
            if diff == 0:
                score += 15
            elif diff <= 5:
                score += 8
            elif diff <= 10:
                score += 3
        
        if intensity and s.get("intensity") == intensity:
            score += 6
        if focus and focus.lower() in (s.get("title", "") + " " + s.get("subtitle", "") + " " + str(s.get("focus", ""))).lower():
            score += 10
        if posture and posture.lower() in (s.get("posture", "") + " " + " ".join(s.get("chips", []))).lower():
            score += 8
            
        scored.append((score, s))
        
    scored.sort(key=lambda x: x[0], reverse=True)
    if scored:
        return scored[0][1]
    return sessions[0]
