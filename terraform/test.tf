resource "google_compute_firewall" "" {
  allow {
    protocol = "icmp"
  }
  description   = "Allow ICMP from anywhere"
  direction     = "INGRESS"
  name          = "default-allow-icmp"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  priority      = 65534
  project       = "events-atamel-terraform"
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "" {
  allow {
    ports    = ["0-65535"]
    protocol = "tcp"
  }
  allow {
    ports    = ["0-65535"]
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  description   = "Allow internal traffic on the default network"
  direction     = "INGRESS"
  name          = "default-allow-internal"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  priority      = 65534
  project       = "events-atamel-terraform"
  source_ranges = ["10.128.0.0/9"]
}
resource "google_compute_firewall" "" {
  allow {
    ports    = ["3389"]
    protocol = "tcp"
  }
  description   = "Allow RDP from anywhere"
  direction     = "INGRESS"
  name          = "default-allow-rdp"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  priority      = 65534
  project       = "events-atamel-terraform"
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "" {
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  description   = "Allow SSH from anywhere"
  direction     = "INGRESS"
  name          = "default-allow-ssh"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  priority      = 65534
  project       = "events-atamel-terraform"
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_network" "" {
  auto_create_subnetworks = true
  description             = "Default network for the project"
  name                    = "default"
  project                 = "events-atamel-terraform"
  routing_mode            = "REGIONAL"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.162.0.0/20."
  dest_range  = "10.162.0.0/20"
  name        = "default-route-1d2533dc901714c0"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.186.0.0/20."
  dest_range  = "10.186.0.0/20"
  name        = "default-route-1c228f2317f2f858"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.150.0.0/20."
  dest_range  = "10.150.0.0/20"
  name        = "default-route-44858b4e08514112"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.164.0.0/20."
  dest_range  = "10.164.0.0/20"
  name        = "default-route-545b5a6f07eb13de"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.182.0.0/20."
  dest_range  = "10.182.0.0/20"
  name        = "default-route-78603778a8c6125a"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.138.0.0/20."
  dest_range  = "10.138.0.0/20"
  name        = "default-route-77197420fe3d0a43"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.156.0.0/20."
  dest_range  = "10.156.0.0/20"
  name        = "default-route-8fe350c617162e95"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.132.0.0/20."
  dest_range  = "10.132.0.0/20"
  name        = "default-route-923210fb2ce2d770"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.160.0.0/20."
  dest_range  = "10.160.0.0/20"
  name        = "default-route-945d7022d4d1f4a5"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description      = "Default route to the Internet."
  dest_range       = "0.0.0.0/0"
  name             = "default-route-976b96b28b37d072"
  network          = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  next_hop_gateway = "https://www.googleapis.com/compute/beta/projects/events-atamel-terraform/global/gateways/default-internet-gateway"
  priority         = 1000
  project          = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.166.0.0/20."
  dest_range  = "10.166.0.0/20"
  name        = "default-route-0757bde801011bd9"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.180.0.0/20."
  dest_range  = "10.180.0.0/20"
  name        = "default-route-2b43a807ed36feca"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.178.0.0/20."
  dest_range  = "10.178.0.0/20"
  name        = "default-route-97a4b8eeb094af99"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.152.0.0/20."
  dest_range  = "10.152.0.0/20"
  name        = "default-route-747b9396c2f2986e"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.128.0.0/20."
  dest_range  = "10.128.0.0/20"
  name        = "default-route-9d06a22e7f2c66d4"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.172.0.0/20."
  dest_range  = "10.172.0.0/20"
  name        = "default-route-a3422e8c1db2004f"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.140.0.0/20."
  dest_range  = "10.140.0.0/20"
  name        = "default-route-b031d1576dcedb41"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.158.0.0/20."
  dest_range  = "10.158.0.0/20"
  name        = "default-route-b5307787d84e08be"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.184.0.0/20."
  dest_range  = "10.184.0.0/20"
  name        = "default-route-b84676812b8831e8"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.170.0.0/20."
  dest_range  = "10.170.0.0/20"
  name        = "default-route-c8f7b942894ccf27"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.154.0.0/20."
  dest_range  = "10.154.0.0/20"
  name        = "default-route-cb7f45e956eae614"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.142.0.0/20."
  dest_range  = "10.142.0.0/20"
  name        = "default-route-e7a613ca79665ab5"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.168.0.0/20."
  dest_range  = "10.168.0.0/20"
  name        = "default-route-e7aca5c35bac8552"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.174.0.0/20."
  dest_range  = "10.174.0.0/20"
  name        = "default-route-ee0b945607b935e9"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.146.0.0/20."
  dest_range  = "10.146.0.0/20"
  name        = "default-route-f687c5d457ff3b2d"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_route" "" {
  description = "Default local route to the subnetwork 10.148.0.0/20."
  dest_range  = "10.148.0.0/20"
  name        = "default-route-f92a2fcbc16aa418"
  network     = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project     = "events-atamel-terraform"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.140.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-east1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.170.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-east2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.146.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-northeast1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.178.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-northeast3"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.148.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-southeast1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.184.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-southeast2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.186.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "europe-central2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.132.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "europe-west1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.154.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "europe-west2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.174.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-northeast2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.152.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "australia-southeast1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.166.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "europe-north1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.160.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "asia-south1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.128.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "us-central1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.164.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "europe-west4"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.156.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "europe-west3"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.158.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "southamerica-east1"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.172.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "europe-west6"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.182.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "us-west4"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.168.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "us-west2"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.138.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "us-west1"
}
resource "google_pubsub_topic" "" {
  labels {
    goog-eventarc   = ""
    managed-by-cnrm = "true"
  }
  message_storage_policy {
    allowed_persistence_regions = ["europe-west1"]
  }
  name    = "eventarc-europe-west1-trigger-auditlog-tf-809"
  project = "events-atamel-terraform"
}
resource "google_pubsub_subscription" "" {
  ack_deadline_seconds = 10
  expiration_policy {
    ttl = "2678400s"
  }
  labels {
    goog-eventarc   = ""
    managed-by-cnrm = "true"
  }
  message_retention_duration = "86400s"
  name                       = "eventarc-europe-west1-trigger-auditlog-tf-sub-809"
  project                    = "events-atamel-terraform"
  push_config {
    oidc_token {
      audience              = "https://cloudrun-hello-u5jzw3umja-ew.a.run.app"
      service_account_email = "382761898639-compute@developer.gserviceaccount.com"
    }
    push_endpoint = "https://cloudrun-hello-u5jzw3umja-ew.a.run.app?__GCP_CloudEventsMode=CE_PUBSUB_BINDING"
  }
  retry_policy {
    maximum_backoff = "600s"
    minimum_backoff = "10s"
  }
  topic = "projects/events-atamel-terraform/topics/eventarc-europe-west1-trigger-auditlog-tf-809"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.150.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "us-east4"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.142.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "us-east1"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "artifactregistry.googleapis.com"
}
resource "google_pubsub_topic" "" {
  labels {
    goog-eventarc   = ""
    managed-by-cnrm = "true"
  }
  message_storage_policy {
    allowed_persistence_regions = ["europe-west1"]
  }
  name    = "eventarc-europe-west1-trigger-pubsub-tf-427"
  project = "events-atamel-terraform"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "compute.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "logging.googleapis.com"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.162.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "northamerica-northeast1"
}
resource "google_service_account" "" {
  account_id   = "382761898639-compute"
  display_name = "Compute Engine default service account"
  project      = "events-atamel-terraform"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "sql-component.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "pubsub.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "cloudapis.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "storage.googleapis.com"
}
resource "google_compute_subnetwork" "" {
  ip_cidr_range = "10.180.0.0/20"
  name          = "default"
  network       = "https://www.googleapis.com/compute/v1/projects/events-atamel-terraform/global/networks/default"
  project       = "events-atamel-terraform"
  purpose       = "PRIVATE"
  region        = "us-west3"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "serviceusage.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "servicemanagement.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "monitoring.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "bigquerystorage.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "eventarc.googleapis.com"
}
resource "google_pubsub_subscription" "" {
  ack_deadline_seconds = 10
  expiration_policy {
    ttl = "2678400s"
  }
  labels {
    goog-eventarc   = ""
    managed-by-cnrm = "true"
  }
  message_retention_duration = "86400s"
  name                       = "eventarc-europe-west1-trigger-pubsub-tf-sub-427"
  project                    = "events-atamel-terraform"
  push_config {
    push_endpoint = "https://cloudrun-hello-u5jzw3umja-ew.a.run.app?__GCP_CloudEventsMode=CUSTOM_PUBSUB_projects%2Fevents-atamel-terraform%2Ftopics%2Feventarc-europe-west1-trigger-pubsub-tf-427"
  }
  retry_policy {
    maximum_backoff = "600s"
    minimum_backoff = "10s"
  }
  topic = "projects/events-atamel-terraform/topics/eventarc-europe-west1-trigger-pubsub-tf-427"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "clouddebugger.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "run.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "storage-api.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "cloudtrace.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "datastore.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "bigquery.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "oslogin.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "containerregistry.googleapis.com"
}
resource "google_project_service" "" {
  project = "382761898639"
  service = "storage-component.googleapis.com"
}
