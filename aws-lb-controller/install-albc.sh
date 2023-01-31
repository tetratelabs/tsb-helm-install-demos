curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

oidc_id=$(aws eks describe-cluster --name $MY_CLUSTER --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
echo $oidc_id

aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

cat >load-balancer-role-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${AWS_ACC}:oidc-provider/oidc.eks.${AWS_REGION}.amazonaws.com/id/${oidc_id}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.${AWS_REGION}.amazonaws.com/id/${oidc_id}:aud": "sts.amazonaws.com",
                    "oidc.eks.${AWS_REGION}.amazonaws.com/id/${oidc_id}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name AmazonEKSLoadBalancerControllerRole --assume-role-policy-document file://"load-balancer-role-trust-policy.json"

aws iam attach-role-policy --policy-arn arn:aws:iam::$AWS_ACC:policy/AWSLoadBalancerControllerIAMPolicy --role-name AmazonEKSLoadBalancerControllerRole

cat >aws-load-balancer-controller-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACC}:role/AmazonEKSLoadBalancerControllerRole
EOF

kubectl apply -f aws-load-balancer-controller-service-account.yaml

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=$MY_CLUSTER --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
echo "Pods provisioning - takes a few seconds"
sleep 7
kubectl get deployment -n kube-system aws-load-balancer-controller
