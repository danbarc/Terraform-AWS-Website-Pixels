# ==================== INSTANCE CONFIG ====================

variable "instance_type" {
  description = "EC2 instance type for the WordPress server"
  type        = string
  default     = "t3.nano"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "pixels-wp-key"
}

# ==================== DATABASE CONFIG ====================

variable "db_password" {
  description = "Master password for the RDS MySQL database (must be strong)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "The db_password must be at least 16 characters long."
  }
}

# ==================== OPTIONAL VARIABLES (Future) ====================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "volume_size" {
  description = "Size of the EC2 root volume in GB"
  type        = number
  default     = 30
}
