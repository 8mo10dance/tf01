# Repository Guidelines

## Code Formatting

- Do not add padding spaces to vertically align `=` signs. Keep formatting changes limited to the lines required by the task to avoid noisy diffs.

## Git

- Do not run `git push` or `git fetch`; ask the user to run these commands instead.

## Terraform

- When changing `production`, check whether the affected AWS resources already exist and whether they are recorded in Terraform state.
- When moving or adding existing resources under a module, determine whether `import` or `moved` blocks are required instead of creating the resources again.
- Do not align `=` signs or otherwise reformat unrelated Terraform attributes when editing a block. Keep formatting changes limited to lines required by the task to avoid noisy diffs.
- After changing Terraform configuration, run:
  - `terraform fmt -check -recursive`
  - `terraform -chdir=production validate`
  - `terraform -chdir=production plan -input=false`
- Confirm that every `add`, `change`, `destroy`, and `import` in the plan is intentional. Do not allow unintended recreation or deletion of existing resources.

## Pull Request Reviews

- Keep review-comment fixes focused on the problem identified by the reviewer.
- Do not include unrelated refactoring or parameterization without first confirming that it is needed.
- Before replying to a review comment, confirm that the fix is committed and reflected in the pull request branch.
- In the reply, briefly state what changed and how it was verified.
