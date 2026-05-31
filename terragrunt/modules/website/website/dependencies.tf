# look up the route 53 zone by domain name
# Note that this assumes it's already created
data "aws_route53_zone" "main" {
  name = var.domain
}

# reference an AWS managed cloudfront cache policy
data "aws_cloudfront_cache_policy" "cache-optimized" {
  name = "Managed-CachingOptimized"
}
