#!/bin/sh
set -eu

bucket_name="my-bucket-949926374137-ap-northeast-1-an"

until aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; do
  sleep 1
done

until [ -f /seed/index.html ]; do
  sleep 1
done

aws s3 sync /seed "s3://$bucket_name" --delete
