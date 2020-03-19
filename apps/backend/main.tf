provider "aws" {
  region  = "eu-central-1"
  version = "~> 2.50"
}

terraform {
  backend "s3" {
    bucket = "state.digitale-kumpel.ruhr"
    key    = "nettrek_backend"
    region = "eu-central-1"
  }
}

data "archive_file" "lambda_zip" {
  type          = "zip"
  source_file   = "index.js"
  output_path   = "lambda_function.zip"
}

resource "aws_lambda_function" "popcorn" {
  function_name = "nettrek-backend-popcorn"
  handler = "index.popcorn"
  role    = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  filename         = data.archive_file.lambda_zip.output_path
  runtime = "nodejs12.x"
  memory_size = 128
  timeout = 3
}

resource "aws_lambda_function" "ticket" {
  function_name = "nettrek-backend-ticket"
  handler = "index.ticket"
  role    = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  filename         = data.archive_file.lambda_zip.output_path
  runtime = "nodejs12.x"
  memory_size = 128
  timeout = 3
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

output "lambda_name_popcorn" {
  value = aws_lambda_function.popcorn.function_name
}

output "lambda_name_ticket" {
  value = aws_lambda_function.ticket.function_name
}