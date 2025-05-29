# 📁 Project Structure Visualization

## 🌳 Directory Tree Structure

```
scalable-llm-over-kubernetes-deployment/
├── 📱 app/                           # FastAPI Backend Application
│   ├── __init__.py                   # Package initialization
│   ├── main.py                       # FastAPI application entry point
│   ├── models.py                     # Pydantic data models
│   ├── connection_manager.py         # WebSocket connection management
│   └── llm_service.py               # LLM service integration layer
├── 🎨 frontend/                      # React Frontend Application
│   ├── public/                       # Static assets
│   ├── src/
│   │   ├── App.js                    # Main React component
│   │   └── index.js                  # React app entry point
│   ├── package.json                  # NPM dependencies
│   ├── Dockerfile                    # Frontend container build
│   └── nginx.conf                    # Nginx configuration
├── ☸️  k8s/                           # Kubernetes Manifests
│   ├── backend-deployment-cloud.yaml # Backend deployment with sidecar
│   ├── frontend-deployment-cloud.yaml# Frontend deployment
│   ├── hpa-cloud.yaml               # Horizontal Pod Autoscaler
│   ├── frontend-hpa-cloud.yaml      # Frontend HPA
│   ├── backend-service-cloud.yaml   # Backend service definition
│   ├── configmap-cloud.yaml         # Configuration management
│   ├── rbac.yaml                     # Role-based access control
│   └── ssl-*.yaml                   # SSL/TLS configuration
├── 🚀 scripts/                       # Deployment & Utility Scripts
│   ├── setup-cloud.sh               # GCP infrastructure setup
│   ├── deploy-to-existing-cluster.sh# Cluster deployment
│   ├── setup-models.sh              # Model configuration
│   ├── test-deployment.sh           # Deployment testing
│   └── setup-ssl-askllm.sh          # SSL certificate setup
├── 🧪 load_testing/                  # Performance Testing
│   ├── locustfile.py                # Locust load testing script
│   ├── run_load_tests.sh            # Load test runner
│   ├── monitor_scaling.sh           # Scaling behavior monitor
│   └── README.md                     # Testing documentation
├── 🧪 tests/                         # Unit & Integration Tests
├── 📊 diagrams/                      # Architecture Diagrams
│   ├── autoscaling_diagram.mmd      # Complete autoscaling architecture
│   ├── autoscaling_flow_diagram.mmd # Scaling process flow
│   ├── autoscaling_metrics_dashboard.mmd # Metrics visualization
│   ├── poster_autoscaling_diagram.mmd # Simplified poster diagram
│   └── scaling_timeline_diagram.mmd # Timeline visualization
├── 🎓 poster/                        # Academic Poster Materials
│   ├── academic_poster.tex          # LaTeX poster document
│   ├── beamerthemeconfposter.sty   # Beamer theme
│   └── final-2.pdf                  # Generated poster PDF
├── 📚 docs/                          # Documentation
│   ├── PROJECT_OVERVIEW.md          # Comprehensive project overview
│   ├── MULTI_MODELS.md              # Multi-model support guide
│   └── SETUP.md                     # Setup instructions
├── 🐳 Container Files
│   ├── Dockerfile                   # Main backend container
│   ├── ollama-tinyllama.Dockerfile  # Custom Ollama with TinyLlama
│   └── requirements.txt             # Python dependencies
├── 🚀 Deployment Scripts
│   ├── deploy-gke.sh                # Main GKE deployment script
│   ├── quick-setup.sh               # Initial environment setup
│   └── manual-cloud-deploy.sh       # Manual deployment option
└── 📋 Configuration Files
    ├── README.md                     # Main project documentation
    ├── DEPLOYMENT_GUIDE.md          # Step-by-step deployment
    ├── DEPLOYMENT_SUMMARY.md        # Production achievements
    ├── SSL_SETUP_GUIDE.md           # SSL configuration
    ├── GITHUB_SETUP.md              # GitHub Actions setup
    └── .gitignore                    # Git ignore patterns
```

