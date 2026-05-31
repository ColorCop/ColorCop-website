resource "aws_s3_bucket" "bucket" {
  bucket = var.domain
}

resource "aws_s3_bucket_logging" "bucket_logging" {
  bucket = aws_s3_bucket.bucket.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.domain}-logs"
}

# Enable ACLs on the log bucket so CloudFront can write access logs
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket,
    aws_s3_bucket_public_access_block.bucket,
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}

# Grant CloudFront permission to write access logs to this bucket
resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]

  bucket = aws_s3_bucket.logs.id
  acl    = "log-delivery-write"
}

# Configure website settings
resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rules = jsonencode([
    {
      Condition = {
        KeyPrefixEquals = "colorcop/download"
      }
      Redirect = {
        ReplaceKeyWith = "download"
        HostName = var.domain
      }
    },
    {
      Condition = {
        KeyPrefixEquals = "colorcop/features"
      }
      Redirect = {
        ReplaceKeyWith = "features"
        HostName = var.domain
      }
    }
  ])
}

resource "aws_cloudfront_distribution" "distribution" {
  aliases         = [local.www_domain, var.domain]
  comment         = "Cloudfront distribution for ${var.domain}"
  enabled         = true
  http_version    = "http2and3"
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_regional_domain_name
    prefix          = "cloudfront/"
  }


  origin {
    domain_name = aws_s3_bucket_website_configuration.bucket.website_endpoint
    origin_id   = aws_s3_bucket.bucket.bucket_regional_domain_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  tags = {
    Environment = var.env
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.cache-optimized.id
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.bucket.bucket_regional_domain_name
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.record : record.fqdn]
}

