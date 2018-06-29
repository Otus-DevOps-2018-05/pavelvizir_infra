provider "google" {
  version = "1.4.0"
  project = "${var.project}"
  region  = "${var.region}"
}

resource "google_compute_instance" "app" {
  zone         = "${var.app_zone}"
  name         = "reddit-app"
  machine_type = "g1-small"
  zone         = "europe-west1-b"
  tags         = ["reddit-app"]

  boot_disk {
    initialize_params {
      image = "${var.disk_image}"

      # image = "reddit-base-1529926486"
    }
  }

  metadata {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }

  network_interface {
    network = "default"

    # использовать ephemeral IP для доступа из Интернет
    access_config {}
  }

  connection {
    type        = "ssh"
    user        = "appuser"
    agent       = false
    private_key = "${file(var.private_key_path)}"
  }

  provisioner "file" {
    source      = "files/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name    = "allow-puma-default"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["reddit-app"]
}

resource "google_compute_project_metadata_item" "project-ssh-keys" {
    key = "ssh-keys"
    value = "appuser1:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFeEI5Qrl0cyie6TPhQlwTgQJg3g97pFShbGxq5YkO5H1PWl1Vlt7y6+3peTn545LQ/9EjybdDl6zlM7GSrB9QjWXTH5RnEMyIS1kDVIIKW9L5JElB4avccZPLZMR/PxsmUJMWssCGwax18gQcdwTp7fakz8+z+QpI8HBzP24DhJQBdcwQKUJwUkhZaO7c0T2RQ3wS4SQSqTSwNLw6VmYt23ZlheWIemp7CIofRIv29FHr82Oi/NTT819KC4hPPshCo3pa7KHnm0aiDQWNoLO7seiiGHqBTnQZLAT19XOSvEz8Dg0pY/Lym/M/e7XFSt8+YV8n1RVwcX3xydgSV/2QUMy3eXBZayZ5kgiZFJNZnyXN8Gd4SjzfHMtwxpVlZEAOAJiB16gvNGuaJ5f8kujtmbe1ist4Rz/w3JuyQ0DeG0OIYbPx5o57LU11K00Mz3OiOtm+mgwop43xlqSl0wZOSW5viK7Ft/p9qdAlWRU6wJAJXLiAprX6N6opSIZfdFgYTV4YYh0IG2G+ElufosOiZG7WW89uIPpqfOHUXvaQlKgKDDCkIf4CqsEKQk6mAipNPUDwI+ZcBWOOoJjkAjyXXGPRXJVta0V5Hp9/uk4a79N94tT8xkQep2IylLS8rBlNXeO8RSflWzxrmo6P1nZuWB5n7njpBIM2hDuhNG9inw== appuser1\nappuser2:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFeEI5Qrl0cyie6TPhQlwTgQJg3g97pFShbGxq5YkO5H1PWl1Vlt7y6+3peTn545LQ/9EjybdDl6zlM7GSrB9QjWXTH5RnEMyIS1kDVIIKW9L5JElB4avccZPLZMR/PxsmUJMWssCGwax18gQcdwTp7fakz8+z+QpI8HBzP24DhJQBdcwQKUJwUkhZaO7c0T2RQ3wS4SQSqTSwNLw6VmYt23ZlheWIemp7CIofRIv29FHr82Oi/NTT819KC4hPPshCo3pa7KHnm0aiDQWNoLO7seiiGHqBTnQZLAT19XOSvEz8Dg0pY/Lym/M/e7XFSt8+YV8n1RVwcX3xydgSV/2QUMy3eXBZayZ5kgiZFJNZnyXN8Gd4SjzfHMtwxpVlZEAOAJiB16gvNGuaJ5f8kujtmbe1ist4Rz/w3JuyQ0DeG0OIYbPx5o57LU11K00Mz3OiOtm+mgwop43xlqSl0wZOSW5viK7Ft/p9qdAlWRU6wJAJXLiAprX6N6opSIZfdFgYTV4YYh0IG2G+ElufosOiZG7WW89uIPpqfOHUXvaQlKgKDDCkIf4CqsEKQk6mAipNPUDwI+ZcBWOOoJjkAjyXXGPRXJVta0V5Hp9/uk4a79N94tT8xkQep2IylLS8rBlNXeO8RSflWzxrmo6P1nZuWB5n7njpBIM2hDuhNG9inw== appuser2"
}
