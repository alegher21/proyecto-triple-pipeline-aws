output "ecr_frontend_url" { value = aws_ecr_repository.frontend.repository_url }
output "ecr_backend_url" { value = aws_ecr_repository.backend.repository_url }
output "ecs_cluster_name" { value = aws_ecs_cluster.main.name }
output "ecs_exec_role_arn" { value = data.aws_iam_role.lab_role.arn }
