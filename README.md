# Docker Twingate Headless

This is for [Twingate][twingate] connect local network, using docker container!

## Docker Compose

This will need to use ``network_mode: host`` to make sure it can connect inside whole network, not only inside the container.

Also, you will want to use custom DNS for container to make sure it can connect with internal DNS!

(Every time start container, internal IP address is different, so make sure you use the DNS)

DNS:

- 100.95.0.251
- 100.95.0.252
- 100.95.0.253
- 100.95.0.254

```yml
version: "3"

services:
  twingate_client:
    container_name: twingate_client
    image: ghcr.io/docker-collection/twingate_headless:latest
    network_mode: "host"
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    environment:
      - 'SERVICE_KEY=One-Line-JSON-String'
```

Example for custom dns

```yml
version: "3"

services:
  test:
    container_name: alpine-test
    image: alpine
    dns:
      - 100.95.0.251
      - 100.95.0.252
      - 100.95.0.253
      - 100.95.0.254
      - 1.1.1.1
      - 1.0.0.1
    command:
      - sleep
      - infinity
```

## Reference

- [Twingate/github-action][twingate-action]

[twingate]: https://twingate.com/
[twingate-action]: https://github.com/Twingate/github-action
