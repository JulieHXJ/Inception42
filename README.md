*This project has been created as part of the 42 curriculum by xhuang.*

# Inception

## Description

Inception is a system administration and containerization project from the 42 curriculum.

The goal of the project is to build a small multi-service web infrastructure using Docker and Docker Compose. Instead of installing all services directly on one machine, each major component runs inside its own container and communicates with the others through Docker networks.

### Architecture

The mandatory infrastructure contains three services:

- **NGINX** — the only public entry point. It accepts HTTPS connections on port `443`, terminates TLS, serves static files, and forwards PHP requests to PHP-FPM through FastCGI.
- **WordPress + PHP-FPM** — the application layer. WordPress provides the website and application logic, while PHP-FPM executes PHP code.
- **MariaDB** — the database layer used by WordPress to store users, posts, comments, options, and other structured application data.

Request flow:

```text
Client
  │
  │ HTTPS :443
  ▼
NGINX
  │
  │ FastCGI :9000
  ▼
WordPress + PHP-FPM
  │
  │ SQL :3306
  ▼
MariaDB
  │
  ▼
Persistent storage
```

Only NGINX publishes a host port. WordPress and MariaDB remain internal to Docker networks.

The project uses two bridge networks:

```text
                 frontend
NGINX ----------------------------- WordPress
                                         |
                                         | backend
                                         |
                                      MariaDB
```

WordPress is connected to both networks because it must communicate with NGINX and MariaDB. NGINX does not directly communicate with MariaDB.

## Instructions

### Prerequisites

The machine must provide:

- Docker
- Docker Compose
- GNU Make
- permission to run Docker
- a Linux environment suitable for the project
- local hostname resolution for the project domain

The project domain is:

```text
xhuang.42.fr
```

Inside the VM, it resolves to the local machine `/etc/hosts`:

```text
127.0.1.1 xhuang.42.fr xhuang
```

### Configuration

Non-sensitive configuration is stored in:

```text
srcs/.env
```

Sensitive values such as passwords are stored separately in local secret files and used through Docker secrets.

### Build and Start

From the repository root:

```bash
make
```

or:

```bash
make up
```


### Inspect the Containers

```bash
docker ps
```

or:

```bash
docker compose -f srcs/docker-compose.yml ps
```

If healthchecks are enabled, the services should eventually report a healthy state.

### Access the Website

Inside the VM:

```text
https://xhuang.42.fr
```

The WordPress administration page is:

```text
https://xhuang.42.fr/wp-admin
```

A self-signed certificate warning may appear in the browser.

The site can also be tested from the terminal:

```bash
curl -k https://xhuang.42.fr
```


### Stop the Infrastructure

```bash
make down
```

### Rebuild

```bash
make re
```

### Persistence Test

Container state and application data are deliberately separated.

A useful persistence test is:

1. Start the infrastructure.
2. Create or edit a WordPress post or page.
3. Reboot the VM or recreate the containers.
4. Start the infrastructure again.
5. Verify that the WordPress content and database state are still present.

Persistent data is stored outside the lifecycle of the containers.

## Technical Choices

### Docker and Docker Compose

Docker builds images from Dockerfiles and runs isolated containers from those images.

A Docker image can be built and run manually using commands such as:

```bash
docker build
docker run
```

Docker Compose does not replace Docker images. It coordinates multiple services and defines how the images, containers, networks, volumes, secrets, dependencies, and published ports work together.

In this project, Docker Compose is useful because NGINX, WordPress, and MariaDB must be started as one infrastructure with defined relationships.

### Virtual Machines vs Docker

A virtual machine provides a complete virtualized machine environment and normally runs its own operating-system kernel.

A Docker container runs isolated processes while sharing the host Linux kernel.

Virtual machines generally provide stronger isolation but require more resources. Containers are lighter, start faster, and are well suited to separating application services.

In this project Docker runs inside a virtual machine:

```text
Physical host
   │
   ▼
Virtual Machine
   │
   ▼
Docker Engine
   │
   ├── NGINX
   ├── WordPress + PHP-FPM
   └── MariaDB
```


### Secrets vs Environment Variables

Environment variables are appropriate for normal runtime configuration such as:

- domain name
- database name
- usernames
- service configuration
- paths to secret files

Sensitive information such as passwords must not be stored directly in Dockerfiles or committed to Git.

Docker Compose secrets are mounted only into authorized containers, typically under:

```text
/run/secrets/
```

This keeps sensitive values separate from normal configuration.

### Docker Networks

A Docker bridge network provides an isolated network between containers.

Containers on the same Docker network can communicate using Docker DNS and service names instead of fixed container IP addresses.

#### Host Network vs Bridge Network

This project uses bridge networks.

Only NGINX publishes a host port:

```text
host:443 -> nginx:443
```

WordPress port `9000` and MariaDB port `3306` remain internal.

With host networking, a container directly uses the host networking namespace. This reduces network isolation and makes the service bind directly to host interfaces and ports.

### Docker Volumes vs Bind Mounts

A Docker volume is storage managed through Docker and has a lifecycle independent from an individual container.

A bind mount maps a specific host file or directory directly into a container.

This project uses named Docker volumes configured with the local driver and bind options, so persistent data is stored in explicit host directories.

Example:

```text
Host
/home/xhuang/data/mariadb
        │
        │ mounted as a Docker volume
        ▼
MariaDB container
/var/lib/mysql
```

WordPress persistent files are stored in a corresponding host directory such as:

```text
/home/xhuang/data/wordpress
```

Removing and recreating a container therefore does not automatically delete the persistent WordPress or MariaDB data.

### Healthchecks

Healthchecks distinguish between a container that is merely running and a service that is actually ready.

The intended startup chain is:

```text
MariaDB healthy
      │
      ▼
WordPress / PHP-FPM healthy
      │
      ▼
NGINX healthy
```

This helps prevent WordPress from starting before MariaDB is ready and prevents NGINX from depending on a WordPress service that is not yet available.

## Resources

The following resources were used to understand and implement the technologies in this project:

- Docker documentation — Dockerfiles, containers, images, volumes, networks, Compose, and secrets
- Docker Compose documentation
- NGINX documentation
- MariaDB Server documentation
- PHP-FPM documentation
- WordPress documentation
- WP-CLI documentation
- OpenSSL documentation

Official references:

- Docker Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- NGINX: https://nginx.org/en/docs/
- MariaDB: https://mariadb.com/docs/
- PHP-FPM: https://www.php.net/manual/en/install.fpm.php
- WordPress Developer Resources: https://developer.wordpress.org/
- WP-CLI: https://wp-cli.org/
- OpenSSL: https://docs.openssl.org/

### Use of AI

AI tools were used as a learning and troubleshooting aid during development. They were used to:

- explain Docker networking, containers, volumes, FastCGI, PHP-FPM, and TLS concepts;
- help diagnose configuration, secret-file, and container-startup problems;
- review shell scripts and Docker Compose configuration;
- help structure documentation and evaluation checks.

AI-generated suggestions were not treated as authoritative. Commands and configuration changes were tested in the project environment, and technical behaviour was verified through Docker, MariaDB, WordPress, NGINX, and TLS inspection commands.
