# Create a launch configuration
resource "aws_launch_configuration" "wpresume" {
  name_prefix   = "wpresume-launchconfig-"
  image_id      = data.aws_ami.amazon_linux.id # Replace with your desired AMI ID
  instance_type = var.ec2_instance_type
  security_groups = [aws_security_group.wordpress_sg.id]
  key_name        = var.key_name
  
}

# Create an Auto Scaling group
resource "aws_autoscaling_group" "wpresume" {
    launch_template {
    id      = aws_launch_template.scaling_launch_template.id
    version = "$Latest" #aws_launch_template.wordpress_launch_template.latest_version
  }
  name                      = "wpresume-asg"
  max_size                  = 4
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  #launch_configuration      = aws_launch_configuration.wpresume.name
  vpc_zone_identifier       = [aws_subnet.public[0].id, aws_subnet.public[1].id] # Replace with your subnet IDs

  tag {
    key                 = "Name"
    value               = "Wpresume_Instance_AS${var.tagNameDate}-"
    propagate_at_launch = true
  }
}

# Create a launch template
resource "aws_launch_template" "scaling_launch_template" {
  name_prefix            = "wpresume-launchtemplate-"
  image_id               = data.aws_ami.amazon_linux.id # Replace with your desired AMI ID
  instance_type          = var.ec2_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]
  # This will hold the configuration for each instance
  #user_data = base64encode(file("UserDataEC2.sh"))
  user_data = base64encode(templatefile("${path.module}/UserDataEC2.sh", {
    access_key    = var.access_key
    secret_key    = var.secret_key
    session_token = var.session_token
    region        = var.region
    bucket_name   = var.S3_BUCKET
    elb_dns       = aws_lb.wpresume_alb.dns_name

    rds_endpoint = replace(aws_db_instance.rds-db.endpoint, ":3306", "")
    rds_username = var.rds_db_username
    rds_password = var.rds_db_password
    rds_db_name  = var.rds_db_name
    
  }))
  lifecycle {
    create_before_destroy = true
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "wpresume-template${var.tagNameDate}"
    }
  }
}








