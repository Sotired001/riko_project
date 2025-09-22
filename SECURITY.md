# Security & Secrets

This repository contains code for both the Orchestrator and Agent components. Follow these OpSec recommendations:

- Never commit private keys, certificates, or credentials to the repository. Use GitHub Secrets for CI.
- Store runtime secrets (tokens, SSH private keys) in GitHub repository or organization Secrets and reference them from workflows.
- Rotate any exposed secret immediately (see below) and revoke affected tokens/keys.

Rotation steps if a secret was exposed:
1. Identify the secret type (SSH key, API token, AWS key).
2. Revoke or rotate the credential in the provider's console (GitHub, AWS, etc.).
3. Replace the secret value in GitHub Secrets and CI configuration.
4. Remove the secret from git history (if necessary) using BFG or git-filter-repo, then force-push to the repo (coordinate with all contributors).
5. Rotate any dependent credentials or sessions.

Recommended storage:
- GitHub Actions: use repository-level secrets (Settings → Secrets) or environment secrets.
- Local development: use a local environment file outside the repo (e.g., use .env but do NOT commit it).

Pre-commit checks:
- Add pre-commit or a git hook to scan staged files for private key headers and likely API keys.

Contact:
- If you suspect a secret was leaked, open an issue and notify repository admins and affected services immediately.
