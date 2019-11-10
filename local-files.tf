locals {
  assets = merge(local.static-manifests,
    local.manifests,
    local.kubeconfig-kubelet,
    local.kubeconfig-admin,
    local.kubeconfig-admin-named,
    local.flannel-manifests,
    local.calico-manifests,
    local.kube-router-manifests,
    local.aggregation-certs,
    local.etcd-certs,
  local.k8s-certs)
}

resource "local_file" "assets" {
  for_each = var.asset_dir != null ? local.assets : {}

  filename = "${var.asset_dir}/${each.key}"
  content  = "${each.value}"
}
