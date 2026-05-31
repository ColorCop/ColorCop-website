include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}


terraform {
  # Point Terragrunt at the module inside terragrunt/modules/website.
  # This ensures Terraform runs ONLY inside .terragrunt-cache and NEVER
  # writes .terraform.lock.hcl into the live folder.
  source = "../../modules/website"
}

inputs = {
  env    = "live"
  domain = "colorcop.net"
}
