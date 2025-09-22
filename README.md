# Riko AI - General Use Host

A comprehensive AI assistant system designed to run on a host machine with remote control capabilities.

## Overview

Riko AI is an intelligent assistant that can be controlled remotely through a dedicated control interface. The system is split into two main components:

- **Riko AI (Host)**: The main AI system running on the host machine
- **Riko Remote**: Remote control interface for accessing the host system

## Features

- 🤖 **AI-Powered Assistant**: Intelligent conversation and task execution
- 🖥️ **Remote Control**: Access and control the host machine remotely
- 🔄 **Auto-Updates**: Automatic system updates for both host and remote components
- 🔒 **Secure Communication**: Token-based authentication for remote access
- 📊 **Real-time Monitoring**: Live screenshot streaming and system status

## Architecture

```
┌─────────────────┐    HTTP API    ┌──────────────────┐
│   Remote Control │◄─────────────►│   Riko AI Host   │
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
- Windows OS (for host machine)
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

3. **Set up remote control (optional):**
   ```bash
   # Clone the remote control repository
   git clone https://github.com/Sotired001/Riko-Remote.git
   cd Riko-Remote
   pip install -r requirements.txt
   ```

### Running Riko AI

1. **Start the AI host:**
   ```bash
   python main.py
   ```

2. **Configure remote access (optional):**
   - Set environment variable: `REMOTE_API_TOKEN=your-secure-token`
   - Start remote control interface from the Riko-Remote repository

## Configuration

### Environment Variables

- `REMOTE_API_TOKEN`: Secure token for remote API access (required for remote control)
- `HOST_AGENT_URL`: URL of the remote control agent (default: http://127.0.0.1:8000)

### Security

- Always set a strong, unique `REMOTE_API_TOKEN`
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

## Remote Control Integration

The Riko AI system integrates with the Riko-Remote repository for remote control capabilities:

- **Repository**: [Riko-Remote](https://github.com/Sotired001/Riko-Remote)
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

**Note**: This system provides remote control capabilities. Use responsibly and only on machines you have permission to control.