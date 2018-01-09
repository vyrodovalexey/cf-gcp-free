variable "project" {
  type    = "string"
}

variable "user_sql_password" {
  type    = "string"
}

variable "user_sql" {
  type    = "string"
}

variable "domains" {
  type	  = "list"
}

variable "domain" {
  type	  = "string"
}


provider "google" {
  credentials = "${file("~/cf-user.key.json")}"
  project     = "${var.project}"
  region        = "us-central1"
}

#data "template_file" "group1-startup-script" {
#  template = "${file("${format("%s/../scripts/gceme.sh.tpl", path.module)}")}"
#
#  vars {
#    PROXY_PATH = ""
#  }
#}

resource "google_compute_subnetwork" "cfnet" {
  name          = "cfnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = "default"
  region        = "us-central1"
  private_ip_google_access = "1"
}

resource "google_compute_subnetwork" "cfnet1" {
  name          = "cfnet1"
  ip_cidr_range = "10.0.1.0/24"
  network       = "default"
  region        = "southamerica-east1"
  private_ip_google_access = "1"
}


resource "google_compute_subnetwork" "cfnet2" {
  name          = "cfnet2"
  ip_cidr_range = "10.0.2.0/24"
  network       = "default"
  region        = "asia-southeast1"
  private_ip_google_access = "1"
}

resource "google_compute_subnetwork" "cfnet3" {
  name          = "cfnet3"
  ip_cidr_range = "10.0.3.0/24"
  network       = "default"
  region        = "australia-southeast1"
  private_ip_google_access = "1"
}

resource "google_compute_subnetwork" "cfnet4" {
  name          = "cfnet4"
  ip_cidr_range = "10.0.4.0/24"
  network       = "default"
  region        = "europe-west1"
  private_ip_google_access = "1"
}


resource "google_compute_firewall" "allow-internal-cfnets" {
  name    = "allow-internal-cfnets"
  network = "default"

  allow {
    protocol = "icmp"
  }


  allow {
    protocol = "tcp"
    ports    = [ "0-65535" ]
  }

  allow {
    protocol = "udp"
    ports    = [ "0-65535" ]
  }


  source_ranges = ["10.0.0.0/22"]
}


resource "google_compute_firewall" "bosh-agents-and-director" {
  name    = "bosh-agent-and-director"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["4222", "6868", "8443", "8844", "25250", "25555", "25777" ]
  }

  target_tags = ["bosh-director"]
}

