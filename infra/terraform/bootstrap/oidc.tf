# GitHub's OIDC token endpoint. AWS validates the certificate chain against
# its own trusted root CAs since 2023 — fetching the thumbprint dynamically
# here avoids hardcoding a value that GitHub has rotated before.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}
