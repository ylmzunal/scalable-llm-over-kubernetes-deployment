#!/bin/bash

# UML Diagram PNG Generator for LLM Chatbot Project
# Converts Mermaid diagrams to PNG format for PDF reports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if mermaid-cli is installed
check_mermaid_cli() {
    if ! command -v mmdc &> /dev/null; then
        print_error "Mermaid CLI not found. Please install it first:"
        echo "npm install -g @mermaid-js/mermaid-cli"
        exit 1
    fi
    
    local version=$(mmdc --version)
    print_success "Mermaid CLI found: $version"
}

# Create diagrams directory
create_diagrams_dir() {
    mkdir -p diagrams
    print_status "Created diagrams directory"
}

# Generate PNG from Mermaid file
generate_png() {
    local mmd_file=$1
    local png_file="${mmd_file%.mmd}.png"
    
    print_status "Generating $(basename $png_file)..."
    
    mmdc \
        -i "$mmd_file" \
        -o "$png_file" \
        -t default \
        -b white \
        --width 1920 \
        --height 1080 \
        --scale 2
    
    if [ $? -eq 0 ]; then
        print_success "Generated $(basename $png_file)"
        
        # Show file size
        if command -v du &> /dev/null; then
            local size=$(du -h "$png_file" | cut -f1)
            echo "   File size: $size"
        fi
    else
        print_error "Failed to generate $(basename $png_file)"
    fi
}

# Main function
main() {
    echo "🚀 UML Diagram PNG Generator for LLM Chatbot Project"
    echo "============================================================"
    
    # Check prerequisites
    check_mermaid_cli
    
    # Create output directory
    create_diagrams_dir
    
    # Check if Mermaid files exist
    if [ ! -f "uml_diagrams.md" ]; then
        print_error "uml_diagrams.md not found. Please ensure the file exists."
        exit 1
    fi
    
    print_status "Found UML diagrams markdown file"
    
    # Extract and create individual Mermaid files
    print_status "Extracting Mermaid diagrams..."
    
    # Use awk to extract mermaid code blocks and create separate files
    awk '
    /^```mermaid/ { 
        in_mermaid = 1
        diagram_count++
        if (diagram_count == 1) filename = "diagrams/component_diagram.mmd"
        else if (diagram_count == 2) filename = "diagrams/deployment_diagram.mmd"
        else if (diagram_count == 3) filename = "diagrams/chat_sequence_diagram.mmd"
        else if (diagram_count == 4) filename = "diagrams/deployment_sequence_diagram.mmd"
        next
    }
    /^```$/ && in_mermaid { 
        in_mermaid = 0
        close(filename)
        next
    }
    in_mermaid { 
        print $0 > filename
    }
    ' uml_diagrams.md
    
    # Generate PNG files
    print_status "Generating PNG images..."
    
    for mmd_file in diagrams/*.mmd; do
        if [ -f "$mmd_file" ]; then
            generate_png "$mmd_file"
        fi
    done
    
    # Create README
    print_status "Creating documentation..."
    cat > diagrams/README.md << 'EOF'
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
   ./generate_diagrams.sh
   ```

## File Sizes and Quality

The generated PNG files are optimized for:
- Print quality (300 DPI equivalent)
- Web display compatibility
- Reasonable file sizes for document inclusion
- Clear readability at various zoom levels
EOF

    print_success "Created diagrams/README.md"
    
    # Summary
    echo
    print_success "PNG generation complete!"
    echo "📁 Diagrams saved in: $(pwd)/diagrams"
    echo
    echo "📋 Generated files:"
    for png_file in diagrams/*.png; do
        if [ -f "$png_file" ]; then
            local basename_file=$(basename "$png_file")
            if command -v du &> /dev/null; then
                local size=$(du -h "$png_file" | cut -f1)
                echo "   • $basename_file ($size)"
            else
                echo "   • $basename_file"
            fi
        fi
    done
    
    echo
    print_success "💡 These PNG files are ready for inclusion in PDF reports!"
}

# Run main function
main "$@" 