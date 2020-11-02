terraform {
  backend "remote" {
    organization = "ninad-one"

    workspaces {
      name = "assignments"
    }
  }
}
