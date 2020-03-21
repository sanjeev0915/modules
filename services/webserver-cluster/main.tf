provider "aws" {
	region = "us-east-1"
}


resource "aws_security_group" "instance" {
		//name = "terraform-example-instance"
		name = "${var.cluster_name}-instance"
		ingress {
			from_port="${var.server_port}"
			to_port="${var.server_port}"
			protocol="tcp"
			cidr_blocks=["0.0.0.0/0"]

		}



		lifecycle {
			create_before_destroy = true
		}
	}

	resource "aws_security_group" "elb" {
		//name = "terraform-example-elb"
		name = "${var.cluster_name}-elb"
		ingress {
			from_port= 80
			to_port=80
			protocol="tcp"
			cidr_blocks=["0.0.0.0/0"]

		}

		egress {
			from_port = 0
			to_port = 0
			protocol = "-1"
			cidr_blocks = ["0.0.0.0/0"]

		}
	}

resource "aws_launch_configuration" "example" {

	//instance_type="t2.micro"
	instance_type = "${var.instance_type}"
	image_id = "ami-40d28157"
	security_groups = ["${aws_security_group.instance.id}"]
	user_data = "${data.template_file.user_data.rendered}"
	

	lifecycle {
	create_before_destroy = true
	}
	


}

resource "aws_autoscaling_group" "example" {
	
	launch_configuration = "${aws_launch_configuration.example.id}"
	availability_zones = ["${data.aws_availability_zones.all.names}"]

	load_balancers = ["${aws_elb.example.id}"]
	health_check_type = "ELB"

	//min_size=2
	//max_size=10

	min_size= "${var.min_size}"
	max_size= "${var.max_size}"

	tag {
		key = "Name"
		//value = "terraform-asg-example"
		value = "${var.cluster_name}-example"
		propagate_at_launch = true
	}
}

resource "aws_elb" "example" {
	
	//name = "terraform-elb-example"
	name = "${var.cluster_name}-example"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
	security_groups = ["${aws_security_group.elb.id}"]

	listener {
		lb_port = 80
		lb_protocol = "http"
		instance_port = "${var.server_port}"
		instance_protocol = "http"
	}

	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		interval = 30
		target = "HTTP:${var.server_port}/"
	}
}


	data "aws_availability_zones" "all" {}

	data "terraform_remote_state" "db" {
		backend = "s3"
		config {
			//bucket="terraform-up-and-runnig-state-sanjeev0915"
			//key ="stage/data-stores/mysql/terraform.tfstate"
			bucket="${var.db_remote_state_bucket}"
			key ="${var.db_remote_state_key}"
			region = "us-east-1"
		}
	}

	data "template_file" "user_data" {
		template = "${file("../../../modules/services/webserver-cluster/user-data.sh")}"

		vars {
			server_port = "${var.server_port}"
			db_address = "${data.terraform_remote_state.db.address}"
			db_port = "${data.terraform_remote_state.db.port}"
		}

	}