## 🏗️ Architecture Component Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            🌐 INTERNET ACCESS                                     │
│                                    │                                              │
│                          ┌─────────▼──────────┐                                 │
│                          │   GKE LoadBalancer  │                                 │
│                          │   (External IP)     │                                 │
│                          │   SSL/TLS Support   │                                 │
│                          └─────────┬──────────┘                                 │
│                                    │                                              │
├────────────────────────────────────┼──────────────────────────────────────────────┤
│                     🎨 FRONTEND TIER                                             │
│                                    │                                              │
│    ┌──────────────────────────────▼─────────────────────────────────┐           │
│    │               Frontend Service (ClusterIP)                     │           │
│    └──────────────────────────────┬─────────────────────────────────┘           │
│                                   │                                              │
│    ┌──────────────────┬───────────▼────────────┬──────────────────┐             │
│    │   Frontend Pod   │    Frontend Pod        │  Frontend Pod     │             │
│    │                  │                        │  (Auto-scaled)    │             │
│    │  ┌─────────────┐ │  ┌─────────────┐      │  ┌─────────────┐  │             │
│    │  │   React     │ │  │   React     │      │  │   React     │  │             │
│    │  │   App       │ │  │   App       │      │  │   App       │  │             │
│    │  └─────────────┘ │  └─────────────┘      │  └─────────────┘  │             │
│    │  ┌─────────────┐ │  ┌─────────────┐      │  ┌─────────────┐  │             │
│    │  │   Nginx     │ │  │   Nginx     │      │  │   Nginx     │  │             │
│    │  │  (Port 80)  │ │  │  (Port 80)  │      │  │  (Port 80)  │  │             │
│    │  └─────────────┘ │  └─────────────┘      │  └─────────────┘  │             │
│    └──────────────────┴───────────────────────┴──────────────────┘             │
│                                   │                                              │
│             HPA: 2-10 replicas    │                                              │
│          CPU: 60%, Memory: 70%    │                                              │
│                                   │                                              │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│                    🔧 BACKEND TIER │                                             │
│                                   │                                              │
│    ┌──────────────────────────────▼─────────────────────────────────┐           │
│    │               Backend Service (ClusterIP)                      │           │
│    └──────────────────────────────┬─────────────────────────────────┘           │
│                                   │                                              │
│    ┌──────────────────┬───────────▼────────────┬──────────────────┐             │
│    │   Backend Pod    │    Backend Pod         │  Backend Pod      │             │
│    │                  │                        │  (Auto-scaled)    │             │
│    │ ┌──────────────┐ │ ┌──────────────┐       │ ┌──────────────┐  │             │
│    │ │   FastAPI    │ │ │   FastAPI    │       │ │   FastAPI    │  │             │
│    │ │ (Port 8000)  │ │ │ (Port 8000)  │       │ │ (Port 8000)  │  │             │
│    │ │              │ │ │              │       │ │              │  │             │
│    │ │ WebSocket +  │ │ │ WebSocket +  │       │ │ WebSocket +  │  │             │
│    │ │ REST API     │ │ │ REST API     │       │ │ REST API     │  │             │
│    │ └──────┬───────┘ │ └──────┬───────┘       │ └──────┬───────┘  │             │
│    │        │localhost│        │localhost      │        │localhost │             │
│    │        │:11434   │        │:11434         │        │:11434    │             │
│    │ ┌──────▼───────┐ │ ┌──────▼───────┐       │ ┌──────▼───────┐  │             │
│    │ │   Ollama     │ │ │   Ollama     │       │ │   Ollama     │  │             │
│    │ │ (Port 11434) │ │ │ (Port 11434) │       │ │ (Port 11434) │  │             │
│    │ │              │ │ │              │       │ │              │  │             │
│    │ │  TinyLlama   │ │ │  TinyLlama   │       │ │  TinyLlama   │  │             │
│    │ │ (Pre-loaded) │ │ │ (Pre-loaded) │       │ │ (Pre-loaded) │  │             │
│    │ └──────────────┘ │ └──────────────┘       │ └──────────────┘  │             │
│    └──────────────────┴────────────────────────┴──────────────────┘             │
│                                   │                                              │
│             HPA: 1-3 replicas     │                                              │
│          CPU: 60%, Memory: 70%    │                                              │
│                                   │                                              │
├───────────────────────────────────┼──────────────────────────────────────────────┤
│              🖥️  INFRASTRUCTURE TIER                                             │
│                                   │                                              │
│    ┌──────────────────────────────▼─────────────────────────────────┐           │
│    │                    GKE Worker Nodes                            │           │
│    │                                                                │           │
│    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────┐ │           │
│    │  │   Node 1    │  │   Node 2    │  │   Node 3    │  │ Node  │ │           │
│    │  │ e2-small    │  │ e2-small    │  │ e2-small    │  │   4   │ │           │
│    │  │ 2 vCPU      │  │ 2 vCPU      │  │ 2 vCPU      │  │(Auto- │ │           │
│    │  │ 2GB RAM     │  │ 2GB RAM     │  │ 2GB RAM     │  │scale) │ │           │
│    │  └─────────────┘  └─────────────┘  └─────────────┘  └───────┘ │           │
│    │                                                                │           │
│    │         Cluster Autoscaler: 1-4 nodes                         │           │
│    └────────────────────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow Diagram

