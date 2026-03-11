# Marketing Site — Infrastructure as Code

This repository contains the Terraform configuration to provision a secure, scalable, and highly available environment for the Marketing "Hello World" application on Azure.

## Strategic Context

This deployment is designed as a **Proof of Concept (POC)** to establish a reusable, standardized pattern for containerized workloads across the organization. It leverages modern cloud-native principles to ensure the architecture is resilient, cost-effective, and secure by default.

## System Architecture

The architecture is built on the principles of stateless compute tiers, edge caching, and strict network isolation.

- **Global Gateway:** Azure Front Door sits at the edge, providing Web Application Firewall (WAF) capabilities and CDN routing.
- **Compute:** Azure Container Apps (ACA) hosts the frontend and backend microservices.
- **Data & Cache:** Azure SQL (Serverless) and Azure Cache for Redis handle state and caching.
- **Security Perimeter:** The data layer is completely isolated from the internet using Azure Private Endpoints.
- **Secrets Management:** Azure Key Vault stores connection strings, accessed securely via User-Assigned Managed Identities.

```mermaid
flowchart TB
    classDef edge fill:#0078d4,stroke:#005a9e,color:#fff,font-weight:bold
    classDef compute fill:#10b981,stroke:#059669,color:#fff,font-weight:bold
    classDef data fill:#f59e0b,stroke:#d97706,color:#fff,font-weight:bold
    classDef security fill:#ef4444,stroke:#dc2626,color:#fff,font-weight:bold
    classDef network fill:#8b5cf6,stroke:#7c3aed,color:#fff,font-weight:bold
    classDef observe fill:#06b6d4,stroke:#0891b2,color:#fff,font-weight:bold
    classDef user fill:#64748b,stroke:#475569,color:#fff
    classDef dns fill:#a78bfa,stroke:#8b5cf6,color:#fff

    USERS["👥 Internet Traffic<br/><i>Campaign visitors 10AM–8PM EST</i>"]:::user

    subgraph EDGE["🌐 Global Edge — ADR-1"]
        direction LR
        AFD["Azure Front Door<br/><i>CDN + Global LB</i>"]:::edge
        WAF["WAF Policy<br/><i>OWASP Top 10</i>"]:::edge
        AFD --- WAF
    end

    USERS -->|HTTPS| EDGE

    subgraph VNET["🔗 Azure Virtual Network — 10.0.0.0/16"]
        direction TB

        subgraph ACA_SUB["⚡ ACA Environment Subnet — 10.0.0.0/23 — ADR-2"]
            direction LR
            SITE["Marketing Site<br/><i>External Ingress :8080</i>"]:::compute
            API["Marketing API<br/><i>Internal-Only Ingress</i>"]:::compute
            SITE -->|"HTTP (internal)"| API
        end

        subgraph PE_SUB["🔒 Private Endpoints Subnet — 10.0.2.0/24 — ADR-3"]
            direction LR
            REDIS["Azure Cache<br/>for Redis<br/><i>5s TTL</i>"]:::data
            SQL["Azure SQL<br/>Serverless<br/><i>Auto-scale · ADR-4</i>"]:::data
        end

        DNS1["privatelink.database.windows.net"]:::dns
        DNS2["privatelink.redis.cache.windows.net"]:::dns
    end

    EDGE -->|"Origin (validated)"| SITE
    SITE -->|"Private Endpoint"| REDIS
    API -->|"Private Endpoint"| SQL
    SQL -.- DNS1
    REDIS -.- DNS2

    subgraph SUPPORT["Supporting Services"]
        direction LR

        subgraph SEC["🔐 Identity & Secrets — ADR-5"]
            KV["Azure Key Vault<br/><i>Connection strings</i>"]:::security
            MI["Managed Identity<br/><i>User-assigned · acrPull</i>"]:::security
        end

        subgraph REG["📦 Container Registry"]
            ACR["Azure ACR<br/><i>Admin disabled</i>"]:::compute
        end

        subgraph OBS["📊 Observability"]
            LOG["Log Analytics<br/>Workspace"]:::observe
        end
    end

    MI -.->|"Secret access"| KV
    MI -.->|"Image pull"| ACR
    ACA_SUB -.->|"Logs & metrics"| LOG
```

## Architecture Decision Records (ADRs)

### ADR-1: Edge Ingress & Routing — Azure Front Door

**Context:** The site expects significant daytime traffic spikes and needs protection from common web vulnerabilities.

**Decision:** Implement Azure Front Door (AFD) with a Web Application Firewall (WAF) as the global entry point.

**Justification:** Exposing compute directly to the internet is an anti-pattern for production enterprise applications. AFD caches static assets at the edge, reducing origin load, while the WAF protects against OWASP Top 10 threats. The Marketing Site Container App is configured to reject any traffic that does not originate from our specific Front Door instance.

