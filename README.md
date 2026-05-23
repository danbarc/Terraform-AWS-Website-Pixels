# Terraform Infrastructure - pixels.dev.br

This repository contains the IaC (Infrastructure as Code) for the **pixels.dev.br** WordPress website.

## Architecture

- **VPC** with public subnets in 2 Availability Zones (sa-east-1a + sa-east-1b)
- **EC2 Instance** (Ubuntu 26.04 + Apache + PHP 8.5)
- **RDS MySQL** (managed database)
- **Route 53** for DNS management
- **Let's Encrypt** SSL Certificate (via Certbot)
- **SSM Session Manager** for secure access (no public SSH)

## Domains

- **Primary**: pixels.dev.br
- **Secondary**: pixels.net.br
- **Other**: dgmais.com

## Project Structure

```
Terraform-AWS-Website-Pixels/
├── main.tf                 # Core infrastructure (VPC, EC2, RDS)
├── provider.tf
├── variables.tf
├── route53.tf              # DNS configuration
├── cloudfront.tf           # CloudFront + ACM (future)
├── userdata.sh             # Server bootstrap script
├── .gitignore
├── README.md
└── terraform.tfvars.example
```

## How to Deploy

# 1. Initialize
terraform init

# 2. Review changes
terraform plan

# 3. Deploy
terraform apply

## Important Notes

- Use t3.small during migration, then downgrade to t3.nano for cost savings
- Database password is defined in terraform.tfvars
- SSL is managed with Let's Encrypt (Certbot)
- Access the server using: aws ssm start-session --target <instance-id>

## Post-Deployment Tasks

- Run Certbot for HTTPS
- Update WordPress URLs using WP-CLI
- Clean up Duplicator files (installer.php + archive.zip) for security
- Consider enabling CloudFront + WAF in the future

## Technologies

- Terraform
- AWS (EC2, RDS, Route 53, VPC)
- WordPress
- Apache + PHP 8.5 + Let's Encrypt

Made specially for pixels.dev.br
