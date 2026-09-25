This file must describe how a developer can:
◦ Set up the environment from scratch (prerequisites, configuration files, secrets).
◦ Build and launch the project using the Makefile and Docker Compose.
◦ Use relevant commands to manage the containers and volumes.
◦ Identify where the project data is stored and how it persists


prerequisites
setup
Makefile usage
docker compose commands
persistence
development/rebuild procedure

.env
│
├── domain
├── database name
├── usernames
├── configuration
└── secret file/path references

Secrets
│
├── DB password
├── WP password
└── SMTP/API credentials