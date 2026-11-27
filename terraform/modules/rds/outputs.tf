output "address" {
  description = "DNS name of the database (use as DB_HOST)."
  value       = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "username" {
  value = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the generated username/password JSON."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
