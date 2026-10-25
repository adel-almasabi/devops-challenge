# Getting started

## Tooling

- Terraform 1.7+ (see `.terraform-version`)
- Terragrunt (same major as Terraform is fine)
- Helm 3, helmfile
- AWS CLI, with the `acme` profile

```
aws configure --profile acme
export AWS_PROFILE=acme
```

Account `111111111111`, region `ap-southeast-3`.

## Layout

Live config is under `live/acme/ap-southeast-3/<bu>/<env>/<stack>`. Always `include` the
root `live/terragrunt.hcl`. Don't put raw `*.tf` next to a `terragrunt.hcl`.

```
cd live/acme/ap-southeast-3/claims/dev/claims-documents-queue
terragrunt plan
terragrunt apply
```

Cluster apps:

```
cd apps/acme-dev-cluster
helmfile diff
helmfile apply
```

Prod is the same, from `apps/acme-prod-cluster`.
