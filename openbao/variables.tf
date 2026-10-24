variable "state_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase de chiffrement du state fournie par rbw"
}

variable "openbao_yoann_password" {
  type        = string
  sensitive   = true
  ephemeral   = true
  description = "Mot de passe userpass admin, à fournir uniquement à la création ou à la rotation"
}
