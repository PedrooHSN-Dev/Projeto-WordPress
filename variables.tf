variable "project_name" {
  description = "Nome do projeto."
  type        = string
  default     = "wordpressproject"
}

variable "aws_region" {
  description = "Regiao da AWS."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloco CIDR para a VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de blocos CIDR para as sub-redes publicas."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Lista de blocos CIDR para as sub-redes privadas."
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "db_username" {
  description = "Usuario do banco de dados."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco de dados."
  type        = string
  sensitive   = true
}

variable "tag_name" {
  description = "Valor Name nas EC2."
  type        = string
}

variable "tag_costcenter" {
  description = "Valor CostCenter nas EC2."
  type        = string
}

variable "tag_project" {
  description = "Valor Project nas EC2."
  type        = string
}