Buliding a full stack Devops pipeline demonstrating containerization, IAC, CI/CD automtaion

**Technologies Used:**
- Docker (Containerization)
- Kubernetes (Container Orchestration)
- Jenkins (CI/CD)
- Terraform (Infrastructure as Code)
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

**Step 2:** Install Minikube
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

3. Add DockerHub credentials in Jenkins in that credentials section
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
adding that in the pipeline so suggested to use minikube 
