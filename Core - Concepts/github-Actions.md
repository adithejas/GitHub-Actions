# GitHub Actions

## Defination

An **Event** is a specific activity in a repository that triggers a workflow run.

## 🛠️ GitHub Actions: Verified Creators vs. Third-Party Actions

When utilizing pre-built actions in your workflows via the uses: directive, actions fall into two main categories:

### 1. Verified Creators

- What they are: Actions developed by organizations whose identity GitHub has verified as an official partner or trusted vendor (e.g., actions/, aws-actions/, docker/).
- Badge: Display a Verified Creator badge on the GitHub Marketplace.
- Security: Lower risk of malicious supply-chain attacks, but version pinning is still recommended.

### 2. Third-Party Actions

- What they are: Actions built by individual community members or non-verified organizations.

- Badge: Do not carry the verified badge on GitHub Marketplace.

- Security: Higher risk because external maintainers could update or compromise the action's codebase. Code auditing and strict version pinning are critical.

## Defining Actions by Version (Tags, Branches, SHAs)

You specify which code version an action runs by adding @ followed by a Git Tag, Branch Name, or Commit SHA.

```yaml
uses: <owner>/<repository>@<ref>
```

### Using Tags (Recommended for trusted/verified actions)

Points to a release tag created by the author.

_Pros_: Convenient; receives non-breaking updates automatically.

_Cons_: Tags are mutable (can be moved or deleted by the repository owner).

```yaml
# Major version tag (automatically includes minor updates/bug fixes)
- name: Checkout Code
  uses: actions/checkout@v4

# Precise semantic release tag
- name: Setup Node
  uses: actions/setup-node@v4.0.0
```

### Using Branch Names (Use with caution)

Points directly to a Git branch.

_Pros_: Always runs the latest commit on that branch.

_Cons_: Extremely unstable; breaking changes or untested code can break your pipeline without warning.

### Using Commit SHAs (Most Secure / Immutable)

Points to the exact 40-character Git commit hash (SHA-1).

_Pros_: 100% Immutable. Guarantees that the code running in your workflow cannot be changed, even if the action repository is compromised.

_Cons_: You won't automatically receive security updates or bug fixes unless updated manually or via tools like Dependabot.

```yaml
# Pinned to an exact commit SHA with an inline comment indicating the version
- name: Checkout Code
  uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

## This is the reason why first_workflow has failed

[Failed Job](https://github.com/adithejas/GitHub-Actions/actions/runs/31667120144)

> [!WARNING]
> **Missing Repository Checkout Step**
>
> ![Workflow Error](./images/error_1.png)
> Running file commands like `cat README.md` will fail with `cat: README.md: No such file or directory` if the repository files are not checked out first. In GitHub Actions workflows, jobs run in an isolated virtual machine and do not contain your repository files by default.
>
> **Solution:** Ensure `actions/checkout` is included as the first step in your job:
>
> ```yaml
> steps:
>   - name: Checkout repository
>     uses: actions/checkout@v4
> ```
