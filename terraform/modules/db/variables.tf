variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable zone {
  description = "Zone for app"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

variable private_key_path {
  description = "Path to the private key used for ssh access"
}

variable provision_trigger {
  description = "To provision or not"
  default = true
}
