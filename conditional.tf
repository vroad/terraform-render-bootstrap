# Assets generated only when certain options are chosen

resource "aws_s3_bucket_object" "flannel-manifests" {
  for_each = var.networking == "flannel" ? fileset("${path.module}/resources/flannel", "**/*.yaml") : []

  bucket = aws_s3_bucket.assets.id
  key    = "/manifests-networking/${each.value}"
  content = templatefile("${path.module}/resources/flannel/${each.value}", {
    flannel_image     = var.container_images["flannel"]
    flannel_cni_image = var.container_images["flannel_cni"]
    pod_cidr          = var.pod_cidr
  })
}

resource "aws_s3_bucket_object" "calico-manifests" {
  for_each = var.networking == "calico" ? fileset("${path.module}/resources/calico", "**/*.yaml") : []

  bucket = aws_s3_bucket.assets.id
  key    = "/manifests-networking/${each.value}"
  content = templatefile("${path.module}/resources/calico/${each.value}", {
    calico_image                    = var.container_images["calico"]
    calico_cni_image                = var.container_images["calico_cni"]
    network_mtu                     = var.network_mtu
    network_encapsulation           = indent(2, var.network_encapsulation == "vxlan" ? "vxlanMode: Always" : "ipipMode: Always")
    ipip_enabled                    = var.network_encapsulation == "ipip" ? true : false
    ipip_readiness                  = var.network_encapsulation == "ipip" ? indent(16, "- --bird-ready") : ""
    vxlan_enabled                   = var.network_encapsulation == "vxlan" ? true : false
    network_ip_autodetection_method = var.network_ip_autodetection_method
    pod_cidr                        = var.pod_cidr
    enable_reporting                = var.enable_reporting
  })
}

resource "aws_s3_bucket_object" "kube-router-manifests" {
  for_each = var.networking == "kube-router" ? fileset("${path.module}/resources/kube-router", "**/*.yaml") : []

  bucket = aws_s3_bucket.assets.id
  key    = "/manifests-networking/${each.value}"
  content = templatefile("${path.module}/resources/kube-router/${each.value}", {
    kube_router_image = var.container_images["kube_router"]
    flannel_cni_image = var.container_images["flannel_cni"]
    network_mtu       = var.network_mtu
  })
}

