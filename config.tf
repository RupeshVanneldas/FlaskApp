terraform {
  backend "s3" {
    bucket = "your-bucket-name" // Bucket from where to GET Terraform State
    key    = "3tierpyapp.tfstate"
    region = "us-east-1" // Region where bucket created
  }
}