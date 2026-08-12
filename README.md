# 🚀 GitHub Actions Learning Log & Reference Guide

Welcome to my personal learning repository for **GitHub Actions**! This repo serves as a comprehensive notebook, containing concepts, code snippets, custom workflows, and key insights I have gathered while mastering GitHub Actions.

---

## 📌 Core Concepts

GitHub Actions is an automated CI/CD platform built directly into GitHub. Key components include:

- **Workflows (`.github/workflows/*.yml`)**: Configurable automated processes stored as YAML files.
- **Events (`on:`)**: Triggers that start a workflow (e.g., `push`, `pull_request`, `workflow_dispatch`, or scheduled `cron`).
- **Jobs (`jobs:`)**: A set of steps executed on the same runner (can run in parallel or sequentially using `needs:`).
- **Steps (`steps:`)**: Individual tasks within a job executing shell commands (`run:`) or actions (`uses:`).
- **Runners (`runs-on:`)**: Virtual machines (hosted by GitHub or self-hosted) executing the jobs.

---

## 🛠️ Basic Workflow Template

```yaml
name: CI Workflow

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository code
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test
