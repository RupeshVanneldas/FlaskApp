output "load_balancer_endpoint" {
  value = module.loadbalancer.web_alb_endpoint
}

output "database_endpoint" {
  value = module.db.db_instance_endpoint
}