variable "records" {
  type        = map(string)
  description = "Enregistrements A à gérer : nom court => IPv4"
}

variable "zone" {
  type        = string
  default     = "macopla.home"
  description = "Zone DNS"
}

variable "ttl" {
  type        = number
  default     = 3600
  description = "TTL des enregistrements, en secondes"
}
