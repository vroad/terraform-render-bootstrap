# Self-hosted Kubernetes bootstrap-manifests
resource "template_dir" "bootstrap-manifests" {
  source_dir      = "${path.module}/resources/bootstrap-manifests"
  destination_dir = "${var.asset_dir}/bootstrap-manifests"

  vars = {
    hyperkube_image   = var.container_images["hyperkube"]
    etcd_servers      = join(",", formatlist("https://%s:2379", var.etcd_servers))
    cloud_provider    = var.cloud_provider
    pod_cidr          = var.pod_cidr
    service_cidr      = var.service_cidr
    trusted_certs_dir = var.trusted_certs_dir
    apiserver_port    = var.apiserver_port
  }
}

# Self-hosted Kubernetes manifests
resource "template_dir" "manifests" {
  source_dir      = "${path.module}/resources/manifests"
  destination_dir = "${var.asset_dir}/manifests"

  vars = {
    hyperkube_image        = var.container_images["hyperkube"]
    pod_checkpointer_image = var.container_images["pod_checkpointer"]
    coredns_image          = var.container_images["coredns"]
    etcd_servers           = join(",", formatlist("https://%s:2379", var.etcd_servers))
    control_plane_replicas = max(2, length(var.etcd_servers))
    cloud_provider         = var.cloud_provider
    pod_cidr               = var.pod_cidr
    service_cidr           = var.service_cidr
    cluster_domain_suffix  = var.cluster_domain_suffix
    cluster_dns_service_ip = cidrhost(var.service_cidr, 10)
    trusted_certs_dir      = var.trusted_certs_dir
    apiserver_port         = var.apiserver_port
    ca_cert                = base64encode(tls_self_signed_cert.kube-ca.cert_pem)
    ca_key                 = base64encode(tls_private_key.kube-ca.private_key_pem)
    server                 = format("https://%s:%s", element(var.api_servers, 0), var.apiserver_port)
    apiserver_key          = base64encode(tls_private_key.apiserver.private_key_pem)
    apiserver_cert         = base64encode(tls_locally_signed_cert.apiserver.cert_pem)
    serviceaccount_pub     = base64encode(tls_private_key.service-account.public_key_pem)
    serviceaccount_key     = base64encode(tls_private_key.service-account.private_key_pem)
    etcd_ca_cert           = base64encode(tls_self_signed_cert.etcd-ca.cert_pem)
    etcd_client_cert       = base64encode(tls_locally_signed_cert.client.cert_pem)
    etcd_client_key        = base64encode(tls_private_key.client.private_key_pem)
    aggregation_flags      = var.enable_aggregation == "true" ? indent(8, local.aggregation_flags) : ""
    aggregation_ca_cert    = var.enable_aggregation == "true" ? base64encode(join(" ", tls_self_signed_cert.aggregation-ca.*.cert_pem)) : ""
    aggregation_client_cert = var.enable_aggregation == "true" ? base64encode(
      join(" ", tls_locally_signed_cert.aggregation-client.*.cert_pem),
    ) : ""
    aggregation_client_key = var.enable_aggregation == "true" ? base64encode(
      join(" ", tls_private_key.aggregation-client.*.private_key_pem),
    ) : ""
  }
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
resource "local_file" "kubeconfig-kubelet" {
  content = data.template_file.kubeconfig-kubelet.rendered
  filename = "${var.asset_dir}/auth/kubeconfig-kubelet"
}

# Generated admin kubeconfig (bootkube requires it be at auth/kubeconfig)
# https://github.com/kubernetes-incubator/bootkube/blob/master/pkg/bootkube/bootkube.go#L42
resource "local_file" "kubeconfig-admin" {
  content = data.template_file.kubeconfig-admin.rendered
  filename = "${var.asset_dir}/auth/kubeconfig"
}

# Generated admin kubeconfig in a file named after the cluster
resource "local_file" "kubeconfig-admin-named" {
  content = data.template_file.kubeconfig-admin.rendered
  filename = "${var.asset_dir}/auth/${var.cluster_name}-config"
}

data "template_file" "kubeconfig-kubelet" {
  template = file("${path.module}/resources/kubeconfig-kubelet")

  vars = {
    ca_cert = base64encode(tls_self_signed_cert.kube-ca.cert_pem)
    kubelet_cert = base64encode(tls_locally_signed_cert.kubelet.cert_pem)
    kubelet_key = base64encode(tls_private_key.kubelet.private_key_pem)
    server = format(
      "https://%s:%s",
      element(var.api_servers, 0),
      var.apiserver_port,
    )
  }
}

data "template_file" "kubeconfig-admin" {
  template = file("${path.module}/resources/kubeconfig-admin")

  vars = {
    name = var.cluster_name
    ca_cert = base64encode(tls_self_signed_cert.kube-ca.cert_pem)
    kubelet_cert = base64encode(tls_locally_signed_cert.admin.cert_pem)
    kubelet_key = base64encode(tls_private_key.admin.private_key_pem)
    server = format(
      "https://%s:%s",
      element(var.api_servers, 0),
      var.apiserver_port,
    )
  }
}

