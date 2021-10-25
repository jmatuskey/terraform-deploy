# Create IAM role + automatically make it available to cluster autoscaler service account
module "iam_assumable_role_admin" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.2.0"
  depends_on = [null_resource.kubectl_config,  module.eks]

  create_role                   = false
  role_name                     = "${module.eks.cluster_id}-cluster-autoscaler"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler-service-account"]
}

resource "helm_release" "cluster-autoscaler" {
  name = "cluster-autoscaler"
  namespace = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart = "cluster-autoscaler"
  version = "9.10.3"
  depends_on = [null_resource.kubectl_config,  module.eks]

  values = [
    file("cluster-autoscaler-values.yml")
  ]

  set{
    name = "awsRegion"
    value = var.region
  }

  set{
    name = "autoDiscovery.clusterName"
    value = module.eks.cluster_id
  }
}
