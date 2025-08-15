# Ragdoll Demo Documentation

Welcome to the Ragdoll Demo documentation. This directory contains comprehensive documentation for understanding, using, and deploying the Ragdoll Demo application - a full-featured Rails application that demonstrates the complete capabilities of the Ragdoll document processing and semantic search system.

## Quick Start

The Ragdoll Demo is a Rails 8.0.2+ application that showcases intelligent document processing, vector embeddings, and semantic search capabilities. To get started quickly:

```bash
./bin/dev
```

Then visit `http://localhost:3000` to explore the application.

## Documentation Overview

### 📖 For Users

- **[User Manual](user_manual.md)** - Complete workflow tutorial with screenshots showing how to upload documents, monitor processing, and perform semantic searches
- **[Overview](overview.md)** - High-level summary of features and capabilities demonstrated by the application

### 🔧 For Administrators

- **[Cleanup Temp Files](cleanup_temp_files.md)** - Automated and manual cleanup procedures for temporary upload files

### 📸 Screenshots

The `images/` directory contains comprehensive screenshots documenting:
- Complete workflow from empty system to working search
- All major interface components and features
- Processing status indicators and job monitoring
- Search results and analytics dashboards

## What Ragdoll Demo Demonstrates

The Ragdoll Demo application is a comprehensive showcase of the Ragdoll ecosystem, demonstrating:

### Core Ragdoll Capabilities

- **Document Processing**: Intelligent text extraction, chunking, and metadata generation
- **Vector Embeddings**: Automatic generation of semantic embeddings for search
- **Semantic Search**: Natural language queries that understand context and meaning
- **Multi-format Support**: PDF, Word, Markdown, HTML, and text document processing

### Rails Integration Features

- **ragdoll-rails Engine**: Complete Rails integration with generators and helpers
- **Background Processing**: SolidQueue-based asynchronous document processing
- **Real-time Monitoring**: Live status updates and progress tracking
- **ViewComponent Architecture**: Modern, component-based UI development

### Production-Ready Features

- **Background Jobs**: Scalable processing with queue management
- **Error Handling**: Graceful failure management and retry mechanisms
- **Configuration Management**: Multi-provider LLM and embedding service support
- **Analytics Dashboard**: Comprehensive usage and performance metrics
- **API Integration**: RESTful endpoints for programmatic access

### Technical Architecture

- **Rails 8.0.2+** with modern Rails features
- **PostgreSQL** with pgvector extension for vector storage
- **SolidQueue** for background job processing
- **Hotwire (Turbo + Stimulus)** for interactive features
- **ViewComponent** for reusable UI components
- **Bootstrap** for responsive design

## Getting Started

### Prerequisites

- Ruby 3.4.4+
- Rails 8.0.2+
- PostgreSQL with pgvector extension
- Node.js for asset compilation

### Installation

1. **Start the application**:
   ```bash
   ./bin/dev
   ```

2. **Access the application**:
   - Main interface: http://localhost:3000
   - Job monitoring: http://localhost:3000/jobs

3. **Follow the workflow**: See the [User Manual](user_manual.md) for a complete step-by-step tutorial

## Use Cases Demonstrated

### Document Management
- Upload and process various document formats
- Automatic metadata extraction and keyword generation
- Bulk document operations and batch processing
- Document status tracking and reprocessing capabilities

### Semantic Search
- Natural language query processing
- Context-aware search results with relevance scoring
- Search history and analytics tracking
- Export capabilities for search results

### System Administration
- Background job monitoring and management
- Configuration management for LLM providers
- System health monitoring and analytics
- Automated cleanup and maintenance procedures

### API Integration
- RESTful endpoints for document management
- Search API with various query options
- Analytics data access for reporting
- Configuration management via API

## Integration Examples

The demo shows how to integrate Ragdoll into various scenarios:

### Content Management Systems
- Document libraries with intelligent search
- Knowledge bases with semantic capabilities
- Research platforms with contextual discovery

### Enterprise Applications
- Internal documentation systems
- Customer support knowledge bases
- Research and development platforms

### Educational Platforms
- Course material search and discovery
- Research paper organization and search
- Student resource management

## Performance Characteristics

The demo application demonstrates:

- **Processing Speed**: Efficient document chunking and embedding generation
- **Search Performance**: Fast semantic search across large document collections
- **Scalability**: Background job processing for handling large document volumes
- **Reliability**: Error handling and retry mechanisms for robust operation

## Next Steps

After exploring the demo:

1. **Try Different Documents**: Upload various file types and sizes
2. **Experiment with Search**: Test different query types and natural language patterns
3. **Monitor Processing**: Use the jobs dashboard to understand processing flow
4. **Explore Configuration**: Try different LLM and embedding providers
5. **Review Code**: Examine the Rails integration patterns and best practices

## Development and Customization

The demo serves as a reference implementation for:

- **Rails Integration Patterns**: How to use ragdoll-rails in your applications
- **Background Processing**: Implementing scalable document processing workflows
- **UI Components**: Building user interfaces for document management and search
- **API Design**: Creating RESTful interfaces for Ragdoll functionality

## Support and Resources

- **Main Ragdoll Documentation**: See the ragdoll-docs submodule
- **Rails Integration Guide**: Refer to ragdoll-rails documentation
- **CLI Tools**: Explore ragdoll-cli for command-line operations
- **Issue Reporting**: Use the GitHub repositories for each component

---

This demo application represents the culmination of the Ragdoll ecosystem, showing how all components work together to create a powerful, intelligent document processing and search platform.