# User Documentation

## Overview

This project provides a small WordPress infrastructure composed of three Docker services:

- **NGINX** — HTTPS entry point on port `443`
- **WordPress + PHP-FPM** — website and application logic
- **MariaDB** — persistent WordPress database

The normal request path is:

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
```

Only NGINX is exposed to the host. WordPress and MariaDB communicate over private Docker bridge networks.

## Start the Project

From the repository root:

```bash
make
```

or:

```bash
make up
```

To check the running containers:

```bash
docker ps
```

or:

```bash
docker compose -f srcs/docker-compose.yml ps
```

If healthchecks are enabled, wait until the services report a healthy status.

## Stop the Project

```bash
make down
```

To stop containers without removing them, if the Makefile provides the target:

```bash
make stop
```

To restart:

```bash
make restart
```

## Access the Website

Inside the VM, open:

```text
https://xhuang.42.fr
```

The WordPress administration panel is:

```text
https://xhuang.42.fr/wp-admin
```

A self-signed TLS certificate warning may appear. This is expected for the local project environment.

The website can also be checked from the terminal:

```bash
curl -k https://xhuang.42.fr
```

A terminal browser can be used if installed:

```bash
w3m https://xhuang.42.fr
```

The stack itself exposes HTTPS on port `443`. Any VirtualBox host-side port forwarding is outside the Docker project and is not required for normal evaluation inside the VM.

## Credentials

Non-sensitive settings are stored in:

```text
srcs/.env
```

Passwords are stored in local secret files and are mounted into the containers under:

```text
/run/secrets/
```


Do not commit real secret files to Git.

To inspect which secret files are mounted inside a container:

```bash
docker exec wordpress ls -l /run/secrets
docker exec mariadb ls -l /run/secrets
```

Avoid printing passwords during normal administration.

## Check Service Status

Show the Compose service state:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Show container status:

```bash
docker ps
```

Show recent logs:

```bash
docker compose -f srcs/docker-compose.yml logs --tail=100
```

Logs for one service:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

If healthchecks are configured:

```bash
docker inspect nginx --format '{{.State.Health.Status}}'
docker inspect wordpress --format '{{.State.Health.Status}}'
docker inspect mariadb --format '{{.State.Health.Status}}'
```

To inspect recent healthcheck output:

```bash
docker inspect mariadb \
  --format '{{range .State.Health.Log}}{{println .Output}}{{end}}'
```

## Check HTTPS and TLS

Confirm that HTTPS responds:

```bash
curl -kI https://xhuang.42.fr
```

Confirm that HTTP on port `80` is not exposed:

```bash
curl -I --max-time 5 http://xhuang.42.fr
```

Inspect the negotiated TLS protocol:

```bash
curl -kv https://xhuang.42.fr 2>&1 | grep -i TLS
```

The NGINX configuration should support the required TLS version, such as TLS 1.2 and/or TLS 1.3.

## WordPress Administration

Login page:

```text
https://xhuang.42.fr/wp-admin
```

The administrator account is used to:

- access the WordPress dashboard;
- edit pages and posts;
- manage users;
- inspect site settings.

A regular WordPress user can be used to test normal user permissions, for example by adding a comment if comments are enabled.

### Check WordPress Users

From the VM:

```bash
docker exec wordpress \
  wp user list \
  --allow-root \
  --path=/var/www/html
```

To inspect a specific user:

```bash
docker exec wordpress \
  wp user get xhuang \
  --fields=ID,user_login,user_email,roles \
  --allow-root \
  --path=/var/www/html
```

## MariaDB Administration

To login as MariaDB root using the Docker secret directly:

```bash
docker exec mariadb sh -c \
'mariadb -u root \
-p"$(cat /run/secrets/mysql_root_password)"'
```

To login as the WordPress database user:

```bash
docker exec mariadb sh -c \
'mariadb -u "$MYSQL_USER" \
-p"$(cat /run/secrets/mysql_password)" \
"$MYSQL_DATABASE"'
```

Useful SQL checks:

```sql
SELECT USER(), CURRENT_USER(), VERSION();

SHOW DATABASES;

SELECT User, Host FROM mysql.user;

USE wordpress;

SHOW TABLES;

SELECT COUNT(*) FROM wp_posts;

SELECT ID, user_login, user_email FROM wp_users;

SELECT option_name, option_value
FROM wp_options
WHERE option_name IN ('siteurl', 'home');
```

To inspect the privileges of the current MariaDB account:

```sql
SHOW GRANTS;
```

## Check Docker Networks

List networks:

```bash
docker network ls
```

Inspect the backend network:

```bash
docker network inspect srcs_backend
```

A shorter view of the connected containers:

```bash
docker network inspect srcs_backend \
  --format '{{range .Containers}}{{println .Name .IPv4Address}}{{end}}'
```

The expected logical separation is:

```text
frontend:
NGINX <-> WordPress

backend:
WordPress <-> MariaDB
```

## Check Persistent Data

List volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume-name>
```

The volume configuration should refer to host paths under:

```text
/home/xhuang/data/
```

Typical persistent directories are:

```text
/home/xhuang/data/mariadb
/home/xhuang/data/wordpress
```

## Persistence Test

A basic persistence test is:

1. Start the project.
2. Edit a WordPress page or create a post.
3. Verify the change in the browser.
4. Reboot the VM.
5. Start the project again with `make`.
6. Verify that the WordPress change is still present.
7. Verify that MariaDB still contains the WordPress tables.

This confirms that application data is stored outside the lifecycle of the containers.
