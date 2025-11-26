# Deluge Headless

> **One-line install for Deluge daemon + WebUI on headless Debian servers, pre-configured for Servarr stack compatibility.**

## Why This Script?

No more fighting with permissions. This script handles all the tedious setup:
- **Servarr-ready**: Creates `media` group with proper permissions (774, umask 0002)
- **Pre-configured**: Download location set to `/mnt/deluge` out of the box
- **Service optimized**: Daemon and WebUI services configured with correct group permissions
- **Smart**: Auto-detects UFW and opens port 8112 if needed

## Quick Install

**Run as root:**

```bash
wget -q https://rigslab.com/Rambo/deluge-headless/raw/branch/main/install.sh -O install.sh && chmod +x install.sh && ./install.sh
```

**Optional:** Pass your username to get added to the deluge group:

```bash
./install.sh yourusername
```

## Post-Install

| What | Where |
|------|-------|
| **WebUI** | `http://server_ip:8112` |
| **Default Password** | `deluge` |
| **Downloads** | `/mnt/deluge` |

Your downloads are accessible to both Deluge and your Servarr apps via the `media` group.