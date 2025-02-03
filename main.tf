provider "aws" {
  region  = var.region
  profile = var.profile
}

# Create the VPC
resource "aws_vpc" "serverless_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                 = aws_vpc.serverless_vpc.id
  cidr_block             = "10.0.1.0/24"
  availability_zone      = "us-east-1a"
  map_public_ip_on_launch = true
}

# Create Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                 = aws_vpc.serverless_vpc.id
  cidr_block             = "10.0.2.0/24"
  availability_zone      = "us-east-1b"
  map_public_ip_on_launch = true
}

# Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id                 = aws_vpc.serverless_vpc.id
  cidr_block             = "10.0.3.0/24"
  availability_zone      = "us-east-1a"
}

# Create Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id                 = aws_vpc.serverless_vpc.id
  cidr_block             = "10.0.4.0/24"
  availability_zone      = "us-east-1b"
}

# Lambda Execution Role
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Effect = "Allow"
    }]
  })
}

# Attach AWSLambdaBasicExecutionRole Policy to the Lambda Role
resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda-execution-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_exec_role.name]
}

# ECR Repository for Lambda Container
resource "aws_ecr_repository" "lambda_repo" {
  name = "lambda-repository"
}

# Security Group for Lambda
resource "aws_security_group" "lambda_sg" {
  name        = "lambda_security_group"
  description = "Allow Lambda function to access resources"
  vpc_id      = aws_vpc.serverless_vpc.id
}

# Lambda Function
resource "aws_lambda_function" "serverless_lambda" {
  function_name = "serverless-lambda"
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"

  vpc_config {
    subnet_ids         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# API Gateway for Lambda Invocation
resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "serverless-api-gateway"
  description = "API Gateway to trigger Lambda function"
}

# Create the root API Gateway Resource
resource "aws_api_gateway_resource" "root_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "invoke"
}

# Define the API Gateway Method
resource "aws_api_gateway_method" "invoke_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.root_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration to Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.root_resource.id
  http_method             = aws_api_gateway_method.invoke_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.serverless_lambda.arn}/invocations"
}

# Create the API Gateway Stage
resource "aws_api_gateway_stage" "api_stage" {
  rest_api_id  = aws_api_gateway_rest_api.api_gateway.id
  stage_name   = "prod"
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  triggers = {
    redeploy = "${timestamp()}"
  }
}

# Lambda Permission to Invoke from API Gateway
resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  function_name = aws_lambda_function.serverless_lambda.function_name
}

