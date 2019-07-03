terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  version = "~> 2.0"
}

data "terraform_remote_state" "training_emr_cluster" {
  backend = "s3"
  config {
    key    = "training_emr_cluster.tfstate"
    bucket = "tw-dataeng-${var.cohort}-tfstate"
    region = "${var.aws_region}"
  }
}

resource "aws_cloudwatch_metric_alarm" "main" {
  alarm_name = "platform-not-up-for-${var.cohort}",
  alarm_description = "${var.cohort}: Alert for when all of the applications of streaming pipeline are not up"
  comparison_operator = "LessThanThreshold",
  threshold = "5",
  namespace = "AWS/ElasticMapReduce"
  metric_name = "AppsRunning"
  period = "300",
  evaluation_periods = "1",
  statistic = "Average",
  alarm_actions = [
    "${var.sns_alert_topic_arn}"
  ],
  dimensions {
    JobFlowId = "${data.terraform_remote_state.training_emr_cluster.emr_cluster_id}"
  }
}