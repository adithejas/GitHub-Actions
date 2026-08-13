# Comprehensive Guide: Variables and Secrets in GitHub Actions

## Table of Contents
1. [Overview & Core Concepts](#overview--core-concepts)
2. [GitHub Actions Variables (`vars` & `env`)](#github-actions-variables-vars--env)
   - [1. Configuration Variables (`vars` context)](#1-configuration-variables-vars-context)
   - [2. Workflow Environment Variables (`env` context)](#2-workflow-environment-variables-env-context)
   - [3. Default Environment Variables](#3-default-environment-variables)
   - [4. Variable Scope & Precedence Rules](#4-variable-scope--precedence-rules)
3. [GitHub Actions Secrets (`secrets`)](#github-actions-secrets-secrets)
   - [1. Understanding GitHub Secrets](#1-understanding-github-secrets)
   - [2. Types & Hierarchies of Secrets](#2-types--hierarchies-of-secrets)
   - [3. Built-in `GITHUB_TOKEN`](#3-built-in-github_token)
   - [4. Secret Redaction & Security Engine](#4-secret-redaction--security-engine)
4. [Contexts Comparison & Syntax Guide](#contexts-comparison--syntax-guide)
   - [Expression Syntax (`${{ ... }}`) vs Shell Syntax (`$VAR`)](#expression-syntax----vs-shell-syntax-var)
   - [Context Matrix Comparison](#context-matrix-comparison)
5. [Analysis of Provided Example Workflow](#analysis-of-provided-example-workflow)
   - [Detailed Walkthrough](#detailed-walkthrough)
   - [Production-Ready Refactored Workflow](#production-ready-refactored-workflow)
6. [Security Best Practices & Hardening](#security-best-practices--hardening)

---

## Overview & Core Concepts

In GitHub Actions, workflows often require dynamic data, configuration settings, and sensitive credentials. GitHub provides two primary mechanisms for handling non-hardcoded values:

- **Variables (`vars` and `env`)**: Used for non-sensitive configuration data such as server URLs, Docker image names, usernames, deployment paths, feature flags, or build parameters.
- **Secrets (`secrets`)**: Encrypted key-value pairs used for sensitive credentials such as API tokens, private SSH keys, password hashes, or cloud access keys.

### Key Conceptual Differences

| Feature | Configuration Variables (`vars`) | Environment Variables (`env`) | GitHub Secrets (`secrets`) |
| :--- | :--- | :--- | :--- |
| **Primary Purpose** | Global/Org non-sensitive configs | Inline workflow/job/step configs | Sensitive credentials & tokens |
| **Encryption at Rest** | No (Stored as plain text) | Stored in repository code | Yes (Encrypted with Libsodium) |
| **Log Visibility** | Fully visible in workflow logs | Fully visible in workflow logs | Automatically masked (`***`) |
| **Storage Location** | Repo / Org / Env Settings | `.github/workflows/*.yml` files | Repo / Org / Env Settings |
| **Access Scope** | `${{ vars.VARIABLE_NAME }}` | `${{ env.VARIABLE_NAME }}` or `$VARIABLE_NAME` | `${{ secrets.SECRET_NAME }}` |

---

## GitHub Actions Variables (`vars` & `env`)

GitHub Actions distinguishes between **Configuration Variables** (managed in GitHub settings) and **Workflow Environment Variables** (defined directly inside the YAML workflow file).

### 1. Configuration Variables (`vars` context)

Configuration variables are key-value pairs created in the GitHub UI or API. They allow you to reuse non-sensitive configuration values across multiple workflows without hardcoding them into repository code.

#### Types by Scope Level:
1. **Organization Variables**: Accessible by multiple repositories within an organization. Can be shared with all repositories or restricted to specific ones.
2. **Repository Variables**: Accessible by all workflows within a single repository.
3. **Environment Variables (Deployment Environments)**: Associated with a specific deployment target (e.g., `production`, `staging`, `development`). These override repository/organization variables when referencing that environment.

#### Naming Constraints:
- Must only contain alphanumeric characters (`A-Z`, `a-z`, `0-9`) or underscores (`_`).
- Cannot start with `GITHUB_` (reserved for default environment variables).
- Cannot start with a number.
- Case-insensitive on creation, but conventionally written in **UPPERCASE** (e.g., `DOCKER_USER`).

#### Accessing `vars` in YAML:
```yaml
steps:
  - name: Output Docker User
    run: echo "Docker user is ${{ vars.DOCKER_USER }}"
```

---

### 2. Workflow Environment Variables (`env` context)

Environment variables defined directly inside the YAML file using the `env` keyword. They exist at three levels of scope within the workflow structure.

#### Levels of Definition:

1. **Workflow Level**: Available to all jobs and steps in the entire workflow.
   ```yaml
   name: CI Pipeline
   env:
     GLOBAL_REGION: us-east-1
     APP_ENV: production
   ```

2. **Job Level**: Available only to steps within a specific job.
   ```yaml
   jobs:
     build:
       runs-on: ubuntu-latest
       env:
         BUILD_TARGET: release
       steps:
         - run: echo "Target: $BUILD_TARGET"
   ```

3. **Step Level**: Available only to that specific step.
   ```yaml
   steps:
     - name: Run Script
       env:
         STEP_SPECIFIC_VAR: debug_mode
       run: python main.py
   ```

---

### 3. Default Environment Variables

GitHub Actions automatically injects set environment variables into every runner environment. These describe the current repository, workflow run, actor, commit SHA, branch, and runner workspace.

| Variable Name | Description | Example Value |
| :--- | :--- | :--- |
| `GITHUB_WORKFLOW` | Name of the active workflow | `CI Build` |
| `GITHUB_RUN_ID` | Unique ID for the workflow run | `1658932401` |
| `GITHUB_ACTOR` | Username of the person/account that triggered the run | `octocat` |
| `GITHUB_REPOSITORY` | Owner and repository name | `octocat/Hello-World` |
| `GITHUB_SHA` | Commit SHA that triggered the workflow | `ffac537e6cbbf934b08745a378932722df287a53` |
| `GITHUB_REF_NAME` | Short ref name of the branch or tag | `main` or `v1.0.0` |
| `GITHUB_WORKSPACE` | Absolute path on runner where repo was cloned | `/home/runner/work/repo/repo` |
| `RUNNER_OS` | Operating system of the runner executing the step | `Linux`, `Windows`, `macOS` |

---

### 4. Variable Scope & Precedence Rules

When variables share the same key name across different levels, GitHub Actions resolves them according to a strict order of precedence (**narrower scopes override broader scopes**):

1. **Step-level `env`** *(Highest Priority)*
2. **Job-level `env`**
3. **Workflow-level `env`**
4. **Environment-level `vars`** (when `environment:` is declared on the job)
5. **Repository-level `vars`**
6. **Organization-level `vars`** *(Lowest Priority)*

---

## GitHub Actions Secrets (`secrets`)

Secrets are encrypted values stored in GitHub that enable workflow jobs to securely interact with third-party systems, databases, and APIs.

### 1. Understanding GitHub Secrets

- **Encryption Standard**: GitHub uses [libsodium sealed boxes](https://libsodium.gitbook.io/doc/public-key_cryptography/sealed_boxes) to encrypt secrets before they are stored in the database.
- **Write-Only**: Once saved in GitHub UI/API, secret values cannot be viewed or retrieved by human users or API queries.
- **Maximum Size**: 48 KB per secret. Maximum 100 organization secrets, 1000 repository secrets.

---

### 2. Types & Hierarchies of Secrets

1. **Organization Secrets**: Defined at the org level. Can be shared across multiple repos using visibility policies (All repos, Private repos, or Selected repos).
2. **Repository Secrets**: Defined within a single repository settings page.
3. **Environment Secrets**: Associated with specific deployment environments (e.g., `prod-aws-credentials`). They are only exposed to jobs that explicitly declare that `environment`.
4. **Dependabot Secrets**: Secrets specifically created for Dependabot pull requests (since automated Dependabot PRs do not get access to standard repo secrets by default for security).

---

### 3. Built-in `GITHUB_TOKEN`

At the start of each workflow run, GitHub automatically creates a unique installation access token called `GITHUB_TOKEN`.

#### Features of `GITHUB_TOKEN`:
- Expires automatically when the workflow run completes.
- Authenticates against the current repository (e.g., creating releases, pushing packages, commenting on PRs).
- Permissions can be defined granularly in YAML:
  ```yaml
  permissions:
    contents: read
    packages: write
    issues: write
  ```
- Accessed via context: `${{ secrets.GITHUB_TOKEN }}` or `${{ github.token }}`.

---

### 4. Secret Redaction & Security Engine

GitHub Actions runner inspects every output printed to the console log:
- Any text matching a secret value in the workflow is automatically masked and replaced with `***`.
- **Dynamic Masking**: You can manually register values to be masked in logs using workflow commands:
  ```bash
  echo "::add-mask::$DYNAMIC_SECRET_VALUE"
  ```

> ⚠️ **Warning**: Never convert secrets to Base64 or URL encoding before printing to stdout, as GitHub's log masker may not recognize encoded variations of the raw secret.

---

## Contexts Comparison & Syntax Guide

### Expression Syntax (`${{ ... }}`) vs Shell Syntax (`$VAR`)

There are two primary ways to access values within step execution:

1. **GitHub Actions Expression Syntax (`${{ context.KEY }}`)**:
   - Evaluated by GitHub's workflow engine **before** sending the script to the runner machine shell.
   - Required for workflow keys like `if:`, `with:`, `matrix:`, or `environment:`.

2. **Shell Environment Variable Syntax (`$KEY` or `%KEY%`)**:
   - Evaluated directly by the shell process executing on the runner during step execution.
   - Recommended for shell execution steps (`run:`) to prevent shell injection vulnerabilities.

```yaml
steps:
  # Approach A: GitHub Expression Syntax (Engine-level evaluation)
  - name: Expression approach
    run: echo "User is ${{ vars.DOCKER_USER }}"

  # Approach B: Shell Syntax (Shell-level evaluation - SAFER for dynamic data)
  - name: Shell variable approach
    env:
      USER_NAME: ${{ vars.DOCKER_USER }}
    run: echo "User is $USER_NAME"
```

---

### Context Matrix Comparison

| Context Name | Access Syntax | Main Usage / Description |
| :--- | :--- | :--- |
| `env` | `${{ env.MY_VAR }}` | Values defined in workflow `env` blocks. |
| `vars` | `${{ vars.MY_VAR }}` | Non-sensitive configuration variables created in GitHub Settings. |
| `secrets` | `${{ secrets.MY_SECRET }}` | Encrypted sensitive credentials created in GitHub Settings. |
| `inputs` | `${{ inputs.MY_INPUT }}` | Inputs passed via `workflow_dispatch` or reusable workflow events. |
| `github` | `${{ github.actor }}` | Metadata regarding the workflow run, triggering user, SHA, repo. |

---

## Analysis of Provided Example Workflow

### Detailed Walkthrough

Below is an analysis of your provided snippet:

```yaml
name: variables

on: 
  workflow_dispatch:

env:
  DOCKER_REGISTRY: docker.io
  IMAGE_NAME: my-docker-image

jobs:
  docker_build:
    runs-on: ubuntu-latest
    steps:
      - name: Build Docker image
        run: echo docker build -t ${{ env.DOCKER_REGISTRY }}/${{ vars.DOCKER_USER }}/${{ env.IMAGE_NAME }}:latest .

      - name: Login to Docker Hub
        run: echo docker login --username ${{ vars.DOCKER_USER }} --password ${{ secrets.DOCKER_PASSWORD }}

      - name: Push Docker image to Docker Hub
        run: |
          echo docker push ${{ env.DOCKER_REGISTRY }}/${{ vars.DOCKER_USER }}/${{ env.IMAGE_NAME }}:latest
```

#### Key Highlights & Observations:
1. **`env.DOCKER_REGISTRY` & `env.IMAGE_NAME`**:
   - Correctly references workflow-level `env` variables defined at top-level.
2. **`vars.DOCKER_USER`**:
   - Successfully pulls the non-sensitive configuration variable defined in GitHub Repository / Org / Environment settings.
3. **`secrets.DOCKER_PASSWORD`**:
   - Accesses encrypted secret stored in GitHub Settings. GitHub will automatically mask `${{ secrets.DOCKER_PASSWORD }}` with `***` in the logs.
4. **`echo` Statements**:
   - The commands use `echo` in front of `docker`, making this a dry-run demonstration pipeline.

---

## Security Best Practices & Hardening

1. **Use Shell Environment Variable Binding**: Avoid directly inserting `${{ github.event.issue.title }}` or dynamic inputs straight into `run:` scripts to prevent **Shell Injection**. Pass them through `env:` instead:
   ```yaml
   # SAFE PRACTICE
   steps:
     - name: Safe Execution
       env:
         USER_TITLE: ${{ github.event.issue.title }}
       run: echo "$USER_TITLE"
   ```

2. **Least Privilege Principle for `GITHUB_TOKEN`**:
   Restrict permissions globally at top of the workflow file, granting access only where required:
   ```yaml
   permissions:
     contents: read
     packages: write
   ```

3. **Protect Environments with Required Reviewers**:
   Store sensitive environment secrets inside designated Environments (e.g., `production`) and enable mandatory reviewer approvals in repo settings before jobs accessing those secrets can run.

4. **Never Print Secrets in Debug Flags**:
   Avoid enabling commands like `set -x` in bash scripts when handling secrets, as parameter expansion can print plaintext values prior to masking.
