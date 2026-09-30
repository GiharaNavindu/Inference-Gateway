from locust import HttpUser, task, between
import random

class AIForgeEngineer(HttpUser):
    # Wait 1 to 3 seconds between requests per user
    wait_time = between(1, 3)

    @task(3)
    def cached_question(self):
        # Simulates the "Fast Path" (Semantic Cache Hit)
        self.client.post("/api/generate", json={
            "model": "microsoft/Phi-3.5-mini-instruct",
            "messages": [{"role": "user", "content": "Explain Kubernetes Autoscaling"}],
            "max_tokens": 50
        }, name="Semantic Cache Hit")

    @task(1)
    def unique_question(self):
        # Simulates the "Heavy Path" (NVIDIA L4 GPU Inference)
        random_id = random.randint(1, 99999)
        self.client.post("/api/generate", json={
            "model": "microsoft/Phi-3.5-mini-instruct",
            "messages": [{"role": "user", "content": f"Write a complex python data processing script. ID: {random_id}"}],
            "max_tokens": 100
        }, name="GPU Inference")
