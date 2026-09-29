# Developer Documentation

## Purpose

This document describes how to set up, build, run, inspect, rebuild, and maintain the Inception project from a developer perspective.

The mandatory stack contains:

```text
NGINX
  │
  │ FastCGI
  ▼
WordPress + PHP-FPM
  │
  │ SQL
  ▼
MariaDB
```

Docker Compose coordinates the three services, their networks, persistent storage, secrets, and startup dependencies.

## Prerequisites

The development environment must provide:

- Debian or another suitable Linux environment
- Docker
- Docker Compose
- GNU Make
- permission to run Docker
- sufficient disk space for Docker images and persistent data
- local hostname resolution for `xhuang.42.fr`

The project is intended to run inside a VM.

Typical VM resources:

```text
CPU: 2 cores
RAM: 2 GB or more
Disk: approximately 20–30 GB
Network: NAT
GUI: not required
```

## Repository Layout

All service configuration is stored inside `srcs/`.

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

Each mandatory service has its own Dockerfile.

## Initial Environment Setup

### 1. Clone or copy the repository

Enter the repository root:

```bash
cd /path/to/inception
```

### 2. Configure hostname resolution

Inside the VM, ensure that the domain resolves locally.

Example `/etc/hosts` entry:

```text
127.0.1.1 xhuang.42.fr xhuang
```

`127.0.0.1` is also a valid loopback address.

Test:

```bash
getent hosts xhuang.42.fr
```

### 3. Configure `srcs/.env`

The `.env` file stores normal non-sensitive configuration.

Example:

```env
DOMAIN_NAME=xhuang.42.fr

MYSQL_DATABASE=
MYSQL_USER=

WP_TITLE=Inception
WP_ADMIN_USER=
WP_ADMIN_EMAIL=

WP_USER=
WP_USER_EMAIL=
```

Depending on the Compose file, `.env` may also contain paths to local secret files.

The `.env` file should contain configuration such as:

```text
.env
│
├── domain name
├── database name
├── usernames
├── normal runtime configuration
└── secret file/path references
```

Passwords should not be placed directly in `.env` if Docker secrets are used.

### 4. Create the secret files

The exact host filenames must match `srcs/docker-compose.yml`.

Typical examples are:

```text
secrets/
├── mysql_root_password.txt
├── mysql_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

Each file must contain only the raw secret value.

Secrets are mounted into authorized containers under:

```text
/run/secrets/
```

## Build and Launch

From the repository root:

```bash
make
```

or:

```bash
make up
```

The Makefile invokes Docker Compose and builds the service images from the local Dockerfiles.

The resulting service images should correspond to:

```text
mariadb
wordpress
nginx
```

Check:

```bash
docker images
```

Check the running services:

```bash
docker compose -f srcs/docker-compose.yml ps
```

## Makefile Usage

Typical targets are:

```bash
make
make up
make down
make re
```

The exact target set is defined by the repository Makefile.

`make re` is normally used for a full clean rebuild.

Before using destructive targets, understand whether they also delete persistent host data.

## Docker Compose Commands

The Compose file is:

```text
srcs/docker-compose.yml
```

Useful commands:

```bash
docker compose -f srcs/docker-compose.yml config
docker compose -f srcs/docker-compose.yml config --services
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs
docker compose -f srcs/docker-compose.yml logs -f
docker compose -f srcs/docker-compose.yml up -d --build
docker compose -f srcs/docker-compose.yml down
```

Inspect a single service:

```bash
docker logs mariadb
docker logs wordpress
docker logs nginx
```

## Networks

The project uses Docker bridge networks instead of host networking.

Expected logical structure:

```text
                 frontend
NGINX ----------------------------- WordPress
                                         |
                                         | backend
                                         |
                                      MariaDB
```

List networks:

```bash
docker network ls
```

Inspect a network:

```bash
docker network inspect srcs_backend
docker network inspect srcs_frontend
```

Show only connected container names and addresses:

```bash
docker network inspect srcs_backend \
  --format '{{range .Containers}}{{println .Name .IPv4Address}}{{end}}'
```

Containers use Docker DNS and service names for communication.

For example, WordPress connects to MariaDB using the service name:

```text
mariadb
```

not `localhost`.

## Healthchecks and Startup Order

A container being in the `running` state does not guarantee that its application is ready.

Healthchecks provide readiness information.

The intended startup chain is:

```text
MariaDB
   │
   │ healthcheck succeeds
   ▼
WordPress + PHP-FPM
   │
   │ healthcheck succeeds
   ▼
