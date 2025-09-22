"""
vm_agent_client.py

Host-side client for communicating with the in-guest agent.
Provides simple wrappers: get_status(), get_screenshot(), exec_action()

Usage (host):
from external_reused.vm_agent_client import VMAgentClient
import os
# Prefer new AGENT_* env vars but fall back to older names for compatibility
base = os.getenv('AGENT_URL') or os.getenv('VM_AGENT_URL') or os.getenv('HOST_AGENT_URL') or os.getenv('REMOTE_AGENT_URL') or 'http://127.0.0.1:8000'
token = os.getenv('AGENT_API_TOKEN') or os.getenv('REMOTE_API_TOKEN')
client = VMAgentClient(base, api_token=token)
print(client.get_status())
img = client.get_screenshot()

Note: Keep network access restricted. Prefer host-only network or loopback with port forwarding.
"""

import requests
import base64
from PIL import Image
import io

class VMAgentClient:
    def __init__(self, base_url: str, api_token: str = None):
        self.base_url = base_url.rstrip('/')
        # optional API token used for /exec requests
        self.api_token = api_token

    def get_status(self):
        try:
            r = requests.get(f"{self.base_url}/status", timeout=5)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            return {'error': str(e)}

    def get_screenshot(self):
        try:
            r = requests.get(f"{self.base_url}/screenshot", timeout=10)
            r.raise_for_status()
            data = r.json()
            if 'image' in data:
                img_bytes = base64.b64decode(data['image'])
                return Image.open(io.BytesIO(img_bytes))
            return {'error': 'no image in response'}
        except Exception as e:
            return {'error': str(e)}

    def exec_action(self, action: dict):
        try:
            headers = {}
            if self.api_token:
                headers['Authorization'] = f"Bearer {self.api_token}"
            r = requests.post(f"{self.base_url}/exec", json=action, timeout=5, headers=headers)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            return {'error': str(e)}
