#=============================================================#
#========================= VM  SPECS =========================#
#=============================================================#

variable "vm_name" {
  type        = string
  description = "Nom de la VM dans Proxmox"
}

variable "vm_id" {
  type        = number
  default     = null
  nullable    = true
  description = "ID unique de la VM dans Proxmox (si null, calculé depuis ip_adresse ! {3eme octet}+{4ème octet})"
}

variable "target_node" {
  type        = string
  description = "Nom du nœud Proxmox où la VM sera créée"
}

variable "template_id" {
  type        = number
  default     = null
  nullable    = true
  description = "ID du template Proxmox à utiliser pour la création de la VM (doit être un nombre entier). Défini automatiquement par le target_node"
}

variable "iso_file_id" {
  type        = string
  default     = null
  nullable    = true
  description = "ID du fichier ISO à utiliser pour la création de la VM. Si défini, la VM est créée depuis l'ISO au lieu d'un clone template"
}

variable "cores" {
  type        = number
  default     = 1
  description = "Nombre de cœurs CPU pour la VM"
}

variable "cpu_shares" {
  type        = number
  default     = 1024
  description = "CPU share/units (priorité relative, défaut 1024). Valeur : 512 (basse), 1024 (normale), 2048 (haute)"
}

variable "cpu_type" {
  type        = string
  default     = "host"
  description = "Processor type (host pour passthrought)"
}

variable "gpu_mapping" {
  type        = string
  default     = null
  description = "Nom du mapping PCI du GPU à passer à la VM (null = pas de GPU)"
}

variable "gpu_pcie" {
  type        = bool
  default     = true
  description = "Utiliser PCIe pour le GPU passthrough"
}

variable "gpu_rombar" {
  type        = bool
  default     = true
  description = "Activer ROM BAR pour le GPU"
}

variable "memory" {
  type        = number
  default     = 2048
  description = "Quantité de mémoire RAM pour la VM (en Mo)"

  validation {
    condition     = var.memory >= 256 && floor(var.memory) == var.memory
    error_message = "memory doit etre un entier >= 256 (Mo)."
  }
}

variable "memory_max" {
  type        = number
  default     = null
  description = "Quantité de mémoire RAM maximum pour ballooning (si null, pas de ballooning)"

  validation {
    condition     = var.memory_max == null || (var.memory_max >= var.memory && floor(var.memory_max) == var.memory_max)
    error_message = "memory_max doit etre null ou un entier >= memory."
  }
}

variable "vlan_id" {
  type        = number
  default     = null
  description = "Tag VLAN (si null, auto-détecté depuis IP - 3e octet)"
}

variable "disks" {
  type = map(object({
    size      = optional(number, 10)
    storage   = optional(string, "local-ZFS")
    interface = optional(string, "scsi0")
    aio       = optional(string, "io_uring")
    iothread  = optional(bool, true)
    backup    = optional(bool, false)
    cache     = optional(string, "none")
    discard   = optional(string, "on")
    replicate = optional(bool, true)
    ssd       = optional(bool, true)
  }))
  default = {
    root = {}
  }
  validation {
    condition     = contains(keys(var.disks), "root")
    error_message = "Le disque root est obligatoire."
  }
  validation {
    condition     = length(distinct([for d in values(var.disks) : d.interface])) == length(var.disks)
    error_message = "Chaque disque doit avoir une interface unique."
  }
  validation {
    condition     = var.target_node != "mininode" || !contains([for d in values(var.disks) : d.storage], "local-ZFS")
    error_message = "Le storage local-ZFS n'est pas autorisé sur le nœud mininode."
  }
  validation {
    condition     = alltrue([for d in values(var.disks) : d.size > 0])
    error_message = "Chaque disque doit avoir size > 0."
  }
  validation {
    condition = alltrue([
      for d in values(var.disks) :
      can(regex("^(scsi|virtio|sata|ide)[0-9]+$", d.interface))
    ])
    error_message = "interface disque invalide. Exemples: scsi0, scsi1, virtio0."
  }
}

variable "onboot" {
  type        = bool
  default     = true
  description = "Indique si la VM doit démarrer automatiquement au démarrage du nœud Proxmox"
}

variable "order" {
  type        = number
  default     = null
  description = "Ordre de boot et shutdown, 1 = premier boot et dernier shutdown"
}
variable "up_delay" {
  type        = number
  default     = null
  description = "Délai en seconde avant le boot du prochain LxC au demarrage"
}
variable "down_delay" {
  type        = number
  default     = null
  description = "Délai en seconde avant que le prochain LxC soit shutdown"
}

# == Cloud-Init Specs ==
variable "ip_address" {
  type        = string
  description = "Adresse IP statique à attribuer à la VM"

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "ip_address doit etre une IPv4 valide (ex: 10.86.40.11)."
  }
}

variable "subnet_mask" {
  type        = number
  default     = 24
  description = "Masque de sous-réseau CIDR pour la VM"

  validation {
    condition     = var.subnet_mask >= 1 && var.subnet_mask <= 32
    error_message = "subnet_mask doit être entre 1 et 32."
  }
}

variable "gateway" {
  type        = string
  description = "Passerelle par défaut pour la VM"
}

variable "hostname" {
  type        = string
  default     = null
  description = "Nom d'hôte de la VM"
}

variable "domain" {
  type        = string
  default     = "macopla.home"
  description = "Domaine de la VM"
}

variable "cloud_init_user_data" {
  type        = string
  description = "Contenu du fichier cloud-init user-data (en YAML) pour la configuration de la VM"
}

variable "cloud_init_datastore_id" {
  type        = string
  description = "ID du datastore où stocker le cloud-init"
}

variable "started" {
  type        = bool
  default     = true
  description = "Indique si la VM doit être démarrée après création (false = créée mais éteinte)"
}

variable "protection" {
  type        = bool
  default     = true
  description = "Protection Proxmox : empêche la suppression de la VM"
}

variable "snippets_datastore_id" {
  type        = string
  description = "ID du datastore où stocker les snippets cloud-init"

  validation {
    condition     = var.snippets_datastore_id != "local-ZFS"
    error_message = "snippets_datastore_id ne doit pas etre local-ZFS (snippets non supportes)."
  }
}

variable "description" {
  type        = string
  default     = null
  description = "Description de la VM"
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags de la VM"
}
