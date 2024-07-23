locals {
  name = "WordPress Instance ${var.tagNameDate}"
}
#Get latest ami ID of Amazon Linux2 - values = ["amzn2-ami-hvm-*-x86_64-gp2"]
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "wordpress_instance" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.ec2_instance_type
  availability_zone           = var.availability_zones[0]
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.wordpress_sg.id]
  subnet_id                   = aws_subnet.public[0].id # Choose one of the public subnets


  tags = {
    Name = local.name
  }
  
 #user_data = file("UserDataEC2.sh")
 #user_data = data.template_file.userdataEC.rendered
 user_data = base64encode(templatefile("${path.module}/UserDataEC2.sh", {
    access_key    = var.access_key
    secret_key    = var.secret_key
    session_token = var.session_token
    region        = var.region
    bucket_name   = var.S3_BUCKET
    
    rds_endpoint = replace(aws_db_instance.rds-db.endpoint, ":3306", "")
    rds_username = var.rds_db_username
    rds_password = var.rds_db_password
    rds_db_name  = var.rds_db_name
    
    
    }))


 }

#  data "template_file" "userdataEC" {
#   template = file("UserDataEC2.sh")

#   vars = {
#     rds_endpoint = replace("${data.aws_db_instance.rds.endpoint}", ":3306", "")
#     rds_username = "${var.rds_db_username}"
#     rds_password = "${var.rds_db_password}"
#     rds_db_name  = "${var.rds_db_name}"
#   }
#  } 