locals {
  # Kubernetes static pod manifests
  static-manifests = { for filename in fileset("${path.module}/resources/static-manifests", "**/*.yaml") :
    "/static-manifests/${filename}" => templatefile("${path.module}/resources/static-manifests/${filename}", {
      hyperkube_image   = var.container_images["hyperkube"]
      etcd_servers      = join(",", formatlist("https://%s:2379", var.etcd_servers))
      cloud_provider    = var.cloud_provider
      pod_cidr          = var.pod_cidr
      service_cidr      = var.service_cidr
      trusted_certs_dir = var.trusted_certs_dir
      aggregation_flags = var.enable_aggregation ? indent(4, local.aggregation_flags) : ""
    })
  }
  static-manifest-contents          = [for filename, content in local.static-manifests : content]
  combined-static-manifest-contents = [for filename, content in local.static-manifests : "${filename}${content}"]
  static-manifests-hash             = sha1(join("", local.combined-static-manifest-contents))

  # Kubernetes control plane manifests
  manifests = { for filename in fileset("${path.module}/resources/manifests", "**/*.yaml") :
    "/manifests/${filename}" => templatefile("${path.module}/resources/manifests/${filename}", {
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
  manifest-contents          = [for filename, content in local.manifests : content]
  combined-manifest-contents = [for filename, content in local.manifests : "${filename}${content}"]
  manifests-hash             = sha1(join("", local.combined-manifest-contents))

  aggregation_flags = <<EOF

- --proxy-client-cert-file=/etc/kubernetes/secrets/aggregation-client.crt
- --proxy-client-key-file=/etc/kubernetes/secrets/aggregation-client.key
- --requestheader-client-ca-file=/etc/kubernetes/secrets/aggregation-ca.crt
- --requestheader-extra-headers-prefix=X-Remote-Extra-
- --requestheader-group-headers=X-Remote-Group
- --requestheader-username-headers=X-Remote-User
EOF

  kubeconfig-kubelet-content = templatefile("${path.module}/resources/kubeconfig-kubelet", {
    ca_cert      = base64encode(tls_self_signed_cert.kube-ca.cert_pem)
    kubelet_cert = base64encode(tls_locally_signed_cert.kubelet.cert_pem)
    kubelet_key  = base64encode(tls_private_key.kubelet.private_key_pem)
    server       = format("https://%s:%s", var.api_servers[0], var.external_apiserver_port)
  })
  kubeconfig-admin-content = templatefile("${path.module}/resources/kubeconfig-admin", {
    name         = var.cluster_name
    ca_cert      = base64encode(tls_self_signed_cert.kube-ca.cert_pem)
    kubelet_cert = base64encode(tls_locally_signed_cert.admin.cert_pem)
    kubelet_key  = base64encode(tls_private_key.admin.private_key_pem)
    server       = format("https://%s:%s", var.api_servers[0], var.external_apiserver_port)
  })
  # Generated kubeconfig for Kubelets
  kubeconfig-kubelet = { "/auth/kubeconfig-kubelet" : local.kubeconfig-kubelet-content }
  # Generated admin kubeconfig to bootstrap control plane
  kubeconfig-admin = { "/auth/kubeconfig" : local.kubeconfig-admin-content }
  # Generated admin kubeconfig in a file named after the cluster
  kubeconfig-admin-named = { "/auth/${var.cluster_name}-config" : local.kubeconfig-admin-content }
}

