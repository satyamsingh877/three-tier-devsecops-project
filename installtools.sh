#!/bin/bash

# 1. EKS Cluster Deployment
echo "Creating EKS cluster..."
eksctl create cluster --name three-tier-k8s-eks-cluster --region us-west-2 --node-type t2.medium --nodes-min 2 --nodes-max 2

# 2. Validate nodes
echo "Validating nodes..."
kubectl get nodes

# 3. Download Load Balancer policy
echo "Downloading Load Balancer policy..."
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json

# 4. Create IAM policy
echo "Creating IAM policy..."
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# 5. Create OIDC Provider
echo "Creating OIDC Provider..."
eksctl utils associate-iam-oidc-provider --region=us-west-2 --cluster=three-tier-k8s-eks-cluster --approve

# 6. Create Service Account
echo "Please enter your AWS account ID:"
read ACCOUNT_ID
echo "Creating Service Account..."
eksctl create iamserviceaccount \
  --cluster=three-tier-k8s-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=us-west-2

# 7. Deploy AWS Load Balancer Controller
echo "Deploying AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=three-tier-k8s-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# 8. Check Load Balancer Controller deployment
echo "Waiting for Load Balancer Controller to deploy..."
sleep 180
kubectl get deployment -n kube-system aws-load-balancer-controller

# 9. Add Helm Stable Chart Repository
echo "Adding Helm Stable Chart Repository..."
helm repo add stable https://charts.helm.sh/stable

# 10. Add Prometheus Community Helm Repository
echo "Adding Prometheus Community Helm Repository..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# 11. Create monitoring namespace
echo "Creating monitoring namespace..."
kubectl create namespace monitoring

# 12. Install Prometheus with Grafana
echo "Installing Prometheus with Grafana..."
helm install stable prometheus-community/kube-prometheus-stack -n monitoring

# 13. Verify Prometheus Installation
echo "Verifying Prometheus installation..."
kubectl get pods -n monitoring

# 14. Check Prometheus services
echo "Checking Prometheus services..."
kubectl get svc -n monitoring

# 15. Expose Prometheus via LoadBalancer
echo "Exposing Prometheus via LoadBalancer..."
kubectl edit svc stable-kube-prometheus-sta-prometheus -n monitoring

# 16. Expose Grafana via LoadBalancer
echo "Exposing Grafana via LoadBalancer..."
kubectl edit svc stable-grafana -n monitoring

# 17. ArgoCD Installation Preparation
echo "Preparing for ArgoCD installation..."
kubectl create namespace three-tier
kubectl create secret generic ecr-registry-secret \
  --from-file=.dockerconfigjson=${HOME}/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson --namespace three-tier
kubectl get secrets -n three-tier

# 18. Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml

# 19. Validate ArgoCD pods
echo "Validating ArgoCD pods..."
kubectl get pods -n argocd

# 20. Expose ArgoCD server as LoadBalancer
echo "Exposing ArgoCD server as LoadBalancer..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# 21. Get ArgoCD credentials
echo "Installing jq for credential extraction..."
sudo apt update && sudo apt install jq -y

echo "Getting ArgoCD credentials..."
export ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq -r '.status.loadBalancer.ingress[0].hostname') 
export ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) 
echo "ARGOCD_SERVER: $ARGOCD_SERVER" 
echo "ARGO_PWD: $ARGO_PWD"

echo "Script completed!"
