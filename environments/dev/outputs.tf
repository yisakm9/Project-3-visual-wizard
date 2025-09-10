output "api_search_url" {
  description = "The URL to invoke the search API."
  value       = module.search_api.invoke_url
}