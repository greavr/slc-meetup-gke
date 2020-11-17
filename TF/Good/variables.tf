# GCP Project Name
variable "gcp-project-name" {
    type = string
#    default = "gke-meetup-demo"
    default = "test-kitchen-2020-02"
}

# Instance Region
variable "region" { 
    type = string
    default = "us-west2"
}

variable "iam_roles" {
    type = list(string)
    default = ["roles/logging.logWriter","roles/monitoring.metricWriter","roles/monitoring.viewer"]
}
