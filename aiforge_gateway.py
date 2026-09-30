from fastapi import FastAPI, Request
import httpx
import time
import redis
import json
import hashlib
from sentence_transformers import SentenceTransformer, util

app = FastAPI(title="AIForge Smart Gateway")
VLLM_URL = "http://vllm-server.default.svc.cluster.local:8000/v1/chat/completions"
COST_PER_SECOND = 0.56 / 3600

print("Connecting to Redis...")
cache = redis.Redis(host='redis-svc.default.svc.cluster.local', port=6379, db=0, decode_responses=True)

print("Loading Embedding Model (all-MiniLM-L6-v2)...")
embedder = SentenceTransformer('all-MiniLM-L6-v2')

@app.post("/generate")
async def generate(request: Request):
    payload = await request.json()
    start_time = time.time()
    
    # 1. Vectorize the User Prompt
    user_prompt = payload["messages"][0]["content"]
    prompt_embedding = embedder.encode(user_prompt)
    
    # 2. Semantic Search (Fast Path)
    for key in cache.scan_iter("prompt:*"):
        cached_data = json.loads(cache.get(key))
        score = util.cos_sim(prompt_embedding, cached_data["embedding"]).item()
        
        if score > 0.95:  # 95% mathematical match
            latency = time.time() - start_time
            return {
                "response": cached_data["response"],
                "telemetry": {
                    "latency_seconds": round(latency, 3),
                    "estimated_gpu_cost_usd": 0.0,
                    "cache_hit": True,
                    "match_score": round(score, 3),
                    "routing": "Redis Semantic Cache (CPU)"
                }
            }

    # 3. Cache Miss -> Route to GPU (Heavy Path)
    async with httpx.AsyncClient() as client:
        response = await client.post(VLLM_URL, json=payload, timeout=60.0)
        result = response.json()
        ai_response = result["choices"][0]["message"]["content"]
        
    latency = time.time() - start_time
    
    # 4. Save to Semantic Memory
    cache_record = {
        "embedding": prompt_embedding.tolist(),
        "response": ai_response
    }
    prompt_hash = hashlib.md5(user_prompt.encode()).hexdigest()
    cache.setex(f"prompt:{prompt_hash}", 3600, json.dumps(cache_record))
    
    return {
        "response": ai_response,
        "telemetry": {
            "latency_seconds": round(latency, 3),
            "estimated_gpu_cost_usd": round(latency * COST_PER_SECOND, 6),
            "cache_hit": False,
            "routing": "NVIDIA L4 GPU"
        }
    }
