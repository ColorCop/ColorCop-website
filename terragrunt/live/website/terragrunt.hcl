include "root" {
  path = find_in_parent_folders()
}

terraform {
  # Prevent OpenTofu/Terraform from generating a .terraform.lock.hcl file
  # inside the live Terragrunt directory. Live folders do not own provider
  # versions — the module lockfile in terraform/website/ is the single
  # source of truth. Without this flag, `terragrunt init` would create a
  # local lockfile here, causing CI to detect uncommitted changes.
  extra_arguments "disable_lockfile" {
    commands  = ["init"]
    arguments = ["-lockfile=readonly"]
  }

  # Force initialization before plan/apply, but run *terraform init*
  # instead of terragrunt init. Running terragrunt init inside the
  # .terragrunt-cache causes include recursion and breaks.
  before_hook "force_init" {
    commands = ["plan", "apply"]
    execute  = ["terraform", "init", "-lockfile=readonly"]
  }

  source = "../../../terraform/website/"
}

inputs = {
  env    = "live"
  domain = "colorcop.net"
}
