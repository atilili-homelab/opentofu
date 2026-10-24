proxmox_url     = "https://10.86.30.12:8006"
ssh_public_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFM6msAQtQM2H5CtSTtuJ03Pn6cSYQ7swOjBy1TIgsJr"]
nodes = {
  meganode  = { address = "10.86.30.11", template_id = 9000 }
  supernode = { address = "10.86.30.12", template_id = 9001 }
  mininode  = { address = "10.86.30.13", template_id = 9002 }
}
