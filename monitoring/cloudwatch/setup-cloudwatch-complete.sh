#!/bin/bash
# Complete CloudWatch Setup Script
# Automates the entire CloudWatch setup process

set -e  # Exit on error

REGION="ap-northeast-2"
TERRAFORM_DIR="../../terraform"
ANSIBLE_DIR="../../ansible"

echo "═══════════════════════════════════════════════════════"
echo "  ☁️  AWS CloudWatch Complete Setup"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI configured"

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install it first."
    exit 1
fi

echo "✅ Terraform found"

# Check Ansible
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not found. Please install it first."
    exit 1
fi

echo "✅ Ansible found"
echo ""

# Step 1: Apply Terraform changes
echo "═══════════════════════════════════════════════════════"
echo "Step 1/5: Applying Terraform Changes"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Creating CloudWatch IAM roles, alarms, and log groups..."
echo ""

cd ${TERRAFORM_DIR}

# Check if cloudwatch.tf exists
if [ ! -f "cloudwatch.tf" ]; then
    echo "❌ cloudwatch.tf not found in ${TERRAFORM_DIR}"
    exit 1
fi

terraform init -upgrade > /dev/null 2>&1
terraform apply -auto-approve

if [ $? -ne 0 ]; then
    echo "❌ Terraform apply failed"
    exit 1
fi

echo ""
echo "✅ Terraform resources created"
echo ""

# Get outputs
PROFILE_NAME=$(terraform output -raw cloudwatch_instance_profile 2>/dev/null)
FRONTEND_ID=$(terraform output -raw frontend_instance_id 2>/dev/null)
BACKEND_ID=$(terraform output -raw backend_instance_id 2>/dev/null)
DATABASE_ID=$(terraform output -raw database_instance_id 2>/dev/null)

if [ -z "$PROFILE_NAME" ] || [ -z "$FRONTEND_ID" ]; then
    echo "❌ Could not get Terraform outputs"
    exit 1
fi

echo "Instance IDs:"
echo "  Frontend: ${FRONTEND_ID}"
echo "  Backend:  ${BACKEND_ID}"
echo "  Database: ${DATABASE_ID}"
echo ""

# Step 2: Attach IAM instance profiles
echo "═══════════════════════════════════════════════════════"
echo "Step 2/5: Attaching IAM Instance Profiles"
echo "═══════════════════════════════════════════════════════"
echo ""

attach_profile() {
    local instance_id=$1
    local instance_name=$2

    echo "Attaching profile to ${instance_name}..."

    # Check if already attached
    CURRENT_PROFILE=$(aws ec2 describe-instances \
        --instance-ids ${instance_id} \
        --query 'Reservations[0].Instances[0].IamInstanceProfile.Arn' \
        --output text \
        --region ${REGION} 2>/dev/null)

    if [ "$CURRENT_PROFILE" != "None" ] && [ -n "$CURRENT_PROFILE" ]; then
        echo "  Profile already attached, skipping..."
    else
        aws ec2 associate-iam-instance-profile \
            --instance-id ${instance_id} \
            --iam-instance-profile Name=${PROFILE_NAME} \
            --region ${REGION} > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo "  ✅ Profile attached successfully"
        else
            echo "  ⚠️  Could not attach profile (may already be attached)"
        fi
    fi
}

attach_profile ${FRONTEND_ID} "Frontend"
attach_profile ${BACKEND_ID} "Backend"
attach_profile ${DATABASE_ID} "Database"

echo ""
echo "✅ IAM profiles attached"
echo ""

# Step 3: Deploy CloudWatch agent
echo "═══════════════════════════════════════════════════════"
echo "Step 3/5: Installing CloudWatch Agent"
echo "═══════════════════════════════════════════════════════"
echo ""

cd ${ANSIBLE_DIR}

if [ ! -f "playbooks/setup-cloudwatch.yml" ]; then
    echo "❌ setup-cloudwatch.yml not found"
    exit 1
fi

echo "Installing CloudWatch agent on all instances..."
echo "(This may take 2-3 minutes)"
echo ""

ansible-playbook playbooks/setup-cloudwatch.yml

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CloudWatch agent installed and running"
else
    echo ""
    echo "⚠️  CloudWatch agent installation had issues, but continuing..."
fi

echo ""

# Step 4: Wait for metrics to start appearing
echo "═══════════════════════════════════════════════════════"
echo "Step 4/5: Waiting for Metrics"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Waiting 60 seconds for metrics to start appearing..."
echo "(CloudWatch metrics can take a few minutes to show up)"
echo ""

for i in {60..1}; do
    echo -ne "  ${i} seconds remaining...\r"
    sleep 1
done

echo ""
echo "✅ Metrics should now be available in CloudWatch"
echo ""

# Step 5: Create CloudWatch dashboard
echo "═══════════════════════════════════════════════════════"
echo "Step 5/5: Creating CloudWatch Dashboard"
echo "═══════════════════════════════════════════════════════"
echo ""

cd - > /dev/null  # Go back to cloudwatch directory
./create-dashboard.sh

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ CloudWatch Setup Complete!"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 What's Configured:"
echo "  ✅ CloudWatch agent running on 3 instances"
echo "  ✅ Custom metrics being collected"
echo "  ✅ Alarms configured (CPU, Memory, Disk)"
echo "  ✅ Log groups created"
echo "  ✅ Dashboard created"
echo ""
echo "🔗 Access CloudWatch:"
echo "   Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#dashboards:name=VotingApp-Infrastructure"
echo "   Metrics:   https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#metricsV2:"
echo "   Logs:      https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#logsV2:log-groups"
echo "   Alarms:    https://console.aws.amazon.com/cloudwatch/home?region=${REGION}#alarmsV2:"
echo ""
echo "📈 Available Metrics Namespaces:"
echo "   - AWS/EC2 (default EC2 metrics)"
echo "   - VotingApp/Infrastructure (custom metrics)"
echo ""
echo "🔔 Alarms:"
echo "   - VotingApp-Frontend-HighCPU"
echo "   - VotingApp-Backend-HighCPU"
echo "   - VotingApp-Database-HighCPU"
echo "   - VotingApp-Frontend-HighMemory"
echo "   - VotingApp-Frontend-LowDisk"
echo ""
echo "💡 Tip: Run a stress test to see metrics in action!"
echo "   cd ../../monitoring && ./quick-stress.sh 1000 40"
echo ""
echo "═══════════════════════════════════════════════════════"
