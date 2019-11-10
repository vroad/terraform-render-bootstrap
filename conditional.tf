# Assets generated only when certain options are chosen

locals {
  in-flannel-manifests = var.networking == "flannel" ? fileset("${path.module}/resources/flannel", "**/*.yaml") : []
  flannel-manifests = { for filename in local.in-flannel-manifests :
    "/manifests-networking/${filename}" => templatefile("${path.module}/resources/flannel/${filename}", {
      flannel_image     = var.container_images["flannel"]
      flannel_cni_image = var.container_images["flannel_cni"]
      pod_cidr          = var.pod_cidr
    })
  }
  in-calico-manifests = var.networking == "calico" ? fileset("${path.module}/resources/calico", "**/*.yaml") : []
  calico-manifests = { for filename in local.in-calico-manifests :
    "/manifests-networking/${filename}" => templatefile("${path.module}/resources/calico/${filename}", {
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
  in-kube-router-manifests = var.networking == "kube-router" ? fileset("${path.module}/resources/kube-router", "**/*.yaml") : []
  kube-router-manifests = { for filename in local.in-kube-router-manifests :
    "/manifests-networking/${filename}" => templatefile("${path.module}/resources/kube-router/${filename}", {
      kube_router_image = var.container_images["kube_router"]
      flannel_cni_image = var.container_images["flannel_cni"]
      network_mtu       = var.network_mtu
    })
  }
}

