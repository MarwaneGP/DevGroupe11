variable "project_name" {
  type        = string
  description = "Name of the project used for resource naming"
  default     = "archidevopsiimwebsite"
}

variable "bucket_name" {
  type        = string
  description = "Base bucket name (derived from project_name if not specified)"
  default     = ""
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
    mjs  = "application/javascript"    
    map  = "application/javascript"
    json = "application/json"
    png  = "image/png"             
    jpg  = "image/jpeg"              
    jpeg = "image/jpeg"              
    gif  = "image/gif"                 
    svg  = "image/svg+xml"            
    ico  = "image/x-icon"             
    ttf  = "font/ttf"
    woff = "font/woff"                
    woff2 = "font/woff2"             
  }
}

variable "sync_directories" {
  type = list(object({
    local_source_directory = string
    s3_target_directory    = string
  }))
  description = "Local build folder to sync with S3"
  default = [{
    local_source_directory = "../client/dist"  # Pour développement local
    s3_target_directory    = ""
  }]
}

variable "aws_region" {
  type = string
  default = "eu-west-1"
}

# Variable pour l'environnement CI/CD
variable "ci_build_path" {
  type        = string
  description = "Path to the build files in CI/CD environment"
  default     = "client/dist"  # ❌ CORRECTION : sans "./" au début
}

locals {
  actual_bucket_name = var.bucket_name != "" ? var.bucket_name : var.project_name
  build_path = fileexists("client/dist") ? "client/dist" : var.sync_directories[0].local_source_directory
}