resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state"
  acl    = "private"

  versioning {
    enabled = true
  }
}

// sets up an s3 object key where terraform state files will be placed
resource "aws_s3_bucket_object" "region_key" {
  bucket = "${aws_s3_bucket.terraform_state_bucket.id}"
  acl    = "private"
  key    = "${data.aws_region.current}"
  source = "/dev/null"
}
