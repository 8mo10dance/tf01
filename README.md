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
docker compose run --rm client npm run build
```

The generated files are written to the ignored `client/public` directory. Start
Floci and nginx, then create the local S3 website with Terraform:

```sh
docker compose up -d floci nginx
terraform -chdir=local init
terraform -chdir=local apply
```

Open the `local_site_url` shown by Terraform (`http://localhost:8080`). The `/`,
`/users`, and `/users/new` routes are handled by the React application. nginx
loads missing local routes from the bucket's `index.html`, matching the SPA
fallback configured on the production CloudFront distribution.

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
