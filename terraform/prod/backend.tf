terraform {
  backend "gcs" {
    bucket  = "test_storage_infra"
    prefix  = "prod"
  }
}

