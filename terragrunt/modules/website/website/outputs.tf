output "distribution_id" {
  value       = aws_cloudfront_distribution.distribution.id
  description = "Cloudfront distribution ID.  This is used for invalidation"
}

output "bucket_name" {
  value       = aws_s3_bucket.bucket.id
  description = "Name of the S3 bucket that hosts the files for the website."
}
