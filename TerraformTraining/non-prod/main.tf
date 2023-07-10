provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "example" {
    ami = "ami-ofb653ca2d3203ac1"
    instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
    vpc_security_group_ids = [ aws_security_group.instance.id ]

    # user_data = <<-EOF
    #             // #!/bin/bash
    #             echo "Hello, World" > index.html
    #             nohup busybox httpd -f -p ${var.server_port} & 
    #             EOF

    user_data = templatefile("user-data.sh", {
        server_port = var.server_port
        db_address = 
    })

    user_data_replace_on_change = true
    tags = {
        Name = "terraform-example"
    }
}

resource "aws_security_group" "instance" {
    name = "terraform-example-instance"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}



# storing the terraform state
resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-up-and-running-state"

    # prevent acccidental deletion of this bucket
    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state.id

    rule {
        apply_server_side_encryption_by_default {
          sse_algorithm = "AES256"
        }
    }
}

data "terraform_remote_state" "db" {
    backend = "s3"
    config = {
        bucket = "(YOUR_BUCKET_NAME)"
        key = "stage/data-store/mysql/terraform.tfstate"
        region = "us-east-2"
    }
}

# Explicity block all public access to the s3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
    name = "terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

# Can't be used with tflocal
# terraform {
#   backend "s3" {
#     # Replace this with your bucket nam
#     bucket = "terraform-up-and-running-state"
#     key = "global/s3/terraform.tfstate"
#     region = "us-east-2"

#     # Replace this with your Dynamo table name
#     dynamodb_table = "terraform-up-and-running-locks"
#     encrypt = true
#   }
# }