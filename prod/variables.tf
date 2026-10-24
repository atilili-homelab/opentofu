# Configuration Provider
variable "proxmox_url" {
  type    = string
  default = "http://10.86.30.10:8006"
}

variable "login_approle_role_id" {
  type      = string
  sensitive = true
}

variable "login_approle_secret_id" {
  type      = string
  sensitive = true
}

variable "ssh_public_keys" {
  type        = list(string)
  default     = []
  description = "Liste de clés SSH à ajouter aux utilisateurs"
}

variable "ip_base" {
  type    = string
  default = "10.86"
}

variable "host_id_min" {
  type    = number
  default = 20
}

variable "host_id_max" {
  type    = number
  default = 99
}

variable "vms" {
  description = "Map des VMs à créer"
  type = map(object({
    target_node = string
    host_id     = number
    # Le reste est optionnel (valeur par défaut du module)
    cores      = optional(number, 1)
    cpu_shares = optional(number, 1024)
    memory     = optional(number, 2048)
    memory_max = optional(number)
    disks = optional(map(object({
      size      = optional(number, 10)
      storage   = optional(string, "local-ZFS")
      interface = optional(string, "scsi0")
      backup    = optional(bool, false)
      })), {
      root = {}
    })
    gpu_passthrough = optional(bool, false)
    iso_file_id     = optional(string, null)
    started         = optional(bool, true)
    protection      = optional(bool, true)
    onboot          = optional(bool, true)
    order           = optional(number, null)
    down_delay      = optional(number, null)
    up_delay        = optional(number, null)
    # ha              = optional(bool, false) <= fonctionnalité provider cassé
    description = optional(string, null)
    tags        = optional(list(string), [])
  }))
  validation {
    condition     = length(distinct([for vm in values(var.vms) : vm.host_id])) == length(var.vms)
    error_message = "Chaque VM doit avoir une ID unique."
  }
  validation {
    condition = alltrue([for vm in values(var.vms) : contains(["meganode", "supernode", "mininode"],
    vm.target_node)])
    error_message = "Chaque VM doit avoir un target_node valide (meganode/supernode/mininode)."
  }
  validation {
    condition     = alltrue([for vm in values(var.vms) : vm.host_id >= var.host_id_min && vm.host_id <= var.host_id_max])
    error_message = "Range d'ID obligatoire des VM = 20 à 99"
  }
}

variable "lxcs" {
  description = "Map des LXC à créer"
  type = map(object({
    target_node      = string
    host_id          = number
    template_file_id = optional(string, "nas-ressources:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst")
    cores            = optional(number, 1)
    memory           = optional(number, 512)
    swap             = optional(number, 0)
    disk_size        = optional(number, 4)
    disk_datastore   = optional(string, "local-ZFS")
    start_on_boot    = optional(bool, true)
    started          = optional(bool, true)
    protection       = optional(bool, true)
    order            = optional(number, null)
    down_delay       = optional(number, null)
    up_delay         = optional(number, null)
    unprivileged     = optional(bool, true)
    description      = optional(string, null)
    tags             = optional(list(string), [])
    ssh_public_keys  = optional(list(string), [])
    password         = optional(string, null)
  }))
  default = {}
  validation {
    condition     = length(distinct([for lxc in values(var.lxcs) : lxc.host_id])) == length(var.lxcs)
    error_message = "Chaque LXC doit avoir un host_id unique."
  }
  validation {
    condition = alltrue([for lxc in values(var.lxcs) : contains(["meganode", "supernode", "mininode"],
    lxc.target_node)])
    error_message = "Chaque LXC doit avoir un target_node valide (meganode/supernode/mininode)."
  }
}
