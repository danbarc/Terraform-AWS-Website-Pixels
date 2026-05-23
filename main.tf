# ==================== NETWORKING ====================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "wp-vpc" }
}

# First Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "sa-east-1a"
  tags                    = { Name = "wp-public-1a" }
}

# Second Public Subnet (Required for RDS)
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "sa-east-1b"
  tags                    = { Name = "wp-public-1b" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "wp-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "wp-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

# ==================== SECURITY GROUPS ====================

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wp-web-sg" }
}

resource "aws_security_group" "rds_sg" {
  name   = "wp-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wp-rds-sg" }
}

# ==================== IAM for SSM ====================

resource "aws_iam_role" "ec2_ssm_role" {
  name = "wp-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "wp-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# ==================== KEY PAIR ====================

resource "aws_key_pair" "wp_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/pixels-wp-key.pub")
}

# ==================== AMI ====================

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }
}

# ==================== EC2 INSTANCE ====================

resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.wp_key.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = file("userdata.sh")

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp3"
  }

  tags = { Name = "pixels-wp" }
}

# ==================== RDS ====================

resource "aws_db_subnet_group" "main" {
  name       = "wp-db-subnet-group"
  subnet_ids = [aws_subnet.public.id, aws_subnet.public2.id] # Now using 2 AZs

  tags = { Name = "wp-db-subnet-group" }
}

resource "aws_db_instance" "wordpress" {
  identifier              = "pixels-wp-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  db_name                 = "wordpress"
  username                = "wpuser"
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 7
  multi_az                = false

  tags = { Name = "pixels-wp-db" }
}

# ==================== OUTPUTS ====================

output "ec2_public_ip" {
  value = aws_instance.wordpress.public_ip
}

output "ssm_connect_command" {
  value = "aws ssm start-session --target ${aws_instance.wordpress.id}"
}

output "rds_endpoint" {
  value = aws_db_instance.wordpress.endpoint
}

output "wordpress_installer_url" {
  value = "http://${aws_instance.wordpress.public_ip}/installer.php"
}
