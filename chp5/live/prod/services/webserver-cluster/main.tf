module "webserver_cluster" {
    source = "../../../../../chp4/modules/services/webserver-cluster"

    cluster_name = "webservers-prod"
    db_remote_state_bucket = "terrorform"
    db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"

    instance_type = "m4.large"
    min_size = 2
    max_size = 10

    custom_tags = {
        Owner = "evilmurries"
        DeployedBy = "terrorform"
    }
}

resource "aws_autoscaling_group" "asg_web" {
    launch_configuration = aws_launch_configuration.web_config.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids
    target_group_arns = [aws_lb_target_group.tg_asg_web.arn]
    health_check_type = "ELB"

    min_size = var.min_size
    max_size = var.max_size

    tag {
        key = "Name"
        value = var.cluster_name
        propogate_at_launch = true
    }

    dynamic "tag" {
        for_each = var.custom_tags

        content {
            key = tag.key
            value = tag.value
            propagate_at_launch = true
        }
    }
}