data "template_file" "iam_db_auth" {
  template = file(format("%s/iam_db_auth.tpl", path.module))
 
  # values pulled from Terraform variables and outputs
  vars = {
    project       = var.project
    db_endpoint   = aws_db_instance.db.endpoint
    db_username   = var.db_username
    db_port       = 3306
    region        = var.region
  }
}



