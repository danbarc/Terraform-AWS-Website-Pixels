# ==================== ROUTE 53 HOSTED ZONES ====================

# Main domain
resource "aws_route53_zone" "pixels_dev_br" {
  name    = "pixels.dev.br"
  comment = "Main website domain - pixels.dev.br"
}

# Secondary domain (SSL certificate domain)
resource "aws_route53_zone" "pixels_net_br" {
  name    = "pixels.net.br"
  comment = "Secondary domain - SSL certificate"
}

# Optional: dgmais.com
resource "aws_route53_zone" "dgmais_com" {
  name    = "dgmais.com"
  comment = "dgmais.com domain"
}

# ==================== DNS RECORDS - pixels.dev.br ====================

# Point to your EC2
resource "aws_route53_record" "pixels_dev_br_root" {
  zone_id = aws_route53_zone.pixels_dev_br.zone_id
  name    = "pixels.dev.br"
  type    = "A"
  ttl     = 300
  records = ["56.124.85.173"]
}

resource "aws_route53_record" "pixels_dev_br_www" {
  zone_id = aws_route53_zone.pixels_dev_br.zone_id
  name    = "www.pixels.dev.br"
  type    = "A"
  ttl     = 300
  records = ["18.230.130.74"]
}

# ==================== DNS RECORDS - pixels.net.br ====================

resource "aws_route53_record" "pixels_net_br_root" {
  zone_id = aws_route53_zone.pixels_net_br.zone_id
  name    = "pixels.net.br"
  type    = "A"
  ttl     = 300
  records = ["18.230.130.74"]
}

resource "aws_route53_record" "pixels_net_br_www" {
  zone_id = aws_route53_zone.pixels_net_br.zone_id
  name    = "www.pixels.net.br"
  type    = "A"
  ttl     = 300
  records = ["18.230.130.74"]
}

# ==================== Google Workspace MX Records (for all domains) ====================

# Google Workspace MX Records - pixels.dev.br
resource "aws_route53_record" "pixels_dev_br_mx" {
  zone_id = aws_route53_zone.pixels_dev_br.zone_id
  name    = ""
  type    = "MX"
  ttl     = 3600

  records = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com."
  ]
}

# Google Workspace MX Records - pixels.net.br
resource "aws_route53_record" "pixels_net_br_mx" {
  zone_id = aws_route53_zone.pixels_net_br.zone_id
  name    = ""
  type    = "MX"
  ttl     = 3600

  records = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com."
  ]
}

# Optional for dgmais.com
resource "aws_route53_record" "dgmais_com_mx" {
  zone_id = aws_route53_zone.dgmais_com.zone_id
  name    = ""
  type    = "MX"
  ttl     = 3600

  records = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com."
  ]
}

# ==================== OUTPUTS ====================

output "pixels_dev_br_nameservers" {
  value = aws_route53_zone.pixels_dev_br.name_servers
}

output "pixels_net_br_nameservers" {
  value = aws_route53_zone.pixels_net_br.name_servers
}

output "dgmais_com_nameservers" {
  value = aws_route53_zone.dgmais_com.name_servers
}
