output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "alb_dns" {
  value = aws_lb.lb.dns_name
}