import random
import json
import time
from locust import HttpUser, TaskSet, task, between, tag
from locust.exception import StopUser
import websocket
import uuid
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ChatBotTaskSet(TaskSet):
    """
    Task set for testing the scalable LLM chatbot application
    """
    
    def on_start(self):
        """Initialize conversation ID for this user"""
        self.conversation_id = str(uuid.uuid4())
        self.messages_sent = 0
        self.max_messages = random.randint(5, 15)  # Each user sends 5-15 messages
        
        # Test data
        self.test_messages = [
            "Hello, how are you?",
            "What is Kubernetes?",
            "How does container orchestration work?",
            "Explain microservices architecture",
            "What are the benefits of using Docker?",
            "How do you scale applications in Kubernetes?",
            "What is a pod in Kubernetes?",
            "Explain the concept of auto-scaling",
            "What are Kubernetes services?",
            "How do you deploy applications to Kubernetes?",
            "What is the difference between Docker and Kubernetes?",
            "Explain horizontal pod autoscaling",
            "What are the advantages of microservices?",
            "How do you monitor Kubernetes clusters?",
            "What is a container registry?",
            "Explain the concept of load balancing",
            "What are Kubernetes namespaces?",
            "How do you handle secrets in Kubernetes?",
            "What is CI/CD in containerized environments?",
            "Explain the concept of service mesh"
        ]
    
    @task(3)
    @tag("health")
    def health_check(self):
        """Test health endpoint"""
        with self.client.get("/health", catch_response=True) as response:
            if response.status_code == 200:
                data = response.json()
                if data.get("status") == "healthy":
                    response.success()
                else:
                    response.failure(f"Health check failed: {data}")
            else:
                response.failure(f"Health check returned {response.status_code}")
    
    @task(5)
    @tag("chat")
    def send_chat_message(self):
        """Test chat endpoint with realistic messages"""
        if self.messages_sent >= self.max_messages:
            return
            
        message = random.choice(self.test_messages)
        
        payload = {
            "message": message,
            "conversation_id": self.conversation_id
        }
        
        with self.client.post("/chat", 
                            json=payload, 
                            headers={"Content-Type": "application/json"},
                            catch_response=True) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    if "response" in data and "timestamp" in data:
                        response.success()
                        self.messages_sent += 1
                        # Simulate user reading response
                        time.sleep(random.uniform(1, 3))
                    else:
                        response.failure(f"Invalid response format: {data}")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Chat request failed with status {response.status_code}")
    
    @task(1)
    @tag("stats")
    def get_stats(self):
        """Test stats endpoint"""
        with self.client.get("/stats", catch_response=True) as response:
            if response.status_code == 200:
                try:
                    data = response.json()
                    required_fields = ["total_messages", "active_conversations", "uptime_seconds"]
                    if all(field in data for field in required_fields):
                        response.success()
                    else:
                        response.failure(f"Missing required stats fields: {data}")
                except json.JSONDecodeError:
                    response.failure("Invalid JSON response")
            else:
                response.failure(f"Stats request failed with status {response.status_code}")
    
    @task(1)
    @tag("metrics")
    def get_metrics(self):
        """Test Prometheus metrics endpoint"""
        with self.client.get("/metrics", catch_response=True) as response:
            if response.status_code == 200:
                if "http_requests_total" in response.text:
                    response.success()
                else:
                    response.failure("Metrics format incorrect")
            else:
                response.failure(f"Metrics request failed with status {response.status_code}")

class WebSocketChatUser(HttpUser):
    """
    User that primarily uses WebSocket for real-time chat
    """
    wait_time = between(1, 3)
    tasks = [ChatBotTaskSet]
    weight = 3  # 75% of users use HTTP API
    
    def on_start(self):
        """Test initial connection"""
        response = self.client.get("/health")
        if response.status_code != 200:
            logger.error("Backend not healthy, stopping user")
            raise StopUser()

class HighVolumeUser(HttpUser):
    """
    User that sends high volume of requests to test scaling
    """
    wait_time = between(0.5, 1.5)  # Faster requests
    tasks = [ChatBotTaskSet]
    weight = 1  # 25% of users are high volume
    
    def on_start(self):
        """Test initial connection"""
        response = self.client.get("/health")
        if response.status_code != 200:
            logger.error("Backend not healthy, stopping user")
            raise StopUser()

class StressTestTaskSet(TaskSet):
    """
    Stress testing task set for extreme load scenarios
    """
    
    def on_start(self):
        self.conversation_id = str(uuid.uuid4())
    
    @task(10)
    def rapid_fire_chat(self):
        """Send rapid chat messages to stress test the system"""
        messages = [
            "Test message 1",
            "Test message 2", 
            "Test message 3",
            "Quick test",
            "Load test message"
        ]
        
        message = random.choice(messages)
        payload = {
            "message": message,
            "conversation_id": self.conversation_id
        }
        
        self.client.post("/chat", json=payload)
    
    @task(3)
    def rapid_health_checks(self):
        """Rapid health checks"""
        self.client.get("/health")

class StressTestUser(HttpUser):
    """
    User for stress testing scenarios
    """
    wait_time = between(0.1, 0.5)  # Very fast requests
    tasks = [StressTestTaskSet]
    weight = 0  # Disabled by default, enable manually for stress testing

# Custom test scenarios for different load patterns
class BurstTrafficUser(HttpUser):
    """
    Simulates burst traffic patterns
    """
    wait_time = between(0.1, 0.3)
    tasks = [ChatBotTaskSet]
    weight = 0  # Enable manually for burst testing
    
    def on_start(self):
        # Burst pattern: send many requests quickly, then wait
        for _ in range(random.randint(5, 10)):
            self.client.get("/health")
            time.sleep(0.1)
        
        # Then normal behavior
        super().on_start()

# Test configuration for different scenarios
class LoadTestConfig:
    """
    Configuration for different load testing scenarios
    """
    
    @staticmethod
    def light_load():
        """Light load configuration"""
        return {
            "users": 10,
            "spawn_rate": 1,
            "run_time": "5m"
        }
    
    @staticmethod
    def moderate_load():
        """Moderate load configuration"""
        return {
            "users": 50,
            "spawn_rate": 5,
            "run_time": "10m"
        }
    
    @staticmethod
    def heavy_load():
        """Heavy load configuration"""
        return {
            "users": 100,
            "spawn_rate": 10,
            "run_time": "15m"
        }
    
    @staticmethod
    def stress_test():
        """Stress test configuration"""
        return {
            "users": 200,
            "spawn_rate": 20,
            "run_time": "20m"
        } 