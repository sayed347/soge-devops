resource "random_pet" "oidc_smoke_test" {
  length = 2
}

output "pet_name" {
  value = random_pet.oidc_smoke_test.id
}

output "environment" {
  value = var.environment
}
