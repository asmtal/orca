# Orca exercise

This is a short summary on how to connect to infrastructure and check the results of work.
Results are uploaded to GitHub repository

## Connecting

1. Exporting AWS credentials as environment variables.
- AWS credentials were given as a part of exercise.
- Region was taken according to the closest geographical position (Frankfurt).
```
export AWS_ACCESS_KEY_ID=paste_your_access_key
export AWS_SECRET_ACCESS_KEY=paste_your_secret_key
export AWS_DEFAULT_REGION=eu-central-1
```
2. Connecting to VPN.
- All internal resources were deployed in private subnets. You need to use VPN to access them.
- [AWS Client VPN](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html) was configured to access the resources.
- You can use VPN clients like [OpenVPN](https://openvpn.net/community-downloads/) or [Tunnelblick](https://tunnelblick.net/).
- VPN configuration file (**orca.ovpn**) is situated in archive (**certs.zip**) with other confidential files.

3. Temporary modifiying **/etc/hosts** file.
There is no separate domain for this project, that's why local modification of */etc/hosts* file was used.
All external resources are accessible via [NLB](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) with public endpoint (aee2ae41455eb4809ae6d15bc65a3ae9-d830fe0131adb23e.elb.eu-central-1.amazonaws.com) which resolves to 3 public IP-addresses (52.28.44.71, 3.122.160.121, 52.58.5.115). Please add one line to your /etc/hosts file to check the results of exercise. Your file may look like that:
```
...
3.122.160.121 app.example.com jenkins.example.com argo.example.com grafana.example.com
...
```

4. Update kubeconfig file to connect to EKS cluster
```
aws eks --region eu-central-1 update-kubeconfig --name my-cluster```
```

## Repository contents

1. **/app**:
- application itself
- Dockerfile for packaging
- docker-compose file for local testing
- Jenkinsfile for CI/CD process

2. **/k8s**:
|- *app-manifests* - k8s resources to deploy the application, ingress manifests
|- *argocd* - k8s resources to deploy [ArgoCD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
|- *ingress-controller* - k8s resources to deploy [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/#aws)
|- *jenkins-k8s* - k8s resources to deploy [Jenkins](https://www.jenkins.io/doc/book/installing/kubernetes/#install-jenkins-with-helm-v3)
|- *monitoring* - Git submodule to deploy [Kube-Prometheus](https://github.com/prometheus-operator/kube-prometheus)

3. **/terraform**:
- IaC to deploy the components

## Architecture and component details

**VPC**
- [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) contains 6 subnets (3 public and 3 private)
- subnets are distributed between 3 [Availability Zones](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)
- every private subnet uses separate [NAT gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) for high availability
- more details can be obtained in terraform module configuration or AWS Console

**EKS**
- [EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) cluster consists of EKS managed [Node Group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html) with configured [autoscaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)
- k8s worker nodes are distributed between 3 Availability Zones
- cluster uses private endpoint
- more details can be obtained in terraform module configuration or AWS Console

**RDS**
- [RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html) uses PostgreSQL database engine
- RDS uses private endpoint
- more details can be obtained in terraform module configuration or AWS Console
- credential are situated in **creds.txt** file

**App**
- after modifying */etc/hosts* file application can accessed using the following URL: http://app.example.com/

**Building image**
- image is automatically built and pushed to [ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html) using Jenkins pipeline
- Jenkins can be accessed with the following URL: http://jenkins.example.com/job/orca/job/main/
- Jenkins builds */app* directory
- credential are situated in **creds.txt** file
- no webhook configured for pipeline, please start build manually

**Deploying app**
- application is automatically deployed using ArgoCD
- ArgoCD can be accessed using the following URL: https://argo.example.com/
- ArgoCD uses GitOps approach and performs sync of */k8s/app-manifests* directory with actual application state
- credential are situated in **creds.txt** file
- no webhook configured for pipeline, please start sync manually

**Monitoring**
- Kube-Prometheus includes Prometheus, Grafana (with a bunch of predefined dashboards) and other components for k8s observability
- Grafana can be accessed using the following URL: http://grafana.example.com/dashboards
- credential are situated in **creds.txt** file

## Summary
Application is deployed in HA mode. It is automatically scalable, redundant, embraces GitOps approach and automatic building/deployment processes.

## What else can be improved
- add tests for CI/CD process
- add webhooks for automatic triggering of build and deploy processes
- configure DNS (buy domain) for more meaningful URLs
- add [Cert Manager](https://cert-manager.io/docs/) to improve security
- perform load tests using [Locust](http://docs.locust.io/en/stable/)
