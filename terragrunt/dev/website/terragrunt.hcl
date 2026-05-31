
# TODO(j4y): dev.colorcop.net DNS isn't there and needs some work
skip = true

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "../../modules/website"
}

inputs = {
  env    = "dev"
  domain = "dev.colorcop.net"
}

