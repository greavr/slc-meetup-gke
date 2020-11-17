# GCP Project Name
variable "gcp-project-name" {
    type = string
    default = "gke-meetup-demo-295823"
}

# Instance Region
variable "region" { 
    type = string
    default = "us-west2"
}

variable "iam_roles" {
    type = list(string)
    default = ["roles/cloudsql.client"]
}