provider "aws" {
  region = "us-west-2"
}

module "web" {
  source = "../modules/web"
}
