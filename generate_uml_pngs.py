#!/usr/bin/env python3
"""
UML Diagram PNG Generator for LLM Chatbot Project
Converts Mermaid diagrams to PNG format for PDF reports
"""

import os
import subprocess
import sys
from pathlib import Path

def check_mermaid_cli():
    """Check if mermaid-cli is installed"""
    try:
        result = subprocess.run(['mmdc', '--version'], capture_output=True, text=True)
        print(f"✅ Mermaid CLI found: {result.stdout.strip()}")
        return True
    except FileNotFoundError:
        print("❌ Mermaid CLI not found. Please install it first:")
        print("npm install -g @mermaid-js/mermaid-cli")
        return False

def create_mermaid_files():
    """Create individual Mermaid files for each diagram"""
    
    # Component Diagram
    component_diagram = """
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
"""

    # Deployment Diagram
    deployment_diagram = """
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
"""

    # Chat Interaction Sequence Diagram
    chat_sequence_diagram = """
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
"""

    # Deployment Process Sequence Diagram
    deployment_sequence_diagram = """
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
"""

    # Create diagrams directory
    diagrams_dir = Path("diagrams")
    diagrams_dir.mkdir(exist_ok=True)
    
    # Write Mermaid files
    diagrams = {
        "component_diagram.mmd": component_diagram,
        "deployment_diagram.mmd": deployment_diagram,
        "chat_sequence_diagram.mmd": chat_sequence_diagram,
        "deployment_sequence_diagram.mmd": deployment_sequence_diagram
    }
    
    for filename, content in diagrams.items():
        filepath = diagrams_dir / filename
        with open(filepath, 'w') as f:
            f.write(content.strip())
        print(f"✅ Created {filepath}")
    
    return diagrams_dir

def generate_png_images(diagrams_dir):
    """Generate PNG images from Mermaid files"""
    
    # Configuration for high-quality PNG output
    config = {
        "theme": "default",
        "themeVariables": {
            "primaryColor": "#ffffff",
            "primaryTextColor": "#000000",
            "primaryBorderColor": "#cccccc",
            "lineColor": "#666666"
        }
    }
    
    # Create config file
    config_file = diagrams_dir / "config.json"
    import json
    with open(config_file, 'w') as f:
        json.dump(config, f, indent=2)
    
    # Generate PNG files
    mermaid_files = list(diagrams_dir.glob("*.mmd"))
    
    for mmd_file in mermaid_files:
        png_file = mmd_file.with_suffix('.png')
        
        # Command to generate PNG with high quality
        cmd = [
            'mmdc',
            '-i', str(mmd_file),
            '-o', str(png_file),
            '-t', 'default',
            '-b', 'white',
            '--width', '1920',
            '--height', '1080',
            '--scale', '2',
            '-c', str(config_file)
        ]
        
        try:
            print(f"🔄 Generating {png_file.name}...")
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            print(f"✅ Generated {png_file}")
        except subprocess.CalledProcessError as e:
            print(f"❌ Error generating {png_file}: {e}")
            print(f"   stdout: {e.stdout}")
            print(f"   stderr: {e.stderr}")
    
    # Clean up config file
    config_file.unlink()

def create_readme():
    """Create README for the diagrams"""
    readme_content = """# UML Diagrams - PNG Format

This directory contains PNG versions of the UML diagrams for the Scalable LLM Chatbot Infrastructure project.

## Generated Diagrams

### 1. Component Diagram (`component_diagram.png`)
- Shows the internal structure and relationships between system components
- Illustrates the multi-tier architecture with Frontend, API Gateway, Model Serving, and Infrastructure layers
- Highlights the sidecar pattern and service interactions

### 2. Deployment Diagram (`deployment_diagram.png`)
- Illustrates the physical deployment architecture on Google Cloud Platform
- Shows GKE cluster configuration with node pools, services, and auto-scaling
- Details resource allocation and networking components

### 3. Chat Sequence Diagram (`chat_sequence_diagram.png`)
- Details the runtime behavior for user chat interactions
- Shows WebSocket connection flow, message processing, and model inference
- Includes auto-scaling triggers and error handling scenarios

### 4. Deployment Sequence Diagram (`deployment_sequence_diagram.png`)
- Shows the CI/CD pipeline and infrastructure provisioning process
- Details container build, image push, and Kubernetes deployment steps
- Includes health verification and rolling update processes

## Usage in PDF Reports

These PNG files are optimized for inclusion in PDF reports with:
- High resolution (1920x1080 with 2x scaling)
- White background for print compatibility
- Clear text and diagram elements
- Professional color scheme

## Regenerating Diagrams

To regenerate the PNG files:

1. Install Mermaid CLI:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. Run the generator script:
   ```bash
   python3 generate_uml_pngs.py
   ```

## File Sizes and Quality

The generated PNG files are optimized for:
- Print quality (300 DPI equivalent)
- Web display compatibility
- Reasonable file sizes for document inclusion
- Clear readability at various zoom levels
"""
    
    with open("diagrams/README.md", 'w') as f:
        f.write(readme_content)
    print("✅ Created diagrams/README.md")

def main():
    """Main function to generate UML diagrams as PNG files"""
    print("🚀 UML Diagram PNG Generator for LLM Chatbot Project")
    print("=" * 60)
    
    # Check prerequisites
    if not check_mermaid_cli():
        print("\n📋 Installation Instructions:")
        print("1. Install Node.js: https://nodejs.org/")
        print("2. Install Mermaid CLI: npm install -g @mermaid-js/mermaid-cli")
        print("3. Run this script again")
        sys.exit(1)
    
    # Create Mermaid files
    print("\n📝 Creating Mermaid diagram files...")
    diagrams_dir = create_mermaid_files()
    
    # Generate PNG images
    print("\n🖼️  Generating PNG images...")
    generate_png_images(diagrams_dir)
    
    # Create README
    print("\n📚 Creating documentation...")
    create_readme()
    
    print("\n🎉 PNG generation complete!")
    print(f"📁 Diagrams saved in: {diagrams_dir.absolute()}")
    print("\n📋 Generated files:")
    for png_file in diagrams_dir.glob("*.png"):
        file_size = png_file.stat().st_size / 1024 / 1024  # MB
        print(f"   • {png_file.name} ({file_size:.1f} MB)")
    
    print("\n💡 These PNG files are ready for inclusion in PDF reports!")

if __name__ == "__main__":
    main() 