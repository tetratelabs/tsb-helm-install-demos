# For All regular AWS Regions (Not for AWS GovCloud Regions)

## Follow the steps to install aws-load-balancer-controller on you plane EKS cluster via Helm

1. Create following env vars:
```
export AWS_ACC="<aws-account-number>"
export AWS_REGION="<eks-cluster-region>"
export MY_CLUSTER="<eks-cluster-name>"
```

2. Use `kubectx` to switch to the cluster you'd like to install LB controller

3. Run `./install-albc.sh` to install aws-load-balancer-controller on you cluster

## If you need to install LB controller on multiple clusters

1. Use same `kubectx` to switch to your next cluster

2. If you see errors like: 

    `An error occurred (EntityAlreadyExists) when calling the CreatePolicy operation: A policy called AWSLoadBalancerControllerIAMPolicy already exists. Duplicate names are not allowed`

    or 

    `An error occurred (EntityAlreadyExists) when calling the CreateRole operation: Role with name AmazonEKSLoadBalancerControllerRole already exists`

    This is normal - you already have the role and policy created in this AWS account
