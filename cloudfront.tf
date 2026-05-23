# ==================== ACM CERTIFICATE ====================

resource "aws_acm_certificate" "main" {
  domain_name               = "pixels.dev.br"
  subject_alternative_names = ["www.pixels.dev.br", "pixels.net.br", "www.pixels.net.br"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "pixels-main-cert" }
}

# ==================== LOCAL TO DETERMINE ZONE ====================

locals {
  cert_validation_zone_id = {
    "pixels.dev.br"     = aws_route53_zone.pixels_dev_br.zone_id
    "www.pixels.dev.br" = aws_route53_zone.pixels_dev_br.zone_id
    "pixels.net.br"     = aws_route53_zone.pixels_net_br.zone_id
    "www.pixels.net.br" = aws_route53_zone.pixels_net_br.zone_id
  }
}

# ==================== CERTIFICATE VALIDATION RECORDS ====================

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = local.cert_validation_zone_id[each.key]
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ==================== CLOUDFRONT DISTRIBUTION ====================

resource "aws_cloudfront_distribution" "wordpress" {
  origin {
    domain_name = "18.230.130.74"
    origin_id   = "ec2-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.php"
  aliases             = ["pixels.dev.br", "www.pixels.dev.br", "pixels.net.br", "www.pixels.net.br"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ec2-origin"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.main.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = { Name = "pixels-wordpress" }
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.wordpress.domain_name
}
