# S3 static website

## Local development

Start Floci, then create the local S3 website with Terraform:

```sh
docker compose up -d
terraform -chdir=local init
terraform -chdir=local apply
```

Open the `local_site_url` shown by Terraform (`http://localhost:8080`). nginx
forwards requests to the bucket in Floci, with `/` resolving to `index.html`.
This is a local browsing entry point, not an emulation of CloudFront caching,
TLS, Origin Access Control, or request signing.

To inspect the local bucket through the AWS CLI:

```sh
AWS_ACCESS_KEY_ID=test \
AWS_SECRET_ACCESS_KEY=test \
AWS_DEFAULT_REGION=ap-northeast-1 \
aws --endpoint-url=http://localhost:4566 s3 ls
```

For troubleshooting, the S3 origin can also be accessed directly at
`http://localhost:4566/my-bucket-949926374137-ap-northeast-1-an`.

`site/index.html` is not managed by Terraform. A Floci initialization hook
uploads it when the container starts. Restart Floci after changing the file:

```sh
docker compose restart floci
```

Stop the emulator without deleting its persisted data:

```sh
docker compose down
```

The S3 website resources are defined in `modules/s3-static-site`. Production
and local environments both call that module, so S3 infrastructure changes can
be tested against Floci before they are planned against AWS. CloudFront
resources are defined separately in `modules/cloudfront` and are used only by
production. nginx provides a temporary local frontend, but local plans do not
validate CloudFront changes:

```sh
terraform -chdir=local plan
terraform -chdir=local apply
terraform -chdir=production plan
```

The production Terraform configuration and state live under `production/`;
the local environment has an independent state under `local/`. Provider
settings are environment-specific; the S3 resource configuration, including
the bucket name, lives in the shared S3 module.
