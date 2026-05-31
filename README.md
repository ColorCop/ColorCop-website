# colorcop-website

[![GitHub Actions Status](https://github.com/ColorCop/colorcop-website/workflows/Test/badge.svg)](https://github.com/ColorCop/colorcop-website/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A static website for the ColorCop project, built with Jekyll and managed using mise for consistent tooling and reproducible development environments.

---

## Installation

This project uses mise to configure the development environment.

- Install [mise](https://mise.jdx.dev/getting-started.html)
- Run `mise trust` and answer yes.
- Run `mise install` to install the required tools
- Run `bundle install`

## Running locally

```sh
mise serve
```

## Running linters

```sh
mise lint
```

## Deploy

There is a [Github Action](https://github.com/ColorCop/colorcop-website/actions/workflows/deploy.yml) that runs when code merges to `main`. It provisions infrastructure with Terragrunt, builds the site, uploads it to S3, and refreshes CloudFront.

---

## How it works

The deploy workflow automates the full publishing pipeline:

- Triggered by pushes to `main` or `deploy-*`, or manually with a selected branch
- Checks out the branch and configures temporary AWS credentials
- Runs Terragrunt `init`, `plan`, and `apply` to update CloudFront, S3, and related infrastructure
- Reads Terragrunt outputs (S3 bucket name and CloudFront distribution ID)
- Builds the Jekyll site using Bundler and `mise build`
- Validates the CloudFront distribution and S3 bucket
- Syncs the built `_site/` directory to the S3 bucket
- Invalidates CloudFront so new content is served immediately
