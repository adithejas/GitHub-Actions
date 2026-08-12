# GitHub Actions Runners: GitHub-Hosted vs. Self-Hosted

## Definition of Runners

In GitHub Actions, a **runner** is an application that runs a job from a GitHub Actions workflow. When a workflow is triggered, the runner executes the specified steps, reports the progress, and sends the logs and results back to GitHub. A runner can execute on a physical server, virtual machine (VM), or inside a container.

---

## Types of Runners

GitHub Actions provides two primary categories of runners based on hosting and management:

### 1. GitHub-Hosted Runners

A **GitHub-hosted runner** is a virtual machine managed entirely by GitHub. GitHub takes care of provisioning, maintaining, updating, and scaling the infrastructure. A fresh virtual machine is automatically created for each individual job execution and is immediately destroyed once the job completes.

### 2. Self-Hosted Runners

A **self-hosted runner** is a physical machine, virtual machine, or containerized environment that you provision, configure, and maintain yourself. You install the GitHub Actions runner application on your custom infrastructure (cloud instance, on-premises server, or local machine) and register it with your GitHub repository, organization, or enterprise.

---

## Key Differences

| Feature                      | GitHub-Hosted Runners                                                                        | Self-Hosted Runners                                                                                  |
| :--------------------------- | :------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------- |
| **Management & Maintenance** | Fully managed, updated, and patched by GitHub.                                               | Managed, patched, and updated by you/your organization.                                              |
| **Operating Environment**    | Clean, ephemeral virtual machine for every job.                                              | Can be persistent or ephemeral (requires custom setup for clean states).                             |
| **Customization**            | Standard software pre-installed; customization occurs per job run.                           | Fully customizable with persistent tools, custom hardware, and specialized dependencies.             |
| **Network Access**           | Public internet access; requires IP allowlisting or complex VPN setups for private networks. | Direct access to private cloud resources, internal networks, and databases behind firewalls.         |
| **Performance & Hardware**   | Preconfigured CPU/RAM tiers provided by GitHub.                                              | Flexible; can leverage high-performance hardware, GPUs, or local caching.                            |
| **Cost Structure**           | Free tier available; paid per-minute usage based on OS type and machine size.                | Free from GitHub (no per-minute charge); you pay only for your infrastructure.                       |
| **Security Risk**            | Isolated ephemeral environments managed by GitHub standards.                                 | Risk of persistent state contamination or unauthorized access on public repositories if not secured. |
| **Supported OS**             | Ubuntu Linux, Windows Server, and macOS.                                                     | Linux, Windows, macOS, and custom container environments (e.g., Kubernetes).                         |

---

### Detailed Breakdown

- **Infrastructure Control:** GitHub-hosted runners eliminate infrastructure management overhead. Self-hosted runners give you complete control over operating systems, compute power, and installed software.
- **Security Context:** GitHub-hosted runners are recommended for public repositories to prevent untrusted pull requests from executing malicious code on private network infrastructure. Self-hosted runners are ideal for private repositories requiring internal network access.
- **Performance Optimization:** Self-hosted runners allow persistent caching of large dependencies across workflow runs, significantly reducing build times compared to downloading packages on fresh GitHub-hosted VMs.
