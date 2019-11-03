resource "aws_s3_bucket_object" "static-manifests" {
  for_each = fileset("${path.module}/resources/static-manifests", "**/*.yaml")

  bucket = aws_s3_bucket.assets.id
  key    = "/static-manifests/${each.value}"
  content = templatefile("${path.module}/resources/static-manifests/${each.value}", {
    hyperkube_image   = var.container_images["hyperkube"]
    etcd_servers      = join(",", formatlist("https://%s:2379", var.etcd_servers))
    cloud_provider    = var.cloud_provider
    pod_cidr          = var.pod_cidr
    service_cidr      = var.service_cidr
    trusted_certs_dir = var.trusted_certs_dir
    aggregation_flags = var.enable_aggregation ? indent(4, local.aggregation_flags) : ""
  })
}

# Kubernetes control plane manifests
resource "aws_s3_bucket_object" "manifests" {
  for_each = fileset("${path.module}/resources/manifests", "**/*.yaml")

  bucket = aws_s3_bucket.assets.id
  key    = "/manifests/${each.value}"
  content = templatefile("${path.module}/resources/manifests/${each.value}", {
    hyperkube_image        = var.container_images["hyperkube"]
    coredns_image          = var.container_images["coredns"]
    control_plane_replicas = max(2, length(var.etcd_servers))
    pod_cidr               = var.pod_cidr
    cluster_domain_suffix  = var.cluster_domain_suffix
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    trusted_certs_dir      = var.trusted_certs_dir
    server                 = format("https://%s:%s", var.api_servers[0], var.external_apiserver_port)
  })
}

locals {
  aggregation_flags = <<EOF

- --proxy-client-cert-file=/etc/kubernetes/secrets/aggregation-client.crt
- --proxy-client-key-file=/etc/kubernetes/secrets/aggregation-client.key
- --requestheader-client-ca-file=/etc/kubernetes/secrets/aggregation-ca.crt
- --requestheader-extra-headers-prefix=X-Remote-Extra-
- --requestheader-group-headers=X-Remote-Group
- --requestheader-username-headers=X-Remote-User
EOF
}

# Generated kubeconfig for Kubelets
resource "aws_s3_bucket_object" "kubeconfig-kubelet" {
  bucket  = aws_s3_bucket.assets.id
  content = data.template_file.kubeconfig-kubelet.rendered
  key     = "/auth/kubeconfig-kubelet"
}

# Generated admin kubeconfig to bootstrap control plane
resource "aws_s3_bucket_object" "kubeconfig-admin" {
  bucket  = aws_s3_bucket.assets.id
  content = data.template_file.kubeconfig-admin.rendered
  key     = "/auth/kubeconfig"
}

# Generated admin kubeconfig in a file named after the cluster
resource "aws_s3_bucket_object" "kubeconfig-admin-named" {
  bucket  = aws_s3_bucket.assets.id
  content = data.template_file.kubeconfig-admin.rendered
  key     = "/auth/${var.cluster_name}-config"
}

data "template_file" "kubeconfig-kubelet" {
  template = file("${path.module}/resources/kubeconfig-kubelet")

  vars = {
    ca_cert      = base64encode(tls_self_signed_cert.kube-ca.cert_pem)
    kubelet_cert = base64encode(tls_locally_signed_cert.kubelet.cert_pem)
    kubelet_key  = base64encode(tls_private_key.kubelet.private_key_pem)
    server       = format("https://%s:%s", var.api_servers[0], var.external_apiserver_port)
  }
}

data "template_file" "kubeconfig-admin" {
  template = file("${path.module}/resources/kubeconfig-admin")

  vars = {
    name         = var.cluster_name
    ca_cert      = base64encode(tls_self_signed_cert.kube-ca.cert_pem)
    kubelet_cert = base64encode(tls_locally_signed_cert.admin.cert_pem)
    kubelet_key  = base64encode(tls_private_key.admin.private_key_pem)
    server       = format("https://%s:%s", var.api_servers[0], var.external_apiserver_port)
  }
}

