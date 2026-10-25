resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "mandy-ha-vpc"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "mandy-ha-igw"
    Project = "terraform-ha-2tier-aws"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name    = "mandy-public-subnet-a"
    Project = "terraform-ha-2tier-aws"
    Tier    = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name    = "mandy-public-subnet-b"
    Project = "terraform-ha-2tier-aws"
    Tier    = "public"
  }
}

resource "aws_subnet" "private_app_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name    = "mandy-private-app-subnet-a"
    Project = "terraform-ha-2tier-aws"
    Tier    = "application"
  }
}

resource "aws_subnet" "private_app_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name    = "mandy-private-app-subnet-b"
    Project = "terraform-ha-2tier-aws"
    Tier    = "application"
  }
}

resource "aws_subnet" "private_db_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name    = "mandy-private-db-subnet-a"
    Project = "terraform-ha-2tier-aws"
    Tier    = "database"
  }
}

resource "aws_subnet" "private_db_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name    = "mandy-private-db-subnet-b"
    Project = "terraform-ha-2tier-aws"
    Tier    = "database"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "mandy-public-rt"
    Project = "terraform-ha-2tier-aws"
    Tier    = "public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_a" {
  domain = "vpc"

  tags = {
    Name    = "mandy-nat-eip-a"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"

  tags = {
    Name    = "mandy-nat-eip-b"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.allocation_id
  subnet_id     = aws_subnet.public_a.id

  tags = {
    Name    = "mandy-nat-gateway-a"
    Project = "terraform-ha-2tier-aws"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.allocation_id
  subnet_id     = aws_subnet.public_b.id

  tags = {
    Name    = "mandy-nat-gateway-b"
    Project = "terraform-ha-2tier-aws"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private_app_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name    = "mandy-private-rt-a"
    Project = "terraform-ha-2tier-aws"
    Tier    = "application"
  }
}

resource "aws_route_table" "private_app_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name    = "mandy-private-rt-b"
    Project = "terraform-ha-2tier-aws"
    Tier    = "application"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_app_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_app_b.id
  route_table_id = aws_route_table.private_app_b.id
}

resource "aws_security_group" "alb" {
  name        = "mandy-alb-sg"
  description = "Allow HTTP traffic from the internet to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "mandy-alb-sg"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_security_group" "ec2" {
  name        = "mandy-ec2-sg"
  description = "Allow HTTP traffic from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "mandy-ec2-sg"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_security_group" "rds" {
  name        = "mandy-rds-sg"
  description = "Allow MySQL traffic from EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Traffic from EC2 to RDS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "mandy-rds-sg"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_lb" "web" {
  name               = "mandy-ha-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name    = "mandy-ha-alb"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_lb_target_group" "web" {
  name        = "mandy-web-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name    = "mandy-web-tg"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# IAM role assumed by EC2 instances for Systems Manager
resource "aws_iam_role" "ec2_ssm" {
  name = "mandy-ha-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "mandy-ha-ec2-role"
    Project = "terraform-ha-2tier-aws"
  }
}

# Give the EC2 role the permissions required by SSM
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 receives an instance profile rather than the IAM role directly
resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "mandy-ha-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "mandy-ha-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Read the external startup script and Base64 encode it for EC2 user data
  user_data = base64encode(file("${path.module}/user-data.sh"))
}

resource "aws_autoscaling_group" "web" {
  name = "mandy-asg-web"

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = [
    aws_subnet.private_app_a.id,
    aws_subnet.private_app_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "mandy-asg-web"
    propagate_at_launch = true
  }
}

resource "aws_db_subnet_group" "main" {
  name = "mandy-ha-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_db_a.id,
    aws_subnet.private_db_b.id
  ]

  tags = {
    Name    = "mandy-ha-db-subnet-group"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_db_instance" "mysql" {
  identifier = "mandy-ha-mysql"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "mandyapp"
  username = "admin"

  multi_az                    = true
  publicly_accessible         = false
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  manage_master_user_password = true
  backup_retention_period     = 1

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name    = "mandy-ha-mysql"
    Project = "terraform-ha-2tier-aws"
  }
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "mandy-private-db-rt"
    Project = "terraform-ha-2tier-aws"
    Tier    = "database"
  }
}

resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name        = "mandy-ha-unhealthy-targets"
  alarm_description = "Alarm when the ALB target group has one or more unhealthy targets"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"

  statistic           = "Average"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = aws_lb.web.arn_suffix
    TargetGroup  = aws_lb_target_group.web.arn_suffix
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name    = "mandy-ha-unhealthy-targets"
    Project = "terraform-ha-2tier-aws"
  }
}