*This project has been created as part of the 42 curriculum by xhuang.*

# Inception

## Description

Inception is a system administration and containerization project from the 42 curriculum.


### Goal 

The goal of the project is to build a small multi-service web infrastructure using Docker and Docker Compose. Instead of installing all services directly on one machine, each major component runs inside its own container and communicates with the others through Docker networks.

### Overview.

#### Infrastructure
The mandatory infrastructure consists of three main services:

- **NGINX** — the only public entry point of the infrastructure. It accepts HTTPS connections on port `443`, terminates TLS, serves static files, and forwards PHP requests to PHP-FPM using FastCGI.
- **WordPress + PHP-FPM** — the application layer. WordPress provides the website and application logic, while PHP-FPM executes the PHP code.
- **MariaDB** — the database server used by WordPress to store structured application data such as users, posts, comments, and site settings.

#### Request Flow
The general request flow is:

```
Internet
   │
  443
   ▼
NGINX
   │ FastCGI
   ▼
WordPress + PHP-FPM
   │ SQL
   ▼
MariaDB
   │
   ▼
Persistent Volume
```

Only NGINX publishes a port to the host. WordPress and MariaDB are accessible only through internal Docker networks.

Persistent data is stored outside the lifecycle of the containers:


## Instructions

### Prerequisites

The machine must have:

Docker;
Docker Compose;
GNU Make;
sufficient permissions to run Docker;
the required local hostname configuration.

The domain must resolve locally to the machine running the infrastructure: `xhuang.42.fr`

### Configration

Configure the non-sensitive project variables in: `srcs/.env`

Example:

```
DOMAIN_NAME=xhuang.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

WP_TITLE=Inception
WP_ADMIN_USER=xhuang
WP_ADMIN_EMAIL=xhuang@student.42.fr

WP_USER=user42
WP_USER_EMAIL=user42@student.42.fr
```

Passwords and other confidential values must be stored separately in the local secrets files and must not be committed to Git.


### Build and Start

From the repository root:
```
make
```
or, depending on the Makefile targets:
```
make up
```


### Inspect the Containers
```
docker ps
```

### Access the Website

The website is served over HTTPS:
```
https://xhuang.42.fr
```
or test from inside the VM using tools such as curl or a terminal browser:
```
curl -k https://xhuang.42.fr
```

### Stop the Infrastructure

```
make down
```

### Rebuild
```
make re
```

### Persistence Test

Container state and application data are deliberately separated. A container can be replaced, while new container can use the same persistent database storage.

A useful persistence test is:

- start the infrastructure;
- create a WordPress post or user;
- remove and recreate the containers;
- verify that the WordPress content is still present.




## Technical Choices

• A Project description section must also explain the use of Docker and the sources
included in the project. It must indicate the main design choices, as well as a
comparison between:
### Virtual Machines vs Docker

OS: Debian 12 / 64-bit
RAM: 2 GB+
CPU: 2
Disk: 20–30 GB
GUI: 不装
Network: NAT


A virtual machine emulates or virtualizes an entire machine environment and normally runs its own operating system kernel.

A Docker container instead runs isolated processes while sharing the host Linux kernel.

Virtual machines generally provide stronger isolation but require more resources.

Containers are lighter, start faster, and are well suited to separating application services such as NGINX, WordPress, and MariaDB.

In this project, Docker runs inside a virtual machine. The VM provides the isolated environment required by the project, while Docker provides service-level isolation inside that VM.

### Secrets vs Environment Variables

Environment variables are useful for normal runtime configuration. Normal configuration is supplied through .env.

Sensitive information such as passwords should not be stored directly in Dockerfiles or committed to Git. Sensitive values are provided through Docker Compose secrets and mounted inside authorized containers under:

/run/secrets/

### Docker Netwokrs

A Docker bridge network creates an isolated network used by containers.

Services on the same Docker network can communicate using Docker DNS and service names

The infrastructure currently uses two Docker bridge networks:
```
                 frontend
NGINX -------------------------- WordPress
                                     |
                                     | backend
                                     |
                                  MariaDB
```

This prevents NGINX from directly connecting to MariaDB and provides basic network segmentation between the public-facing and database layers.

#### Host Network

With host networking, a container uses the host's networking namespace directly. This reduces network isolation and makes the service bind directly to host interfaces and ports.

This project uses Docker bridge networks because they provide isolation and allow only the required communication paths between services.

Only NGINX publishes a host port:

host:443 -> nginx:443

WordPress port 9000 and MariaDB port 3306 remain internal.

### Docker Volumes vs Bind Mounts

A Docker volume is storage managed through Docker and has a lifecycle independent from an individual container. 

A bind mount maps a specific file or directory from the host filesystem directly into a container.

The current project uses named Docker volumes configured with the local driver and bind options so that the persistent data is stored in explicitly defined host directories. The MariaDB service then mounts this storage at /var/lib/mysql.

```
Host directory
/home/xhuang/data/mariadb

        |
        | mount
        v

MariaDB container
/var/lib/mysql
```

This separates the lifecycle of the database data from the lifecycle of the MariaDB container.

Removing and recreating a container therefore does not automatically delete the database files.

## Resources

The following resources were used to understand and implement the technologies used by this project:

- Docker Documentation — Dockerfiles, containers, volumes, networks, Compose and secrets
- Docker Compose Documentation
- NGINX Documentation
- MariaDB Server Documentation
- PHP-FPM Documentation
- WordPress Documentation
- WP-CLI Documentation
- OpenSSL Documentation

Useful official references:

- Docker Docs: https://docs.docker.com/
- Docker Compose: https://docs.docker.com/compose/
- NGINX: https://nginx.org/en/docs/
- MariaDB: https://mariadb.com/docs/
- PHP: https://www.php.net/manual/en/install.fpm.php
- WordPress: https://developer.wordpress.org/
- WP-CLI: https://wp-cli.org/
- OpenSSL: https://docs.openssl.org/