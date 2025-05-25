# UML Diagrams for Scalable LLM Chatbot Infrastructure

## 1. Component Diagram

```mermaid
graph TB
    subgraph "Frontend Tier"
        UI[React Chat Interface]
        WS[WebSocket Client]
        HTTP[HTTP Client]
        Router[React Router]
        State[State Management]
        
        UI --> WS
        UI --> HTTP
        UI --> Router
        UI --> State
    end
    
    subgraph "API Gateway Tier"
        FastAPI[FastAPI Application]
        WSHandler[WebSocket Handler]
        HTTPHandler[HTTP Request Handler]
        ConnMgr[Connection Manager]
        Auth[Authentication Service]
        
        FastAPI --> WSHandler
        FastAPI --> HTTPHandler
        FastAPI --> ConnMgr
        FastAPI --> Auth
    end
    
    subgraph "Model Serving Tier"
        LLMService[LLM Service]
        OllamaClient[Ollama Client]
        ModelMgr[Model Manager]
        ContextMgr[Context Manager]
        
        LLMService --> OllamaClient
        LLMService --> ModelMgr
        LLMService --> ContextMgr
    end
    
    subgraph "Ollama Sidecar"
        OllamaServer[Ollama Server]
        TinyLlama[TinyLlama Model]
        ModelAPI[Model API]
        
        OllamaServer --> TinyLlama
        OllamaServer --> ModelAPI
    end
    
    subgraph "Infrastructure Services"
        ConfigMap[Configuration]
        Secrets[Secrets Management]
        HPA[Horizontal Pod Autoscaler]
        LoadBalancer[Load Balancer]
        Registry[Artifact Registry]
        
        ConfigMap --> FastAPI
        Secrets --> FastAPI
        HPA --> FastAPI
    end
    
    subgraph "Monitoring & Observability"
        Metrics[Prometheus Metrics]
        Logs[Application Logs]
        Health[Health Checks]
        
        FastAPI --> Metrics
        FastAPI --> Logs
        FastAPI --> Health
        OllamaServer --> Health
    end
    
    %% Connections between tiers
    WS -.->|WebSocket| WSHandler
    HTTP -.->|HTTP/REST| HTTPHandler
    LoadBalancer -.->|Route Traffic| FastAPI
    
    HTTPHandler --> LLMService
    WSHandler --> LLMService
    ConnMgr --> LLMService
    
    OllamaClient -.->|HTTP API| ModelAPI
    
    %% External connections
    Users[Users] -.->|HTTPS| LoadBalancer
    Registry -.->|Pull Images| FastAPI
    Registry -.->|Pull Images| OllamaServer
    
    classDef frontend fill:#e1f5fe
    classDef backend fill:#f3e5f5
    classDef model fill:#e8f5e8
    classDef infra fill:#fff3e0
    classDef monitor fill:#fce4ec
    
    class UI,WS,HTTP,Router,State frontend
    class FastAPI,WSHandler,HTTPHandler,ConnMgr,Auth backend
    class LLMService,OllamaClient,ModelMgr,ContextMgr,OllamaServer,TinyLlama,ModelAPI model
    class ConfigMap,Secrets,HPA,LoadBalancer,Registry infra
    class Metrics,Logs,Health monitor
```

## 2. Deployment Diagram

