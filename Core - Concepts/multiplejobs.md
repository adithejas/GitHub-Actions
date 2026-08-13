# GitHub Actions: Comprehensive Guide to Multiple Jobs and Job Dependencies

## Table of Contents

1. [Overview](#overview)
2. [Key Concepts & Definitions](#key-concepts--definitions)
3. [Default Settings & Execution Behavior](#default-settings--execution-behavior)
4. [Job Dependencies (`needs`)](#job-dependencies-needs)
5. [Artifact Sharing Between Jobs](#artifact-sharing-between-jobs)
6. [Complete Annotated Workflow Example](#complete-annotated-workflow-example)
7. [Detailed Breakdown of Example Jobs](#detailed-breakdown-of-example-jobs)
8. [Best Practices & Common Pitfalls](#best-practices--common-pitfalls)

---

## Overview

In GitHub Actions, a **workflow** is composed of one or more **jobs**. By default, jobs run in **parallel**. However, real-world continuous integration and continuous deployment (CI/CD) pipelines often require sequential execution—where one job depends on the success or completion of another.

This guide explores how GitHub Actions manages multiple jobs, dependencies, environment isolation, and artifact passing between workflow steps and jobs.

---

## Key Concepts & Definitions

### 1. Job (`jobs.<job_id>`)

A job is a set of sequential steps executed on a runner instance. Each job runs in its own fresh runner environment (virtual machine or container).

- **`runs-on`**: Specifies the type of runner machine (e.g., `ubuntu-latest`, `windows-latest`, `macos-latest`).
- **`steps`**: An ordered list of tasks executed in sequence within the same job runner.
- **`needs`**: Identifies any jobs that must complete successfully before this job can run.

### 2. Runner Isolation

Each job in a GitHub Actions workflow runs on a separate, fresh virtual machine instance.

- Files created in `dependent_job` **do not automatically exist** in `Test_job` or `Deploy_job`.
- To pass files or data between separate jobs, you must use **artifacts** (`actions/upload-artifact` and `actions/download-artifact`) or workflow outputs.

---

## Default Settings & Execution Behavior

| Feature                | Default Setting       | Behavior / Details                                                                                                                             |
| :--------------------- | :-------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| **Execution Mode**     | Parallel              | Jobs without a `needs` key run concurrently.                                                                                                   |
| **Fail-Fast Behavior** | Enabled               | If one job in a workflow fails, GitHub Actions cancels other running or pending jobs by default (configurable in matrix jobs).                 |
| **Timeout**            | 360 minutes (6 hours) | Maximum execution time allowed for a single job.                                                                                               |
| **Environment**        | Clean VM / Container  | Each job gets a clean, isolated environment. No shared state or local disk space between jobs.                                                 |
| **Status Check**       | `success()`           | Dependent jobs only execute if all jobs listed in `needs` succeed (unless conditional functions like `always()` or `failure()` are specified). |

---

## Job Dependencies (`needs`)

The `needs` keyword establishes dependency relationships between jobs, creating a **Directed Acyclic Graph (DAG)** of execution order.

### Syntax Variations

#### Single Dependency

```yaml
Test_job:
  runs-on: ubuntu-latest
  needs: dependent_job
```

#### Multiple Dependencies

```yaml
Deploy_job:
  runs-on: ubuntu-latest
  needs: [dependent_job, Test_job]
```

### Dependency Execution Flow

```
[ dependent_job ]  (Generates & Uploads Artifact)
        │
        ▼
   [ Test_job ]    (Downloads Artifact & Validates Content)
        │
        ▼
  [ Deploy_job ]   (Downloads Artifact & Renders Output)
```

---

## Artifact Sharing Between Jobs

Because jobs run on isolated runners, artifacts serve as the bridge for transferring data.

- **`actions/upload-artifact@v4`**: Saves files or directories from the current job workspace to GitHub storage.
- **`actions/download-artifact@v4`**: Retrieves saved files into the current job workspace.

> **Note on Action Versions**: It is recommended to use official stable versions such as `@v4`.

---

## Complete Annotated Workflow Example

Below is the updated and fully formatted workflow YAML file.

```yaml
name: multiplejobs

on:
  workflow_dispatch:

jobs:
  dependent_job:
    name: Build & Generate Artwork
    runs-on: ubuntu-latest
    steps:          
      - name: Install Cowsay program
        run: sudo apt-get update && sudo apt-get install -y cowsay

      - name: Generate ASCII artwork
        run: /usr/games/cowsay -f dragon "Run for cover, I am a dragon!" > dragon_artwork.txt

      - name: Upload ASCII artwork as artifact
        uses: actions/upload-artifact@v4
        with:
          name: dragon_artwork
          path: dragon_artwork.txt

  Test_job:
    name: Validate Artwork Artifact
    runs-on: ubuntu-latest
    needs: dependent_job
    steps:
      - name: Download ASCII artwork artifact
        uses: actions/download-artifact@v4
        with:
          name: dragon_artwork

      - name: Test the file existence
        run: |
          if [ -f dragon_artwork.txt ]; then
            echo "File exists."
            grep -i "dragon" dragon_artwork.txt
          else
            echo "File does not exist."
            exit 1
          fi

  Deploy_job:
    name: Display & Deploy Artwork
    runs-on: ubuntu-latest
    needs: Test_job
    steps:
      - name: Download ASCII artwork artifact
        uses: actions/download-artifact@v4
        with:
          name: dragon_artwork

      - name: Display ASCII artwork
        run: cat dragon_artwork.txt

      - name: Checkout repo files
        run: ls -ltar
```

---

## Detailed Breakdown of Example Jobs

### 1. `dependent_job` (First Job in Pipeline)

- **Role**: Installs system binaries (`cowsay`), generates output (`dragon_artwork.txt`), and uploads it as a workflow artifact named `dragon_artwork`.
- **Dependencies**: None. Executes immediately when the workflow triggers.

### 2. `Test_job` (Second Job in Pipeline)

- **Role**: Validates that the file created in `dependent_job` was passed correctly via artifacts and verifies its content using `grep`.
- **Dependencies**: `needs: dependent_job`. Starts only after `dependent_job` completes successfully.

### 3. `Deploy_job` (Third Job in Pipeline)

- **Role**: Downloads the verified artifact and displays the content to standard output using `cat`.
- **Dependencies**: `needs: Test_job`. Starts only after `Test_job` completes successfully.

---

## Best Practices & Common Pitfalls

1. **Avoid Missing Artifact Paths**:
   When using `actions/download-artifact@v4` without specifying a `path`, the files are extracted directly into the runner's current working directory root (`.`).

2. **Handle Failure Conditionals Explicitly**:
   By default, if `dependent_job` fails, `Test_job` and `Deploy_job` will be skipped. Use conditionals like `if: always()` or `if: failure()` if cleanup or notification steps are needed regardless of job status.

3. **Keep Artifact Sizes Lean**:
   Upload only necessary files to speed up workflow execution times and reduce storage consumption.
