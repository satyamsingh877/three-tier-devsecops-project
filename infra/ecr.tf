
# Create ECR repository for frontend
resource "aws_ecr_repository" "frontend" {
  name                 = "frontend"
  image_tag_mutability = "MUTABLE" # Or "IMMUTABLE" for production

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "Development"
    Application = "Frontend"
  }
}

# Create ECR repository for backend
resource "aws_ecr_repository" "backend" {
  name                 = "backend"
  image_tag_mutability = "MUTABLE" # Or "IMMUTABLE" for production

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "Development"
    Application = "Backend"
  }
}

# Output the repository URLs
output "frontend_ecr_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}
