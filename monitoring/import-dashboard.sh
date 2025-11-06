#!/bin/bash
# Import Voting App Presentation Dashboard into Grafana

GRAFANA_URL="http://3.36.116.222:3000"
GRAFANA_USER="admin"
GRAFANA_PASS="admin"
DASHBOARD_FILE="grafana/dashboards/voting-app-presentation.json"

echo "🎨 Importing Voting App Presentation Dashboard..."

# First, add Prometheus datasource if not exists
echo "📊 Configuring Prometheus datasource..."
curl -X POST -H "Content-Type: application/json" \
  -u ${GRAFANA_USER}:${GRAFANA_PASS} \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://localhost:9090",
    "access":"proxy",
    "isDefault":true
  }' \
  ${GRAFANA_URL}/api/datasources 2>/dev/null

# Import dashboard
echo "📈 Importing dashboard..."
DASHBOARD_JSON=$(cat ${DASHBOARD_FILE})

curl -X POST -H "Content-Type: application/json" \
  -u ${GRAFANA_USER}:${GRAFANA_PASS} \
  -d "{
    \"dashboard\": ${DASHBOARD_JSON},
    \"overwrite\": true,
    \"message\": \"Imported presentation dashboard\"
  }" \
  ${GRAFANA_URL}/api/dashboards/db

echo ""
echo "✅ Dashboard imported successfully!"
echo ""
echo "🔗 Access your dashboard:"
echo "   ${GRAFANA_URL}/d/voting-app-demo/voting-app-presentation-dashboard"
echo ""
echo "📊 Credentials:"
echo "   Username: admin"
echo "   Password: admin"
