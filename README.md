# asterisk-homelab
A home lab setup for Asterisk VoIP system experimentation and testing. This project demonstrates PBX configuration, call routing, and VoIP integration in a controlled environment.

## Features
- Asterisk PBX configuration
- SIP endpoint management
- Call routing and IVR setup
- Extension management
- Voicemail system

## Prerequisites
- Linux server (Ubuntu/Debian recommended)
- Asterisk 18+ installed
- Basic networking knowledge
- SIP client or softphone for testing

## Installation
1. Clone this repository
2. Review configuration files in `/etc/asterisk/`
3. Customize extensions.conf for your setup
4. Start Asterisk service

## Configuration
Edit the following files to customize your setup:
- `extensions.conf` - Call routing rules
- `sip.conf` - SIP peer definitions
- `voicemail.conf` - Voicemail settings

## Deploying on Docker Swarm (HA Setup)
This repository includes a configuration to deploy Asterisk in a Docker Swarm High Availability environment using macvlan for direct physical network connectivity.

### How to deploy via Portainer (GitHub integration)
1. In Portainer, navigate to **Stacks** > **Add stack**.
2. Select **Repository**.
3. Set the Repository URL to your GitHub repo URL (e.g., `https://github.com/warpflow/asterisk.git`).
4. Set the Repository reference (e.g., `refs/heads/main`).
5. Set the Compose path to: `stacks/asterisk/asterisk-stack.yml`.
6. Ensure your Swarm nodes have GlusterFS mounted to `/mnt/gluster/` for persistent volumes.
7. The macvlan network `swarm-macvlan` must be configured in Swarm with `192.168.1.200` assigned.
8. Click **Deploy the stack**.

### Important Network Configurations
* **macvlan IP**: `192.168.1.200` is used for SIP/RTP traffic to ensure NAT does not interfere.
* **pjsip.conf**: Ensure `local_net` includes your physical network and Swarm overlay network. Also ensure `bindaddr` and `externaddr` are set to `192.168.1.200`.

## Testing
Use a SIP client (Zoiper, Linphone, etc.) to register extensions and test calls within the lab.

## License
MIT