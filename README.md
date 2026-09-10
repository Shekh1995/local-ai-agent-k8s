## 🏗️ Architecture Overview

* **Cluster Infrastructure:** Google Kubernetes Engine (GKE) Zonal Cluster.
* **Inference Engine:** Ollama running completely locally within the default namespace.
* **LLM Engine:** `gemma4:e4b` (3.65 GB edge-optimized model).
* **Agent Controller:** kagent-controller utilising local OpenAI-compatible routing schemes backed by a persistent PostgreSQL instance.
* **Working Status:** Though it may require the GPU-integrated cluster, have made it worked with extra CPUs(e2-standard-16), so it may take time to respond to simple prompts also
---

## 🚀 Step-by-Step Deployment

### 1. Provision the GKE Infrastructure
Spin up a compact zonal cluster designed to fit efficiently under standard cloud vCPU quotas.

```bash
# Execute the script to provision the single-zone cluster footprint
./zonal-cluster.sh
```

Once the physical nodes are ready, authenticate your local terminal's workspace context to attach `kubectl`:

```bash
gcloud container clusters get-credentials [your-cluster-name] --zone=[your zone]
```

---

### 2. Launch the Local Model Engine

Deploy Ollama onto your cluster. This service automatically handles fetching and serving the weights for the local model.

```bash
kubectl apply -f ollama-gemma.yml
```

💡 **Verification:** To confirm that the Ollama instance is healthy and has successfully pulled down the model, run:

```bash
kubectl exec -it deployment/ollama-service -- ollama list 
```

---

### 3. Establish Authentication Placeholders

The underlying client SDKs require credential structures to be initialised safely. We pass a dummy parameter to bypass cloud verification.

Create the cluster secret:

```bash
# Install Schema CRDs
helm upgrade --install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --namespace kagent \
  --create-namespace

kubectl create secret generic kagent-openai \
  --namespace kagent \
  --from-literal=OPENAI_API_KEY="dummy-key" \
  --dry-run=client -o yaml | kubectl apply -f -

```

---

### 4. Deploy the kagent Control Plane

Install the required Custom Resource Definitions (CRDs) along with the core application components using Helm.

```bash

# Install the Core Controller and UI Web Engine
helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --namespace kagent \
  --set postgresql.enabled=true \
  --set providers.default=openai \
  --set providers.openai.model="gemma4:e4b" \
  --set providers.openai.apiKey="dummy-key" \
  --set providers.openai.baseUrl="[http://ollama-internal-svc.default.svc.cluster.local:11434/v1](http://ollama-internal-svc.default.svc.cluster.local:11434/v1)"

```

Apply the unified model tracking target parameters:

```bash
kubectl apply -f model-config.yml
```

---

## 🖥️ Accessing the Dashboard

To step inside your local AI control matrix, route the user interface service cleanly back to your machine's localhost network pool:

```bash
kubectl -n kagent port-forward service/kagent-ui 8080:8080 &
```

Now, point your web browser directly to: **[http://localhost:8080](https://www.google.com/search?q=http://localhost:8080)**

---

## 🛠️ Setting Up Your First Agent

Follow the interactive onboarding wizard screen by screen to configure your local automated workspace assistant:

```
[ Let's Get Started ]
         │
         ▼
┌──────────────────────────────────────────────┐
│ Step 1: Configure AI Model                   │  ► Choose an existing model (gemma4:e4b)
└────────────────────────┬─────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────┐
│ Step 2: Set up the AI Agent                  │  ► Review default configurations for the K8s agent
└────────────────────────┬─────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────┐
│ Step 3: Select Tools                         │  ► Review preselected internal API capability tools
└────────────────────────┬─────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────┐
│ Step 4: Review Agent Configuration           │  ► Click "Create kagent/nitesh-k8s-agent & Finish"
└────────────────────────┬─────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────┐
│ Step 5 & 6: Success Landing                  │  ► Click "Finish & Go to Agent" (Refresh page if needed)
└────────────────────────┬─────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────┐
│ Step 7 & 8: Chat & Automate                  │  ► Open your agent thread and begin prompting!
└──────────────────────────────────────────────┘
```

### Example Verification Prompts

Test your offline agent infrastructure using standard interactive chat strings or deep cluster discovery automation parameters:

* 💬 `"Hello! Tell me a one-sentence joke."`
* ☸️ `"What API resources are running in my cluster?"`

## Kagent in action  

<img width="1471" height="1408" alt="kagent-in-action-01" src="https://github.com/user-attachments/assets/35647298-bba6-41c8-8f58-1fa6b3181b70" />

<img width="1472" height="1349" alt="kagent-in-action-02" src="https://github.com/user-attachments/assets/3b06514b-78b8-4580-afea-4476dc4f595b" />

<img width="1855" height="1412" alt="kagent-in-action-03" src="https://github.com/user-attachments/assets/3345eefd-2268-4dde-8c8f-fda67cf983ce" />

<img width="1854" height="1355" alt="kagent-in-action-04" src="https://github.com/user-attachments/assets/30ded5d5-5794-4e07-a16e-4ad45d57ca13" />

## 🧹 Clean up the Lab
To avoid unexpected cloud billing or draining your remaining free tier credits when your testing is complete, make sure to completely purge all infrastructure components from your Google Cloud environment.

1. Remove Local Kubernetes Services
Cleanly drop the deployments, database storage elements, and the local model engine before decommissioning the underlying hardware.

```bash
# Terminate the background port-forward tunnel
pkill -f "port-forward service/kagent-ui"

# Uninstall kagent Helm packages
helm uninstall kagent -n kagent
helm uninstall kagent-crds -n kagent

# Delete workloads and dedicated configurations
kubectl delete -f ollama-gemma.yml
kubectl delete -f model-config.yml
kubectl delete secret kagent-openai -n kagent
kubectl delete namespace kagent
```



2. Nuke the GKE Cluster Footprint
This command tears down the control planes, drops the compute instance node pools, releases your vCPU capacity limits, and releases any persistent load balancer IPs.

```bash
gcloud container clusters delete [your-cluster-name] --zone=[your zone] --quiet
```

3. Verify Clean Tear Down
Run these brief diagnostic checks to confirm no trailing resources remain on your GCP dashboard:

```bash
# Ensure no orphaned worker node VMs are still up
gcloud compute instances list

# Ensure no clusters are running
gcloud container clusters list

# Ensure no persistent load balancer endpoints are still charging hourly rates
gcloud compute forwarding-rules list
```
