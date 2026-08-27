# Amazon S3

## 1. What is Amazon S3?

Amazon S3 (Simple Storage Service) is a highly scalable, secure, and durable object storage service provided by AWS.

- **Bucket:** The top-level container for data. Names must be globally unique across all AWS accounts.
- **Object:** The actual file (e.g., image, log, backup) and its associated metadata.
- **Key:** The unique identifier (path/name) for an object within a bucket (e.g., `logs/2026/error.log`). S3 has a flat structure; prefixes simulate folders.
- S3 bucket ARNs do not include a region or an account ID.

Because S3 bucket names must be globally unique across all of AWS, AWS doesn't need the region or account ID to figure out which bucket you are talking about.

### Examples:

- Standard S3 Bucket ARN: arn:aws:s3:::my-devops-bucket
  (Notice the three colons ::: in a row—this means the region and account ID fields are intentionally left blank).

- Standard IAM Role ARN: arn:aws:iam::123456789012:role/Jenkins-Pipeline-Role
  (IAM is a global service, so it skips the region, but it requires the account ID and the resource type role/).

- Standard EC2 Instance ARN: arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0
  (EC2 is regional, so it includes both the region and the account ID).

---

## 2. File Size Limits & Constraints

- **Maximum Object Size:** 5 TB
- **Maximum Single `PUT` Upload:** 5 GB
- **Multipart Upload:** Recommended for files > 100 MB, and **mandatory** for files > 5 GB. It breaks files into smaller chunks, uploads them in parallel, and reassembles them, improving speed and reliability.
- **Consistency Model:** S3 provides **Strong read-after-write consistency** for all `PUT` and `DELETE` requests. If you write a file and immediately read it, you will always get the latest version.

---

## 3. Data Durability vs. Availability

- **Durability (11 9s or 99.999999999%):** The probability that data remains intact. If you store 10 million objects, you can expect to lose a single object once every 10,000 years. AWS achieves this by copying data across multiple facilities.
- **Availability (99.9% to 99.99%):** The percentage of time the system is operational and you can successfully access your data immediately when requested.

---

## 4. S3 Storage Classes & Differences

AWS provides different storage tiers to optimize costs based on access frequency.

| Storage Class                          | Use Case                                                                          | Availability | Minimum Duration | Retrieval Fee               |
| :------------------------------------- | :-------------------------------------------------------------------------------- | :----------- | :--------------- | :-------------------------- |
| **S3 Standard**                        | Frequent access, active workloads (websites, mobile apps).                        | 99.99%       | None             | None                        |
| **S3 Intelligent-Tiering**             | Unknown or changing access patterns. Automatically moves objects between tiers.   | 99.9%        | None             | None (Small monitoring fee) |
| **S3 Standard-IA (Infrequent Access)** | Accessed less than once a month, but requires immediate access when needed.       | 99.9%        | 30 days          | Per GB retrieved            |
| **S3 One Zone-IA**                     | Recreatable data or secondary backups. Stored in a single Availability Zone (AZ). | 99.5%        | 30 days          | Per GB retrieved            |
| **S3 Glacier Instant Retrieval**       | Rarely accessed data (once a quarter) requiring millisecond access.               | 99.9%        | 90 days          | Per GB retrieved            |
| **S3 Glacier Flexible Retrieval**      | Archival data. Retrieval takes minutes (1-5 min) to hours (3-5 hrs).              | 99.99%       | 90 days          | Per GB retrieved            |
| **S3 Glacier Deep Archive**            | Long-term compliance backups (kept for years). Retrieval takes 12-48 hours.       | 99.99%       | 180 days         | Per GB retrieved            |
| **S3 Express One Zone**                | High-performance, single-AZ tier for latency-sensitive apps (e.g., ML training).  | 99.95%       | None             | None                        |

---

## 5. Security & Access Control Mechanisms

- **Block Public Access (BPA):** A central guardrail that prevents public access to S3 resources, overriding permissive policies.
- **IAM Policies:** Attached to an IAM User, Group, or Role. Defines what that specific identity can do in S3.
- **Bucket Policies:** A JSON document attached directly to the bucket. Useful for cross-account access or enforcing security rules (e.g., forcing HTTPS).
- **Access Control Lists (ACLs):** A legacy method of granting basic read/write permissions. AWS recommends disabling them in favor of Bucket Policies.
- **Presigned URLs:** Time-limited URLs that grant temporary access to download or upload a specific object without requiring AWS credentials.

---

## 6. Encryption at Rest & In-Transit

**In-Transit (Data moving over the network):**

- Achieved using SSL/TLS. You can enforce this by creating a Bucket Policy that denies requests where `"aws:SecureTransport": "false"`.

**At Rest (Data stored on S3 disks):**

- **SSE-S3 (Server-Side Encryption with S3 Keys):** Default encryption. AWS manages the 256-bit AES encryption and the keys.
- **SSE-KMS (Key Management Service):** Uses AWS KMS for key management. Gives you an audit trail of key usage and allows key rotation. (Tip: Use _S3 Bucket Keys_ to reduce KMS throttling and costs).
- **SSE-C (Customer-Provided Keys):** You provide the encryption key, S3 encrypts the data, and then S3 immediately throws away your key.
- **Client-Side Encryption:** You encrypt the data on your own machine/server before sending it to AWS.

---

## 7. Replication & Data Management

- **Versioning:** Keeps multiple variants of an object in the same bucket. Protects against accidental deletion (adds a 'Delete Marker') and overwrites.
- **MFA Delete:** Requires a Multi-Factor Authentication code to permanently delete a versioned object or change the versioning state.
- **Lifecycle Rules:** Automatically transition objects to cheaper storage classes (e.g., move to Glacier after 30 days) or expire (delete) them after a certain period.
- **S3 Replication (CRR & SRR):** Cross-Region or Same-Region Replication automatically copies new objects to a destination bucket. Requires Versioning on both buckets.
- **S3 Object Lock (WORM - Write Once Read Many):** Prevents objects from being deleted or overwritten for a fixed amount of time. Used for regulatory compliance.

---

## 8. Performance Optimization & Scaling

- **Prefix Request Limits:** S3 naturally scales to support **3,500 PUT/COPY/POST/DELETE** and **5,500 GET/HEAD** requests per second **per prefix** (folder path).
- **Scaling Strategy:** If you expect higher traffic, distribute your objects across multiple prefixes (e.g., `/images/2026/`, `/images/2027/`).
- **Multipart Upload:** As mentioned, parallelizes large uploads to maximize network throughput.
- **Byte-Range Fetches:** Allows you to download specific byte ranges of a large file concurrently, speeding up downloads.
- **S3 Transfer Acceleration:** Uses Amazon CloudFront's globally distributed Edge Locations to route your upload/download traffic over AWS's fast internal network instead of the public internet.

## 9. Cross-Account Access & Security

How does an EC2 instance in Account A write to an S3 bucket in Account B?

- **The Two-Part Handshake:**
  1. **IAM Role (Account A):** The EC2 instance assumes an IAM Role that has a policy granting `s3:PutObject` to the Account B bucket ARN.
  2. **Bucket Policy (Account B):** The bucket in Account B must have a Resource-Based Policy that explicitly grants access to the IAM Role's ARN from Account A.
- **Object Ownership:** Always configure the bucket with **Bucket Owner Enforced** (disabling ACLs) to ensure the destination account owns the uploaded objects.
