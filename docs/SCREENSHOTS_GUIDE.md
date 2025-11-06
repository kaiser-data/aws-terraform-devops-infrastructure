# Screenshots Guide for Portfolio Presentation

This guide helps you capture and organize screenshots for portfolio presentation.

## 📸 Required Screenshots

### 1. Infrastructure Diagram (✅ Created)
**File**: `docs/screenshots/infrastructure-diagram.drawio`
- ✅ Already created as draw.io file
- Open with https://app.diagrams.net/
- Export as PNG: `infrastructure-diagram.png`

**What to show**:
- VPC with public/private subnets
- 3 EC2 instances (Frontend, Backend, Database)
- Internet Gateway, NAT Gateway
- CloudWatch monitoring connections
- Security group boundaries

---

### 2. Presentation Slide
**File**: `docs/screenshots/presentation-slide.png`

**How to capture**:
```bash
cd presentation/
# Option 1: Export PDF, then screenshot one slide
marp PRESENTATION.md --pdf

# Option 2: Present in browser and screenshot
marp PRESENTATION.md --preview
```

**Recommended slide to capture**:
- Slide 3: "AWS Architecture Overview" (shows complete diagram)
- OR Slide 11: "Monitoring Architecture" (shows Prometheus/Grafana)

---

### 3. Grafana Dashboard
**File**: `docs/screenshots/grafana-dashboard.png`

**How to capture**:
```bash
# 1. Ensure Grafana is running
curl http://<FRONTEND_IP>:3000

# 2. Open in browser
# Navigate to: http://<FRONTEND_IP>:3000
# Login: admin / admin (or your password)

# 3. Open dashboard: "Voting App Infrastructure Metrics"
# 4. Take full-screen screenshot showing:
#    - All 3 instances (Frontend, Backend, Database)
#    - CPU usage graphs
#    - Memory usage graphs
#    - Network traffic
#    - Time range: Last 15 minutes or 1 hour
```

**Best practices**:
- Use dark theme for professional look
- Show live data with recent timestamps
- Include legend and time range
- Capture during/after stress test for activity

---

### 4. Stress Test Terminal
**File**: `docs/screenshots/stress-test-terminal.png`

**How to capture**:
```bash
# 1. Prepare terminals side-by-side
Terminal 1: Stress test script
Terminal 2: Result app (watch votes increase)

# 2. Run stress test
cd monitoring/
./quick-stress.sh 1000 40

# 3. While running, screenshot showing:
#    - Terminal with scrolling dots (vote submissions)
#    - Progress counter
#    - Final statistics (duration, rate)
#    - Optional: Split screen with Result App showing votes

# 4. Capture when it shows:
#    - "✓ Completed 1000 votes in XX seconds"
#    - "Rate: 40+ votes per second"
```

**Alternative - Combined screenshot**:
```bash
# Split terminal into 3 panes:
# Left: Stress test running
# Top-right: Vote app (curl loop)
# Bottom-right: Result app (curl loop showing vote count)

# This shows end-to-end real-time processing!
```

---

### 5. Application Demo (Optional but Recommended)
**File**: `docs/screenshots/app-voting-demo.png`

**How to capture**:
```bash
# Option 1: Browser side-by-side
# Left half: Vote App (http://<FRONTEND_IP>)
# Right half: Result App (http://<FRONTEND_IP>:5001)

# Option 2: Sequential screenshots
# Screenshot 1: Vote App with "Cats vs Dogs" buttons
# Screenshot 2: Result App showing live percentages
```

**What to show**:
- Clean UI
- Vote options (Cats/Dogs with icons)
- Result percentages updating
- Vote count totals

---

## 🎨 Screenshot Best Practices

### Quality Standards
- **Resolution**: Minimum 1920x1080
- **Format**: PNG (lossless)
- **Clarity**: Clear text, no blur
- **Cropping**: Remove unnecessary borders/toolbars

### Professionalism
- ✅ Clean desktop (close unrelated apps)
- ✅ Dark theme for terminal/code
- ✅ Remove personal/sensitive info
- ✅ Focus on relevant content
- ❌ Avoid desktop clutter
- ❌ No notification popups
- ❌ No exposed IP addresses (use placeholders if needed)

### Tools
**Linux Screenshot Tools**:
- `gnome-screenshot` (full screen or selection)
- `flameshot` (annotation features)
- `spectacle` (KDE)

**Browser Tools**:
- Firefox: Shift+F2 → "screenshot --fullpage"
- Chrome: DevTools → Cmd/Ctrl+Shift+P → "Capture full size screenshot"

---

## 📝 Filename Conventions

Use descriptive, lowercase names with hyphens:
```
✅ infrastructure-diagram.png
✅ grafana-dashboard-metrics.png
✅ stress-test-terminal-1000votes.png
✅ voting-app-cats-vs-dogs.png

❌ Screenshot 2024-11-06.png
❌ IMG_1234.png
❌ Untitled.png
```

---

## 🔄 Integration Steps

### After Capturing Screenshots

1. **Save to directory**:
```bash
mv ~/Downloads/screenshot.png docs/screenshots/grafana-dashboard.png
```

2. **Verify image quality**:
```bash
file docs/screenshots/grafana-dashboard.png
# Should show: PNG image data, 1920 x 1080 or similar
```

3. **Update README references** (if needed):
```markdown
![Grafana Dashboard](docs/screenshots/grafana-dashboard.png)
```

4. **Commit**:
```bash
git add docs/screenshots/
git commit -m "Add Grafana dashboard and stress test screenshots"
git push
```

---

## 📊 Export Draw.io Diagram

### To PNG (for embedding in docs)
1. Open `infrastructure-diagram.drawio` in https://app.diagrams.net/
2. File → Export As → PNG
3. Settings:
   - ✅ Transparent background: No
   - ✅ Border width: 10
   - ✅ Scale: 100%
4. Save as `infrastructure-diagram.png`

### To SVG (for high-quality scaling)
1. File → Export As → SVG
2. Save as `infrastructure-diagram.svg`

---

## 🎯 Portfolio Impact

These screenshots demonstrate:
- ✅ **Infrastructure Design** - Professional AWS architecture
- ✅ **Monitoring Expertise** - Grafana/Prometheus setup
- ✅ **Performance Testing** - Load testing capabilities
- ✅ **End-to-End Functionality** - Working application
- ✅ **Presentation Skills** - Professional slide deck

**Result**: Complete visual story for recruiters and hiring managers!

---

## 📍 Current Status

| Screenshot | Status | Priority | Details |
|------------|--------|----------|---------|
| Infrastructure Diagram | ✅ Complete (draw.io) | High | Professional AWS architecture |
| Grafana Dashboard | ✅ Complete | High | 188KB, 1673×853, monitoring metrics |
| Stress Test + Results | ✅ Complete | High | 117KB, 1853×1041, combined demo |
| Terraform Destroy | ✅ Complete | High | 313KB, 1209×1345, 29 resources |
| Presentation Slide | ⏳ Optional | Medium | Can export from Marp presentation |

**Status**: All critical screenshots captured! ✅

**Portfolio Impact**:
- Visual proof of working infrastructure
- Live monitoring capabilities demonstrated
- Load testing performance validated
- Complete automation lifecycle shown
