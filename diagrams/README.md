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

# Autoscaling Diagrams for Poster Presentation

This directory contains comprehensive autoscaling diagrams for your LLM chatbot project poster presentation. Each diagram serves a specific purpose and can be used individually or combined for different sections of your poster.

## 📊 Available Diagrams

### 1. `autoscaling_diagram.mmd` - Complete Architecture
**Purpose**: Main architecture diagram showing all components and their relationships
**Best for**: Technical audience, architecture overview section
**Key Features**:
- Shows all 3 tiers: Frontend, Backend, Node scaling
- Detailed HPA configurations
- Monitoring and metrics flow
- Scaling triggers and behaviors

### 2. `autoscaling_flow_diagram.mmd` - Process Flow
**Purpose**: Step-by-step process of how autoscaling works
**Best for**: Explaining the autoscaling logic, educational presentations
**Key Features**:
- Decision tree for scaling actions
- Timing windows and stabilization
- Real-world example scenario
- Color-coded states (normal, warning, critical)

### 3. `autoscaling_metrics_dashboard.mmd` - Metrics Dashboard
**Purpose**: Real-time monitoring and metrics visualization
**Best for**: Performance section, demonstrating monitoring capabilities
**Key Features**:
- Live metrics examples
- Alert states and triggers
- Historical trends
- Predictive scaling insights

### 4. `poster_autoscaling_diagram.mmd` - Simplified for Poster
**Purpose**: Clean, poster-ready diagram optimized for printing
**Best for**: Main poster diagram, general audience
**Key Features**:
- Simplified visual design
- Key metrics and results highlighted
- High contrast colors for printing
- Easy to read at poster size

### 5. `scaling_timeline_diagram.mmd` - Timeline View
**Purpose**: Shows scaling behavior over time during load testing
**Best for**: Results section, demonstrating scaling effectiveness
**Key Features**:
- Gantt chart format
- Load patterns vs scaling response
- Performance and cost correlation
- Timeline of scaling events

## 🎨 Converting to Images

### Using Mermaid CLI
```bash
# Install mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Convert to PNG (high resolution for printing)
mmdc -i autoscaling_diagram.mmd -o autoscaling_diagram.png -w 3000 -H 2000 --backgroundColor white

# Convert to SVG (vector graphics, scalable)
mmdc -i autoscaling_diagram.mmd -o autoscaling_diagram.svg --backgroundColor white

# Convert all diagrams
for file in *.mmd; do
    mmdc -i "$file" -o "${file%.mmd}.png" -w 3000 -H 2000 --backgroundColor white
done
```

### Using Online Tools
1. **Mermaid Live Editor**: https://mermaid.live/
   - Paste diagram code
   - Download as PNG/SVG
   - Adjust theme and size

2. **GitHub Mermaid Rendering**:
   - Commit diagrams to GitHub
   - View rendered in README
   - Right-click to save images

## 📐 Poster Layout Recommendations

### Main Architecture Section (Bottom Center)
**Use**: `poster_autoscaling_diagram.mmd`
**Size**: 8" × 6" (landscape)
**DPI**: 300 for printing
**Colors**: High contrast, printer-friendly

### Process Flow Section (Bottom Right)
**Use**: `autoscaling_flow_diagram.mmd` (simplified version)
**Size**: 6" × 8" (portrait)
**Focus**: Key decision points and timing

### Results Section (Bottom Left)
**Use**: `scaling_timeline_diagram.mmd`
**Size**: 8" × 4" (landscape)
**Focus**: Performance metrics and cost savings

### Technical Innovation Section
**Use**: Selected parts from `autoscaling_metrics_dashboard.mmd`
**Focus**: HPA configuration details, monitoring setup

## 🎯 Customization for Different Audiences

### For Technical Audience
- Use `autoscaling_diagram.mmd` with full technical details
- Include configuration snippets
- Show actual resource specifications
- Highlight sidecar pattern and pre-loaded models

### For Business Audience
- Use `poster_autoscaling_diagram.mmd` focused on results
- Emphasize cost savings ($75-100 vs $500+)
- Highlight 80% cost reduction
- Show scaling efficiency and availability

### For Academic Audience
- Combine `autoscaling_flow_diagram.mmd` with metrics
- Focus on algorithmic approach
- Include stabilization windows and policies
- Show research implications

## 🖨️ Printing Guidelines

### Color Scheme
- **Primary**: Deep blue (#1976d2) - headers and main flow
- **Secondary**: Green (#4caf50) - normal states and success
- **Warning**: Orange (#ff9800) - scaling states
- **Critical**: Red (#f44336) - alerts and high load
- **Background**: White - for print clarity

### Font Sizes (for 36" × 48" poster)
- **Main diagram text**: 14-16pt minimum
- **Labels**: 12-14pt minimum
- **Annotations**: 10-12pt minimum
- **Test print at 25% to verify readability**

### Resolution Settings
- **Minimum**: 300 DPI for printing
- **Recommended**: 600 DPI for professional quality
- **Vector formats (SVG)**: Preferred for scalability

## 🔧 Customization Options

### Modifying Configurations
To update the HPA settings in diagrams, edit these sections:
```mermaid
BE_HPA[📊 Backend HPA<br/>Min: 1, Max: 3<br/>CPU: 60%, Memory: 70%]
```

### Changing Metrics
Update the metrics values in `autoscaling_metrics_dashboard.mmd`:
```mermaid
BE_CPU[📈 Backend CPU<br/>Current: 65%<br/>Target: < 60%<br/>Status: ⚠️ High]
```

### Color Themes
Modify the classDef sections:
```mermaid
classDef backend fill:#f1f8e9,stroke:#388e3c,stroke-width:2px
```

## 📝 Integration with Poster

### QR Code Integration
Add QR codes that link to:
- Interactive Mermaid diagrams online
- Live monitoring dashboard (if available)
- GitHub repository with full diagrams
- Demo website showing scaling in action

### Animation for Digital Display
For digital presentations, consider:
- Highlighting scaling paths with animations
- Progressive disclosure of complexity
- Interactive exploration of different load scenarios

## 🎪 Demonstration Scripts

### Live Demo Flow
1. Start with `poster_autoscaling_diagram.mmd` - show overall architecture
2. Transition to `autoscaling_flow_diagram.mmd` - explain process
3. Show `scaling_timeline_diagram.mmd` - demonstrate real results
4. End with metrics from `autoscaling_metrics_dashboard.mmd`

### Key Talking Points
- **Pre-loaded models**: Zero cold start (15-30s vs 5-15min)
- **Cost optimization**: $75-100 vs $500+ monthly
- **Intelligent scaling**: CPU/Memory thresholds with stabilization
- **Three-tier scaling**: Frontend, Backend, Node levels
- **Production ready**: 99.9% availability, auto-recovery

## 🔍 Troubleshooting

### Diagram Not Rendering
- Check Mermaid syntax
- Verify quotes and brackets are balanced
- Test in Mermaid Live Editor first

### Poor Print Quality
- Increase resolution (width/height parameters)
- Use vector formats (SVG) when possible
- Test print at small scale first

### Text Too Small
- Increase font sizes in node definitions
- Reduce diagram complexity
- Split into multiple simpler diagrams

## 📚 Additional Resources

- [Mermaid Documentation](https://mermaid-js.github.io/mermaid/)
- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Poster Design Best Practices](https://www.makesigns.com/SciPosters_Effective.aspx)
- [Scientific Poster Guidelines](https://guides.nyu.edu/posters)
