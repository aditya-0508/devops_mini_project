# DevOps Mini Project: Jenkins + Docker + KIND + Kubernetes

A beginner-friendly CI/CD project that builds a Node.js application, pushes a Docker image to Docker Hub, and deploys it to a local Kubernetes cluster using Jenkins.

## 1. What this project does

When you run the Jenkins pipeline, it:

1. Checks out this GitHub repository.
2. Builds a Docker image for the application.
3. Tags the image with the Jenkins build number and `latest`.
4. Logs in to Docker Hub and pushes both tags.
5. Loads the image into the local KIND cluster.
6. Applies the Kubernetes Deployment and Service manifests.
7. Updates the Deployment to the current build's image.
8. Waits for the rollout and prints deployment details.

**Important:** This guide describes the working local setup used for this project: Windows + WSL Ubuntu, Docker Desktop, Jenkins running in a Docker container, and KIND running through the same Docker engine. It is a learning/lab setup, not a production-hardened Jenkins installation.

## 2. Architecture at a glance

```text
GitHub (master)
     |
     v
Jenkins Pipeline
     |
     +--> Build Docker image
     +--> Push image to Docker Hub
     +--> Load image into KIND
     +--> kubectl apply / set image
                     |
                     v
             KIND Kubernetes cluster
               Deployment + Service
```

## 3. Prerequisites

Install and verify the following:

- Windows with WSL 2 and an Ubuntu distribution
- Docker Desktop, configured to use the WSL 2 backend and Linux containers
- Git in Ubuntu
- `kubectl` in Ubuntu
- KIND in Ubuntu
- A Docker Hub account
- A GitHub account/repository

In Ubuntu, check:

```bash
git --version
docker version
kubectl version --client
kind version
```

Docker Desktop must be running before using Docker or KIND. If `docker version` shows a client but cannot connect to the daemon, start Docker Desktop and check its WSL integration settings.

## 4. Clone the repository

Run these commands in **Ubuntu/WSL**, not inside the Jenkins container:

```bash
git clone https://github.com/aditya-0508/devops_mini_project.git
cd devops_mini_project
```

Check the repository files:

```bash
ls
```

The project should include the application source, `Dockerfile`, `Jenkinsfile`, and the `kubernetes/` manifests.

## 5. Start or verify the KIND cluster

Check whether the cluster already exists:

```bash
kind get clusters
kubectl config current-context
kubectl get nodes
```

The expected cluster name is `devops-cluster` and the context is normally `kind-devops-cluster`.

If the cluster already exists and its node is `Ready`, **do not create another cluster**. If you are setting up from scratch and no cluster exists, create it once:

```bash
kind create cluster --name devops-cluster
kubectl get nodes
```

If `kubectl` is using the wrong context, select the KIND context:

```bash
kubectl config use-context kind-devops-cluster
```

## 6. Build and test the application locally (recommended)

From the repository root:

```bash
docker build -t adi070903/devops-mini-app:local .
docker run --rm -p 3000:3000 adi070903/devops-mini-app:local
```

Open `http://localhost:3000` in a browser. If the app exposes a health endpoint, test `http://localhost:3000/health` too. Stop the container with `Ctrl+C`.

If port `3000` is already in use, stop the process using it or change the host-side port, for example `-p 3001:3000`.

## 7. Configure Jenkins

### 7.1 Start Jenkins

This project uses a Jenkins container named `jenkins`, exposing port `8080`. If Jenkins is already running, do not create a second container.

```bash
docker ps
```

Open Jenkins at:

<http://localhost:8080>

Useful commands:

```bash
docker logs jenkins
docker exec -it jenkins bash
```

The Jenkins home directory must be persisted. In the existing setup it is mounted at `/var/jenkins_home`; avoid deleting that directory or volume because it contains Jenkins jobs and credentials.

### 7.2 Required tools inside Jenkins

The Jenkins container needs all three command-line tools used by the pipeline:

```bash
docker exec jenkins docker version
docker exec jenkins kubectl version --client
docker exec jenkins kind version
```

If a command returns `not found`, that tool is missing **inside the Jenkins container**. Having it installed only in Ubuntu does not make it available to Jenkins.

The current lab setup has Docker CLI, `kubectl`, and KIND installed in the Jenkins container, and Docker access is provided through the mounted Docker socket. Installing tools manually into a running container may be lost if the container is replaced. For a repeatable setup, create a custom Jenkins image that installs the required tools and run Jenkins from that image.

> **Docker socket note:** Mounting `/var/run/docker.sock` gives Jenkins broad control over the Docker daemon. Use this only in a trusted local lab environment.

