#!/bin/sh
set -eu

aws_region="ap-northeast-1"
image_name="${IMAGE_NAME:-tf01-nginx}"
local_image_tag="${IMAGE_TAG:-production}"

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: commit all changes before pushing an immutable Git SHA tag." >&2
  exit 1
fi

repository_url="$(terraform -chdir=production output -raw ecr_repository_url)"
registry="${repository_url%%/*}"
ecr_repository_name="${repository_url##*/}"
git_sha="$(git rev-parse HEAD)"
local_image="${image_name}:${local_image_tag}"
remote_image="${repository_url}:${git_sha}"

docker image inspect "$local_image" >/dev/null

aws ecr get-login-password --region "$aws_region" \
  | docker login --username AWS --password-stdin "$registry"

docker tag "$local_image" "$remote_image"
docker push "$remote_image"

image_digest="$(aws ecr describe-images \
  --region "$aws_region" \
  --repository-name "$ecr_repository_name" \
  --image-ids "imageTag=$git_sha" \
  --query 'imageDetails[0].imageDigest' \
  --output text)"

echo "Pushed image: $remote_image"
echo "Digest URI: ${repository_url}@${image_digest}"