resource "google_compute_firewall" "bosh-cf-router-lb" {
  name    = "bosh-cf-router-lb"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443" ]
  }

  allow {
    protocol = "tcp"
    ports    = ["80" ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bosh-cf-router-lb"]
}

resource "google_compute_firewall" "bosh-cf-ssh-proxy" {
  name    = "bosh-cf-ssh-proxy"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["2222" ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bosh-cf-ssh-proxy"]
}

resource "google_compute_firewall" "bosh-cf-tcp-router" {
  name    = "bosh-cf-tcp-router"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["1024-32678" ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bosh-cf-tcp-router"]
}

resource "google_compute_firewall" "bosh-credhub" {
  name    = "bosh-credhub"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8844" ]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["bosh-credhub"]
}

resource "google_compute_firewall" "cf-net" {
  name    = "cf-net"
  network = "default"

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_tags = ["cf-net"]
  target_tags = ["cf-net"]
}

resource "google_storage_bucket" "bosh-gcp" {
  name     = "bosh_gcp_${var.project}"
  location = "US-CENTRAL1"
}

resource "google_storage_bucket" "apppackage-cf" {
  name     = "app_package_cf_${var.project}"
  location = "US-CENTRAL1"
}


resource "google_storage_bucket" "buildpack-cf" {
  name     = "build_pack_cf_${var.project}"
  location = "US-CENTRAL1"
}

resource "google_storage_bucket" "droplet-cf" {
  name     = "droplet_cf_${var.project}"
  location = "US-CENTRAL1"
}

resource "google_storage_bucket" "resource-cf" {
  name     = "resource_cf_${var.project}"
  location = "US-CENTRAL1"
}


resource "google_sql_database_instance" "master" {
  name = "cfdatabase"
  region = "asia-south1"
  settings {
    tier = "db-n1-standard-1"
    ip_configuration {
    authorized_networks {
    name = "all"
    value = "0.0.0.0/0"
    }
    }
    
 }
}

resource "google_sql_user" "users" {
  name     = "${var.user_sql}"
  instance = "${google_sql_database_instance.master.name}"
  host     = "%"
  password = "${var.user_sql_password}"
}

resource "google_sql_database" "bbs" {
  name      = "bbs"
  instance  = "${google_sql_database_instance.master.name}"
}

resource "google_sql_database" "cc" {
  name      = "cc"
  instance  = "${google_sql_database_instance.master.name}"
}

resource "google_sql_database" "locket" {
  name      = "locket"
  instance  = "${google_sql_database_instance.master.name}"
}

resource "google_sql_database" "uaa" {
  name      = "uaa"
  instance  = "${google_sql_database_instance.master.name}"
}

resource "google_sql_database" "silk_controller" {
  name      = "silk_controller"
  instance  = "${google_sql_database_instance.master.name}"
}

resource "google_sql_database" "policy_server" {
  name      = "policy_server"
  instance  = "${google_sql_database_instance.master.name}"
}


resource "google_sql_database" "routing_api" {
  name      = "routing_api"
  instance  = "${google_sql_database_instance.master.name}"
}

resource "google_sql_database" "servicebroker" {
  name      = "servicebroker"
  instance  = "${google_sql_database_instance.master.name}"
}



resource "google_compute_instance_group" "bosh-cf-router-lb" {
  name        = "bosh-cf-router-lb"
  description = "CF router instance group"

  named_port {
    name = "https"
    port = "443"
  }
  named_port {
    name = "http"
    port = "80"
  }


 zone = "australia-southeast1-a"
}


resource "tls_private_key" "domaincert" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "domaincert" {
  key_algorithm   = "${tls_private_key.domaincert.algorithm}"
  private_key_pem = "${tls_private_key.domaincert.private_key_pem}"

  # Certificate expires after 12 hours.
  validity_period_hours = 8760

  # Generate a new certificate if Terraform is run within three
  # hours of the certificate's expiration time.
  early_renewal_hours = 24

  # Reasonable set of uses for a server SSL certificate.
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["${var.domains}"]

  subject {
    common_name  = "${var.domain}"
    organization = "Cloudfoundry GCP free example"
  }
}

module "gce-lb-http" {
  source         = "github.com/GoogleCloudPlatform/terraform-google-lb-http"
  name           = "bosh-cf-router-lb"
  target_tags       = ["bosh-cf-router-lb","bosh-cf-ws"]
  ssl            = true
  private_key    = "${tls_private_key.domaincert.private_key_pem}"
  certificate    = "${tls_self_signed_cert.domaincert.cert_pem}"

  backends = {
    "0" = [
      {
        group = "${google_compute_instance_group.bosh-cf-router-lb.self_link}"
      },
    ]
  }

  backend_params = [
    // health check path, port name, port number, timeout seconds.
    "/health,http,8080,10",
 ]
}


resource "google_compute_target_pool" "bosh-cf-tcp-router" {
  name = "bosh-cf-tcp-router"
  region = "australia-southeast1"
  session_affinity = "NONE"

  health_checks = [
    "${google_compute_http_health_check.bosh-cf-tcp-router.name}",
  ]
}

resource "google_compute_target_pool" "bosh-cf-tcp-router" {
  name = "bosh-cf-tcp-router"
  region = "australia-southeast1"
}

resource "google_compute_target_pool" "bosh-cf-ws" {
  name = "bosh-cf-ws"
  region = "australia-southeast1"
  session_affinity = "NONE"

  health_checks = [
    "${google_compute_http_health_check.bosh-cf-public.name}",
  ]

}

resource "google_compute_target_pool" "bosh-cf-ssh-proxy" {
  name = "bosh-cf-ssh-proxy"
  region = "australia-southeast1"
}

resource "google_compute_http_health_check" "bosh-cf-tcp-router" {
  name         = "bosh-cf-tcp-router"
  port         = 80
  request_path = "/health"
}

resource "google_compute_http_health_check" "bosh-cf-public" {
  name         = "bosh-cf-public"
  port         = 8080
  request_path = "/health"
}


resource "google_compute_forwarding_rule" "bosh-cf-tcp-router" {
  name        = "bosh-cf-tcp-router"
  target      = "${google_compute_target_pool.bosh-cf-tcp-router.self_link}"
  port_range  = "1024-32768"
  ip_protocol = "TCP"
  region = "australia-southeast1"
}

resource "google_compute_forwarding_rule" "bosh-cf-ws-https" {
  name        = "bosh-cf-ws-https"
  target      = "${google_compute_target_pool.bosh-cf-ws.self_link}"
  port_range  = "443"
  ip_protocol = "TCP"
  region = "australia-southeast1"
}

resource "google_compute_forwarding_rule" "bosh-cf-ws-http" {
  name        = "bosh-cf-ws-http"
  target      = "${google_compute_target_pool.bosh-cf-ws.self_link}"
  port_range  = "80"
  ip_protocol = "TCP"
  region = "australia-southeast1"
}

resource "google_compute_forwarding_rule" "bosh-cf-ssh-proxy" {
  name        = "bosh-cf-ssh-proxy"
  target      = "${google_compute_target_pool.bosh-cf-ssh-proxy.self_link}"
  port_range  = "2222"
  ip_protocol = "TCP"
  region = "australia-southeast1"

}