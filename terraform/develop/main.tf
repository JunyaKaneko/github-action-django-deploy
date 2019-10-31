provider "aws" {
    region = "us-west-2"
}

module "rds" {
    source = "../modules/web"
    rds_identifier = "django-sample-dev"
}
