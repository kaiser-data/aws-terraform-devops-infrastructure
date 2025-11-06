#!/bin/bash
# Quick check of vote distribution

echo "📊 Vote Distribution:"
echo ""

ansible database -i /home/marty/ironhack/project_multistack_devops_app/ansible/inventory/hosts.yml \
  -m shell \
  -a "docker exec postgres psql -U postgres -d postgres -t -c \"SELECT vote, COUNT(*) FROM votes GROUP BY vote ORDER BY vote;\"" \
  2>/dev/null | grep -v "SUCCESS\|CHANGED" | grep -E "^\s*(a|b)" | while read line; do
    vote=$(echo "$line" | awk '{print $1}')
    count=$(echo "$line" | awk '{print $2}')

    if [ "$vote" = "a" ]; then
      echo "🐱 Cats: $count"
    elif [ "$vote" = "b" ]; then
      echo "🐶 Dogs: $count"
    fi
  done

echo ""
echo "Total:"
ansible database -i /home/marty/ironhack/project_multistack_devops_app/ansible/inventory/hosts.yml \
  -m shell \
  -a "docker exec postgres psql -U postgres -d postgres -t -c \"SELECT COUNT(*) FROM votes;\"" \
  2>/dev/null | grep -v "SUCCESS\|CHANGED" | tr -d ' ' | grep -E "^[0-9]+" | head -1
