variable "state_passphrase" {
  type        = string
  sensitive   = true
  description = "Passphrase de chiffrement du state, lue dans OpenBao (secret/opentofu/state)"
}
