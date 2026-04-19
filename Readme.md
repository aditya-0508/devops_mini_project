Buliding a full stack Devops pipeline demonstrating containerization, CI/CD automtaion

**Technologies Used:**
- Docker (Containerization)
- Kubernetes (Container Orchestration)
- Jenkins (CI/CD)
- Git/GitHub (Version Control)

## Phase 1 --> Installation and Prerequisties
- Open Powershell as Administrator and run
wsl --install
You might have to restart your computer
- Install Ubuntu from Microsoft Store
- Complete all the launch setting using the username and password

### 1.2 Install Docker Desktop

**Step 1:** Download Docker Desktop
- Visit: https://www.docker.com/products/docker-desktop
- Download Docker Desktop for Windows

**Step 2:** Install Docker Desktop
- Run the installer
- Enable WSL2 integration during setup
- Restart computer if prompted

**Step 3:** Configure Docker
- Open Docker Desktop
- Go to Settings → Resources → WSL Integration
- Enable integration with Ubuntu
- Click "Apply & Restart"

**Step 4:** Verify Installation
# Open Ubuntu terminal
```bash
# Open Ubuntu terminal
docker --version
docker run hello-world
```
---

### 1.3 Install Kubernetes (Minikube)

**Step 1:** Install kubectl in Ubuntu
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

**Step 2:** Install Minikube(For local installation only)
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Step 3:** Start Minikube
```bash
minikube start
minikube status
```

---

### 1.4 Install Jenkins

**Option A: Jenkins in Docker (Recommended for learning)**

**Step 1:** Create Jenkins directory
```bash
mkdir -p ~/jenkins_home
```

**Step 2:** Run Jenkins container
```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v ~/jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

**Step 3:** Get initial admin password
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Step 4:** Access Jenkins
- Open browser: http://localhost:8080
- Enter the password from Step 3
- Install suggested plugins
- Create admin user

**Option B: Jenkins on Windows Native**

Download from: https://www.jenkins.io/download/ and follow installer

---

### 1.5 Install Terraform

**Step 1:** In Ubuntu terminal, download Terraform
```bash
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
```

**Step 2:** Install unzip and extract
```bash
sudo apt update
sudo apt install unzip -y
unzip terraform_1.7.0_linux_amd64.zip
```

**Step 3:** Move to bin directory
```bash
sudo mv terraform /usr/local/bin/
terraform --version
```

---

### 1.6 Install Git

```bash
# In Ubuntu
sudo apt update
sudo apt install git -y
git --version

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## Phase 2: Mini Project

### 2.1 Create the Application

**Step 1:** Create project directory
```bash
mkdir -p ~/devops-mini-project/app
cd ~/devops-mini-project/app

**Build and Test:**
```bash
# Build the image
docker build -t devops-mini-app:v1 .

# Run the container
docker run -d -p 3000:3000 --name demo-app devops-mini-app:v1

# TO debug in case of any failure
docker exec -it demo-app sh
ls

# Test the application
curl http://localhost:5000

# Check logs
docker logs demo-app

# Stop and remove
docker stop demo-app
docker rm demo-app


#I have used this in my project 
# Or use docker-compose
docker-compose up -d
docker-compose ps

# If you want to access from my personal laptop it is :5000 otherwise from :3000 as app is running at 3000
# dockerfile exposing at 5000, app running at 3000 so docker-compose created accordingly
curl http://localhost:5000
docker-compose down
```

---

### 2.3 Kubernetes Deployment

**Create kubernetes directory:**
```bash
mkdir -p ~/devops-mini-project/kubernetes
cd ~/devops-mini-project/kubernetes
```

**Deploy to Kubernetes:**
```bash
# Make sure Minikube is running
minikube status

# Load Docker image into Minikube
minikube image load devops-mini-app:v1

# Apply Kubernetes manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Check deployment
kubectl get deployments
kubectl get pods
kubectl get services

# Access the application
minikube service devops-service --url
# will give you an url put in browser and check

Browser → NodePort (30007)
        → Service
        → Pod (container)
        → App (port 3000)
Go through the logic of imagePullPolicy
```
**Jenkins Pipeline**
```
## Jenkins Setup

1. Run Jenkins using Docker:

docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

