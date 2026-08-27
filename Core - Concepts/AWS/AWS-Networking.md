# AWS Networking

## 1. Core Network Foundation

### Virtual Private Cloud (VPC)

A logically isolated virtual network defined within an AWS Region. It represents your private data center in the cloud.

- **Key Concept:** VPCs span an entire Region. You define its IP address space using one or more CIDR blocks.
- **Interview Tip:** A VPC cannot span multiple Regions, but it automatically spans all Availability Zones (AZs) within its designated Region.

### Classless Inter-Domain Routing (CIDR) Blocks

The standard method used to allocate IP addresses and IP routing.

- **Key Concept:** When creating a VPC, you assign an IPv4 CIDR block (e.g., `10.0.0.0/16`). Allowed block sizes range from `/16` (65,536 IPs) down to `/28` (16 IPs).
- **AWS Reserved IPs Gotcha:** In every subnet CIDR block, AWS reserves **5 IP addresses** that cannot be assigned to instances:
  - `.0`: Network address.
  - `.1`: Reserved by AWS for the VPC router.
  - `.2`: Reserved by AWS for DNS mapping.
  - `.3`: Reserved by AWS for future use.
  - `.255` (or last IP): Network broadcast address (AWS does not support standard broadcast, but reserves the address).

### Subnets

Subdivisions of a VPC's CIDR block that reside strictly within a **single Availability Zone (AZ)**.

- **Public Subnet:** A subnet whose route table contains an explicit route to an Internet Gateway (`0.0.0.0/0` -> `igw-xxxx`).
- **Private Subnet:** A subnet whose route table does _not_ route directly to an IGW.
- **Interview Best Practice:** Always architect for High Availability (HA) across at least two AZs.

### Elastic Network Interface (ENI)

A virtual network interface card (NIC) that you can attach to an EC2 instance.

- **Key Attributes:** Primary private IPv4 address, one or more secondary private IPs, Elastic IP, MAC address, and attached Security Groups.
- **Use Cases:**
  - Dual-homing instances across multiple subnets.
  - Low-cost active/passive failover (detaching an ENI from a failed primary instance and re-attaching it to a standby instance).

### Elastic IP (EIP)

A static, public IPv4 address designed for dynamic cloud computing.

- **Key Concept:** Unlike standard dynamic public IPs (which change on instance stop/start), an EIP remains allocated to your AWS account until explicitly released.
- **Common Use Cases:** Required for Public NAT Gateways; necessary for instances requiring IP whitelisting by third parties.
- **Interview Gotchas & Cost:** AWS charges for allocated Elastic IPs that are _not_ associated with a running instance to prevent IP hoarding. AWS also charges an hourly fee for all public IPv4 addresses in use. The default limit is 5 EIPs per Region.

---

## 2. Routing & Gateways

### Route Tables and Rules

A collection of rules (routes) used to determine where network traffic from a subnet or gateway is directed.

- **Key Concept:** Every subnet must be associated with a route table. Multiple subnets can share the same route table, but a subnet can only be associated with one route table at a time.
- **Local Route:** Every route table has a default `local` route covering the VPC CIDR block. This allows internal VPC communication and cannot be deleted.

### Internet Gateway (IGW)

A horizontally scaled, redundant, and highly available VPC component that enables bidirectional communication between your VPC and the public internet.

- **Key Concept:** Performs 1:1 NAT mapping between private instance IPs and their associated public/Elastic IPs.

### NAT Gateway (Network Address Translation)

Enables outbound internet access for private subnet resources while blocking unsolicited inbound connections from the internet.

- **Key Concept:** Deployed in a **Public Subnet** and requires an attached Elastic IP.
- **High Availability Gotcha:** NAT Gateways are zone-redundant within a single AZ, but _not multi-AZ_. If the AZ fails, the NAT Gateway fails. For high availability, deploy **one NAT Gateway per AZ** and associate private route tables to their local AZ NAT Gateway.

### Virtual Private Gateway (VGW) & Customer Gateway (CGW)

The building blocks for AWS Site-to-Site VPN connections.

- **Customer Gateway (CGW):** The physical appliance or software configuration on the on-premises network.
- **Virtual Private Gateway (VGW):** The VPN concentrator attached to the AWS VPC.
- **Interview Tip:** A VGW can only attach to one VPC at a time. To connect on-premises VPN/Direct Connect to multiple VPCs, use a **Transit Gateway (TGW)** instead.

---

## 3. Network Security Controls

### Security Groups (SGs)

Stateful virtual firewalls operating at the **instance/ENI level**.

