#!/bin/bash

# Load Testing Script for Scalable LLM Chatbot
# This script provides easy commands to run different load testing scenarios

LOCUST_FILE="load_testing/locustfile.py"
HOST="http://localhost:8000"

echo "🚀 Scalable LLM Chatbot Load Testing"
echo "====================================="

show_help() {
    echo "Usage: $0 [SCENARIO] [OPTIONS]"
    echo ""
    echo "Scenarios:"
    echo "  light     - Light load: 10 users, 1/sec spawn rate, 5 minutes"
    echo "  moderate  - Moderate load: 50 users, 5/sec spawn rate, 10 minutes"
    echo "  heavy     - Heavy load: 100 users, 10/sec spawn rate, 15 minutes"
    echo "  stress    - Stress test: 200 users, 20/sec spawn rate, 20 minutes"
    echo "  custom    - Custom configuration (interactive)"
    echo "  web       - Start web UI for interactive testing"
    echo ""
    echo "Options:"
    echo "  --tags TAGS     Run only specific tags (health,chat,stats,metrics)"
    echo "  --exclude TAGS  Exclude specific tags"
    echo "  --csv PREFIX    Save results to CSV files with prefix"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 light                          # Run light load test"
    echo "  $0 moderate --tags chat           # Test only chat endpoints"
    echo "  $0 heavy --csv results            # Save results to CSV"
    echo "  $0 web                            # Start web interface"
}

check_prerequisites() {
    echo "🔍 Checking prerequisites..."
    
    # Check if locust is installed
    if ! command -v locust &> /dev/null; then
        echo "❌ Locust is not installed. Run: pip install locust"
        exit 1
    fi
    
    # Check if backend is accessible
    if ! curl -s http://localhost:8000/health > /dev/null; then
        echo "❌ Backend not accessible at http://localhost:8000"
        echo "   Make sure port forwarding is running:"
        echo "   kubectl port-forward service/llm-chatbot-backend-service 8000:80"
        exit 1
    fi
    
    # Check if Kubernetes pods are running
    if ! kubectl get pods -l app=llm-chatbot | grep -q Running; then
        echo "❌ Backend pods not running in Kubernetes"
        echo "   Check pod status: kubectl get pods -l app=llm-chatbot"
        exit 1
    fi
    
    echo "✅ All prerequisites met!"
    echo ""
}

run_light_load() {
    echo "🔄 Running Light Load Test..."
    locust -f $LOCUST_FILE --host=$HOST \
           --users 10 --spawn-rate 1 --run-time 5m \
           --headless $@
}

run_moderate_load() {
    echo "🔄 Running Moderate Load Test..."
    locust -f $LOCUST_FILE --host=$HOST \
           --users 50 --spawn-rate 5 --run-time 10m \
           --headless $@
}

run_heavy_load() {
    echo "🔄 Running Heavy Load Test..."
    locust -f $LOCUST_FILE --host=$HOST \
           --users 100 --spawn-rate 10 --run-time 15m \
           --headless $@
}

run_stress_test() {
    echo "🔄 Running Stress Test..."
    echo "⚠️  This will generate high load - monitor your system!"
    read -p "Continue? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        locust -f $LOCUST_FILE --host=$HOST \
               --users 200 --spawn-rate 20 --run-time 20m \
               --headless $@
    else
        echo "Stress test cancelled."
    fi
}

run_custom_test() {
    echo "🛠️  Custom Load Test Configuration"
    echo ""
    read -p "Number of users: " users
    read -p "Spawn rate (users/second): " spawn_rate
    read -p "Run time (e.g., 5m, 300s): " run_time
    
    echo ""
    echo "Running custom test: $users users, $spawn_rate/sec spawn rate, $run_time duration"
    locust -f $LOCUST_FILE --host=$HOST \
           --users $users --spawn-rate $spawn_rate --run-time $run_time \
           --headless $@
}

start_web_ui() {
    echo "🌐 Starting Locust Web UI..."
    echo "Open your browser to: http://localhost:8089"
    echo "Host is set to: $HOST"
    echo ""
    locust -f $LOCUST_FILE --host=$HOST
}

# Parse command line arguments
SCENARIO=""
EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        light|moderate|heavy|stress|custom|web)
            SCENARIO="$1"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
    esac
done

# Show help if no scenario provided
if [[ -z "$SCENARIO" ]]; then
    show_help
    exit 1
fi

# Check prerequisites before running
check_prerequisites

# Run the selected scenario
case $SCENARIO in
    light)
        run_light_load $EXTRA_ARGS
        ;;
    moderate)
        run_moderate_load $EXTRA_ARGS
        ;;
    heavy)
        run_heavy_load $EXTRA_ARGS
        ;;
    stress)
        run_stress_test $EXTRA_ARGS
        ;;
    custom)
        run_custom_test $EXTRA_ARGS
        ;;
    web)
        start_web_ui
        ;;
    *)
        echo "❌ Unknown scenario: $SCENARIO"
        show_help
        exit 1
        ;;
esac 