variable "bucket_name" {
  type        = string
  description = "Base bucket name"
  default     = "archidevopsiimwebsite"
}

variable "tags" {
  type = object({
    Name        = string
    Environment = string
  })
  default = {
    Name        = "tp_bucket"
    Environment = "dev"
  }
}

variable "mime_types" {
  description = "Map of file extensions to MIME types"
  type        = map(string)
  default = {
    html = "text/html"
    htm  = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    map  = "application/javascript"
    json = "application/json"
    ttf  = "font/ttf"
  }
}

variable "sync_directories" {
  type = list(object({
    local_source_directory = string
    s3_target_directory    = string
  }))
  description = "Local build folder to sync with S3"
  default = [{
    local_source_directory = "../dist"
    s3_target_directory    = ""
  }]
}

# variables
variable "aws_region" {
  type = string
  default = "eu-west-1"
}