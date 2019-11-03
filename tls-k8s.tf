# Kubernetes CA (tls/{ca.crt,ca.key})

resource "tls_private_key" "kube-ca" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_self_signed_cert" "kube-ca" {
  key_algorithm   = tls_private_key.kube-ca.algorithm
  private_key_pem = tls_private_key.kube-ca.private_key_pem

  subject {
    common_name  = "kubernetes-ca"
    organization = "typhoon"
  }

  is_ca_certificate     = true
  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]
}

resource "aws_s3_bucket_object" "kube-ca-key" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_private_key.kube-ca.private_key_pem
  etag    = md5(tls_private_key.kube-ca.private_key_pem)
  key     = "/tls/ca.key"
}

resource "aws_s3_bucket_object" "kube-ca-crt" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_self_signed_cert.kube-ca.cert_pem
  etag    = md5(tls_self_signed_cert.kube-ca.cert_pem)
  key     = "/tls/ca.crt"
}

# Kubernetes API Server (tls/{apiserver.key,apiserver.crt})

resource "tls_private_key" "apiserver" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "apiserver" {
  key_algorithm   = tls_private_key.apiserver.algorithm
  private_key_pem = tls_private_key.apiserver.private_key_pem

  subject {
    common_name  = "kube-apiserver"
    organization = "system:masters"
  }

  dns_names = flatten([
    var.api_servers,
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.cluster_domain_suffix}",
  ])

  ip_addresses = [
    cidrhost(var.service_cidr, 1),
  ]
}

resource "tls_locally_signed_cert" "apiserver" {
  cert_request_pem = tls_cert_request.apiserver.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.kube-ca.key_algorithm
  ca_private_key_pem = tls_private_key.kube-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.kube-ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "aws_s3_bucket_object" "apiserver-key" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_private_key.apiserver.private_key_pem
  etag    = md5(tls_private_key.apiserver.private_key_pem)
  key     = "/tls/apiserver.key"
}

resource "aws_s3_bucket_object" "apiserver-crt" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_locally_signed_cert.apiserver.cert_pem
  etag    = md5(tls_locally_signed_cert.apiserver.cert_pem)
  key     = "/tls/apiserver.crt"
}

# Kubernetes Admin (tls/{admin.key,admin.crt})

resource "tls_private_key" "admin" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "admin" {
  key_algorithm   = tls_private_key.admin.algorithm
  private_key_pem = tls_private_key.admin.private_key_pem

  subject {
    common_name  = "kubernetes-admin"
    organization = "system:masters"
  }
}

resource "tls_locally_signed_cert" "admin" {
  cert_request_pem = tls_cert_request.admin.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.kube-ca.key_algorithm
  ca_private_key_pem = tls_private_key.kube-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.kube-ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "aws_s3_bucket_object" "admin-key" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_private_key.admin.private_key_pem
  etag    = md5(tls_private_key.admin.private_key_pem)
  key     = "/tls/admin.key"
}

resource "aws_s3_bucket_object" "admin-crt" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_locally_signed_cert.admin.cert_pem
  etag    = md5(tls_locally_signed_cert.admin.cert_pem)
  key     = "/tls/admin.crt"
}

# Kubernete's Service Account (tls/{service-account.key,service-account.pub})

resource "tls_private_key" "service-account" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "aws_s3_bucket_object" "service-account-key" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_private_key.service-account.private_key_pem
  etag    = md5(tls_private_key.service-account.private_key_pem)
  key     = "/tls/service-account.key"
}

resource "aws_s3_bucket_object" "service-account-crt" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_private_key.service-account.public_key_pem
  etag    = md5(tls_private_key.service-account.public_key_pem)
  key     = "/tls/service-account.pub"
}

# Kubelet

resource "tls_private_key" "kubelet" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "kubelet" {
  key_algorithm   = tls_private_key.kubelet.algorithm
  private_key_pem = tls_private_key.kubelet.private_key_pem

  subject {
    common_name  = "kubelet"
    organization = "system:nodes"
  }
}

resource "tls_locally_signed_cert" "kubelet" {
  cert_request_pem = tls_cert_request.kubelet.cert_request_pem

  ca_key_algorithm   = tls_self_signed_cert.kube-ca.key_algorithm
  ca_private_key_pem = tls_private_key.kube-ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.kube-ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "aws_s3_bucket_object" "kubelet-key" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_private_key.kubelet.private_key_pem
  etag    = md5(tls_private_key.kubelet.private_key_pem)
  key     = "/tls/kubelet.key"
}

resource "aws_s3_bucket_object" "kubelet-crt" {
  bucket  = aws_s3_bucket.assets.id
  content = tls_locally_signed_cert.kubelet.cert_pem
  etag    = md5(tls_locally_signed_cert.kubelet.cert_pem)
  key     = "/tls/kubelet.crt"
}

