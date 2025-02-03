output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.api_gateway.id}.execute-api.${var.region}.amazonaws.com/prod/invoke"
}

