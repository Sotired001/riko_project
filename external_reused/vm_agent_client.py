"""
vm_agent_client.py

Host-side client for communicating with the in-guest VM agent.
Provides simple wrappers: get_status(), get_screenshot(), exec_action()

Usage (host):
from external_reused.vm_agent_client import VMAgentClient
client = VMAgentClient('http://192.168.56.101:8000')  # replace with your VM IP
print(client.get_status())
img = client.get_screenshot()

Note: Keep network access restricted. Prefer host-only network or loopback with port forwarding.
"""

import requests
import base64
from PIL import Image
import io

class VMAgentClient:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')

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
            r = requests.post(f"{self.base_url}/exec", json=action, timeout=5)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            return {'error': str(e)}
