# Repository Guidelines

## Terraform

- When changing `production`, check whether the affected AWS resources already exist and whether they are recorded in Terraform state.
- When moving or adding existing resources under a module, determine whether `import` or `moved` blocks are required instead of creating the resources again.
- Do not align `=` signs or otherwise reformat unrelated Terraform attributes when editing a block. Keep formatting changes limited to lines required by the task to avoid noisy diffs.
- After changing Terraform configuration, run:
  - `terraform fmt -check -recursive`
  - `terraform -chdir=production validate`
  - `terraform -chdir=production plan -input=false`
- Confirm that every `add`, `change`, `destroy`, and `import` in the plan is intentional. Do not allow unintended recreation or deletion of existing resources.

## Local Development

- Terraform manages the S3 bucket and website configuration, but does not manage generated site contents such as `index.html`.
- Site contents are uploaded by the Floci ready hook or a future static-site build and sync workflow.
- The Floci ready hook can start before Terraform has created the bucket. If it times out, restart Floci after `terraform apply` to run the hook again.
- Keep destructive options such as `force_destroy = true` limited to disposable local resources. Production must retain the safe default.
- Floci executes ready-hook scripts through `/bin/sh`; executable permission is not required.

## Pull Request Reviews

- Keep review-comment fixes focused on the problem identified by the reviewer.
- Do not include unrelated refactoring or parameterization without first confirming that it is needed.
- Before replying to a review comment, confirm that the fix is committed and reflected in the pull request branch.
- In the reply, briefly state what changed and how it was verified.
