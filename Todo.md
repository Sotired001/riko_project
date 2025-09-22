## Vision-Based Desktop Assistant – Project Status & Roadmap
### 1. Agent-run mode (run Riko on another machine and stream video back)

If you prefer to run the assistant on a separate machine (another orchestrator or VM) while keeping development on this machine, use an agent-run + streaming setup. This keeps risky actions off your local desktop while letting you update code here and observe/monitor execution on the agent.


1. On the agent machine, run the in-guest agent that exposes:
    - GET `/status` — health check
    - GET `/screenshot` — returns a base64 JPEG snapshot of the agent display
    - POST `/exec` — accepts an action JSON and logs or executes it on the agent side
    - The agent can be started with `python vm_agent.py --port 8000` (requires Pillow). Ensure the agent machine allows incoming connections on this port (firewall/NSG).

2. On this orchestrator (development machine), configure `AGENT_URL` to point to the agent. Prefer a host-only or private network, or use SSH port forwarding / VPN for encryption.

3. Use polling-based streaming for rapid iteration:
    - The host repeatedly calls `/screenshot` at a controlled rate (e.g., 5–15 FPS).
    - Display frames locally using OpenCV or a simple GUI.
    - This method is higher-latency than native streaming protocols but requires no extra infrastructure.
    - Consider using a lower polling rate (e.g., 1 FPS) for less CPU usage.
    - Implement a mechanism to adjust the polling rate dynamically based on system load.
    - Allow user to configure polling rate via environment variable (e.g., `VM_POLLING_RATE`).
    - Provide feedback on current polling rate and system load.
    - Implement a mechanism to adjust the polling rate dynamically based on system load.
    - Allow user to configure polling rate via environment variable (e.g., `VM_POLLING_RATE`).
    - Provide feedback on current polling rate and system load.

4. Action dispatching:
    - The orchestrator can send intended actions (JSON) to the agent's `/exec` endpoint. Keep `DRY_RUN = True` on the orchestrator until you trust the agent's execution policy.

5. Security considerations:
    - The agent has no authentication by default. Use network-level security (VPN, SSH tunnel, host-only network).
    - Consider adding simple token-based authentication to the API endpoints.

---

Priority checklist (work items)

1) Minimal streaming and control (MVP) — aim: quick working loop
-- [x] Agent runner: ensure endpoints exist — `/status`, `/screenshot`, `/exec` (JSON) and write audit log.
- [x] Local viewer: implement polling viewer that requests `/screenshot` and displays frames (`scripts/vm_stream_viewer.py` already present; verify and harden).
-- [x] Local client: provide `agent_client.py` (or `vm_agent_client.py`) with `get_status()`, `get_screenshot()->PIL.Image`, `exec_action(action:dict, token=None)` and timeouts/retries.
-- [x] Secure by default: require a simple API token header for `/exec`; configure token via env var on agent and orchestrator.

2) Dev-to-run flow: deploy/update agent runner
-- [x] Add a small deploy script (one-liner) that copies/syncs repository to the agent runner and restarts the service (support scp/rsync or Windows copy + agent restart via SSH/WinRM).
- [x] Document the manual developer loop: edit locally -> run tests locally -> push to agent -> restart agent service -> reconnect viewer.

3) Reliability & performance improvements
- [x] Implement exponential backoff & reconnect in viewer/client.
- [x] Optional: add delta-only screenshot extraction (send only changed regions) to reduce bandwidth.
- [x] Optional: ffmpeg-based MJPEG or RTSP streaming for lower-latency if needed.

4) Audit & safety
-- [x] Agent runner must persist an append-only JSONL audit log of received `/exec` entries with timestamp, origin IP, token-id, and full JSON payload.
-- [x] Add a `--dry-run` flag to agent runner that verifies actions but does not execute them; default to dry-run unless explicitly enabled in agent config.

5) Next-phase optional features (defer until MVP done)
- [ ] API authentication via mutual TLS or SSH tunnel (for production-like security).
- [x] Integrated deployment via CI (GitHub Actions job to push to agent runner and restart service).
- [ ] Low-latency streaming via WebSocket MJPEG or RTP/RTSP with per-frame H.264 encoding.

---

Manual developer loop (for item 2.2):

1. Edit code locally in this workspace (e.g., modify `main.py` or add features).
2. Run tests locally if available (e.g., `python -m pytest` or manual smoke tests).
3. Deploy to agent runner: Use `.\scripts\deploy_to_agent.ps1 -AgentHost "agent-ip" -AgentPath "C:\agent_setup"` (copies the `agent_setup` folder).
4. On agent: The deploy script starts `install_agent.bat` automatically, or run it manually if needed.
5. Reconnect viewer: Run `python scripts/vm_stream_viewer.py` on the orchestrator to view the updated agent stream.
6. Iterate: Repeat as needed for rapid dev cycles.

For manual setup: Copy the `agent_setup` folder to the agent machine and run `install_agent.bat`.

For automated deployment, consider adding Git hooks or CI to trigger the deploy script on push.

---

CI Setup Notes (for item 5.2):
-- The workflow in `.github/workflows/deploy.yml` deploys on push to configured branches.
-- Requires GitHub secrets: `AGENT_HOST` (e.g., user@agent-ip), `AGENT_PATH` (e.g., /path/to/riko), `SSH_KEY` (private key for SSH access). For compatibility the workflow still accepts `REMOTE_HOST` and `REMOTE_PATH`.
-- Assumes SSH is set up on the agent machine. For Windows agent, install OpenSSH server.
-- On push, it copies the repo via SCP and runs `install_agent.bat` remotely.

---

_Last edited: 2025-09-21_