#!/bin/bash
# Update system packages
yum update -y

# Enable Amazon Linux Extras for nginx and Python 3.8
amazon-linux-extras enable nginx1
amazon-linux-extras enable python3.8
yum install -y nginx python3.8 python3-pip

# Install dependencies
yum install -y flask pymysql cryptography mysql

# Import MySQL GPG Key
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023

# Install MySQL 8 Community Server
yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-5.noarch.rpm

# Create application directory
mkdir -p /opt/flask-app/templates

# Write HTML templates
%{ for filename, content in templates ~}
echo '${content}' | base64 -d > /opt/flask-app/templates/${filename}
%{ endfor ~}

# Navigate to app directory
cd /opt/flask-app

# Write app.py
echo '${app_py}' | base64 -d > /opt/flask-app/app.py

# Write MySQL schema
echo '${mysql_sql}' | base64 -d > /opt/flask-app/mysql.sql

# Configure Nginx
cat > /etc/nginx/conf.d/flask.conf <<EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Start Nginx service
systemctl enable nginx
systemctl restart nginx

# Set environment variables securely
export DBHOST="rds-endpoint"
export DBUSER="root"
export DBPWD="password"
export DATABASE="employees"  # <-- Check if this is the correct name

# Wait for RDS to be ready
sleep 30

# Initialize database if needed
mysql -h "$DBHOST" -u "$DBUSER" -p"$DBPWD" "$DATABASE" < /opt/flask-app/mysql.sql || echo "Database import failed"

# Start Flask app with Gunicorn

pip3 install gunicorn
pip3 install flask
pip3 install pymysql

python3 -m gunicorn --bind 0.0.0.0:8000 app:app &