### 7.3 Configure Docker Hub credentials

In Jenkins:

1. Go to **Manage Jenkins → Credentials**.
2. Add a credential of type **Username with password**.
3. Set the ID to exactly `dockerhub-creds`.
4. Enter your Docker Hub username and a Docker Hub access token/password.
5. Save it.

The Jenkinsfile references this ID. Do not put credentials directly in the Jenkinsfile or commit them to GitHub.

### 7.4 Create the pipeline job

1. On the Jenkins dashboard, select **New Item**.
2. Name it `devops-pipeline`.
3. Choose **Pipeline** and create the job.
4. Under **Pipeline**, select **Pipeline script from SCM**.
5. SCM: **Git**.
6. Repository URL: `https://github.com/aditya-0508/devops_mini_project.git`
7. Branch specifier: `*/master` (use the branch that actually contains your Jenkinsfile).
8. Script Path: `Jenkinsfile`.
9. Save, then select **Build Now**.

If your repository's default branch is not `master`, update the branch in the job/Jenkinsfile to match it.

## 8. KIND access from inside Jenkins — important networking fix

KIND runs in Docker, while `kubectl` is running inside the Jenkins container. The Kubernetes API address in the WSL kubeconfig may use `https://127.0.0.1:<port>`. Inside Jenkins, `127.0.0.1` means the Jenkins container itself, **not Ubuntu or the KIND control-plane container**.

For this lab, Jenkins reaches the host-published KIND API through `host.docker.internal`. The working setup used port `46061`. That port can differ if the cluster is recreated, so check the actual API address before copying the example.

From Ubuntu, inspect the current cluster API server:

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'; echo
```

If the output is `https://127.0.0.1:<PORT>`, use that same port below in place of `<PORT>`. In the Jenkins container, configure the cluster endpoint:

```bash
docker exec jenkins kubectl config set-cluster kind-devops-cluster \
  --server=https://host.docker.internal:<PORT> \
  --tls-server-name=127.0.0.1
```

Then verify from Jenkins:

```bash
docker exec jenkins kubectl get nodes
```

For the previously working environment, `<PORT>` was `46061`. Do not use that value blindly after recreating the cluster.

If `host.docker.internal` cannot be resolved or the API cannot be reached, confirm Docker Desktop is running and that the KIND API port is published to the host. Do not delete/recreate the cluster as the first troubleshooting step.

## 9. Kubernetes image settings

The Deployment manifest should use an image name consistent with the project, for example:

```yaml
image: adi070903/devops-mini-app:latest
imagePullPolicy: IfNotPresent
```

The Jenkins pipeline then sets the Deployment image to the unique build tag, such as `adi070903/devops-mini-app:12`.

Avoid `imagePullPolicy: Never` unless you deliberately manage the exact image locally on every Kubernetes node. This setting caused `ErrImageNeverPull` when the requested image was not present in KIND under the exact name/tag. `IfNotPresent` works with the pipeline's `kind load docker-image` stage.

Confirm the manifest's Deployment name and container name match the Jenkinsfile. This project uses:

- Deployment: `devops-deployment`
- Container: `devops-app`

## 10. Run and verify the pipeline

In Jenkins, open `devops-pipeline` and select **Build Now**. Open the build number, then **Console Output**.

A successful run should show these stages completing:

- Checkout Code
- Build Docker Image
- Login to DockerHub
- Push to DockerHub
- Validate KIND and Kubernetes
- Load Image to KIND
- Deploy to Kubernetes
- Verify Deployment

Verify from Ubuntu:

```bash
kubectl get nodes
kubectl get deployments
kubectl get pods -o wide
kubectl get services
kubectl rollout status deployment/devops-deployment
```

For more detail:

```bash
kubectl describe deployment devops-deployment
kubectl describe pods
kubectl get events --sort-by=.metadata.creationTimestamp
```

To check application logs:

```bash
kubectl logs deployment/devops-deployment
```

If the Service is `ClusterIP`, it is not directly exposed outside the cluster by default. Use the Service configuration in `kubernetes/service.yaml` to determine how to access it; for a simple local test, you can use port-forwarding if the service port is correct:

```bash
kubectl port-forward service/<service-name> 3000:<service-port>
```

Then open `http://localhost:3000`.

## 11. Troubleshooting: errors encountered in this project

