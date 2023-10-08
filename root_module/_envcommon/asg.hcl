terraform {
  source = "tfr:///terraform-aws-modules/autoscaling/aws?version=6.5.3"
}

dependencies {
  paths = ["../sg", "../aws_data", "../alb"]
}

dependency "sg" {
  config_path = "../sg"
  mock_outputs = {
    wrapper = {
      "ec2-sg" = {
        security_group_id = "sg-0ca330671e074a05a"
      }
    }
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}



dependency "aws_data" {
  config_path = "../aws_data"
  mock_outputs = {
    r_private_subnets_ids = ["subnet-10.0.1.0", "subnet-10.0.2.0"]
    amzn2_mongo_api_ami   = "ami-0111111"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    target_group_arns = ["10.10.10.10", "target_group_arns"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # # Extract out common variables for reuse
  env               = local.environment_vars.locals.environment
  game_code         = local.environment_vars.locals.game_code
  country           = local.environment_vars.locals.country
  template_key_name = local.environment_vars.locals.template_key_name
  asg_instance_type = "t3.micro"
  user_data         = <<-EOT
#!/bin/bash
pid_9090=`ps -ef|grep 9090|grep ec2-user|awk '{print $2}'`
pid_9091=`ps -ef|grep 9091|grep ec2-user|awk '{print $2}'`

if [ $pid_9090 != "" ];
then
 kill -9 $pid_9090
fi
if [ $pid_9091 != "" ];
then
 kill -9 $pid_9091
fi

gamecd_small="rnd"
gamecd_large="RND"
region_small="kr"
region_large="KR"
mem_small="4g"
mem_max="4g"
pri_dns=r-kr-mongodb-pri.rnd.internal
sec_dns=r-kr-mongodb-sec.rnd.internal

sudo rm -rf /home/ec2-user/deploy/real*
sudo aws s3 cp s3://terragrunt-test-001/RND_GAME-MONGO-SAVE-API.jar /home/ec2-user/deploy/real-$gamecd_small-$region_small-$gamecd_large-$region_large-MONGO-API-9090 
sudo aws s3 cp s3://terragrunt-test-001/RND_GAME-MONGO-SAVE-API.jar /home/ec2-user/deploy/real-$gamecd_small-$region_small-$gamecd_large-$region_large-MONGO-API-9091

sudo su - ec2-user -c "cd /home/ec2-user/deploy/real-$gamecd_small-$region_small-$gamecd_large-$region_large-MONGO-API-9090 & nohup /home/ec2-user/apps/jdk_11/bin/java -jar -Dserver.port=9090 -Dmongo.pri.host=$pri_dns -Dmongo.secon.host=$sec_dns -Dauth.yn=Y -Dauth.mechanism=SCRAM-SHA-1 -Dgame.cds=$gamecd_large -Dservice.cd=$gamecd_large-$region_large-MONGO-API -Dserver.port=9090 -server -Xms$mem_small -Xmx$mem_max -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/ec2-user/logs/oom_error_9090.hprof /home/ec2-user/deploy/real-$gamecd_small-$region_small-$gamecd_large-$region_large-MONGO-API-9090/RB_3.0.11/target/GAME-MONGO-SAVE-API.jar &"
sudo su - ec2-user -c "cd /home/ec2-user/deploy/real-$gamecd_small-$region_small-$gamecd_large-$region_large-MONGO-API-9091 & nohup /home/ec2-user/apps/jdk_11/bin/java -jar -Dserver.port=9091 -Dmongo.pri.host=$pri_dns -Dmongo.secon.host=$sec_dns -Dauth.yn=Y -Dauth.mechanism=SCRAM-SHA-1 -Dgame.cds=$gamecd_large -Dservice.cd=$gamecd_large-$region_large-MONGO-API -Dserver.port=9091 -server -Xms$mem_small -Xmx$mem_max -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/home/ec2-user/logs/oom_error_9091.hprof /home/ec2-user/deploy/real-$gamecd_small-$region_small-$gamecd_large-$region_large-MONGO-API-9091/RB_3.0.11/target/GAME-MONGO-SAVE-API.jar &"
  EOT

}


inputs = {
  name          = "${local.env}-${local.game_code}-${local.country}-mongo-asg"
  instance_name = "${local.env}-${local.game_code}-${local.country}-mongodb-api"
  # Determines whether to create launch template or not
  # type: bool
  create_launch_template = true

  min_size                  = 0
  max_size                  = 2
  desired_capacity          = 2
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  vpc_zone_identifier       = dependency.aws_data.outputs.r_private_subnets_ids

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      # checkpoint_delay       = 600
      # checkpoint_percentages = [35, 70, 100]
      # instance_warmup        = 300
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name        = "${local.env}-${local.game_code}-${local.country}-mongodb-api"
  launch_template_description = "Managed by Terraform"
  update_default_version      = true

  image_id          = dependency.aws_data.outputs.amzn2_mongo_api_ami
  instance_type     = "r6i.large"
  user_data         = base64encode(local.user_data)
  ebs_optimized     = true
  enable_monitoring = true
  key_name          = local.template_key_name

  create_iam_instance_profile = true
  iam_role_name               = "${local.env}-${local.game_code}-mongodb-role"
  iam_role_path               = "/ec2/"
  iam_role_description        = "Managed by Terraform"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonEC2ReadOnlyAccess     = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
    CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    AmazonS3FullAccess          = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }

  target_group_arns = dependency.alb.outputs.target_group_arns

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = false
        volume_size           = 30
        volume_type           = "gp3"
      }
    }
  ]

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
    instance_metadata_tags      = "enabled"
  }

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [dependency.sg.outputs.wrapper["ec2-sg"].security_group_id]
    }
  ]

  tags = {
    Terraform = "true"
  }

}
