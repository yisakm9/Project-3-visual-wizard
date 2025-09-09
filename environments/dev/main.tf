resource "aws_s3_bucket" "name" {
  bucket = "${var.project_name}-photo-storage"

  
}