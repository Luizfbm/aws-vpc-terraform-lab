#!/usr/bin/env bash
set -euo pipefail

read -r -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -r -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
printf "\n"
read -r -p "AWS default region [us-east-1]: " AWS_DEFAULT_REGION

AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"

cat > .env <<EOF
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}
AWS_PROFILE=
EOF

chmod 600 .env
printf "Local .env created with restricted permissions. Do not commit it.\n"
