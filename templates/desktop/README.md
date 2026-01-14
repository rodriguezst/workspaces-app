---
display_name: Virtual Desktop
description: Docker-based Virtual Desktop Infrastructure using LinuxServer.io Webtop images
icon: /icon/desktop.svg
verified: false
tags: [desktop, docker, vdi]
---

# Virtual Desktop

Docker-based Virtual Desktop Infrastructure using LinuxServer.io's Webtop images, offering multiple Linux distributions and desktop environments to choose from.

## Features

- **Multiple Distributions**: Alpine, Arch, Debian, Fedora, Ubuntu
- **Multiple Desktops**: i3, KDE, MATE, XFCE
- **Docker**: Full Docker support via mounted host docker socket
- **GitHub Authentication**: Built-in integration
- **Persistent Storage**: Home directory persists

## Architecture

- **Provider**: Docker
- **Base Images**: LinuxServer.io Webtop series
- **Desktop Access**: Browser-based desktop access using [Selkies](https://selkies-project.github.io/selkies/)
- **Storage**: Docker volume for `/home/config`
