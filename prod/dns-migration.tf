removed {
  from = module.dns_records.terraform_data.record

  lifecycle {
    destroy = false
  }
}

import {
  for_each = local.dns_records
  to       = module.dns_records.dns_a_record_set.this[each.key]
  id       = "${each.key}.macopla.home."
}
