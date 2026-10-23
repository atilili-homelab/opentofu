#=============================================================#
#========================= LXC SPECS =========================#
#=============================================================#
variable "lxc_name" {
  type        = string
  description = "Nom du LXC dans Proxmox"
}
variable "lxc_id" {
  type        = number
  default     = null
  nullable    = true
  description = "ID unique du LXC  dans Proxmox (si null, calculé depuis ip_adresse ! {3eme octet}+{4ème octet})"
}
variable "target_node" {
  type        = string
  description = "Nom du nœud Proxmox où le LXC sera créée"
}
variable "template_file_id" {
  type        = string
  description = "ID du template LXC"
}
variable "os_type" {
  type        = string
  default     = "debian"
  description = "Type d'OS (debian, ubuntu, alpine, etc.)"
}
variable "unprivileged" {
  type        = bool
  default     = true
  description = "Conteneur non-privilégié (recommandé pour la sécurité)"
}
variable "started" {
  type        = bool
  default     = true
  description = "Démarrer le conteneur après création"
}
variable "start_on_boot" {
  type        = bool
  default     = true
  description = "Démarrer automatiquement au boot du nœud Proxmox"
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
variable "cores" {
  type        = number
  default     = 1
  description = "Nombre de cœurs CPU"
}
variable "memory" {
  type        = number
  default     = 512
  description = "RAM dédiée en Mo"

  validation {
    condition     = var.memory >= 128 && floor(var.memory) == var.memory
    error_message = "memory doit être un entier >= 128 (Mo)."
  }
}
variable "swap" {
  type        = number
  default     = 0
  description = "Swap en Mo (défaut 0 dans le provider)"
}
variable "disk_size" {
  type        = number
  default     = 4
  description = "Taille du rootfs en Go"
}

variable "disk_datastore" {
  type        = string
  default     = "local-ZFS"
  description = "Datastore pour le rootfs"
}

# == Réseau ==
variable "ip_address" {
  type        = string
  description = "Adresse IP statique du conteneur"

  validation {
    condition     = can(cidrhost("${var.ip_address}/32", 0))
    error_message = "ip_address doit être une IPv4 valide."
  }
}

variable "subnet_mask" {
  type        = number
  default     = 24
  description = "Masque de sous-réseau CIDR"
}

variable "gateway" {
  type        = string
  description = "Passerelle par défaut"
}

variable "vlan_id" {
  type        = number
  default     = null
  description = "Tag VLAN (si null, auto-détecté depuis IP)"
}

# == Initialisation ==
variable "hostname" {
  type        = string
  default     = null
  description = "Hostname (si null, utilise lxc_name)"
}

variable "domain" {
  type        = string
  default     = "macopla.home"
  description = "Domaine du conteneur"
}

variable "ssh_public_keys" {
  type        = list(string)
  default     = []
  description = "Clés SSH publiques pour root"
}

variable "password" {
  type        = string
  default     = null
  sensitive   = true
  description = "Mot de passe root (optionnel)"
}

variable "description" {
  type        = string
  default     = null
  description = "Description du conteneur"
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags du conteneur"
}

variable "timeout_delete" {
  type        = number
  default     = 600
  description = "Timeout (secondes) pour la suppression du conteneur (utile si Proxmox est lent à arrêter/détruire)."
}
