terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

data "coder_provisioner" "me" {}
data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

data "coder_parameter" "docker_image" {
  description   = "Choose a base image for the container."
  display_name  = "Docker Image"
  mutable       = true
  name          = "docker-image"
  default       = "latest"

  # List of Docker image options
  option {
    name        = "XFCE Alpine"
    value       = "latest"
  }
  option {
    name        = "i3 Alpine"
    value       = "alpine-i3"
  }
  option {
    name        = "MATE Alpine"
    value       = "alpine-mate"
  }
  option {
    name        = "i3 Arch"
    value       = "arch-i3"
  }
  option {
    name        = "KDE Arch"
    value       = "arch-kde"
  }
  option {
    name        = "MATE Arch"
    value       = "arch-mate"
  }
  option {
    name        = "XFCE Arch"
    value       = "arch-xfce"
  }
  option {
    name        = "i3 Debian"
    value       = "debian-i3"
  }
  option {
    name        = "KDE Debian"
    value       = "debian-kde"
  }
  option {
    name        = "MATE Debian"
    value       = "debian-mate"
  }
  option {
    name        = "XFCE Debian"
    value       = "debian-xfce"
  }
  option {
    name        = "i3 Fedora"
    value       = "fedora-i3"
  }
  option {
    name        = "KDE Fedora"
    value       = "fedora-kde"
  }
  option {
    name        = "MATE Fedora"
    value       = "fedora-mate"
  }
  option {
    name        = "XFCE Fedora"
    value       = "fedora-xfce"
  }
  option {
    name        = "i3 Ubuntu"
    value       = "ubuntu-i3"
  }
  option {
    name        = "KDE Ubuntu"
    value       = "ubuntu-kde"
  }
  option {
    name        = "MATE Ubuntu"
    value       = "ubuntu-mate"
  }
  option {
    name        = "XFCE Ubuntu"
    value       = "ubuntu-xfce"
  }

  order = 1
}

resource "coder_agent" "main" {
  arch           = data.coder_provisioner.me.arch
  os             = "linux"
  startup_script = <<-EOT
    set -e

    # Prepare user home with default files on first start.
    if [ ! -f ~/.init_done ]; then
      if [ -d /etc/skel ]; then
        cp -rT /etc/skel ~
      fi
      touch ~/.init_done
    fi

    # Add any commands that should be executed at workspace startup (e.g install requirements, start a program, etc) here
  EOT

  # The following metadata blocks are optional. They are used to display
  # information about your workspace in the dashboard. You can remove them
  # if you don't want to display any information.
  # For basic resources, you can use the `coder stat` command.
  # If you need more control, you can write your own script.
  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "CPU Usage (Host)"
    key          = "4_cpu_usage_host"
    script       = "coder stat cpu --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory Usage (Host)"
    key          = "5_mem_usage_host"
    script       = "coder stat mem --host"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Load Average (Host)"
    key          = "6_load_host"
    # get load avg scaled by number of cores
    script   = <<EOT
      echo "`cat /proc/loadavg | awk '{ print $1 }'` `nproc`" | awk '{ printf "%0.2f", $1/$2 }'
    EOT
    interval = 60
    timeout  = 1
  }

  metadata {
    display_name = "Swap Usage (Host)"
    key          = "7_swap_host"
    script       = <<EOT
      free -b | awk '/^Swap/ { printf("%.1f/%.1f", $3/1024.0/1024.0/1024.0, $2/1024.0/1024.0/1024.0) }'
    EOT
    interval     = 10
    timeout      = 1
  }
}

resource "coder_app" "virtual-desktop" {
  agent_id     = coder_agent.main.id
  slug         = "virtual-desktop"
  display_name = "Desktop"
  url          = "http://localhost:3000"
  icon         = "/icon/desktop.svg"
  order        = 3

  healthcheck {
    url       = "http://localhost:3000/app"
    interval  = 5
    threshold = 5
  }
}

module "filebrowser" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/filebrowser/coder"
  version  = "1.1.3"
  agent_id = coder_agent.main.id
}

resource "docker_volume" "home_volume" {
  name = "coder-${data.coder_workspace.me.id}-home"
  # Protect the volume from being deleted due to changes in attributes.
  lifecycle {
    ignore_changes = all
  }
  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  # This field becomes outdated if the workspace is renamed but can
  # be useful for debugging or cleaning out dangling volumes.
  labels {
    label = "coder.workspace_name_at_creation"
    value = data.coder_workspace.me.name
  }
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = "lscr.io/linuxserver/webtop:${data.coder_parameter.docker_image.value}"
  # Uses lower() to avoid Docker restriction on container names.
  name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  # Hostname makes the shell more user friendly: coder@my-workspace:~$
  hostname = data.coder_workspace.me.name
  # Use the docker gateway if the access URL is 127.0.0.1
  entrypoint = ["/init", "/command/with-contenv","sh", "-c",replace(coder_agent.main.init_script, "/localhost|127\\.0\\.0\\.1/", "host.docker.internal")]
  env        = ["CODER_AGENT_TOKEN=${coder_agent.main.token}"]
  host {
    host = "host.docker.internal"
    ip   = "host-gateway"
  }
  volumes {
    container_path = "/config"
    volume_name    = docker_volume.home_volume.name
    read_only      = false
  }
  mounts {
    target = "/var/run/docker.sock"
    source = "/var/run/docker.sock"
    type   = "bind"
  }

  # Add labels in Docker to keep track of orphan resources.
  labels {
    label = "coder.owner"
    value = data.coder_workspace_owner.me.name
  }
  labels {
    label = "coder.owner_id"
    value = data.coder_workspace_owner.me.id
  }
  labels {
    label = "coder.workspace_id"
    value = data.coder_workspace.me.id
  }
  labels {
    label = "coder.workspace_name"
    value = data.coder_workspace.me.name
  }
}
