resource "aws_s3_bucket" "document_s3" {
    bucket = "${var.s3_bucket_name_doc}"
}

resource "aws_s3_bucket" "log_s3" {
    bucket = "${var.s3_bucket_name_log}"
}

resource "aws_s3_bucket_ownership_controls" "bucketowner" {
  bucket = aws_s3_bucket.log_s3.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "aclbucket" {
  depends_on = [aws_s3_bucket_ownership_controls.bucketowner]

  bucket = aws_s3_bucket.log_s3.id
  acl    = "private"
}
resource "aws_s3_bucket_lifecycle_configuration" "lfbucket" {
  rule {
    id      = "log"
    status  = "Enabled"
 
    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  bucket = aws_s3_bucket.log_s3.id
}


resource "aws_s3_bucket_versioning" "versioning_s3" {
  bucket = aws_s3_bucket.document_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_iam_role" "ReadWriteRole" {
  name = var.document_access_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect  = "Allow"
        Action  = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "RWpolicy" {
  name        = "s3RWpolicy"
  path        = "/"
  description = "s3 read write policy"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid":"ReadWriteS3",
      "Action": [
            "s3:ListBucket"
                ],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::document_s3"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:DeleteObject",              
        "s3:DeleteObjectVersion",
        "s3:GetObjectVersion",
        "s3:GetObjectVersionTagging",
        "s3:GetObjectACL",
        "s3:PutObjectACL"
      ],
      "Resource": ["arn:aws:s3:::document_s3/*"]
    }
  ]
}    
EOF
}

resource "aws_iam_role_policy_attachment" "RWpolicyattach" {
  role       = aws_iam_role.ReadWriteRole.name
  policy_arn = aws_iam_policy.RWpolicy.arn
}


resource "aws_iam_role" "ReadOnlyRole" {
  name = var.log_access_role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect  = "Allow"
        Action  = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "ROpolicy" {
  name        = "s3ROpolicy"
  path        = "/"
  description = "s3 read only policy"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Describe*",
                "s3-object-lambda:Get*",
                "s3-object-lambda:List*"
            ],
            "Resource": ["arn:aws:s3:::log_s3/*"]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ROpolicyattach" {
  role       = aws_iam_role.ReadOnlyRole.name
  policy_arn = aws_iam_policy.ROpolicy.arn
}

#Outputs 
output "document_access_role_arn" {
  value = aws_iam_role.ReadWriteRole.arn
}

output "logs_access_role_arn" {
  value = aws_iam_role.ReadOnlyRole.arn
}

output "document_storage_bucket_name" {
  value = aws_s3_bucket.document_s3.bucket_domain_name
}

output "logs_bucket_name" {
  value = aws_s3_bucket.log_s3.bucket_domain_name
}

