# Riko AI Orchestrator - AI Coding Assistant Instructions

## Architecture Overview
Riko AI is a vision-based desktop assistant with a client-server architecture:
- **Riko Orchestrator** (this repo): Main AI system running on the orchestrator machine
- **Riko Agent** (separate repo): Agent control interface and client

Communication via HTTP API endpoints:
- `GET /status` - Health check
- `GET /screenshot` - Returns base64 JPEG snapshot
-- `POST /exec` - Accepts action JSON and executes on agent side

## Development Workflow
Use **agent-run mode** for development: Run agent on a separate machine/VM, stream video back to the orchestrator for safe iteration.

### Agent-Run Setup
1. Deploy `agent_setup` folder to agent machine using `scripts/deploy_to_agent.ps1`
2. Run `scripts/install_agent.bat` on agent to start the agent process
3. Use `external_reused/vm_agent_client.py` on the orchestrator to communicate
4. Poll `/screenshot` at 5-15 FPS for video streaming

### Deployment
-- Manual: `.\scripts\deploy_to_agent.ps1 -AgentHost "agent-ip" -AgentPath "C:\agent_setup"`
- CI/CD: GitHub Actions deploys on push to configured branches via SCP

## Key Patterns & Conventions

### Security & Safety
-- Require API token header for `/exec` endpoint (set via `AGENT_API_TOKEN` env var; `REMOTE_API_TOKEN` accepted for compatibility)
-- Enable `--dry-run` flag on agent to verify actions without execution
-- Persist append-only JSONL audit log of all `/exec` entries with timestamp, IP, token, full JSON

### Vision Processing
- Use `external_reused/vision_utils.py` for OCR, screen capture, image encoding
- OCR caching with similarity-based LRU cache (max 50 entries, 90% threshold)
- Screen capture via `mss` library for performance
- Lazy Tesseract import to avoid binary dependency issues

### Agent Communication
- Polling-based streaming instead of WebSocket/RTP for simplicity and firewall compatibility
- Exponential backoff & reconnect in clients for reliability
- Timeouts: 5s for status/exec, 10s for screenshots

### Code Organization
- Shared utilities in `external_reused/` folder (safe to import, no side effects)
- PowerShell scripts for Windows deployment and VM checks
-- Separate repos: Orchestrator (AI logic) ↔ Agent (control interface)

## Integration Points
-- **riko-agent repo**: Client interface for screenshot viewing and action dispatching
- **VirtualBox**: Optional VM management (see `scripts/vm_checks.ps1`)
- **Tesseract OCR**: For text extraction from screenshots
- **OpenCV**: Optional for advanced image processing

## Common Tasks
- **Add new action type**: Extend JSON schema in `/exec` endpoint, update audit logging
- **Improve vision**: Modify `vision_utils.py` functions, test with cached OCR
- **Deploy updates**: Run deploy script or push to trigger CI/CD
-- **Debug agent**: Check audit logs, use dry-run mode, verify token auth

## File Reference Examples
- `external_reused/vm_agent_client.py`: Client wrapper for agent API calls (accepts `AGENT_API_TOKEN` or `REMOTE_API_TOKEN`)
- `scripts/deploy_to_agent.ps1`: PowerShell deployment to agent host
- `scripts/install_agent.bat`: One-click agent setup (installs Python, dependencies)
- `.github/workflows/deploy.yml`: CI/CD deployment on push</content>
<parameter name="filePath">c:\Users\ninja\Documents\Riko Host\.github\copilot-instructions.md