| Error / symptom | Likely reason | What to do |
|---|---|---|
| `docker: command not found` in Jenkins | Docker CLI is installed on Ubuntu, not in Jenkins | Install Docker CLI in the Jenkins image/container; verify with `docker exec jenkins docker version`. |
| `Cannot connect to the Docker daemon` | Docker Desktop is stopped, or Jenkins cannot access the Docker socket/daemon | Start Docker Desktop; verify the socket mount and run `docker exec jenkins docker version`. |
| `kind: not found` / exit code `127` | KIND is missing inside Jenkins | Install KIND inside Jenkins or, preferably, build a custom Jenkins image with KIND included. Then run `docker exec jenkins kind version`. |
| `kubectl` cannot connect to `127.0.0.1:<port>` from Jenkins | `127.0.0.1` points to the Jenkins container, not the host/KIND API | Configure Jenkins kubeconfig to use `https://host.docker.internal:<PORT>` and retain the appropriate TLS server name. |
| `Unable to connect to the server` / timeout | Wrong API port, KIND API not published, or Docker Desktop/network issue | Check the current server port in Ubuntu with `kubectl config view --minify`; confirm host access and test from Jenkins. |
| `ErrImageNeverPull` | Manifest uses `imagePullPolicy: Never`, but the exact image/tag is absent from KIND | Use `IfNotPresent` and ensure `kind load docker-image` loads the same full image tag that Kubernetes deploys. |
| `ImagePullBackOff` | Image name/tag is wrong, image isn't public/accessible, or image was not loaded/pushed | Check `kubectl describe pod`; confirm Docker Hub push succeeded and the deployed image matches the tag. |
| `unauthorized: authentication required` during push | Docker Hub credentials are wrong or expired | Check `dockerhub-creds` in Jenkins; use the correct Docker Hub username and access token. Never echo the token in logs. |
| Jenkins says credentials ID `dockerhub-creds` is missing | Credential ID does not exactly match the Jenkinsfile | Create/update the Username with password credential with ID `dockerhub-creds`. |
| `Deployment ... not found` or `container ... not found` | Manifest resource/container names differ from the Jenkinsfile | Check `metadata.name` and `containers[].name` in `kubernetes/deployment.yaml`, then make the Jenkinsfile names match. |
| Pods remain `Pending`, `CrashLoopBackOff`, or `NotReady` | Scheduling, app startup, port, probe, or resource issue | Run `kubectl describe pod <pod-name>` and `kubectl logs <pod-name>`; verify the app listens on the configured port and `/health` returns success. |
| Rollout times out | New pods are not becoming Ready | Inspect pod status, events, logs, and readiness/liveness probes before rerunning. |
| Jenkins build checks the wrong branch or cannot find `Jenkinsfile` | SCM branch or Script Path is incorrect | Ensure the Jenkins job and Jenkinsfile use the same branch and `Jenkinsfile` path. |
| `port is already allocated` | Another process/container is using the host port | Check `docker ps` and the process using the port; stop the conflicting service or choose a free host port. |

### Quick diagnostic commands

Run these from Ubuntu:

```bash
docker ps
kind get clusters
kubectl config current-context
kubectl get nodes
kubectl get pods
kubectl get events --sort-by=.metadata.creationTimestamp
```

Run these from Ubuntu to test the Jenkins container's tools and Kubernetes access:

```bash
docker exec jenkins docker version
docker exec jenkins kind version
docker exec jenkins kubectl get nodes
```

When a build fails, start with the **first failed stage and its first real error** in Console Output. Later errors may only be consequences of the first failure.

## 12. Common workflow for future changes

After changing application code:

```bash
git status
git add .
git commit -m "Describe your change"
git push origin master
```

Then run **Build Now** in Jenkins. The pipeline should build a new image tag based on the Jenkins build number, push it, load it into KIND, and update the Deployment.

If you changed only the README, a Jenkins build is not necessary unless you want to test the SCM checkout.

## 13. Notes and limitations

- This setup is for local learning and demonstration.
- KIND is a local Kubernetes cluster, not a managed production cluster.
- The API port can change when KIND is recreated; refresh the Jenkins kubeconfig endpoint when necessary.
- Installing tools manually in a running Jenkins container is not reproducible. A custom Jenkins image is the recommended next improvement.
- The pipeline's Docker image cleanup should be reviewed before using it on a shared machine, because image pruning can remove unused images needed by other local workloads.
- Do not commit passwords, access tokens, kubeconfig files, or other secrets to GitHub.

## References

- [Project repository](https://github.com/aditya-0508/devops_mini_project)
- [Jenkins in Docker: official documentation](https://www.jenkins.io/doc/book/installing/docker/)
- [Official Jenkins Docker image](https://hub.docker.com/r/jenkins/jenkins)
- [GitHub README and repository documentation guidance](https://docs.github.com/en/repositories/creating-and-managing-repositories/quickstart-for-repositories)