Also make sure(if docker doesn't work in jenkins container)
docker exec -u 0 -it jenkins bash
groupadd docker
usermod -aG docker jenkins
chmod 666 /var/run/docker.sock
exit
docker restart jenkins

2. Install plugins:
- Docker Pipeline
- Git
- Pipeline

3. Add DockerHub credentials in Jenkins in that credentials section, make sure the name in pipeline for id and in the 
credentials are the same
```
** Adding Git Webhooks to Jenkins**
```
We will be using ngrok
ngrok is a globally managed reverse proxy and secure tunneling tool that exposes local development servers (e.g., localhost:3000) to the public internet via a unique URL. It is heavily used by developers to instantly share local projects, test webhooks (like Stripe or Slack), and access local devices remotely without complex firewall or NAT configuration.
# Installing ngrok
sudo apt install unzip -y
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
unzip ngrok-v3-stable-linux-amd64.zip
sudo mv ngrok /usr/local/bin
Authenticate ngrok
Go to ngrok website → signup
Copy auth token
ngrok config add-authtoken <your_token>
ngrok http 8080
You will be getting a url use that in the webhook(payload url) and application/json while creating in the same repo
Create Pipeline job and connect to GitHub repo
```

Jenkins runs inside Docker and Minikube is a local so it runs on WSL, so we faced a lot of issues with respect to 
adding that in the pipeline so suggested to use kind 

**Kind Deployment for Pipeline**
```
# In your WSL Ubuntu terminal

# Download KIND
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# Make it executable
chmod +x ./kind

# Move to PATH
sudo mv ./kind /usr/local/bin/kind

# Verify installation
kind version

# Create a simple cluster
kind create cluster --name devops-cluster

# Or create with custom config (recommended)
cat > kind-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: devops-cluster
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30007
    hostPort: 30007
    protocol: TCP
EOF

# Create cluster with config
kind create cluster --config kind-config.yaml

# Verify cluster is running
kubectl cluster-info --context kind-devops-cluster
kubectl get nodes

# 1. Jenkins already has Docker access, so it can talk to KIND automatically!

# 2. Just copy kubectl (if not already done)
docker exec jenkins which kubectl || docker cp $(which kubectl) jenkins:/usr/local/bin/kubectl
docker exec jenkins chmod +x /usr/local/bin/kubectl

# 3. Copy the KIND kubeconfig
docker exec jenkins mkdir -p /var/jenkins_home/.kube
docker cp ~/.kube/config jenkins:/var/jenkins_home/.kube/config
docker exec jenkins chown -R jenkins:jenkins /var/jenkins_home/.kube

# 4. Test it - THIS SHOULD WORK NOW!
docker exec jenkins kubectl get nodes


# If you are facing issues
# First, let's check if Jenkins is on the kind network
docker network inspect kind | grep jenkins

# If you don't see jenkins listed, connect it:
docker network connect kind jenkins

# Verify Jenkins is now on the kind network:
docker network inspect kind | grep jenkins
# Step 1: Check if certificates can be extracted
echo "Testing certificate extraction..."
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | head -c 50
echo ""
echo "If you see base64 data above, certificates are OK"

# Step 2: Get the KIND cluster details
echo ""
echo "KIND cluster info:"
kubectl cluster-info --context kind-devops-cluster

# Step 3: Check KIND container name
echo ""
echo "KIND container:"
docker ps | grep devops-cluster

# Step 4: Create kubeconfig manually (verbose version)
echo ""
echo "Creating kubeconfig..."

CA_DATA=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
CLIENT_CERT=$(kubectl config view --raw --minify -o jsonpath='{.users[0].user.client-certificate-data}')
CLIENT_KEY=$(kubectl config view --raw --minify -o jsonpath='{.users[0].user.client-key-data}')

echo "CA_DATA length: ${#CA_DATA}"
echo "CLIENT_CERT length: ${#CLIENT_CERT}"
echo "CLIENT_KEY length: ${#CLIENT_KEY}"

# If all three have data (should be > 100 characters each), continue:
cat > /tmp/jenkins-kubeconfig << EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${CA_DATA}
    server: https://devops-cluster-control-plane:6443
  name: kind-devops-cluster
contexts:
- context:
    cluster: kind-devops-cluster
    user: kind-devops-cluster
  name: kind-devops-cluster
current-context: kind-devops-cluster
kind: Config
preferences: {}
users:
- name: kind-devops-cluster
  user:
    client-certificate-data: ${CLIENT_CERT}
    client-key-data: ${CLIENT_KEY}
EOF

echo "Kubeconfig created at /tmp/jenkins-kubeconfig"
ls -lh /tmp/jenkins-kubeconfig

# Step 5: Copy to Jenkins
echo ""
echo "Copying to Jenkins..."
docker cp /tmp/jenkins-kubeconfig jenkins:/var/jenkins_home/.kube/config

echo "Setting permissions..."
docker exec jenkins chown jenkins:jenkins /var/jenkins_home/.kube/config

# Step 6: Test
echo ""
echo "Testing kubectl in Jenkins:"
docker exec jenkins kubectl get nodes

echo ""
echo "If you see nodes above, SUCCESS! ✅"
```

** ArgoCD **
```
Argo CD is a "GitOps" tool for Kubernetes that acts like a bridge between your code and your live servers. In simple terms, it ensures that whatever is written in your Git repository (like GitHub or GitLab) is exactly what is running in your cluster.
Whenever any change is made in git repo Argocd verifies the state of the cluster with the git state and updates it accordingly (Automatic Sync). And Git is the source of the truth. Visibility: It provides a web UI where you can visually see all your apps, their health, and how they are connected.

#With AgroCD implementation
GitHub → Jenkins (build image)
        ↓
     Update Git (image tag)
        ↓
     ArgoCD → Kubernetes
# Step 1: Create namespace
kubectl create namespace argocd
#Step 2 Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --server-side --force-conflicts
#Step 3
kubectl get pods -n argocd
#Step 4 Expose ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 9090:443
# Step 5 Get Password for the UI
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d