- **Stateful Nature:** Outbound return traffic is automatically allowed regardless of outbound rules.
- **Rules:** Supports **ALLOW rules only**.
- **Security Group Referencing:** The gold standard in multi-tier security. Instead of hardcoding CIDR blocks, configure SGs to allow traffic from another Security Group ID (e.g., App SG allows port 3306 only from `sg-app-tier`).

### Network Access Control Lists (NACLs)

Stateless virtual firewalls operating at the **subnet boundary**.

- **Stateless Nature:** Explicit rules are required for both inbound AND outbound traffic.
- **Rules:** Supports both **ALLOW and DENY rules**, evaluated in numerical order (lowest rule number evaluated first).
- **Ephemeral Ports Gotcha:** When locking down NACLs, you must explicitly allow outbound return traffic on **Ephemeral Ports (1024–65535)**.

### AWS Security Layer Comparison: WAF vs. Shield vs. Network Firewall

- **AWS WAF (Web Application Firewall):** Layer 7 (Application). Protects against web exploits (SQLi, XSS, rate limiting) on CloudFront, ALB, API Gateway, and AppSync.
- **AWS Shield:** Layer 3/4 (Network/Transport) DDoS protection. Standard is free; Advanced offers Layer 7 DDoS response teams and cost protection.
- **AWS Network Firewall:** Stateful Layer 3–7 network inspection, intrusion detection/prevention (IDS/IPS), and URL filtering at the VPC level.

### Administrative Access: Bastion Hosts vs. AWS SSM Session Manager

- **Bastion Host (Jump Box):** EC2 instance in a public subnet running SSH/RDP. Requires open port 22/3389, public IP, and SSH key management.
- **AWS Systems Manager (SSM) Session Manager (AWS Best Practice):** Provides browser-based shell access via IAM permissions and the SSM Agent. Requires **no open inbound ports**, no public IPs, and no SSH key distribution.

---

## 4. Scaling, Hybrid, & Inter-VPC Connectivity

### VPC Peering

A direct network connection between two VPCs using private IP routing.

- **Scope:** Supports cross-account and cross-Region peering.
- **Core Rule (Non-Transitive):** VPC peering is **non-transitive**. If A is peered with B, and B is peered with C, A cannot communicate with C unless directly peered. CIDRs cannot overlap.

### Transit Gateway (TGW)

A centralized regional virtual router that connects VPCs and on-premises networks via a **hub-and-spoke model**.

- **Key Concept:** Supports transitive routing. Replaces complex full-mesh VPC peering meshes when managing dozens or hundreds of VPCs.
- **Hybrid Connectivity:** Connects directly with AWS Direct Connect Gateway and Site-to-Site VPNs.

### AWS Direct Connect (DX) vs. Site-to-Site VPN

- **Site-to-Site VPN:** IPsec VPN over the public internet. Fast setup, lower cost, but subject to public internet latency and bandwidth jitter.
- **Direct Connect (DX):** Dedicated, physical fiber-optic connection from on-premise to AWS. Consistent performance, high bandwidth, and bypasses the public internet completely.

---

## 5. Private Service Access

### VPC Endpoints

Allows instances in private subnets to privately communicate with AWS services without traversing the public internet, NAT Gateways, or Internet Gateways.

- **Gateway Endpoints:**
  - Supported services: **Amazon S3** and **Amazon DynamoDB** only.
  - Mechanism: Adds a prefix-list route target to the VPC Route Table.
  - Cost: **Free**.
- **Interface Endpoints (AWS PrivateLink):**
  - Supported services: Most AWS services (SQS, SNS, Kinesis, CloudWatch, SSM, RDS API) and custom third-party SaaS.
  - Mechanism: Provisions an Elastic Network Interface (ENI) with a private IP directly in your subnet.
  - Cost: Hourly charge per endpoint + data processing fees.

---

## 6. Edge Networking, DNS, & Traffic Acceleration

### Amazon CloudFront

Global Content Delivery Network (CDN) caching content at hundreds of Points of Presence (PoPs) worldwide.

- **Mechanisms:** Terminates SSL/TLS at the edge, caches static assets, forwards dynamic requests to origins (ALB, S3, API Gateway).
- **Security Integration:** Attaches directly to AWS WAF and CloudFront Origin Shield.

### Amazon Route 53

Highly available, scalable cloud Domain Name System (DNS) service.

- **Alias Records vs. CNAME:**
  - CNAME cannot be mapped to the zone apex/root domain (e.g., `example.com`).
  - **Alias Records** can resolve apex domains directly to AWS resources (CloudFront distributions, ALBs, S3 website endpoints) without incurring DNS query fees.
