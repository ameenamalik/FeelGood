try:
    from backend_agent.models import ChatPayload
    from backend_agent.graph import orchestrate_chat_turn
    from backend_agent.catalog import load_catalog, retrieve_best_session
except (ImportError, ValueError, ModuleNotFoundError):
    from models import ChatPayload
    from graph import orchestrate_chat_turn
    from catalog import load_catalog, retrieve_best_session

def test_catalog_loads():
    sessions = load_catalog()
    assert len(sessions) > 0

def test_new_routine_request_flow():
    payload = ChatPayload(
        prompt="Wired, 15 minutes, knees off the list.",
        subscriber_id="user-123"
    )
    res = orchestrate_chat_turn(payload)
    assert res.intent == "new_routine_request"
    assert res.phase == "recommendation_active"
    assert res.recommendation is not None
    assert len(res.quick_replies) > 0
    assert any(q.action_type == "filter_shorter" for q in res.quick_replies)

def test_inquiry_flow():
    payload = ChatPayload(
        prompt="what if I can't sit still",
        subscriber_id="user-123"
    )
    res = orchestrate_chat_turn(payload)
    assert res.intent == "inquiry"
    assert "standing" in res.message.lower() or "move" in res.message.lower()
    assert res.recommendation is not None
    assert res.recommendation.title == "Shake it out"

def test_acknowledgment_flow():
    payload = ChatPayload(
        prompt="sounds good",
        subscriber_id="user-123"
    )
    res = orchestrate_chat_turn(payload)
    assert res.intent == "acknowledgment"
    assert res.phase == "routine_committed"
    assert "set" in res.message.lower() or "ready" in res.message.lower()

if __name__ == "__main__":
    test_catalog_loads()
    test_new_routine_request_flow()
    test_inquiry_flow()
    test_acknowledgment_flow()
    print("All backend agent tests passed successfully!")
