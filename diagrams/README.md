# UML Diagrams - PNG Format

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
