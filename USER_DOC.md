This file must explain, in clear and simple
terms, how an end user or administrator can:
◦ Understand what services are provided by the stack.
◦ Start and stop the project.
◦ Access the website and the administration panel.
◦ Locate and manage credentials.
◦ Check that the services are running correctly




```
                     HOST
                      │
                only port 443
                      │
                      ▼
                   NGINX
                     │
             Docker private network
          ┌──────────┴──────────┐
          ▼                     ▼
WordPress :9000             ...
     │
     ▼
MariaDB :3306
```
on VM:
w3m https://xhuang.42.fr

on Host Machine:
chromium-browser \
  --user-data-dir=/tmp/inception-chrome \
  --host-resolver-rules="MAP xhuang.42.fr 127.0.0.1"