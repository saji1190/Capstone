# Create the Application Load Balancer
resource "aws_lb" "wpresume_alb" {
  name               = "wpresume-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public[0].id, aws_subnet.public[1].id]  # Replace with your subnet IDs
  security_groups    = [aws_security_group.wordpress_sg.id] # Replace with your security group ID
}

# Create the target group
resource "aws_lb_target_group" "wpresume_target_group" {
  name        = "wpresume-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id # Replace with your VPC ID
  target_type = "instance"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# Create the listener
resource "aws_lb_listener" "wpresume_listener" {
  load_balancer_arn = aws_lb.wpresume_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wpresume_target_group.arn
  }
}
