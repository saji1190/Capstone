#You can provide Date value if need to know when its created and what is happening
variable "tagNameDate" {
  default = "04-07-2024"
}
# VPC Variables
variable "cidr_blocks" {
  default = ["0.0.0.0/0"]
}

variable "availability_zones" {
  description = "List of availability zones"
  default     = ["us-west-2a", "us-west-2b"] # Replace with your availability zones
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets"
  default     = ["10.0.0.0/26", "10.0.0.64/26"] # Adjust as needed
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for private subnets"
  default     = ["10.0.0.128/26", "10.0.0.192/26"] # Adjust as needed
}

# EC2 Variables
variable "ec2_instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
  default     = "vockey"
}

# UserData Variables

variable "access_key" {
  default = "access_key"
  }

variable "secret_key" {
  default = "sceret_key"
  }

variable "session_token" {
  default = "<sessio_token>"
  }

variable "region" {
  default     = "us-west-2"
}

# S3 Bucket Variables

variable "S3_BUCKET" {
  default     = "<Specify bucket name>"
}

# Variables for RDS DB Instance
variable "rds_db_username" {
  description = "Username for the RDS instance"
  default = "DBUsername" # Replace with your RDS username
}
variable "rds_db_password" {
  description = "Password for the RDS instance"
  default = "DBpassword" # Replace with your RDS User password
  sensitive = true
}
variable "rds_db_name" {
  description = "Name of the RDS DB instance"
  default = "DBname" # Replace with your desired RDS DB name
}
  
