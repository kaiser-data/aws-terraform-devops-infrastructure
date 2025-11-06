#!/bin/bash
# Simple Database Reset - Direct command

echo "🗑️  Resetting Database..."
echo ""

# Direct connection using Ansible inventory
cd /home/marty/ironhack/project_multistack_devops_app/ansible

# Get current count
echo "📊 Current vote count:"
ansible database -i inventory/hosts.yml -m shell -a "docker exec postgres psql -U postgres -d postgres -t -c 'SELECT COUNT(*) FROM votes;'" 2>/dev/null | grep -v "SUCCESS" | tr -d ' '

echo ""
echo "🔄 Truncating votes table..."

# Truncate the table
ansible database -i inventory/hosts.yml -m shell -a "docker exec postgres psql -U postgres -d postgres -c 'TRUNCATE votes;'" 2>/dev/null

echo ""
echo "✅ Database reset complete!"
echo ""

# Get new count
echo "📊 New vote count:"
ansible database -i inventory/hosts.yml -m shell -a "docker exec postgres psql -U postgres -d postgres -t -c 'SELECT COUNT(*) FROM votes;'" 2>/dev/null | grep -v "SUCCESS" | tr -d ' '

echo ""
echo "🎬 Ready for demo!"
