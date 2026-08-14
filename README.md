# S3 static website

This repository builds a React single-page application and serves its generated
assets from S3. Production uses a private S3 origin behind CloudFront. A custom
nginx image provides a separate delivery path and includes the production client
build in the image.

## Local development

Build and start the custom nginx image with Docker Compose:

```sh
docker compose up --build nginx
```

Docker Compose passes `BUILD_ENV=local` to the multi-stage Docker build, which
runs `npm ci` and `npm run build:local`, then copies the generated client files
into nginx. Open `http://localhost:8080` and check `/`, `/users`, and
`/users/new`. Direct requests to the React routes fall back to `index.html`.

The Dockerfile defaults to `BUILD_ENV=production`. Override it explicitly when
another build is needed:

```sh
docker build --build-arg BUILD_ENV=local -t tf01-nginx:local .
```

Build the production Linux/AMD64 image with Make:

```sh
make build
```

The default image is `tf01-nginx:production`. Override its name or tag when
needed:

```sh
make build IMAGE_NAME=tf01-nginx IMAGE_TAG="$(git rev-parse HEAD)"
```

Stop the local nginx container:

```sh
docker compose down
```

## Production deployment

### Custom nginx image

Create the ECR repository after reviewing the Terraform plan:

```sh
terraform -chdir=production plan -input=false
terraform -chdir=production apply
```

After testing the application through Docker Compose, commit all changes and
build and push the production image to ECR:

```sh
make push
```

This builds `tf01-nginx:production`, authenticates Docker with the current AWS
CLI credentials, and pushes the image with the full Git commit SHA as its tag.
It prints the digest URI after the push. The script refuses to push from a dirty
worktree because ECR tags are immutable.

To deploy an image to EC2, copy the printed digest URI to the `nginx_image_uri`
argument of the production EC2 module. Review the full Terraform plan before
applying it. Changing the digest updates the instance user data and replaces the
EC2 instance, so its public IP address and DNS name may change.

### S3 and CloudFront

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

The S3 resources are defined in `modules/s3-static-site`. CloudFront resources
are defined separately in `modules/cloudfront`. Both are used by production.

```sh
terraform -chdir=production plan -input=false
```

The production Terraform configuration lives under `production/`. Its shared
state is stored in a dedicated, versioned S3 bucket and uses an S3 lock file.
Terraform manages the bucket and delivery configuration, but it does not upload
the generated client assets to production S3.

Create the state bucket once from the bootstrap configuration before
initializing production:

```sh
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan
terraform -chdir=bootstrap apply
```

When migrating an existing production local state, first keep a local backup
outside Git, then run:

```sh
terraform -chdir=production init -migrate-state
```

For another worktree, connect it to the already-migrated remote state without
copying or migrating that worktree's local state:

```sh
terraform -chdir=production init -reconfigure
```

Terraform state and state backups must remain outside Git. The bootstrap
configuration intentionally keeps its own small state locally so that the state
bucket does not manage itself.
