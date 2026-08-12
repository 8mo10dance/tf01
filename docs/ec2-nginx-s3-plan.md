# CloudFront → EC2/nginx → S3 への移行計画

## Summary

既存 S3 を生成物の保存先として維持し、EC2 で読み取り専用マウントして nginx から配信する。既存 CloudFront は EC2/nginx を新しい origin に変更する。デプロイは S3 アップロードと CloudFront invalidation だけで完結させる。

## Implementation Changes

- production に Amazon Linux 2023 の `t3.micro` EC2、IAM ロール／instance profile、security group を追加する。既存 EC2 はないため import/moved は不要。
- EC2 の IAM 権限を対象 bucket の `ListBucket` と `GetObject`、SSM 管理に限定し、SSH ポートは開けない。
- user data で nginx と Mountpoint for Amazon S3 を導入し、既存 private S3 を `/var/www/site` に読み取り専用で自動マウントする。nginx は同ディレクトリを document root にし、未存在パスを `/index.html` へ戻して React Router の直接アクセスに対応する。
- EC2 は default VPC の public subnet に配置する。HTTP inbound は CloudFront origin-facing managed prefix list だけに許可し、CloudFront は既存 distribution を維持したまま origin を S3 から EC2 の public DNS へ変更する。
- S3 bucket、website configuration、OAC、既存 bucket policy は削除せず維持する。OAC は CloudFront origin から外れるが、ロールバック用として残し、計画上の destroy を発生させない。
- production デプロイスクリプトを追加し、ハッシュ付き asset を先に S3 へ同期、`index.html` を最後にアップロードしてから CloudFront の `/*` を invalidate する。EC2 へのコピー、SSH、nginx reload は不要とする。
- local は Floci S3 と既存 origin nginx を維持し、その前段に CloudFront 相当の edge proxy コンテナを追加する。ブラウザ経路を `localhost:8080 → edge proxy → nginx → Floci S3` とし、本番と同じ三段構成を再現する。
- README を新しい構成、起動順序、デプロイ、SSM による診断、Mountpoint 障害時の確認方法に更新する。

## Interfaces and Outputs

- EC2/nginx 用 module は bucket 名、region、VPC/subnet、CloudFront prefix-list ID を入力とし、instance ID と origin domain を出力する。
- CloudFront module は S3 固定ではなく origin domain／origin 種別を受け取り、production では EC2 custom origin を設定する。
- production output に CloudFront URL と EC2 instance ID を公開する。S3 関連 output と bucket 名は互換性を維持する。
- local の公開 URL は引き続き `http://localhost:8080` とする。

## Test Plan

- `terraform fmt -check -recursive` と `terraform -chdir=production validate` を実行する。現在壊れている provider キャッシュは同じ lock 版を再取得してから検証する。
- `terraform -chdir=production plan -input=false` を実行し、EC2/IAM/security group の追加と CloudFront distribution の in-place 変更だけであることを確認する。destroy、import、S3 変更、意図しない再作成は許容しない。
- local で client を build し、Floci の ready hook で S3 へ同期後、`/`、`/users`、`/users/new`、ハッシュ付き asset が edge proxy 経由で 200 になることを確認する。
- 適用後は SSM で Mountpoint、nginx、再起動後の自動マウントを確認し、EC2 へ直接 HTTP 接続できず CloudFront URL からのみ配信できることを確認する。
- デプロイスクリプト実行後、更新された HTML と asset が配信され、S3 を公開せずに動作することを確認する。

## Assumptions

- 既存 S3 は削除せず、引き続き production 生成物を bucket 直下に保存する。
- EC2 は単一インスタンス構成とし、ALB、Auto Scaling、独自ドメイン、ACM 証明書は今回追加しない。
- local の CloudFront 層は AWS CDN そのものではなく、通信経路を検証するための proxy として再現する。
- S3 sync 中の新旧混在を避けるため asset を先行し、`index.html` を最後に更新する。古いハッシュ付き asset の自動削除は今回行わない。
