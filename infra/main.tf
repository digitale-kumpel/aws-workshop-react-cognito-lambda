provider "aws" {
  region  = "eu-central-1"
  version = "~> 2.50"
}

terraform {
  backend "s3" {
    bucket = "state.digitale-kumpel.ruhr"
    key    = "nettrek"
    region = "eu-central-1"
  }
}

resource "aws_s3_bucket" "nettrek-app-bucket" {
  bucket = var.name
}

resource "aws_s3_bucket_policy" "origin-policy" {
  bucket = aws_s3_bucket.nettrek-app-bucket.bucket
  policy = templatefile("${path.module}/policy.json", {
    identity = aws_cloudfront_origin_access_identity.nettrek-origin.id
    bucket = aws_s3_bucket.nettrek-app-bucket.id
  })
}

resource "aws_iam_role" "nettrek-popcorn" {
  name = "nettrek-cognito-popcorn-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_trust.json
}

resource "aws_iam_role" "nettrek-ticket" {
  name = "nettrek-cognito-ticket-role"
  assume_role_policy = data.aws_iam_policy_document.cognito_trust.json
}

data "aws_iam_policy_document" "cognito_trust" {
  statement {
    sid = "1"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"
    principals {
      identifiers = ["cognito-identity.amazonaws.com"]
      type = "Federated"
    }
    condition {
      test = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values = [aws_cognito_identity_pool.nettrek.id]
    }
  }
}

data "aws_iam_policy_document" "allow_lambda_backend_call-ticket" {
  statement {
    sid = "1"
    actions = ["lambda:InvokeFunction"]
    effect = "Allow"
    resources = [data.aws_lambda_function.popcorn.arn]
  }
}

data "aws_lambda_function" "ticket" {
  function_name = "nettrek-backend-ticket"
}

data "aws_lambda_function" "popcorn" {
  function_name = "nettrek-backend-popcorn"
}

data "aws_iam_policy_document" "allow_lambda_backend_call-popcorn" {
  statement {
    sid = "1"
    actions = ["lambda:InvokeFunction"]
    effect = "Allow"
    resources = [data.aws_lambda_function.ticket.arn]
  }
}

resource "aws_iam_policy" "nettrek-lambda-access-popcorn" {
  name = "nettrek-lambda-access-popcorn"
  policy = data.aws_iam_policy_document.allow_lambda_backend_call-popcorn.json
}

resource "aws_iam_policy" "nettrek-lambda-access-ticket" {
  name = "nettrek-lambda-access-ticket"
  policy = data.aws_iam_policy_document.allow_lambda_backend_call-ticket.json
}


resource "aws_iam_role_policy_attachment" "nettrek-cognito-attachment-popcorn" {
  policy_arn = aws_iam_policy.nettrek-lambda-access-popcorn.arn
  role = aws_iam_role.nettrek-popcorn.name
}

resource "aws_iam_role_policy_attachment" "nettrek-cognito-attachment-ticket" {
  policy_arn = aws_iam_policy.nettrek-lambda-access-ticket.arn
  role = aws_iam_role.nettrek-ticket.name
}

resource "aws_cloudfront_origin_access_identity" "nettrek-origin" {
  comment = "Access to nettrek app in s3."
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  origin {
    domain_name = aws_s3_bucket.nettrek-app-bucket.bucket_regional_domain_name
    origin_id   = var.originId

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.nettrek-origin.cloudfront_access_identity_path
    }
  }
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.originId

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cognito_identity_pool" "nettrek" {
  identity_pool_name = "nettrek"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.nettrek-app.id
    provider_name           = aws_cognito_user_pool.nettrek.endpoint
    server_side_token_check = false
  }
}

resource "aws_cognito_user_pool" "nettrek" {
  name = "nettrek-users"
  alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  schema {
    name                     = "nettrek_role"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false
    string_attribute_constraints {
      min_length = "0"
      max_length = "50"
    }
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.nettrek.id

  role_mapping {
    identity_provider         = "${aws_cognito_user_pool.nettrek.endpoint}:${aws_cognito_user_pool_client.nettrek-app.id}"
    type                      = "Rules"
    ambiguous_role_resolution = "Deny"
    mapping_rule {
      claim      = "custom:nettrek_role"
      match_type = "Equals"
      role_arn   = aws_iam_role.nettrek-popcorn.arn
      value      = "popcorn"
    }
    mapping_rule {
      claim      = "custom:nettrek_role"
      match_type = "Equals"
      role_arn   = aws_iam_role.nettrek-ticket.arn
      value      = "ticket"
    }
  }

  roles = {
    "authenticated" = aws_iam_role.nettrek-popcorn.arn
  }
}

resource "aws_cognito_user_pool_client" "nettrek-app" {
  name = "nettrek.app"
  user_pool_id = aws_cognito_user_pool.nettrek.id
  read_attributes = ["custom:nettrek_role"]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["openid","profile"]
  callback_urls = ["http://localhost:3000"]
}


output "cloudfront_id" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "identity-pool-id" {
  value = aws_cognito_identity_pool.nettrek.id
}

output "invalidationid" {
  value = aws_cloudfront_distribution.cdn.id
}

output "user-pool-id" {
  value = aws_cognito_user_pool.nettrek.id
}

output "client-id" {
  value = aws_cognito_user_pool_client.nettrek-app.id
}