```mermaid
graph TB
    subgraph "Google Cloud Platform"
        subgraph "Google Kubernetes Engine Cluster"
            subgraph "Frontend Namespace"
                subgraph "Frontend Pod 1"
                    FE1[React App Container]
                    NGINX1[Nginx Container]
                end
                subgraph "Frontend Pod 2"
                    FE2[React App Container]
                    NGINX2[Nginx Container]
                end
                FEService[Frontend Service<br/>LoadBalancer]
                FEHPA[Frontend HPA<br/>2-10 replicas]
            end
            
            subgraph "Backend Namespace"
                subgraph "Backend Pod 1"
                    BE1[FastAPI Container<br/>256Mi/512Mi<br/>200m/500m CPU]
                    OL1[Ollama Container<br/>2Gi/6Gi Memory<br/>500m/1000m CPU]
                    VOL1[Shared Volume<br/>Logs]
                end
                subgraph "Backend Pod 2"
                    BE2[FastAPI Container]
                    OL2[Ollama Container]
                    VOL2[Shared Volume]
                end
                BEService[Backend Service<br/>ClusterIP]
                BEHPA[Backend HPA<br/>1-3 replicas]
            end
            
            subgraph "Configuration"
                CM[ConfigMap<br/>Environment Variables]
                SEC[Secrets<br/>API Keys]
                RBAC[RBAC<br/>Service Accounts]
            end
            
            subgraph "Node Pool"
                NODE1[Node 1<br/>e2-small<br/>2 vCPU, 2GB RAM]
                NODE2[Node 2<br/>e2-small<br/>2 vCPU, 2GB RAM]
                NODEHPA[Cluster Autoscaler<br/>1-3 nodes]
            end
        end
        
        subgraph "Google Cloud Services"
            ALB[Application Load Balancer<br/>External IP]
            AR[Artifact Registry<br/>Container Images]
            CM_SVC[Cloud Monitoring]
            CL_SVC[Cloud Logging]
        end
        
        subgraph "Networking"
            VPC[Virtual Private Cloud]
            SUBNET[GKE Subnet]
            FW[Firewall Rules]
        end
    end
    
    subgraph "External"
        USERS[Users<br/>Web Browsers]
        DEVS[Developers<br/>CI/CD Pipeline]
        DOCKER[Docker Build<br/>Environment]
    end
    
    %% Connections
    USERS -.->|HTTPS| ALB
    ALB -.->|Route| FEService
    FEService -.->|Load Balance| FE1
    FEService -.->|Load Balance| FE2
    
    FE1 -.->|API Calls| BEService
    FE2 -.->|API Calls| BEService
    BEService -.->|Route| BE1
    BEService -.->|Route| BE2
    
    BE1 -.->|localhost:11434| OL1
    BE2 -.->|localhost:11434| OL2
    
    CM -.->|Config| BE1
    CM -.->|Config| BE2
    SEC -.->|Secrets| BE1
    SEC -.->|Secrets| BE2
    
    FEHPA -.->|Scale| FE1
    FEHPA -.->|Scale| FE2
    BEHPA -.->|Scale| BE1
    BEHPA -.->|Scale| BE2
    
    NODEHPA -.->|Scale| NODE1
    NODEHPA -.->|Scale| NODE2
    
    DEVS -.->|Push Images| AR
    DOCKER -.->|Build & Push| AR
    AR -.->|Pull Images| BE1
    AR -.->|Pull Images| BE2
    AR -.->|Pull Images| FE1
    AR -.->|Pull Images| FE2
    
    BE1 -.->|Metrics| CM_SVC
    BE2 -.->|Metrics| CM_SVC
    BE1 -.->|Logs| CL_SVC
    BE2 -.->|Logs| CL_SVC
    
    %% Node placement
    FE1 -.->|Scheduled on| NODE1
    BE1 -.->|Scheduled on| NODE1
    FE2 -.->|Scheduled on| NODE2
    BE2 -.->|Scheduled on| NODE2
    
    classDef pod fill:#e3f2fd
    classDef service fill:#f1f8e9
    classDef config fill:#fff8e1
    classDef node fill:#fce4ec
    classDef cloud fill:#e8eaf6
    classDef external fill:#efebe9
    
    class FE1,FE2,BE1,BE2,OL1,OL2 pod
    class FEService,BEService,FEHPA,BEHPA service
    class CM,SEC,RBAC config
    class NODE1,NODE2,NODEHPA node
    class ALB,AR,CM_SVC,CL_SVC,VPC,SUBNET,FW cloud
    class USERS,DEVS,DOCKER external
```

## 3. Sequence Diagram - User Chat Interaction

