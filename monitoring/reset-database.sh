#!/bin/bash
# Reset Database - Clear all votes for demo
# This script connects to the database instance and truncates the votes table

set -e

echo "🗑️  Database Reset Script"
echo "========================"
echo ""

# Database connection details
DB_HOST="10.0.2.115"
FRONTEND_IP="3.36.116.222"

echo "📊 Current vote count:"
ssh -o StrictHostKeyChecking=no -i ~/.ssh/voting-app-key.pem ubuntu@${FRONTEND_IP} \
  "ssh -o StrictHostKeyChecking=no ubuntu@${DB_HOST} 'docker exec -it postgres psql -U postgres -d postgres -t -c \"SELECT COUNT(*) FROM votes;\"'" 2>/dev/null || echo "Could not retrieve count"

echo ""
read -p "⚠️  Are you sure you want to DELETE ALL VOTES? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Reset cancelled"
    exit 0
fi

echo ""
echo "🔄 Clearing all votes..."

# Connect through bastion to database and truncate votes table
ssh -o StrictHostKeyChecking=no -i ~/.ssh/voting-app-key.pem ubuntu@${FRONTEND_IP} \
  "ssh -o StrictHostKeyChecking=no ubuntu@${DB_HOST} 'docker exec postgres psql -U postgres -d postgres -c \"TRUNCATE votes;\"'" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Database reset complete!"
    echo ""
    echo "📊 New vote count:"
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/voting-app-key.pem ubuntu@${FRONTEND_IP} \
      "ssh -o StrictHostKeyChecking=no ubuntu@${DB_HOST} 'docker exec -it postgres psql -U postgres -d postgres -t -c \"SELECT COUNT(*) FROM votes;\"'" 2>/dev/null

    echo ""
    echo "🎬 Ready for demo!"
else
    echo "❌ Reset failed"
    exit 1
fi
