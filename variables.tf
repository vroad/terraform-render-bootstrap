variable "cluster_name" {
  type        = string
  description = "Cluster name"
}

variable "api_servers" {
  type        = list(string)
  description = "List of URLs used to reach kube-apiserver"
}

variable "etcd_servers" {
  type        = list(string)
  description = "List of URLs used to reach etcd servers."
}

variable "asset_dir" {
  type        = string
  description = "Absolute path to a directory where generated assets should be placed (contains secrets)"
}

variable "cloud_provider" {
  type        = string
  description = "The provider for cloud services (empty string for no provider)"
  default     = ""
}

variable "networking" {
  type        = string
  description = "Choice of networking provider (flannel or calico or kube-router)"
  default     = "flannel"
}

variable "network_mtu" {
  type        = number
  description = "CNI interface MTU (only applies to calico and kube-router)"
  default     = 1500
}

variable "network_encapsulation" {
  type        = string
  description = "Network encapsulation mode either ipip or vxlan (only applies to calico)"
  default     = "ipip"
}

variable "network_ip_autodetection_method" {
  type        = string
  description = "Method to autodetect the host IPv4 address (only applies to calico)"
  default     = "first-found"
}

variable "pod_cidr" {
  type        = string
  description = "CIDR IP range to assign Kubernetes pods"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  type    = string
  description = <<EOD
CIDR IP range to assign Kubernetes services.
The 1st IP will be reserved for kube_apiserver, the 10th IP will be reserved for kube-dns.
EOD
  default = "10.3.0.0/24"
}


variable "container_images" {
  type        = map(string)
  description = "Container images to use"

  default = {
    calico      = "quay.io/calico/node:v3.10.0"
    calico_cni  = "quay.io/calico/cni:v3.10.0"
    flannel     = "quay.io/coreos/flannel:v0.11.0-amd64"
    flannel_cni = "quay.io/coreos/flannel-cni:v0.3.0"
    kube_router = "cloudnativelabs/kube-router:v0.3.2"
    hyperkube   = "k8s.gcr.io/hyperkube:v1.16.2"
    coredns     = "k8s.gcr.io/coredns:1.6.2"
  }
}


variable "trusted_certs_dir" {
  type        = string
  description = "Path to the directory on cluster nodes where trust TLS certs are kept"
  default     = "/usr/share/ca-certificates"
}

variable "enable_reporting" {
  type        = bool
  description = "Enable usage or analytics reporting to upstream component owners (Tigera: Calico)"
  default     = false
}

variable "enable_aggregation" {
  type        = bool
  description = "Enable the Kubernetes Aggregation Layer (defaults to false, recommended)"
  default     = false
}

# unofficial, temporary, may be removed without notice

variable "external_apiserver_port" {
  type        = number
  description = "External kube-apiserver port (e.g. 6443 to match internal kube-apiserver port)"
  default     = 6443
}

variable "cluster_domain_suffix" {
  type        = string
  description = "Queries for domains with the suffix will be answered by kube-dns"
  default     = "cluster.local"
}

variable "assets_bucket_prefix" {
  type        = string
  description = "Prefix of S3 bucket for storing assets"
  default     = "k8s-assets-"
}

variable "assets_bucket_noncurrent_version_expiration" {
  type        = number
  description = "Number of days deleted files expire"
  default     = 90
}

variable "region" {
  type        = string
  description = "Region of the AWS provider"
}
