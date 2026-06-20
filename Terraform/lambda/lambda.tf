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

  # Le JAR est fourni par l'équipe dev - chemin à adapter
  filename         = "${path.module}/login.jar"  
  source_code_hash = filebase64sha256("${path.module}/login.jar")

  memory_size = 512  # Java nécessite plus de mémoire que Node/Python
  timeout     = 30

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