```
┌─────────────┐    HTTP/WebSocket     ┌─────────────┐    HTTP API      ┌─────────────┐
│             │ ─────────────────────▶│             │ ───────────────▶ │             │
│   Browser   │                       │  Frontend   │                  │   Backend   │
│             │◀───────────────────── │    Pod      │◀─────────────────│    Pod      │
└─────────────┘    HTML/CSS/JS        └─────────────┘   JSON Response  └─────────────┘
                                                                              │
                                                                              │ localhost:11434
                                                                              ▼
                                                                       ┌─────────────┐
                                                                       │   Ollama    │
                                                                       │  Sidecar    │
                                                                       │             │
                                                                       │  TinyLlama  │
                                                                       │ (Pre-loaded)│
                                                                       └─────────────┘
```

## 🚀 Deployment Flow Diagram

```
┌─────────────┐     git push      ┌─────────────┐    docker build    ┌─────────────┐
│             │ ─────────────────▶│             │ ─────────────────▶ │             │
│  Developer  │                   │   GitHub    │                    │  Artifact   │
│             │                   │  Repository │                    │  Registry   │
└─────────────┘                   └─────────────┘                    └─────────────┘
                                         │                                   │
                                         ▼                                   │
                                  ┌─────────────┐                           │
                                  │   GitHub    │                           │
                                  │   Actions   │                           │
                                  │   (CI/CD)   │                           │
                                  └─────────────┘                           │
                                         │                                   │
                                         ▼                                   │
                                  ┌─────────────┐    kubectl apply     ┌────▼────────┐
                                  │   GKE       │◀─────────────────────│   Docker    │
                                  │  Cluster    │                      │   Images    │
                                  │             │                      │             │
                                  └─────────────┘                      └─────────────┘
```

## 📊 File Size & Complexity Analysis

