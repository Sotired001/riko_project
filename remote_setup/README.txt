Remote Agent Setup
==================

This folder contains everything needed to set up the remote agent on a Windows machine.

Files:
- vm_agent.py: The remote agent script.
- install_remote.bat: One-click installer that installs Python (if needed) and starts the agent.

Instructions:
1. Copy this entire folder to the remote Windows machine.
2. Double-click install_remote.bat to install and start the agent.
3. The agent will run on port 8000, providing /status, /screenshot, /stream, and /exec endpoints.
   - It will print the URL, e.g., "VM agent running on http://0.0.0.0:8000 (local IP: 192.168.1.100)"
   - To find the remote machine's IP: Open Command Prompt on remote and run `ipconfig` (look for IPv4 Address under your network adapter).
4. The agent will automatically check for code updates every 5 minutes and restart if new code is available (requires Git).

For host-side viewing:
- On the host machine, set the environment variable: $env:VM_AGENT_URL = 'http://<remote-ip>:8000'
- Run the viewer: python scripts/vm_stream_viewer.py
- This will open a window showing the remote screen in real-time.
- Press 'q' to quit the viewer.

For actions:
- The host can send commands to the remote via /exec (logged in dry-run mode by default).

Security:
- The agent runs in dry-run mode (logs actions without executing).
- Use --no-dry-run to enable live execution (dangerous, only in isolated environments).
- Optionally set REMOTE_API_TOKEN for authentication.

For deployment:
- Use the host's deploy_to_remote.ps1 to copy this folder automatically.