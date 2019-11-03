resource "aws_db_instance" "django-rds" {
  identifier = var.rds_identifier
  allocated_storage = 20
  storage_type = "gp2"
  engine = "postgres"
  engine_version = "11.5"
  instance_class = "db.t2.micro"
  name = "django_sample"
  username = "postgres"
  password = "postgres"
  skip_final_snapshot = "true"
}
