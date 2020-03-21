

terraform {
	backend "s3" {
		key="stage/services/weserver-cluster/terraform.tfstate"
		encrypt=true
		region="us-east-1"
		bucket="terraform-up-and-runnig-state-sanjeev0915"
	}
}


