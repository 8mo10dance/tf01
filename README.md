# S3 static website

This repository builds a React single-page application and serves its generated
assets from S3. Production uses a private S3 origin behind CloudFront. The local
environment uses Floci for S3; nginx is only a browser-friendly proxy to that
bucket and does not serve the generated files directly.

## Local development

Install the client dependencies and create a production build with Docker
Compose:

```sh
docker compose run --rm client npm ci
docker compose run --rm client npm run build:local
```

The generated files are written to the ignored `client/public` directory. Start
Floci and nginx, then create the local S3 website with Terraform:

```sh
docker compose up -d floci nginx
terraform -chdir=local init
terraform -chdir=local apply
```

Open the `local_site_url` shown by Terraform (`http://localhost:8080`). The `/`,
`/users`, and `/users/new` routes are handled by the React application during
client-side navigation. Direct requests to routes without matching S3 objects
return an S3 error until an SPA fallback strategy is configured.

The Floci ready hook waits for Terraform to create the bucket and then syncs all
files from `client/public`. If the hook times out, or after rebuilding the
client, restart Floci to sync the latest build:

```sh
docker compose restart floci
```

To inspect the local bucket through the AWS CLI:

```sh
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
AWS_DEFAULT_REGION=ap-northeast-1 \
aws --endpoint-url=http://localhost:4566 s3 ls \
  s3://my-bucket-949926374137-ap-northeast-1-an
```

Stop the emulator without deleting its persisted data:

```sh
docker compose down
```

## Production deployment

Build the client, preview the S3 changes, and then synchronize the generated
assets to the production site bucket:

```sh
docker compose run --rm client npm ci
docker compose run --rm client npm run build:production
aws s3 sync client/public \
  s3://my-bucket-949926374137-ap-northeast-1-an \
  --delete --dryrun
aws s3 sync client/public \
  s3://my-bucket-949926374137-ap-northeast-1-an \
  --delete
```

The bucket is dedicated to generated site assets. The `--delete` option removes
objects that are no longer present in the current build. After the upload,
invalidate the CloudFront cache and wait for it to complete:

```sh
invalidation_id="$(aws cloudfront create-invalidation \
  --distribution-id E27L9ZCVF9GWVN \
  --paths '/*' \
  --query 'Invalidation.Id' \
  --output text)"
aws cloudfront wait invalidation-completed \
  --distribution-id E27L9ZCVF9GWVN \
  --id "$invalidation_id"
```

## Terraform

The S3 resources are defined in `modules/s3-static-site`. Production and local
environments both call that module, so S3 infrastructure changes can be tested
against Floci before they are planned against AWS. CloudFront resources are
defined separately in `modules/cloudfront` and are used only by production.

```sh
terraform -chdir=local plan
terraform -chdir=local apply
terraform -chdir=production plan -input=false
```

The production Terraform configuration and state live under `production/`; the
local environment has independent state under `local/`. Terraform manages the
bucket and delivery configuration, but it does not upload the generated client
assets to production S3.
