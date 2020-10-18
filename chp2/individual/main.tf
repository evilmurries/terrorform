provider "aws" {
    region = "us-east-2"
}

variable "server_port" {
    description = "the port for the server"
    type = number
    default = 8080
}

output "public_ip" {
    value = aws_instance.example.public_ip
    description = "Public IP of the web server"
}

resource "aws_instance" "example" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.web.id]

    user_data = <<-EOF
                #!/bin/bash
                echo "Spooky Scary" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

    tags = {
        Name = "terrorform"
    }
}

resource "aws_security_group" "web" {
    name = "Terrorform Web Server"
    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}