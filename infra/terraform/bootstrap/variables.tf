variable "aws_region" {
  description = "AWS region for the sandbox account"
  type        = string
  default     = "eu-west-3"
}

variable "github_owner" {
  description = "GitHub username or org that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "Name of the GitHub repository used for this dry run"
  type        = string
}
