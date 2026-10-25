#!/bin/bash

# Update installed packages
dnf update -y

# Install Apache and MariaDB client
dnf install -y httpd mariadb105

# Enable Apache at boot
systemctl enable httpd

# Get an IMDSv2 token for accessing EC2 instance metadata
TOKEN=$(curl -X PUT \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
  http://169.254.169.254/latest/api/token)

# Get the EC2 instance ID
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

# Get the Availability Zone
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Create the custom web page
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mandy's Highly Available AWS Architecture</title>

  <style>
    body {
      font-family: Arial, sans-serif;
      background: #f4f7f6;
      margin: 0;
      padding: 40px;
      text-align: center;
      color: #333;
    }

    .container {
      max-width: 700px;
      margin: auto;
      background: white;
      padding: 40px;
      border-radius: 16px;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
    }

    h1 {
      color: #2e7d32;
    }

    .architecture {
      text-align: left;
      display: inline-block;
      margin: 20px 0;
      line-height: 1.8;
    }

    .server {
      margin-top: 30px;
      padding: 20px;
      background: #eef7ef;
      border-radius: 10px;
    }

    .value {
      font-family: monospace;
      font-weight: bold;
    }
  </style>
</head>

<body>
  <div class="container">

    <h1>☁️ Highly Available AWS Architecture</h1>
    <h2>Built with Terraform 💚</h2>

    <div class="architecture">
      ✓ Application Load Balancer<br>
      ✓ Auto Scaling Group<br>
      ✓ Private EC2 Instances<br>
      ✓ Multi-AZ Architecture<br>
      ✓ RDS MySQL
    </div>

    <div class="server">
      <h3>🖥️ Request Served By</h3>

      <p>
        Instance ID:
        <span class="value">$INSTANCE_ID</span>
      </p>

      <p>
        Availability Zone:
        <span class="value">$AZ</span>
      </p>
    </div>

  </div>
</body>
</html>
EOF

# Start Apache
systemctl start httpd