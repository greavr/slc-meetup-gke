# slc-meetup-gke

## Install TF
Source
`https://learn.hashicorp.com/tutorials/terraform/install-cli`

```
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform
terraform -install-autocomplete
```

## Run TF
```
cd TF/Bad
terraform init
terraform plan
terraform apply -auto-approve
```
Then to destroy
```
terraform destroy -auto-approve`
```


## GKE Node Minimum Permissions
`roles/logging.logWriter`\
`roles/monitoring.metricWriter`\
`roles/monitoring.viewer`

If using private GCR you need to grant service account permissions on the GCR Bucket. Best solution is to assign explicit bucket permissions to the GKE Node SA

## GKE Node Scope Permissions
`https://www.googleapis.com/auth/compute`\
`https://www.googleapis.com/auth/devstorage.read_only`\
`https://www.googleapis.com/auth/logging.write`\
`https://www.googleapis.com/auth/monitoring`