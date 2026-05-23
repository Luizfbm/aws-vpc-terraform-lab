# Webnar Serain AWS Infrastructure

Terraform project for AWS infrastructure.

## First setup

1. Rotate the AWS key that was shared in chat. Treat it as compromised.
2. Create a new IAM access key with only the permissions needed for this project.
3. Fill `.env` locally. Do not commit it. You can do this manually or run:

```bash
bash scripts/setup-aws-local.sh
```

4. Export the variables before running Terraform:

```bash
set -a
source .env
set +a
```

5. Initialize and validate Terraform:

```bash
cd 01-networking-stack
terraform init
terraform validate
```

If you prefer an AWS CLI profile instead of `.env` credentials, configure it with `aws configure --profile <profile-name>` and pass `-var aws_profile=<profile-name>` to Terraform.

## Plan

```bash
terraform plan
```

## Apply

```bash
terraform apply
```
