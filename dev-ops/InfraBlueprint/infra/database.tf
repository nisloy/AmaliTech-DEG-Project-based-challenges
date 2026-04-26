
# PART 3: DATABASE — RDS Subnet Group, Security Group, RDS



# Security Group for RDS Database
# Think of this as the vault door. Only the web server gets in.

resource "aws_security_group" "db" {
  name        = "vela-db-sg"
  description = "Security group for PostgreSQL RDS - allows access from web server only"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow PostgreSQL (5432) but ONLY from the web server's Security Group
  ingress {
    description     = "PostgreSQL from web server only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id] # The magic link!
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "vela-db-sg"
    Project = "vela-payments"
  }
}


# RDS Subnet Group
# Explicitly tells AWS which subnets the database is allowed to live in.

resource "aws_db_subnet_group" "main" {
  name        = "vela-db-subnet-group"
  description = "Places the database physically in our private subnets"

  # AWS requires at least TWO subnets in different Availability Zones
  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name    = "vela-db-subnet-group"
    Project = "vela-payments"
  }
}


# RDS Instance — The Managed Database

resource "aws_db_instance" "main" {
  identifier     = "vela-payments-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.micro" # Keep it in the free tier

  # Inject secrets via variables. NEVER hardcode passwords.
  username = var.db_username
  password = var.db_password

  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false # Explicitly ban internet traversal

  # Storage
  allocated_storage     = 20
  max_allocated_storage = 100

  # Maintenance & Cost Control
  skip_final_snapshot       = false                             # Forces AWS to take a backup right before destroying
  final_snapshot_identifier = "vela-payments-db-final-snapshot" # Name of the backup file
  multi_az                  = false   

  tags = {
    Name    = "vela-payments-db"
    Project = "vela-payments"
  }
}
