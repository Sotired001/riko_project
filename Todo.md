## Vision-Based Desktop Assistant – Project Status & Roadmap
### 1. Remote-run mode (run Riko on another machine and stream video back)

If you prefer to run the assistant on a separate machine (another host or VM) while keeping development on this machine, use a remote-run + streaming setup. This keeps risky actions off your local desktop while letting you update code here and observe/monitor execution remotely.


1. On the remote machine, run the in-guest (remote) agent that exposes:
    - GET `/status` — health check
    - GET `/screenshot` — returns a base64 JPEG snapshot of the remote display
    - POST `/exec` — accepts an action JSON and logs or executes it on the remote side
    - The remote agent can be started with `python vm_agent.py --port 8000` (requires Pillow). Ensure the remote machine allows incoming connections on this port (firewall/NSG).

2. On this host (development machine), configure `VM_AGENT_URL` (or `REMOTE_AGENT_URL`) to point to the remote agent. Prefer a host-only or private network, or use SSH port forwarding / VPN for encryption.

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
    - The host can send intended actions (JSON) to the remote machine's `/exec` endpoint. Keep `DRY_RUN = True` on the host until you trust the remote agent's execution policy.

5. Security considerations:
    - The remote agent has no authentication by default. Use network-level security (VPN, SSH tunnel, host-only network).
    - Consider adding simple token-based authentication to the API endpoints.

---

Priority checklist (work items)

1) Minimal streaming and control (MVP) — aim: quick working loop
- [x] Remote agent: ensure endpoints exist — `/status`, `/screenshot`, `/exec` (JSON) and write audit log.
- [x] Local viewer: implement polling viewer that requests `/screenshot` and displays frames (`scripts/vm_stream_viewer.py` already present; verify and harden).
- [x] Local client: provide `remote_agent_client.py` with `get_status()`, `get_screenshot()->PIL.Image`, `exec_action(action:dict, token=None)` and timeouts/retries.
- [x] Secure by default: require a simple API token header for `/exec`; configure token via env var on remote and local.

2) Dev-to-run flow: deploy/update remote runner
- [x] Add a small deploy script (one-liner) that copies/syncs repository to the remote runner and restarts the service (support scp/rsync or Windows copy + remote restart via SSH/WinRM).
- [x] Document the manual developer loop: edit locally -> run tests locally -> push to remote -> restart remote service -> reconnect viewer.

3) Reliability & performance improvements
- [x] Implement exponential backoff & reconnect in viewer/client.
- [x] Optional: add delta-only screenshot extraction (send only changed regions) to reduce bandwidth.
- [x] Optional: ffmpeg-based MJPEG or RTSP streaming for lower-latency if needed.

4) Audit & safety
- [x] Remote runner must persist an append-only JSONL audit log of received `/exec` entries with timestamp, origin IP, token-id, and full JSON payload.
- [x] Add a `--dry-run` flag to remote runner that verifies actions but does not execute them; default to dry-run unless explicitly enabled in remote config.

5) Next-phase optional features (defer until MVP done)
- [ ] API authentication via mutual TLS or SSH tunnel (for production-like security).
- [x] Integrated deployment via CI (GitHub Actions job to push to remote runner and restart service).
- [ ] Low-latency streaming via WebSocket MJPEG or RTP/RTSP with per-frame H.264 encoding.

---

Manual developer loop (for item 2.2):

1. Edit code locally in this workspace (e.g., modify `main.py` or add features).
2. Run tests locally if available (e.g., `python -m pytest` or manual smoke tests).
3. Deploy to remote runner: Use `.\scripts\deploy_to_remote.ps1 -RemoteHost "remote-ip" -RemotePath "C:\remote_setup"` (copies the `remote_setup` folder).
4. On remote: The deploy script starts `install_remote.bat` automatically, or run it manually if needed.
5. Reconnect viewer: Run `python scripts/vm_stream_viewer.py` on host to view the updated remote stream.
6. Iterate: Repeat as needed for rapid dev cycles.

For manual setup: Copy the `remote_setup` folder to the remote machine and run `install_remote.bat`.

For automated deployment, consider adding Git hooks or CI to trigger the deploy script on push.

---

CI Setup Notes (for item 5.2):
- The workflow in `.github/workflows/deploy.yml` deploys on push to configured branches.
- Requires GitHub secrets: `REMOTE_HOST` (e.g., user@remote-ip), `REMOTE_PATH` (e.g., /path/to/riko), `SSH_KEY` (private key for SSH access).
- Assumes SSH is set up on the remote machine. For Windows remote, install OpenSSH server.
- On push, it copies the repo via SCP and runs `install_remote.bat` remotely.

---

_Last edited: 2025-09-21_