NGINX
```

Typical Compose dependencies use:

```yaml
depends_on:
  mariadb:
    condition: service_healthy
```

and:

```yaml
depends_on:
  wordpress:
    condition: service_healthy
```

Check health status:

```bash
docker compose -f srcs/docker-compose.yml ps
```

or:

```bash
docker inspect mariadb --format '{{.State.Health.Status}}'
docker inspect wordpress --format '{{.State.Health.Status}}'
docker inspect nginx --format '{{.State.Health.Status}}'
```

Inspect healthcheck output:

```bash
docker inspect mariadb \
  --format '{{range .State.Health.Log}}{{println .Output}}{{end}}'
```

## NGINX and TLS

NGINX is the only service that publishes a host port:

```text
443:443
```

Port `80` is intentionally not exposed.

Test HTTPS:

```bash
curl -kI https://xhuang.42.fr
```

Test that HTTP is unavailable:

```bash
curl -I --max-time 5 http://xhuang.42.fr
```

Inspect TLS negotiation:

```bash
curl -kv https://xhuang.42.fr 2>&1 | grep -i TLS
```

The NGINX configuration should explicitly enable the required TLS protocol version, for example TLS 1.2 and/or TLS 1.3.

## WordPress Development Checks

Check WP-CLI access:

```bash
docker exec wordpress \
  wp core is-installed \
  --allow-root \
  --path=/var/www/html
```

List users:

```bash
docker exec wordpress \
  wp user list \
  --allow-root \
  --path=/var/www/html
```

The administrator username must not contain `admin` or `Admin`.

Check PHP-FPM processes:

```bash
docker exec wordpress ps aux
```

The WordPress container must not run NGINX.

## MariaDB Development Checks

Login as root using the secret:

```bash
docker exec mariadb sh -c \
'mariadb -u root \
-p"$(cat /run/secrets/mysql_root_password)"'
```

Useful SQL:

```sql
SELECT USER(), CURRENT_USER(), VERSION();

SHOW DATABASES;

SELECT User, Host FROM mysql.user;

USE wordpress;

SHOW TABLES;

SHOW GRANTS;
```

Check that the WordPress database is not empty:

```sql
SELECT COUNT(*) FROM wp_posts;
```

The MariaDB container must not run NGINX.

## Persistent Storage

The project uses named Docker volumes configured with the local driver and bind options.

The persistent host paths are located under:

```text
/home/xhuang/data/
```

Typical paths:

```text
/home/xhuang/data/mariadb
/home/xhuang/data/wordpress
```

These are mounted into the containers, for example:

```text
/home/xhuang/data/mariadb
          │
          ▼
/var/lib/mysql
```

and:

```text
/home/xhuang/data/wordpress
          │
          ▼
/var/www/html
```

List volumes:

```bash
docker volume ls
```

Inspect one:

```bash
docker volume inspect <volume-name>
```

Verify that the output refers to a path under:

```text
/home/xhuang/data/
```

Because persistent data is stored outside the container writable layer, rebuilding or replacing a container does not automatically erase the application data.

## Rebuild and Development Procedure

For a normal configuration or source change:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

or use:

```bash
make up
```

For a clean rebuild:

```bash
make re
```

After rebuilding, verify:

```bash
docker compose -f srcs/docker-compose.yml ps
curl -kI https://xhuang.42.fr
```

Then verify WordPress and MariaDB state.

## Persistence Verification

Before rebooting the VM:

1. Edit a WordPress page or create a post.
2. Verify the change in the browser.
3. Confirm that MariaDB contains the WordPress tables.

Reboot the VM:

```bash
sudo reboot
```

After reboot:

```bash
make
```

Then verify:

```bash
curl -kI https://xhuang.42.fr
```

and:

```bash
docker exec mariadb sh -c \
'mariadb -u "$MYSQL_USER" \
-p"$(cat /run/secrets/mysql_password)" \
"$MYSQL_DATABASE" \
-e "SHOW TABLES;"'
```

The previous WordPress content must still be present.

## Configuration Modification During Evaluation

During evaluation, a reviewer may ask for one service configuration to be changed.

For example, the PHP-FPM internal port may be changed from:

```text
9000
```

to:

```text
9001
```

Both sides of the FastCGI connection must then be updated:

```text
WordPress PHP-FPM:
listen = 9001

NGINX:
fastcgi_pass wordpress:9001;
```

Then rebuild:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

or:

```bash
make re
```

Finally verify that the site still works:

```bash
curl -kI https://xhuang.42.fr
```

This demonstrates that the developer understands the relationship between NGINX and PHP-FPM rather than only reproducing a static configuration.
