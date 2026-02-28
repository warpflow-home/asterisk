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

## Testing
Use a SIP client (Zoiper, Linphone, etc.) to register extensions and test calls within the lab.

## License
MIT