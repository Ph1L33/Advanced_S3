variable "s3_bucket_name_doc" {
  description = "S3 bucket used for storing documents.versioning enabled"
  default     = "document-storage-bucket32724"
  type       = string
}

variable "s3_bucket_name_log" {
  description = "S3 bucket for storing logs.lifecycle policy transition logs to Glacier after 30 days"
  default     = "log-bucket32724"
  type        = string

}

variable "document_access_role" {
  description = "IAM role that will have read-write access to the document storage bucket."
  default     = "DA_role"
  type        = string

}

variable "log_access_role" {
    description = "IAM role will have read-only access to the logs bucket"
    default     = "LA_role"
      type      = string
}


