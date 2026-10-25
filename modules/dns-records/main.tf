terraform {
  required_version = ">= 1.11"
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.6"
    }
  }
}

resource "dns_a_record_set" "this" {
  for_each = var.records

  zone      = "${var.zone}."
  name      = each.key
  addresses = [each.value]
  ttl       = var.ttl
}
