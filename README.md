# 3-Tier Flask Application on AWS with Terraform

<img width="437" alt="image" src="https://github.com/user-attachments/assets/c993666b-3ee3-46bc-8ad2-1dbcb790c68a" />


A production-ready three-tier web application deployed on AWS using Terraform, featuring:
- Flask web application frontend
- MySQL database backend
- Auto-scaling groups
- Load balancers
- Secure network architecture

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Instructions](#deployment-instructions)
- [Accessing the Application](#accessing-the-application)
- [Troubleshooting](#troubleshooting)
- [Important Notes](#important-notes)
- [Future Improvements](#future-improvements)

## Architecture Overview
The infrastructure consists of four main layers:

1. **Web Tier**
   - Auto Scaling Group (ASG) with EC2 instances
   - Internet-facing Application Load Balancer
   - Hosts Flask application with Nginx reverse proxy

2. **Application Tier**
   - Internal Application Load Balancer
   - ASG for application servers (currently serves as extension point)

3. **Database Tier**
   - MySQL RDS instance
   - Multi-AZ deployment (disabled by default)

4. **Network Layer**
   - VPC with public/private subnets
   - NAT Gateway for outbound traffic
   - Security groups with least-privilege access

## Prerequisites
- AWS account with IAM credentials
- Terraform v1.0+ installed
- AWS CLI configured
- Python 3.8+ (for local development)
- Basic understanding of Flask and Terraform

## Project Structure
```text
FlaskApp + Terraform (3-tier-Architecture)
├── modules/           # Terraform modules
│   ├── compute/       # EC2 instances & ASGs
│   ├── database/      # RDS configuration
│   ├── loadbalancer/  # ALB configurations
│   └── network/       # VPC, subnets, security groups
├── flask-app/         # Flask application code
│   ├── app.py         # Main application logic
│   ├── mysql.sql      # Database schema
│   └── templates/     # HTML templates
├── main.tf            # Root module configuration
├── variables.tf       # Variable declarations
└── terraform.tfvars   # Variable values (create from example)
```

## Deployment Instructions
### Clone Repository
```bash
git clone <your-repository-url>
cd 3tier-flask-terraform
```

### Initialize Terraform
```bash
terraform init
```

### Configure Variables
Create `terraform.tfvars` with:
```hcl
environment  = "prod"
project_name = "3tier-app"
owner        = "your-name"
dbpassword   = "secure-password-here"
dbuser       = "admin"
db_name      = "employees"
```

### Review Plan
```bash
terraform plan
```

### Deploy Infrastructure
```bash
terraform apply -auto-approve
```

## Accessing the Application
After deployment:

1. Get the Load Balancer DNS name from AWS Console
2. Access via web browser: `http://<web-lb-dns>`
3. Test functionality:
   - Add employees via `/addemp`
   - Retrieve records via `/getemp`
   - About page at `/about`

## Key Features
- **Infrastructure as Code**: Entire AWS environment defined in Terraform
- **High Availability**: Multi-AZ deployment for critical components
- **Security**:
  - Network isolation with public/private subnets
  - Security groups with minimal open ports
  - Database in private subnet with no public access
- **Scalability**: Auto Scaling Groups for horizontal scaling

## Troubleshooting
### Common Issues and Solutions
#### Database Connection Failures
- Verify RDS endpoint in `user_data.sh.tpl`
- Check security group rules for MySQL port (3306)

#### Application Not Loading
- Check EC2 instance status
- View Nginx logs: `journalctl -u nginx`
- Check Flask logs in `/opt/flask-app`

#### Terraform Errors
- Run `terraform validate`
- Check AWS provider version
- Verify IAM permissions

## Important Notes
- Database credentials are currently hardcoded - use AWS Secrets Manager for production
- The S3 backend in `config.tf` needs bucket configuration
- **Cost considerations**:
  - `t2.micro` instances fall under AWS Free Tier
  - Monitor RDS storage costs
- Delete infrastructure with `terraform destroy` when not in use

## Future Improvements
- Implement HTTPS with ACM certificates
- Add CloudFront CDN distribution
- Set up Redis caching layer
- Add CI/CD pipeline for Flask app updates
- Implement CloudWatch monitoring
- Use Packer for AMI management
- Add Terraform state locking

