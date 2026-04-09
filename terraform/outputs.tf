output "alb_dns_name" {
  description = "Public ALB DNS"
  value       = aws_lb.app.dns_name
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_lb.app.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.app.name
}

output "task_definition_family" {
  description = "Task definition family"
  value       = aws_ecs_task_definition.app.family
}

output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.app.id
}