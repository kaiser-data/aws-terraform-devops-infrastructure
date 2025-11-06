#!/bin/bash
# Create CloudWatch Dashboard for Voting App

REGION="ap-northeast-2"
DASHBOARD_NAME="VotingApp-Infrastructure"

# Get instance IDs from Terraform
FRONTEND_ID=$(cd ../../terraform && terraform output -raw frontend_instance_id 2>/dev/null)
BACKEND_ID=$(cd ../../terraform && terraform output -raw backend_instance_id 2>/dev/null)
DATABASE_ID=$(cd ../../terraform && terraform output -raw database_instance_id 2>/dev/null)

# Get private IPs for hostname mapping
FRONTEND_IP=$(cd ../../terraform && terraform output -raw frontend_private_ip 2>/dev/null)
BACKEND_IP=$(cd ../../terraform && terraform output -raw backend_private_ip 2>/dev/null)
DATABASE_IP=$(cd ../../terraform && terraform output -raw database_private_ip 2>/dev/null)

# Convert IPs to hostname format (e.g., 10.0.1.22 -> ip-10-0-1-22)
FRONTEND_HOST="ip-$(echo $FRONTEND_IP | tr '.' '-')"
BACKEND_HOST="ip-$(echo $BACKEND_IP | tr '.' '-')"
DATABASE_HOST="ip-$(echo $DATABASE_IP | tr '.' '-')"

if [ -z "$FRONTEND_ID" ]; then
    echo "❌ Error: Could not get instance IDs from Terraform"
    echo "Make sure you're in the monitoring/cloudwatch directory"
    exit 1
fi

echo "📊 Creating CloudWatch Dashboard: ${DASHBOARD_NAME}"
echo ""
echo "Instance IDs:"
echo "  Frontend: ${FRONTEND_ID} (${FRONTEND_HOST})"
echo "  Backend:  ${BACKEND_ID} (${BACKEND_HOST})"
echo "  Database: ${DATABASE_ID} (${DATABASE_HOST})"
echo ""

# Create dashboard JSON with correct dimensions
cat > /tmp/dashboard.json << EOF
{
    "widgets": [
        {
            "type": "text",
            "properties": {
                "markdown": "# 🗳️ Voting App Infrastructure Dashboard\\n\\n**3-Tier Architecture Monitoring**\\n\\nFrontend → Backend → Database"
            },
            "x": 0,
            "y": 0,
            "width": 24,
            "height": 2
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "InstanceId", "${FRONTEND_ID}", { "stat": "Average", "label": "Frontend CPU" } ],
                    [ ".", ".", ".", "${BACKEND_ID}", { "stat": "Average", "label": "Backend CPU" } ],
                    [ ".", ".", ".", "${DATABASE_ID}", { "stat": "Average", "label": "Database CPU" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${REGION}",
                "title": "CPU Utilization by Tier",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            },
            "x": 0,
            "y": 2,
            "width": 12,
            "height": 6
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "VotingApp/Infrastructure", "MEMORY_USED", "host", "${FRONTEND_HOST}", { "stat": "Average", "label": "Frontend Memory" } ],
                    [ ".", ".", ".", "${BACKEND_HOST}", { "stat": "Average", "label": "Backend Memory" } ],
                    [ ".", ".", ".", "${DATABASE_HOST}", { "stat": "Average", "label": "Database Memory" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${REGION}",
                "title": "Memory Usage by Tier",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            },
            "x": 12,
            "y": 2,
            "width": 12,
            "height": 6
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "NetworkIn", "InstanceId", "${FRONTEND_ID}", { "stat": "Sum", "label": "Frontend IN" } ],
                    [ ".", "NetworkOut", ".", ".", { "stat": "Sum", "label": "Frontend OUT" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${REGION}",
                "title": "Network Traffic - Frontend",
                "period": 300
            },
            "x": 0,
            "y": 8,
            "width": 12,
            "height": 6
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "VotingApp/Infrastructure", "DISK_USED", "path", "/", "host", "${FRONTEND_HOST}", { "stat": "Average", "label": "Frontend /" } ],
                    [ "...", "${BACKEND_HOST}", ".", ".", { "stat": "Average", "label": "Backend /" } ],
                    [ "...", "${DATABASE_HOST}", ".", ".", { "stat": "Average", "label": "Database /" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${REGION}",
                "title": "Root Disk Usage by Tier",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            },
            "x": 12,
            "y": 8,
            "width": 12,
            "height": 6
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "StatusCheckFailed", "InstanceId", "${FRONTEND_ID}", { "stat": "Sum", "label": "Frontend" } ],
                    [ ".", ".", ".", "${BACKEND_ID}", { "stat": "Sum", "label": "Backend" } ],
                    [ ".", ".", ".", "${DATABASE_ID}", { "stat": "Sum", "label": "Database" } ]
                ],
                "view": "singleValue",
                "region": "${REGION}",
                "title": "Instance Health Checks",
                "period": 300
            },
            "x": 0,
            "y": 14,
            "width": 8,
            "height": 3
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "VotingApp/Infrastructure", "netstat_tcp_established", "host", "${FRONTEND_HOST}", { "stat": "Average", "label": "Frontend TCP Connections" } ]
                ],
                "view": "singleValue",
                "region": "${REGION}",
                "title": "Active TCP Connections",
                "period": 300
            },
            "x": 8,
            "y": 14,
            "width": 8,
            "height": 3
        },
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "VotingApp/Infrastructure", "processes_running", "host", "${FRONTEND_HOST}", { "stat": "Average", "label": "Frontend" } ],
                    [ "...", "${BACKEND_HOST}", { "stat": "Average", "label": "Backend" } ],
                    [ "...", "${DATABASE_HOST}", { "stat": "Average", "label": "Database" } ]
                ],
                "view": "singleValue",
                "region": "${REGION}",
                "title": "Running Processes",
                "period": 300
            },
            "x": 16,
            "y": 14,
            "width": 8,
            "height": 3
        }
    ]
}
EOF

# Create the dashboard
echo "Creating dashboard..."
aws cloudwatch put-dashboard \
    --dashboard-name "${DASHBOARD_NAME}" \
    --dashboard-body file:///tmp/dashboard.json \
    --region "${REGION}"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Dashboard created successfully!"
    echo ""
    echo "🔗 View your dashboard:"
    echo "   https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards:name=${DASHBOARD_NAME}"
    echo ""
else
    echo "❌ Failed to create dashboard"
    echo "Make sure AWS CLI is configured with proper credentials"
    exit 1
fi

# Clean up
rm /tmp/dashboard.json
