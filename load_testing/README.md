# Load Testing for Scalable LLM Chatbot

This directory contains comprehensive load testing tools for the scalable LLM chatbot deployed on Kubernetes.

## 🚀 Quick Start

### Prerequisites

1. **Backend Running**: Ensure your Kubernetes pods are running
   ```bash
   kubectl get pods -l app=llm-chatbot-backend
   ```

2. **Port Forwarding**: Make sure port forwarding is active
   ```bash
   kubectl port-forward service/llm-chatbot-backend-service 8000:80 &
   ```

3. **Locust Installed**: Install if not already done
   ```bash
   pip install locust
   ```

### Run Load Tests

```bash
# Light load test (recommended to start)
./load_testing/run_load_tests.sh light

# Moderate load test
./load_testing/run_load_tests.sh moderate

# Heavy load test (will trigger auto-scaling)
./load_testing/run_load_tests.sh heavy

# Web UI for interactive testing
./load_testing/run_load_tests.sh web
```

## 📊 Test Scenarios

### 1. Light Load
- **Users**: 10 concurrent users
- **Spawn Rate**: 1 user/second
- **Duration**: 5 minutes
- **Purpose**: Basic functionality testing

### 2. Moderate Load
- **Users**: 50 concurrent users
- **Spawn Rate**: 5 users/second
- **Duration**: 10 minutes
- **Purpose**: Normal traffic simulation

### 3. Heavy Load
- **Users**: 100 concurrent users
- **Spawn Rate**: 10 users/second
- **Duration**: 15 minutes
- **Purpose**: Auto-scaling trigger testing

### 4. Stress Test
- **Users**: 200 concurrent users
- **Spawn Rate**: 20 users/second
- **Duration**: 20 minutes
- **Purpose**: Maximum capacity testing

## 🎯 What Gets Tested

### API Endpoints
- `GET /health` - Health check endpoint
- `POST /chat` - Chat message processing
- `GET /stats` - Application statistics
- `GET /metrics` - Prometheus metrics

### Test Behaviors
- **Realistic Chat**: Uses actual Kubernetes-related questions
- **Conversation Flow**: Maintains conversation context
- **User Patterns**: Different user types (normal, high-volume)
- **Error Handling**: Validates responses and handles failures

## 🔍 Monitoring During Tests

### 1. Auto-Scaling Monitor
Start the monitoring script in a separate terminal:
```bash
./load_testing/monitor_scaling.sh
```

This will show:
- Pod scaling events
- HPA (Horizontal Pod Autoscaler) metrics
- Resource usage (CPU/Memory)
- Service endpoints

### 2. Kubernetes Dashboard
```bash
# Watch pods in real-time
kubectl get pods -l app=llm-chatbot-backend -w

# Watch HPA status
kubectl get hpa llm-chatbot-hpa -w

# Check resource usage
kubectl top pods -l app=llm-chatbot-backend
```

## 📈 Expected Auto-Scaling Behavior

### Load Thresholds
- **Scale Up**: When CPU > 70% or Memory > 80%
- **Scale Down**: When load decreases below thresholds for 5+ minutes
- **Min Replicas**: 2 pods
- **Max Replicas**: 10 pods

### Scaling Timeline
1. **Initial**: 2 pods running
2. **Light Load**: Should stay at 2 pods
3. **Moderate Load**: May scale to 3-4 pods
4. **Heavy Load**: Should scale to 5-8 pods
5. **Stress Test**: Should reach maximum 10 pods

## 🛠️ Advanced Usage

### Custom Load Tests
```bash
./load_testing/run_load_tests.sh custom
# Follow prompts to set custom parameters
```

### Specific Endpoint Testing
```bash
# Test only chat endpoints
./load_testing/run_load_tests.sh moderate --tags chat

# Test everything except metrics
./load_testing/run_load_tests.sh heavy --exclude metrics
```

### Save Results to CSV
```bash
./load_testing/run_load_tests.sh moderate --csv results
# Creates: results_stats.csv, results_failures.csv, results_stats_history.csv
```

### Web UI Mode
```bash
./load_testing/run_load_tests.sh web
# Open http://localhost:8089 in your browser
```

## 📋 Test Metrics

### Performance Metrics
- **Request Rate**: Requests per second
- **Response Time**: Average, median, 95th percentile
- **Failure Rate**: Percentage of failed requests
- **Throughput**: Successful requests per second

### Kubernetes Metrics
- **Pod Count**: Number of active pods
- **CPU Usage**: Per pod and total
- **Memory Usage**: Per pod and total
- **Scaling Events**: Scale up/down events

## 🎓 Learning Objectives

This load testing demonstrates:

1. **Horizontal Pod Autoscaling**: Watch pods scale based on load
2. **Load Distribution**: See how Kubernetes distributes traffic
3. **Performance Characteristics**: Understand system limits
4. **Failure Modes**: How the system behaves under stress
5. **Recovery**: How quickly system recovers after load removal

## 🐛 Troubleshooting

### Backend Not Accessible
```bash
# Check port forwarding
ps aux | grep port-forward

# Restart if needed
kubectl port-forward service/llm-chatbot-backend-service 8000:80 &
```

### Pods Not Scaling
```bash
# Check HPA status
kubectl describe hpa llm-chatbot-hpa

# Check metrics server
kubectl top nodes
```

### High Error Rates
1. Check if Ollama is running and accessible
2. Verify backend logs: `kubectl logs -l app=llm-chatbot-backend`
3. Check resource limits in deployment

### Locust Connection Issues
```bash
# Test backend directly
curl http://localhost:8000/health

# Check if locust can reach backend
ping localhost
```

## 📊 Example Results

### Successful Heavy Load Test
```
Type     Name                  # reqs    # fails  Avg    Min    Max  Median  req/s
GET      /health               2891      0        23     12     1251   18     9.6
POST     /chat                 4818      2        1847   156    15023  1200   16.1
GET      /stats                965       0        25     13     234    22     3.2
GET      /metrics              963       1        31     15     445    26     3.2
```

### Expected Scaling Events
```
2025-05-23 15:30:00 - Deployment Status:
  Ready: 2/2  Up-to-date: 2  Available: 2

2025-05-23 15:35:00 - Deployment Status:
  Ready: 4/4  Up-to-date: 4  Available: 4

2025-05-23 15:40:00 - Deployment Status:
  Ready: 7/7  Up-to-date: 7  Available: 7
```

## 🎯 Best Practices

1. **Start Small**: Begin with light load tests
2. **Monitor Continuously**: Use the monitoring script
3. **Save Results**: Use CSV output for analysis
4. **Test Incrementally**: Gradually increase load
5. **Verify Recovery**: Ensure system returns to baseline

## 📚 Further Reading

- [Locust Documentation](https://locust.io/)
- [Kubernetes HPA Guide](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Load Testing Best Practices](https://locust.io/docs/1.0/writing-a-locustfile) 