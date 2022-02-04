
output "{{service_name}}_lb_dns" {
  value = module.tf_next.cloudfront_domain_name
}