variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable disk_image {
  description = "Disk image"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable app_zone {
  description = "Zone for app"
  default     = "europe-west1-b"
}

variable "node_count" {
  default = "1"
}
