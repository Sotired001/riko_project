# Riko AI - Riko Orchestrator

A comprehensive AI assistant system designed to run on an orchestrator machine with agent control capabilities.

## Overview

Riko AI is an intelligent assistant that can be controlled remotely through a dedicated control interface. The system is split into two main components:

- **Riko Orchestrator** (formerly "Riko Host"): The main AI system running on the orchestrator machine
- **Riko Agent** (formerly "Riko Remote"): Agent control interface for accessing target systems

## Features

- 🤖 **AI-Powered Assistant**: Intelligent conversation and task execution
- 🖥️ **Agent Control**: Access and control target machines via agents
- 🔄 **Auto-Updates**: Automatic system updates for both orchestrator and agent components
- 🔒 **Secure Communication**: Token-based authentication for agent access
- 📊 **Real-time Monitoring**: Live screenshot streaming and system status

## Architecture

```
┌─────────────────┐    HTTP API    ┌──────────────────┐
│   Agent Control │◄─────────────►│   Riko Orchestrator   │
│   (Client)      │                │   (Server)       │
│                 │                │                  │
│ - Control UI    │                │ - AI Assistant   │
│ - Video Stream  │                │ - Action Exec    │
│ - Live Monitor  │                │ - Auto Updates   │
└─────────────────┘                └──────────────────┘
```

## Quick Start

### Prerequisites

- Python 3.8+
- Windows OS (for orchestrator machine)
- Internet connection for updates

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Sotired001/riko_project.git
   cd riko_project
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up agent control (optional):**
   ```bash
   # Clone the agent control repository (formerly Riko-Remote)
   git clone https://github.com/Sotired001/riko-agent.git
   cd riko-agent
   pip install -r requirements.txt
   ```

### Running Riko AI

1. **Start the orchestrator:**
   ```bash
   python main.py
   ```

2. **Configure agent access (optional):**
   - Set environment variable: `AGENT_API_TOKEN=your-secure-token` (the code will also accept `REMOTE_API_TOKEN` for compatibility)
   - Start agent interface from the `riko-agent` repository

## Configuration

### Environment Variables

- `AGENT_API_TOKEN`: Secure token for agent API access (required for agent control). `REMOTE_API_TOKEN` is accepted for backward compatibility.
- `AGENT_URL`: URL of the agent (default: http://127.0.0.1:8000)

### Security

- Always set a strong, unique `AGENT_API_TOKEN`
- Run on trusted networks only
- Keep both repositories updated for security patches

## Project Structure

```
riko_project/
├── scripts/              # Utility scripts
├── external_reused/      # Shared components
├── .github/             # GitHub Actions and templates
├── Todo.md              # Development roadmap
└── README.md            # This file
```

## Agent Control Integration

The Riko Orchestrator integrates with the `riko-agent` repository for agent control capabilities:

- **Repository**: [riko-agent](https://github.com/Sotired001/riko-agent)
- **Features**: Screenshot capture, mouse/keyboard control, live streaming
- **Security**: Token-based authentication, rate limiting, audit logging

## Development

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

### Testing

```bash
# Run tests
python -m pytest

# Run with coverage
python -m pytest --cov=.
```

## License

This project is for educational and personal use. See individual component licenses for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/Sotired001/riko_project/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Sotired001/riko_project/discussions)

---

**Note**: This system provides agent control capabilities. Use responsibly and only on machines you have permission to control.

## Migration note

This repository is transitioning terminology from "host/remote" to "orchestrator/agent". Code accepts old environment variable names (`REMOTE_API_TOKEN`) for backward compatibility for at least one release cycle. Prefer the new names (`AGENT_API_TOKEN`, `riko-agent`) for new deployments and scripts.