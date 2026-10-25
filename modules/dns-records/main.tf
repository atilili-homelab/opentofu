terraform {
  required_providers {
    dns = {
      source = "hashicorp/dns"
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
