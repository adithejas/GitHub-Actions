# GitHub Actions Core Components Guide

This guide provides a detailed overview of the core building blocks that make up a GitHub Actions workflow.

---

## 1. Workflows

### Definition

A **Workflow** is an automated, configurable process made up of one or more jobs. Workflows are defined using YAML files and stored in the `.github/workflows/` directory of your repository.

### Details

- A repository can have multiple workflows (e.g., one for continuous integration, one for releasing packages, and another for labeling issues).
- Workflows are triggered automatically by specific repository events, manual dispatches, or scheduled cron jobs.

### Example

```yaml
# 1. WORKFLOW NAME
name: Full Core Components Demo
```

## 2. Events (on)

### Definition

An **Event** is a specific activity in a repository that triggers a workflow run.

### Details

- Events can originate from GitHub activity (such as push, pull_request, or issues).

- Workflows can also be triggered on a recurring schedule using schedule (cron syntax) or triggered manually using workflow_dispatch.

- Filters can be applied to events, such as targeting specific branches, tags, or paths.

### Example

```yaml
on:
  push:
    branches:
      - main
      - "release/**"
  pull_request:
    branches:
      - main
```

## 3. Jobs

### Definition

A **Job** is a set of steps executed on the same runner environment.

### Details

- By default, multiple jobs within a workflow run in parallel.

- You can define dependencies between jobs using needs to run them sequentially.

- If a job fails, dependent jobs will be skipped by default unless configured with conditional logic.

### Example

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building..."

  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing..."
```

## 4. Runners (runs-on)

### Defination

A **Runner** is a server (virtual machine or container) equipped with the GitHub Actions runner application that executes jobs when triggered.

### Details

- GitHub-hosted Runners: Ephemeral virtual machines managed entirely by GitHub (e.g., ubuntu-latest, windows-latest, macos-latest).

- Self-hosted Runners: Dedicated physical or virtual infrastructure provisioned and maintained by you.

### Example

```yaml
runs-on: ubuntu-latest
```

## 5. Steps

### Defination

A **Step** is an individual task that can run commands or actions within a job.

### Details

- Steps execute sequentially on the same runner environment, allowing them to share file system changes and data across the job.

- A step can either run a shell command (run) or execute a pre-packaged action (uses).

### Example

```yaml
steps:
  - name: Print welcome message
    run: echo "Starting build process"
```

## 6. Actions (uses)

### Defination

An **Action** is a reusable, standalone application or script integrated into a step to perform complex tasks.

### Details

- Actions reduce code duplication by abstracting common tasks (e.g., checking out code, setting up language runtimes, authenticating with cloud providers).

- You can use actions from the GitHub Marketplace, public repositories, or create custom local actions inside .github/actions/.

### Example

```yaml
- name: Check out code
  uses: actions/checkout@v4

- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: "20"
```

## 7. Environment Variables (env) & Secrets

### Defination

**Environment Variables** and Secrets store key-value pairs used to pass parameters or sensitive data into workflows safely.

### Details

- Variables (env): Store non-sensitive configuration data at the workflow, job, or step level.

- Secrets (secrets): Encrypted values stored at the repository, environment, or organization level (accessed via ${{ secrets.SECRET_NAME }}).

### Example

```yaml
env:
  NODE_ENV: production

steps:
  - name: Deploy application
    env:
      API_TOKEN: ${{ secrets.DEPLOY_API_TOKEN }}
    run: ./deploy.sh
```

## Complete Sample Workflow

Below is a complete, annotated .github/workflows/main.yml file demonstrating all the core concepts together:

```yaml
# 1. WORKFLOW NAME
name: Full Core Components Demo

# 2. EVENTS (Triggers)
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch: # Allows manual trigger from GitHub UI

# GLOBAL ENVIRONMENT VARIABLES
env:
  APP_NAME: "MyDemoApp"

# 3. JOBS DEFINITION
jobs:
  # JOB 1: Build and Test
  build-and-test:
    # 4. RUNNER
    runs-on: ubuntu-latest

    # 5. STEPS
    steps:
      # 6. ACTION: Official checkout action to pull code into the runner
      - name: Checkout repository code
        uses: actions/checkout@v4

      # 6. ACTION: Set up runtime environment
      - name: Set up Node.js runtime
        uses: actions/setup-node@v4
        with:
          node-version: "20"

      # 5. STEP (COMMAND): Install dependencies using shell execution
      - name: Install dependencies
        run: npm ci

      # 5. STEP (COMMAND): Execute test suite
      - name: Run test suite
        run: npm test

  # JOB 2: Deployment (Sequential execution using 'needs')
  deploy:
    # JOB DEPENDENCY: Runs only after 'build-and-test' completes successfully
    needs: build-and-test
    runs-on: ubuntu-latest

    # JOB-LEVEL ENVIRONMENT VARIABLES
    env:
      DEPLOY_STAGE: "production"

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # 7. SECRETS & VARIABLES USAGE
      - name: Execute deployment script
        env:
          SERVER_KEY: ${{ secrets.PRODUCTION_SERVER_KEY }}
        run: |
          echo "Deploying ${APP_NAME} to${DEPLOY_STAGE} environment..."
          # Insert deployment script here
```
