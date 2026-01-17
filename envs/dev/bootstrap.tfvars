client_name    = "acme"
project_name   = "landingzone"
environment    = "dev"
owner_email    = "joas@acme.com"
repository_name = "aws-terraform-landingzone"

state_bucket_prefix             = "tf"
enable_versioning               = true
enable_encryption_kms           = false
noncurrent_version_expiration_days = 90
enable_dynamodb_lock            = true
dynamodb_point_in_time_recovery = true
