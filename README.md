# Docker Twingate Headless

This is for [Twingate][twingate] connect local network, using docker container!

## Docker Compose

```yml
version: "3"

services:
  twingate_client:
    container_name: twingate_client
    image: test:a
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    environment:
      - 'SERVICE_KEY=One-Line-JSON-String'
```

## Reference

- [Twingate/github-action][twingate-action]

[twingate]: https://twingate.com/
[twingate-action]: https://github.com/Twingate/github-action