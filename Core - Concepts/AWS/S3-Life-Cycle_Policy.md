# Amazon S3 Lifecycle Policies

## 1. What is an S3 Lifecycle Policy?

An S3 Lifecycle Policy is a set of rules that define actions Amazon S3 should apply to a group of objects over time. The primary goal is **cost optimization**—automatically moving data to cheaper storage tiers as it ages and deleting it when it's no longer needed.

---

## 2. Types of Lifecycle Actions

Lifecycle rules are broken down into two main types of actions:

### A. Transition Actions

These actions move objects to different, usually cheaper, storage classes after a specified number of days since creation.

- **Example:** Move an object from `S3 Standard` to `S3 Standard-IA` after 30 days.
- **Example:** Move from `S3 Standard-IA` to `S3 Glacier Flexible Retrieval` after 90 days.
- _Note:_ You cannot transition objects from a cold tier back to a hot tier via a lifecycle policy.

### B. Expiration Actions

These actions dictate when an object expires and should be permanently deleted.

- **Example:** Delete log files after 365 days.
- **Incomplete Multipart Uploads:** Automatically abort and delete fragments of uploads that failed to complete (a highly recommended cost-saving measure).

---

## 3. Scope and Filtering

You don't have to apply a lifecycle rule to the entire bucket. You can filter which objects the rule applies to using:

- **Prefixes:** e.g., apply only to objects in the `logs/` folder.
- **Object Tags:** e.g., apply only to objects tagged with `environment=dev`.
- **Object Size:** e.g., transition only objects larger than 128 KB (since transitioning tiny objects to Glacier can cost more in request fees than it saves in storage).

---

## 4. Lifecycle Policies in Versioned Buckets

Understanding how lifecycle rules interact with **S3 Versioning** is critical. You must configure actions separately for:

- **Current Versions:** The latest, active version of the file.
- **Noncurrent Versions:** The older, overwritten, or "deleted" versions of the file.

**The "Delete Marker" Trap:**
When a user deletes a file in a versioned bucket, S3 places a "Delete Marker" on top, making the file _appear_ deleted while keeping the noncurrent version hidden underneath. If you set an Expiration action on "Current Versions", S3 just adds a delete marker. To truly save costs, you must set an Expiration action to **permanently delete Noncurrent Versions** after a certain number of days.

---

## 5. Sample Lifecycle Policy (JSON / Terraform Format)

This is a standard real-world policy that moves objects to Standard-IA after 30 days, Glacier after 90 days, and deletes noncurrent versions after 180 days.

```json
{
  "Rules": [
    {
      "ID": "MoveLogsToColdStorage",
      "Filter": {
        "Prefix": "production-logs/"
      },
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 180
      },
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
```

## 6.Interview Scenarios

Q: A company's S3 bill is surprisingly high, but they only have 50 GB of visible files in the bucket. What is likely causing this?

Answer: Two common culprits:

Incomplete Multipart Uploads: Large file uploads failed midway, and the hidden fragments are racking up storage costs. Add a lifecycle rule to abort incomplete uploads after 7 days.

Hidden Noncurrent Versions: Versioning is enabled, and files are constantly being overwritten or deleted. The bucket contains terabytes of noncurrent versions. Add a lifecycle rule to expire noncurrent versions.

Q: You have millions of tiny 10 KB log files. Should you transition them to Glacier to save money?

Answer: No. Glacier has a minimum capacity charge per object (usually 40 KB) and transition request fees (per 1,000 requests). Transitioning millions of tiny files will cost more in API transition fees than you will ever save on storage. Use an object size filter, or aggregate the logs into larger files before uploading.
