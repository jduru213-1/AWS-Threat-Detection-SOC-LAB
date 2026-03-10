output "cloudtrail_s3_sqs_queue_url" {
  description = "SQS queue URL for CloudTrail S3 event notifications (SQS-based S3 inputs)"
  value       = try(aws_sqs_queue.cloudtrail_s3_events[0].id, null)
}

output "cloudtrail_s3_sqs_queue_arn" {
  description = "SQS queue ARN for CloudTrail S3 event notifications"
  value       = try(aws_sqs_queue.cloudtrail_s3_events[0].arn, null)
}

output "config_s3_sqs_queue_url" {
  description = "SQS queue URL for Config S3 event notifications (SQS-based S3 inputs)"
  value       = try(aws_sqs_queue.config_s3_events[0].id, null)
}

output "config_s3_sqs_queue_arn" {
  description = "SQS queue ARN for Config S3 event notifications"
  value       = try(aws_sqs_queue.config_s3_events[0].arn, null)
}

output "vpcflow_s3_sqs_queue_url" {
  description = "SQS queue URL for VPC Flow Logs S3 event notifications (SQS-based S3 inputs)"
  value       = try(aws_sqs_queue.vpcflow_s3_events[0].id, null)
}

output "vpcflow_s3_sqs_queue_arn" {
  description = "SQS queue ARN for VPC Flow Logs S3 event notifications"
  value       = try(aws_sqs_queue.vpcflow_s3_events[0].arn, null)
}

