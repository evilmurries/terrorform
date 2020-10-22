#config
provider "aws" {
  region = "us-east-2"
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terrorform"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

# variables
variable "server_port" {
  description = "the port for the server"
  type        = number
  default     = 8080
}

output "alb_dns_name" {
  value       = aws_lb.alb_web.dns_name
  description = "The domain name of the load balancer"
}

# alb resources
resource "aws_launch_configuration" "web_config" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sg_web.id]

  user_data = data.template_file.user_data.rendered
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "alb_web" {
  name               = "autoscalingGroup"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.sg_alb.id]
}

resource "aws_lb_listener" "alb_web_listener" {
  load_balancer_arn = aws_lb.alb_web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_security_group" "sg_alb" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_web" {
  name = "Terrorform Web Server"
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "asg_web" {
  launch_configuration = aws_launch_configuration.web_config.name
  min_size             = 2
  max_size             = 5
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [aws_lb_target_group.tg_asg_web.arn]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terrorform-asg-web"
    propagate_at_launch = true
  }
}

resource "aws_lb_target_group" "tg_asg_web" {
  name     = "targetGroup"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.alb_web_listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_asg_web.arn
  }
}

# data sources
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "template_file" "user_data" {
  template = file("user-data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}