```mermaid
sequenceDiagram
    participant U as User Browser
    participant LB as Load Balancer
    participant FE as Frontend Pod
    participant BE as FastAPI Container
    participant OL as Ollama Container
    participant TL as TinyLlama Model
    participant CM as Connection Manager
    participant HPA as HPA Controller
    
    Note over U,HPA: Initial Connection Setup
    U->>+LB: HTTPS Request (Chat Page)
    LB->>+FE: Route to Frontend Pod
    FE->>-LB: Return Chat Interface
    LB->>-U: Chat Page Loaded
    
    Note over U,HPA: WebSocket Connection
    U->>+LB: WebSocket Upgrade Request
    LB->>+FE: Route WebSocket
    FE->>+BE: Proxy WebSocket to Backend
    BE->>+CM: Register Connection
    CM->>-BE: Connection Registered
    BE->>-FE: WebSocket Established
    FE->>-LB: WebSocket Ready
    LB->>-U: WebSocket Connected
    
    Note over U,HPA: Chat Message Flow
    U->>+LB: Send Chat Message (WebSocket)
    LB->>+FE: Route Message
    FE->>+BE: Forward Message
    
    BE->>+CM: Validate Connection
    CM->>-BE: Connection Valid
    
    BE->>BE: Extract Message Content
    BE->>BE: Generate Conversation ID
    
    Note over BE,TL: Model Inference Process
    BE->>+OL: HTTP POST /api/generate
    Note over OL: Request: {"model": "tinyllama", "prompt": "user_message"}
    
    OL->>+TL: Load Context & Process
    TL->>TL: Tokenize Input
    TL->>TL: Generate Response
    TL->>-OL: Return Generated Text
    
    OL->>-BE: HTTP Response with Generated Text
    
    BE->>BE: Process Response
    BE->>+CM: Send Response to User
    CM->>-BE: Message Sent
    
    BE->>-FE: WebSocket Response
    FE->>-LB: Forward Response
    LB->>-U: Display Chat Response
    
    Note over U,HPA: Auto-scaling Trigger (High Load)
    BE->>BE: CPU Usage > 60%
    BE->>+HPA: Metrics Update
    HPA->>HPA: Evaluate Scaling Policy
    HPA->>+BE: Scale to 2 Replicas
    Note over BE: New Backend Pod Created
    BE->>-HPA: Scaling Complete
    HPA->>-BE: Scaling Acknowledged
    
    Note over U,HPA: Health Check Flow
    loop Every 30 seconds
        BE->>+OL: GET /api/version (Liveness)
        OL->>-BE: 200 OK
        BE->>BE: Update Health Status
        
        FE->>+BE: GET /health (Readiness)
        BE->>-FE: 200 OK
    end
    
    Note over U,HPA: Error Handling Scenario
    U->>+LB: Send Chat Message
    LB->>+FE: Route Message
    FE->>+BE: Forward Message
    BE->>+OL: HTTP POST /api/generate
    OL-->>-BE: 500 Internal Server Error
    BE->>BE: Log Error & Retry Logic
    BE->>+OL: Retry Request
    OL->>-BE: 200 OK (Success)
    BE->>-FE: Return Response
    FE->>-LB: Forward Response
    LB->>-U: Display Response
    
    Note over U,HPA: Connection Cleanup
    U->>+LB: Close Browser/Tab
    LB->>+FE: WebSocket Disconnect
    FE->>+BE: Connection Closed
    BE->>+CM: Unregister Connection
    CM->>CM: Cleanup Resources
    CM->>-BE: Connection Removed
    BE->>-FE: Cleanup Complete
    FE->>-LB: Disconnect Acknowledged
    LB->>-U: Connection Closed
```

## 4. Sequence Diagram - Deployment Process

