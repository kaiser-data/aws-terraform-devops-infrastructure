# CloudWatch IAM Role for EC2 instances
resource "aws_iam_role" "cloudwatch_agent_role" {
  name = "VotingApp-CloudWatchAgentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name  = "VotingApp-CloudWatchAgentRole"
    Owner = "Marty McFly"
  }
}

# Attach CloudWatch Agent policy
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy" {
  role       = aws_iam_role.cloudwatch_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "cloudwatch_profile" {
  name = "VotingApp-CloudWatchProfile"
  role = aws_iam_role.cloudwatch_agent_role.name
}

# CloudWatch Alarms

# Frontend High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "frontend_high_cpu" {
  alarm_name          = "VotingApp-Frontend-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Frontend CPU exceeds 80%"
  alarm_actions       = []  # Add SNS topic ARN here for notifications

  dimensions = {
    InstanceId = aws_instance.frontend.id
  }

  tags = {
    Name = "Frontend CPU Alarm"
  }
}

# Backend High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "backend_high_cpu" {
  alarm_name          = "VotingApp-Backend-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Backend CPU exceeds 80%"

  dimensions = {
    InstanceId = aws_instance.backend.id
  }

  tags = {
    Name = "Backend CPU Alarm"
  }
}

# Database High CPU Alarm
resource "aws_cloudwatch_metric_alarm" "database_high_cpu" {
  alarm_name          = "VotingApp-Database-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when Database CPU exceeds 80%"

  dimensions = {
    InstanceId = aws_instance.database.id
  }

  tags = {
    Name = "Database CPU Alarm"
  }
}

# High Memory Alarm (using custom metric)
resource "aws_cloudwatch_metric_alarm" "frontend_high_memory" {
  alarm_name          = "VotingApp-Frontend-HighMemory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MEMORY_USED"
  namespace           = "VotingApp/Infrastructure"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alert when Frontend Memory exceeds 85%"

  dimensions = {
    InstanceId = aws_instance.frontend.id
  }

  tags = {
    Name = "Frontend Memory Alarm"
  }
}

# Disk Space Alarm
resource "aws_cloudwatch_metric_alarm" "frontend_low_disk" {
  alarm_name          = "VotingApp-Frontend-LowDisk"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DISK_USED"
  namespace           = "VotingApp/Infrastructure"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alert when Frontend disk usage exceeds 85%"

  dimensions = {
    InstanceId = aws_instance.frontend.id
  }

  tags = {
    Name = "Frontend Disk Alarm"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "system_logs" {
  name              = "/voting-app/system"
  retention_in_days = 7

  tags = {
    Name = "Voting App System Logs"
  }
}

resource "aws_cloudwatch_log_group" "docker_logs" {
  name              = "/voting-app/docker"
  retention_in_days = 7

  tags = {
    Name = "Voting App Docker Logs"
  }
}

resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/voting-app/application"
  retention_in_days = 7

  tags = {
    Name = "Voting App Application Logs"
  }
}

# Outputs
output "cloudwatch_role_arn" {
  description = "ARN of the CloudWatch IAM role"
  value       = aws_iam_role.cloudwatch_agent_role.arn
}

output "cloudwatch_instance_profile" {
  description = "Name of the CloudWatch instance profile"
  value       = aws_iam_instance_profile.cloudwatch_profile.name
}
