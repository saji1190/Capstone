#Create security group of Ec2 instnace
resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress_sg"
  description = "Security group for WordPress instance"

  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }

  tags = {
    Name = "wordpress_sg ${var.tagNameDate}"
  }
}

# Create Security group for RDS Mysql Database
resource "aws_security_group" "rds-sg" {
  name        = "mysql_sg"
  description = "Security group for MySQL database"

  vpc_id = aws_vpc.vpc.id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.wordpress_sg.id]
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks
  }

  tags = {
    Name = "rds_sg ${var.tagNameDate}"
  }
}