### ADR-2: Compute Platform — Azure Container Apps (ACA)

**Context:** The application expects traffic spikes from 10:00 AM to 8:00 PM EST and requires a reusable container deployment pattern.

**Decision:** Deploy the containers using Azure Container Apps.

**Justification:** ACA natively supports Kubernetes Event-driven Autoscaling (KEDA). This allows the infrastructure to scale horizontally in seconds based on concurrent HTTP requests during the campaign spikes, and scale down to zero (or a minimal baseline) at night to optimize costs. It removes the operational overhead of managing AKS while providing superior burst-scaling compared to traditional App Service Plans.

**Internal Routing:** The Marketing API is configured with internal-only ingress, meaning it cannot be reached from the public internet, further shrinking the attack surface.

### ADR-3: Network Security — Private Endpoints

**Context:** The SQL database contains sensitive data.

**Decision:** Deploy Azure Private Endpoints for both Azure SQL Database and Azure Cache for Redis.

**Justification:** We disable all public network access to the database and cache. By using Private Endpoints, traffic between the Container Apps and the data layer travels exclusively over the Microsoft backbone network via the Virtual Network.

### ADR-4: Data Layer — Azure SQL Serverless

**Context:** The database load will mirror the spiky traffic of the frontend.

**Decision:** Utilize Azure SQL Database configured with the Serverless compute tier.

**Justification:** The Serverless tier automatically scales compute resources (vCores and memory) in response to workload demand and auto-pauses during periods of inactivity. This guarantees performance during the 10-hour high-traffic window while aggressively minimizing costs during off-hours.

### ADR-5: Secrets Management — Managed Identities

**Context:** The applications require connection strings for Redis and SQL.

**Decision:** Store connection strings in Azure Key Vault and access them via User-Assigned Managed Identities.

**Justification:** No secrets are stored in Terraform state, Dockerfiles, or environment variables. The Container Apps assume the Managed Identity at runtime to securely fetch secrets, adhering to the principle of least privilege.

## Deployment Instructions

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- An Azure subscription with Contributor access

### 1. Clone and Authenticate

```bash
git clone https://github.com/YOUR_USERNAME/jules-site-mkt-infra.git
cd jules-site-mkt-infra

az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan -var="sql_admin_password=YOUR_SECURE_PASSWORD"
terraform apply -var="sql_admin_password=YOUR_SECURE_PASSWORD"
```

### 3. Build and Push Container Images

From the root of the [site-mkt](https://github.com/RXNT/site-mkt) application repository:

```bash
ACR_NAME=$(cd ../jules-site-mkt-infra/terraform && terraform output -raw acr_login_server | cut -d. -f1)

az acr build \
  --registry $ACR_NAME \
  --image marketing-site:latest \
  --file Dockerfile.site .

az acr build \
  --registry $ACR_NAME \
  --image marketing-api:latest \
  --file Dockerfile.api .
```

### 4. Update Container Images and Re-apply

```bash
cd ../jules-site-mkt-infra/terraform

ACR_SERVER=$(terraform output -raw acr_login_server)

terraform apply \
  -var="sql_admin_password=YOUR_SECURE_PASSWORD" \
  -var="site_image=${ACR_SERVER}/marketing-site:latest" \
  -var="api_image=${ACR_SERVER}/marketing-api:latest"
```

### 5. Verify

```bash
echo "Front Door URL: https://$(terraform output -raw front_door_endpoint)"
```

## State Management Note

For the purpose of this POC and easy local evaluation, the Terraform state is configured to run locally. However, for a production environment, state must be centralized, locked, and versioned. The `providers.tf` file includes a commented-out `backend "azurerm"` block demonstrating how this configuration seamlessly transitions to an Azure Storage Account with state locking.

## Terraform File Reference

| File | Purpose |
| --- | --- |
| `providers.tf` | AzureRM provider, version constraints, backend config |
| `main.tf` | Resource group, common tags |
| `network.tf` | VNet, subnets, NSGs |
| `identity.tf` | User-Assigned Managed Identity, role assignments |
| `keyvault.tf` | Key Vault, secrets |
| `acr.tf` | Container Registry |
| `database.tf` | SQL Server, Serverless DB, Private Endpoint |
| `redis.tf` | Azure Cache for Redis, Private Endpoint |
| `dns.tf` | Private DNS zones, VNet links |
| `container_apps.tf` | ACA environment, Site app, API app |
| `frontdoor.tf` | Front Door profile, WAF policy, routing |
| `variables.tf` | Input variables |
| `outputs.tf` | Key output values |
