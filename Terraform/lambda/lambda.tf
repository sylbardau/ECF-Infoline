# IAM Role pour la Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "infoline-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Security group pour la Lambda (sortie vers RDS uniquement)
resource "aws_security_group" "lambda" {
  name   = "infoline-lambda-sg"
  vpc_id = var.vpc_id
 
  egress {
    description = "PostgreSQL vers RDS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
 
  egress {
    description = "HTTPS vers Secrets Manager / internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}

# Fonction Lambda
resource "aws_lambda_function" "login" {
  function_name = "infoline-login"
  role          = aws_iam_role.lambda_exec.arn
  runtime       = "java21"
  handler       = var.lambda_handler # Variable a metre a jour par l'equipe de dev 

  # Le JAR est fourni par l'équipe dev 
  filename         = "${path.module}/login.jar"
  source_code_hash = filebase64sha256("${path.module}/login.jar")

  memory_size = 512 # Java nécessite plus de mémoire que Node/Python
  timeout     = 30

  vpc_config {
    subnet_ids         = var.private_subnets
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_ENDPOINT = var.db_endpoint
      ENV         = var.environment
    }
  }

  tags = {
    Name        = "infoline-lambda-login"
    Environment = var.environment
  }
}
