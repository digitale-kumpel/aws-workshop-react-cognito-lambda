provider "aws" {
  region  = "eu-central-1"
  version = "~> 2.50"
}

terraform {
  backend "s3" {
    bucket = "state.digitale-kumpel.ruhr"
    key    = "demo1"
    region = "eu-central-1"
  }
}

resource "aws_s3_bucket" "nettrek" {
  region = ""
  bucket = "jajajajajajok"
  acl = "public-read"
  replication_configuration {
    role = ""
    rules {
      status = ""
      destination {
        bucket = ""
      }
    }
  }
}

resource "aws_s3_bucket_object" "neneneobject" {
  bucket = aws_s3_bucket.nettrek.bucket
  key = "manuel.sh"
  source = "${path.module}/echo.sh"
  acl = "public-read"
  etag = "${filemd5("${path.module}/echo.sh")}"
}

#resource "aws_s3_bucket" "pubbucket" {
#  bucket = "nettrek-public-bucket-${terraform.workspace}"
#  acl = "public-read"
#}

#resource "aws_s3_bucket_object" "echo" {
#  bucket = aws_s3_bucket.pubbucket.bucket
#  key    = "echo.sh"
#  source = "${path.module}/echo.sh"
#  acl = "public-read"
#}

output "url" {
  value = "curl ${aws_s3_bucket.nettrek.bucket_regional_domain_name}/echo.sh | bash"
}