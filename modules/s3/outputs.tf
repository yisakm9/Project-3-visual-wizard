# outputs.tf for S3

output "bucket_name" {
  value = aws_s3_bucket.image_storage.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.image_storage.arn
}