```
📁 Directory/File Breakdown:

app/                    📱 Backend (FastAPI)
├── main.py             ▓▓▓▓▓▓▓▓ (8.4KB) - Main application
├── llm_service.py      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ (21KB) - LLM integration
├── connection_manager.py ▓▓▓▓▓▓▓ (6.5KB) - WebSocket management
└── models.py           ▓▓ (1.9KB) - Data models

frontend/               🎨 Frontend (React)
├── App.js              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ (21KB) - Main React app
├── package.json        ▓ (1.2KB) - Dependencies
└── nginx.conf          ▓▓ (2.6KB) - Web server config

k8s/                    ☸️ Kubernetes Manifests
├── backend-deployment-cloud.yaml  ▓▓▓▓ (4.8KB) - Backend deployment
├── frontend-deployment-cloud.yaml ▓▓▓ (3.2KB) - Frontend deployment
├── hpa-cloud.yaml      ▓ (1.1KB) - Auto-scaling config
└── ssl-*.yaml          ▓▓▓▓▓▓▓ (7.8KB) - SSL configuration

scripts/                🚀 Deployment Scripts
├── setup-ssl-askllm.sh ▓▓▓▓▓▓▓▓▓▓▓ (11KB) - SSL setup
├── deploy-gke.sh       ▓▓▓▓▓▓▓▓▓▓▓ (11KB) - Main deployment
└── setup-cloud.sh     ▓▓▓▓ (4.3KB) - Infrastructure setup

load_testing/           🧪 Performance Testing
├── locustfile.py       ▓▓▓▓▓▓▓▓ (8.2KB) - Load testing
└── run_load_tests.sh   ▓▓▓▓▓ (4.9KB) - Test runner

docs/                   📚 Documentation
├── PROJECT_OVERVIEW.md ▓▓▓▓▓▓ (6.0KB) - Project overview
└── MULTI_MODELS.md     ▓▓▓▓▓▓ (6.3KB) - Model documentation

Container Files         🐳 Docker
├── Dockerfile          ▓▓ (1.8KB) - Backend container
└── ollama-tinyllama.Dockerfile ▓ (1.5KB) - Model container
```

## 🎯 Component Responsibilities

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          COMPONENT RESPONSIBILITY MATRIX                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  Frontend (React)         │  Backend (FastAPI)    │  Infrastructure (K8s)       │
│  ─────────────────────    │  ──────────────────   │  ─────────────────────      │
│  • User Interface         │  • API Endpoints      │  • Pod Orchestration        │
│  • Chat Experience        │  • WebSocket Server   │  • Auto-scaling             │
│  • Model Selection        │  • LLM Integration    │  • Load Balancing           │
│  • Real-time Messaging    │  • Connection Mgmt    │  • Health Monitoring        │
│  • Performance Metrics    │  • Request Processing │  • SSL/TLS Termination      │
│  • Responsive Design      │  • Health Checks      │  • Resource Management      │
│                           │  • Error Handling     │  • Rolling Updates          │
│                           │                       │  • Service Discovery        │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🔧 Technology Stack Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                    TECHNOLOGY STACK LAYERS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🌐 External Layer                                             │
│  ├── Internet Users                                            │
│  ├── DNS (askllm.net)                                         │
│  └── SSL/TLS Certificates                                      │
│                                                                 │
│  ☁️  Cloud Platform Layer                                       │
│  ├── Google Cloud Platform (GCP)                              │
│  ├── Google Kubernetes Engine (GKE)                           │
│  ├── Google Artifact Registry                                  │
│  └── Google Cloud Load Balancing                              │
│                                                                 │
│  ☸️  Orchestration Layer                                        │
│  ├── Kubernetes v1.27+                                        │
│  ├── Horizontal Pod Autoscaler (HPA)                          │
│  ├── Cluster Autoscaler                                       │
│  └── Service Mesh                                             │
│                                                                 │
│  🐳 Container Layer                                            │
│  ├── Docker Engine                                            │
│  ├── Multi-stage Builds                                       │
│  ├── Container Registry                                       │
│  └── Image Optimization                                       │
│                                                                 │
│  🔧 Application Layer                                          │
│  ├── React 18 (Frontend)                                      │
│  ├── FastAPI (Backend)                                        │
│  ├── Ollama (Model Server)                                    │
│  └── TinyLlama (Language Model)                               │
│                                                                 │
│  💾 Data Layer                                                 │
│  ├── In-memory Chat State                                     │
│  ├── Model Weights (Pre-loaded)                               │
│  ├── Application Logs                                         │
│  └── Metrics & Monitoring Data                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

This visualization provides a comprehensive overview of your scalable LLM chatbot project structure, showing how all components work together to create a production-ready, cost-effective, and highly scalable AI infrastructure solution. 