- **Routing Policies:**
  - _Simple:_ 1:1 record-to-IP mapping.
  - _Weighted:_ Percentage-based routing (ideal for A/B testing and canary deployments).
  - _Latency-Based:_ Routes traffic to the AWS Region with lowest latency for the end user.
  - _Geolocation / Geoproximity:_ Routes based on user location.
  - _Failover:_ Active-passive failover triggered by Route 53 Health Checks.
  - _Multivalue Answer:_ DNS-level load balancing across multiple healthy IPs.

### Route 53 Resolver (Hybrid DNS)

Bridges DNS resolution between on-premises environments and AWS VPCs.

- **Inbound Endpoint:** Allows on-premise DNS servers to resolve private AWS hosted zones (`.internal`).
- **Outbound Endpoint:** Allows EC2 instances in VPCs to resolve on-premises private domains (`.corp`).

### Elastic Load Balancing (ELB)

- **Application Load Balancer (ALB):** Layer 7 (HTTP/HTTPS). Supports host-based and path-based routing, gRPC, and direct integration with AWS WAF.
- **Network Load Balancer (NLB):** Layer 4 (TCP/UDP/TLS). Ultra-high throughput (millions of requests/sec), extreme low latency, provides one static/Elastic IP per AZ.
- **Gateway Load Balancer (GWLB):** Layer 3 (IP packet listening). Deploys and scales fleets of third-party network virtual appliances (firewalls, IDS/IPS).

### AWS Global Accelerator

Uses the AWS global network infrastructure to route user traffic through the nearest edge location via static Anycast IP addresses.

- **Differentiator from CloudFront:** CloudFront caches content (HTTP/HTTPS/web); Global Accelerator accelerates non-HTTP protocols (TCP/UDP, gaming, IoT, VoIP) without caching.

### VPC Flow Logs

Captures metadata on IP traffic going to and from network interfaces in a VPC.

- **Key Uses:** Security auditing, connection debugging, and identifying rejected packets. Logs stream to Amazon CloudWatch Logs, Amazon S3, or Amazon Kinesis Data Firehose.

---

## 7. Complete Practical Architecture: Secure 3-Tier VPC Design

### Design Blueprint

- **CIDR Block:** `10.0.0.0/16` across **2 Availability Zones** (AZ-A and AZ-B).

### Subnet Layout

1.  **Public Subnets (Web/Presentation):** `10.0.1.0/24` (AZ-A) and `10.0.2.0/24` (AZ-B).
    - Hosts: Internet-Facing Application Load Balancer (ALB), NAT Gateway A, NAT Gateway B.
    - Route Table: `0.0.0.0/0` -> Internet Gateway (IGW).
2.  **Private Subnets (Application/Logic):** `10.0.3.0/24` (AZ-A) and `10.0.4.0/24` (AZ-B).
    - Hosts: Backend application instances / Auto Scaling Group.
    - Route Table AZ-A: `0.0.0.0/0` -> NAT Gateway A.
    - Route Table AZ-B: `0.0.0.0/0` -> NAT Gateway B.
3.  **Private Subnets (Database/Data):** `10.0.5.0/24` (AZ-A) and `10.0.6.0/24` (AZ-B).
    - Hosts: Amazon RDS Multi-AZ DB Cluster (Primary + Standby).
    - Route Table: Isolated (`local` route only, no outbound internet route).

### Security Group Chaining Matrix

- **ALB Security Group (`sg-alb`):**
  - Inbound: Allow Port 443 (HTTPS) from `0.0.0.0/0`.
  - Outbound: Allow Port 8080 to `sg-app`.
- **App Security Group (`sg-app`):**
  - Inbound: Allow Port 8080 from `sg-alb` (Only).
  - Outbound: Allow Port 3306/5432 to `sg-db`. Allow Port 443 to `0.0.0.0/0` (via NAT for package updates).
- **DB Security Group (`sg-db`):**
  - Inbound: Allow Port 3306/5432 from `sg-app` (Only).
  - Outbound: None (Security groups are stateful).

### Complete End-to-End Request Lifecycle

1.  **DNS Query:** The user navigates to `https://www.example.com`. Route 53 resolves the domain using an **Alias Record** to the CloudFront distribution or ALB.
2.  **Edge Delivery:** CloudFront terminates TLS at the edge, checks cache for static assets, and proxies dynamic API traffic over the AWS backbone to the ALB.
3.  **VPC Ingress:** Traffic enters the VPC through the **Internet Gateway** and hits the **ALB** in the Public Subnets.
4.  **Target Routing:** The ALB verifies target health and routes HTTP requests to private instances in the **App Tier Private Subnet**.
5.  **Data Tier Access:** The App server queries the RDS database in the **DB Private Subnet** using private IPs.
6.  **Outbound Patching:** When the App instances require OS updates, traffic routes to the **NAT Gateway** in the public subnet of their respective AZ, then through the IGW to external repositories.
