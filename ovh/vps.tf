data "ovh_me" "my_account" {}

resource "ovh_vps" "vps" {
  lifecycle {
    ignore_changes = [plan, plan_option, ovh_subsidiary]
  }
  display_name   = "controlplane_vps"
  ovh_subsidiary = data.ovh_me.my_account.ovh_subsidiary
  plan = [
    {
      duration     = "P1M"
      plan_code    = "vps-2027-model1"
      pricing_mode = "default"
      configuration = [
        {
          label = "vps_datacenter"
          value = "SBG"
        },
        {
          label = "vps_os"
          value = "Debian 13"
        }
      ]
    }
  ]
  plan_option = [
    {
      duration     = "P1M"
      plan_code    = "option-linux"
      pricing_mode = "default"
      quantity     = "1"
    },
    {
      duration     = "P1M"
      plan_code    = "option-storage-local-2027-model1"
      pricing_mode = "default"
      quantity     = "1"
    },
    {
      duration     = "P1M"
      plan_code    = "option-auto-backup-2027-1-model1"
      pricing_mode = "default"
      quantity     = "1"
    }
  ]
}

output "vps_display_name" {
  value = ovh_vps.vps.display_name
}
