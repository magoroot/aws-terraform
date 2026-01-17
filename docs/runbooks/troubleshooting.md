# Troubleshooting Runbook

## Common Issues and Solutions

### 1. Terraform State Lock Stuck

**Symptom:** 
```
Error: Error acquiring the lock: ConditionalCheckFailedException
```

**Causes:**
- Previous terraform operation crashed and didn't release lock
- Network interrupted during apply
- Multiple processes trying to modify same state

**Solution:**

```bash
# List the lock in DynamoDB
aws dynamodb scan \
  --table-name acme-landingzone-dev-locks \
  --region sa-east-1

# Force unlock (DANGEROUS - only if you're certain no other ops are running)
terraform force-unlock <LOCK_ID>

# Verify lock was released
aws dynamodb scan --table-name acme-landingzone-dev-locks
```

⚠️ **WARNING:** Only force unlock if no terraform processes are running. Check with team first.

---

### 2. State Version Mismatch

**Symptom:**
```
Error: Incompatible Terraform Core version
```

**Cause:** Your local Terraform version differs from the version used to create state

**Solution:**

```bash
# Check state version
aws s3 cp s3://tf-state-<account>-sa-east-1/terraform.tfstate - | \
  jq '.terraform_version'

# Install matching version
terraform version
# If needed, use tfenv: tfenv install 1.6.0
```

---

### 3. Backend Init Fails

**Symptom:**
```
Error: error reading S3 Bucket in account <account>: 
  AccessDenied: Access Denied
```

**Causes:**
- AWS credentials not configured
- Wrong AWS profile
- IAM user lacks S3 permissions

**Solution:**

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check profile
export AWS_PROFILE=default
aws sts get-caller-identity

# Re-initialize
cd stacks/bootstrap
rm -rf .terraform
terraform init
```

---

### 4. Recover Previous Infrastructure State

**Symptom:** Need to restore infrastructure from an earlier version

**Process:**

1. **List available versions:**
```bash
aws s3api list-object-versions \
  --bucket tf-state-<account>-sa-east-1 \
  --prefix terraform.tfstate \
  --query 'Versions[*].[VersionId,LastModified]' \
  --output table
```

2. **Download specific version:**
```bash
aws s3api get-object \
  --bucket tf-state-<account>-sa-east-1 \
  --key terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.backup
```

3. **Review changes:**
```bash
# Compare current vs backup
diff terraform.tfstate terraform.tfstate.backup | head -20
```

4. **Restore (if safe):**
```bash
# BACKUP current state first
cp terraform.tfstate terraform.tfstate.current-backup

# Restore
cp terraform.tfstate.backup terraform.tfstate

# Re-upload
aws s3 cp terraform.tfstate \
  s3://tf-state-<account>-sa-east-1/terraform.tfstate
```

---

### 5. Plan Shows Unexpected Changes

**Symptom:**
```
Terraform will perform the following actions:
  ~ update resource "aws_s3_bucket" "state"
      - versioning_configuration -> versioning_configuration (default false)
```

**Causes:**
- State was imported/created outside Terraform
- Resource configuration changed outside Terraform
- Terraform upgraded provider with breaking changes

**Solution:**

```bash
# Refresh state without making changes
terraform refresh

# Check what changed outside Terraform
terraform plan -destroy -var-file=../../envs/dev/bootstrap.tfvars

# If safe, apply
terraform apply -var-file=../../envs/dev/bootstrap.tfvars
```

---

### 6. Destroy Fails - Bucket Not Empty

**Symptom:**
```
Error: error deleting S3 Bucket: BucketNotEmpty
```

**Cause:** State bucket contains objects or versions

**Solution:**

```bash
# Delete all versions
aws s3api delete-objects \
  --bucket tf-state-<account>-sa-east-1 \
  --delete "$(aws s3api list-object-versions \
    --bucket tf-state-<account>-sa-east-1 \
    --output=json \
    --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' | \
    jq -r '.Objects[] | @json' | tr '\n' ',')"

# Then try destroy again
terraform destroy -var-file=../../envs/dev/bootstrap.tfvars
```

---

### 7. Permission Denied on Bucket Policy

**Symptom:**
```
Error: putting S3 bucket policy: AccessDenied
```

**Causes:**
- IAM user lacks `s3:PutBucketPolicy` permission
- Bucket policy blocking user's principal

**Solution:**

```bash
# Check current principal
aws sts get-caller-identity

# Ensure IAM user has these permissions:
# - s3:CreateBucket
# - s3:PutBucketVersioning
# - s3:PutBucketPolicy
# - s3:PutEncryptionConfiguration
# - dynamodb:CreateTable (if enable_dynamodb_lock=true)

# Verify bucket policy doesn't block your principal
aws s3api get-bucket-policy --bucket tf-state-<account>-sa-east-1
```

---

### 8. Lost Local Terraform Directory

**Symptom:** Deleted `.terraform/` or lost local cache, but state exists in S3

**Solution:**

```bash
cd stacks/bootstrap

# Reinitialize from S3 backend
terraform init \
  -backend-config=../../envs/dev/bootstrap.backend.hcl

# State will be pulled from S3
# Verify
terraform state list
```

---

## Prevention Best Practices

1. **Always use remote state** - Never develop with local state in team settings
2. **Enable versioning** - Keep 90+ days of state versions
3. **Use DynamoDB locks** - Prevent concurrent modifications
4. **Tag everything** - Makes debugging easier
5. **Plan before apply** - Always review plan output
6. **Require approvals for prod** - Prevent accidental changes
7. **Use tfplan files** - For reproducible applies
   ```bash
   terraform plan -var-file=envs/dev/bootstrap.tfvars -out=dev.tfplan
   terraform apply dev.tfplan
   ```