```mermaid
sequenceDiagram
    participant DEV as Developer
    participant GIT as Git Repository
    participant DOCKER as Docker Build
    participant AR as Artifact Registry
    participant GKE as GKE Cluster
    participant K8S as Kubernetes API
    participant POD as Backend Pod
    participant OL as Ollama Container
    participant HPA as HPA Controller
    
    Note over DEV,HPA: CI/CD Deployment Pipeline
    
    DEV->>+GIT: git push (code changes)
    GIT->>-DEV: Push confirmed
    
    DEV->>+DOCKER: ./deploy-gke.sh
    DOCKER->>DOCKER: Validate Prerequisites
    DOCKER->>DOCKER: Setup GCloud Auth
    
    Note over DOCKER,AR: Image Build Process
    DOCKER->>+DOCKER: Build Ollama Image
    Note over DOCKER: FROM ollama/ollama:latest<br/>RUN ollama pull tinyllama
    DOCKER->>-DOCKER: Ollama Image Ready
    
    DOCKER->>+DOCKER: Build Backend Image
    Note over DOCKER: FROM python:3.11<br/>COPY app/ requirements.txt
    DOCKER->>-DOCKER: Backend Image Ready
    
    DOCKER->>+DOCKER: Build Frontend Image
    Note over DOCKER: FROM node:18 (build)<br/>FROM nginx:alpine (serve)
    DOCKER->>-DOCKER: Frontend Image Ready
    
    DOCKER->>+AR: Push Images
    AR->>AR: Store Images with Tags
    AR->>-DOCKER: Push Complete
    
    Note over DOCKER,HPA: Kubernetes Deployment
    DOCKER->>+K8S: kubectl apply -f k8s/rbac.yaml
    K8S->>-DOCKER: RBAC Applied
    
    DOCKER->>+K8S: kubectl apply -f k8s/configmap-cloud.yaml
    K8S->>-DOCKER: ConfigMap Applied
    
    DOCKER->>+K8S: kubectl apply -f k8s/backend-deployment-cloud.yaml
    K8S->>K8S: Schedule Backend Pods
    
    K8S->>+POD: Create Backend Pod
    POD->>+AR: Pull Backend Image
    AR->>-POD: Image Downloaded
    POD->>+AR: Pull Ollama Image
    AR->>-POD: Image Downloaded
    
    Note over POD,OL: Pod Startup Sequence
    POD->>+OL: Start Ollama Container
    OL->>OL: Initialize Ollama Server
    OL->>OL: Load TinyLlama Model (Pre-loaded)
    OL->>-POD: Ollama Ready (15-30 seconds)
    
    POD->>+POD: Start FastAPI Container
    POD->>POD: Initialize FastAPI App
    POD->>+OL: Test Connection (localhost:11434)
    OL->>-POD: Connection Successful
    POD->>-POD: FastAPI Ready
    
    POD->>+K8S: Report Pod Ready
    K8S->>-POD: Readiness Confirmed
    K8S->>-DOCKER: Backend Deployment Complete
    
    DOCKER->>+K8S: kubectl apply -f k8s/frontend-deployment-cloud.yaml
    K8S->>K8S: Schedule Frontend Pods
    K8S->>-DOCKER: Frontend Deployment Complete
    
    DOCKER->>+K8S: kubectl apply -f k8s/hpa-cloud.yaml
    K8S->>+HPA: Create HPA Resources
    HPA->>HPA: Monitor Backend Metrics
    HPA->>-K8S: HPA Active
    K8S->>-DOCKER: HPA Applied
    
    DOCKER->>+K8S: kubectl get services
    K8S->>-DOCKER: External IP Available
    DOCKER->>-DEV: Deployment Complete<br/>App URL: http://EXTERNAL-IP
    
    Note over DEV,HPA: Health Verification
    DEV->>+GKE: curl http://EXTERNAL-IP/health
    GKE->>+POD: Route Health Check
    POD->>+OL: Verify Ollama Status
    OL->>-POD: Status OK
    POD->>-GKE: Health Check Passed
    GKE->>-DEV: 200 OK
    
    Note over DEV,HPA: Auto-scaling Verification
    HPA->>+POD: Monitor CPU/Memory
    POD->>-HPA: Metrics: CPU 30%, Memory 40%
    HPA->>HPA: Within Thresholds (No Scaling)
    
    Note over DEV,HPA: Rolling Update Process
    DEV->>+DOCKER: Deploy New Version
    DOCKER->>+AR: Push Updated Images
    AR->>-DOCKER: Images Updated
    
    DOCKER->>+K8S: kubectl apply (Updated Deployment)
    K8S->>K8S: Rolling Update Strategy
    K8S->>+POD: Create New Pod
    POD->>POD: Start New Version
    POD->>-K8S: New Pod Ready
    K8S->>K8S: Terminate Old Pod
    K8S->>-DOCKER: Rolling Update Complete
    DOCKER->>-DEV: Update Successful
```

These UML diagrams provide comprehensive visualization of:

1. **Component Diagram**: Shows the internal structure and relationships between all system components
2. **Deployment Diagram**: Illustrates the physical deployment architecture on Google Cloud Platform
3. **Sequence Diagrams**: Detail the runtime behavior for both user interactions and deployment processes

The diagrams capture the key architectural decisions including the sidecar pattern, pre-loaded models, auto-scaling mechanisms, and cloud-native deployment strategies. 