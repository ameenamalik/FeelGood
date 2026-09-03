from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
try:
    from .models import ChatPayload, StructuredChatResponse
    from .graph import orchestrate_chat_turn
    from .catalog import load_catalog
except (ImportError, ValueError):
    from models import ChatPayload, StructuredChatResponse
    from graph import orchestrate_chat_turn
    from catalog import load_catalog

app = FastAPI(
    title="FeelGood Agent API",
    description="Stateful orchestrator and schema-driven conversational agent backend for FeelGood",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {
        "status": "ok",
        "agent": "FeelGood LangGraph Agent",
        "version": "2.0.0",
        "endpoints": ["/health", "/catalog", "/chat", "/docs"]
    }

@app.get("/main.py")
def main_py_alias():
    return root()

@app.get("/health")
def health():
    return {"status": "ok", "agent": "FeelGood LangGraph Agent", "version": "2.0.0"}

@app.get("/catalog")
def get_catalog():
    return {"sessions": load_catalog()}

@app.post("/chat", response_model=StructuredChatResponse)
def chat_endpoint(payload: ChatPayload):
    if not payload.prompt.strip():
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")
    return orchestrate_chat_turn(payload)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend_agent.main:app", host="0.0.0.0", port=8000, reload=True)
