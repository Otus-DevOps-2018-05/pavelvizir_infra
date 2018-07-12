resource "google_compute_target_pool" "default" {
  name = "instance-pool"

  instances = [
    "europe-west1-b/reddit-app0",
    "europe-west1-b/reddit-app1"
]

  health_checks = [
    "${google_compute_http_health_check.default.name}",
  ]
}

resource "google_compute_http_health_check" "default" {
  name               = "default"
  request_path       = "/"
  port	             = 9292
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_forwarding_rule" "default" {
  name       = "website-forwarding-rule"
  target     = "${google_compute_target_pool.default.self_link}"
  port_range = "9292"
}

