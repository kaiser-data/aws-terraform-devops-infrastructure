# How to Convert Presentation to PDF

This guide explains how to convert the Marp presentation to a professional PDF.

---

## Method 1: Using Marp CLI (Recommended)

### Install Marp CLI

```bash
# Using npm (Node.js required)
npm install -g @marp-team/marp-cli

# Or using yarn
yarn global add @marp-team/marp-cli
```

### Convert to PDF

```bash
# Basic conversion (using built-in Gaia theme)
marp PRESENTATION.md --pdf

# With custom theme (more professional)
marp PRESENTATION.md --theme presentation-theme.css --pdf

# High quality PDF with custom size
marp PRESENTATION.md \
  --pdf \
  --allow-local-files \
  --theme presentation-theme.css \
  --pdf-outline
```

**Output:** `PRESENTATION.pdf` in the same directory

---

## Method 2: Using Marp for VS Code

### Install VS Code Extension

1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "Marp for VS Code"
4. Install the extension by Marp Team

### Export to PDF

1. Open `PRESENTATION.md` in VS Code
2. Open Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
3. Type "Marp: Export slide deck"
4. Choose "PDF" as format
5. Save the file

**Tip:** You can preview the presentation in VS Code before exporting!

---

## Method 3: Using Marp Web Interface

### Online Conversion

1. Go to https://web.marp.app/
2. Copy and paste the content of `PRESENTATION.md`
3. Click the export button (top right)
4. Select "PDF" format
5. Download the generated file

**Note:** Custom themes might not work in the web interface. Use CLI for best results.

---

## Method 4: Using Docker (No Installation Required)

### One-Command Conversion

```bash
# Run Marp in Docker container
docker run --rm -v $PWD:/home/marp/app/ marpteam/marp-cli \
  PRESENTATION.md \
  --pdf \
  --allow-local-files \
  --theme presentation-theme.css
```

**Output:** `PRESENTATION.pdf` in current directory

---

## Recommended Workflow

### Best Quality PDF:

```bash
# Step 1: Install Marp CLI (one time)
npm install -g @marp-team/marp-cli

# Step 2: Generate PDF with all features
cd /home/marty/ironhack/project_multistack_devops_app
marp PRESENTATION.md \
  --pdf \
  --allow-local-files \
  --theme presentation-theme.css \
  --pdf-outlines \
  --html
```

### What This Does:
- ✅ Creates professional PDF with custom theme
- ✅ Includes PDF bookmarks for navigation
- ✅ Enables HTML features in slides
- ✅ Allows local file references
- ✅ Maintains all formatting and code highlighting

---

## Customization Options

### Change Theme Colors

Edit `presentation-theme.css`:

```css
/* Change primary color from blue to green */
h1 {
  color: #1a365d;  /* Change this */
  border-bottom: 4px solid #3182ce;  /* And this */
}
```

### Change Presentation Size

Add to `PRESENTATION.md` header:

```markdown
---
marp: true
theme: gaia
size: 16:9    # or 4:3 for classic
---
```

### Add Custom Backgrounds

```markdown
---
<!-- _backgroundImage: url('your-image.jpg') -->
# Slide with Custom Background
---
```

---

## Tips for Best Results

### 1. Preview Before Export
```bash
# Start local server with auto-reload
marp PRESENTATION.md --server --watch
```
Open browser at http://localhost:8080

### 2. Check All Slides
- Ensure code blocks fit on slide
- Verify table formatting
- Test all links

### 3. Professional Touch
- Use consistent colors
- Limit text per slide
- Use visuals and diagrams
- Practice timing (15-20 minutes for this deck)

### 4. Print-Friendly Version
```bash
# Generate both PDF and HTML
marp PRESENTATION.md --pdf --html
```

---

## Troubleshooting

### Problem: "marp: command not found"

**Solution:**
```bash
# Check if npm is installed
node --version
npm --version

# Install globally
npm install -g @marp-team/marp-cli

# Verify installation
marp --version
```

### Problem: Custom theme not loading

**Solution:**
```bash
# Use absolute path to theme
marp PRESENTATION.md \
  --theme $(pwd)/presentation-theme.css \
  --pdf
```

### Problem: Code blocks cut off

**Solution:** Reduce font size in slides:
```markdown
<style scoped>
pre { font-size: 0.8em; }
</style>
```

### Problem: PDF too large

**Solution:**
```bash
# Compress PDF after generation
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
   -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH \
   -sOutputFile=PRESENTATION_compressed.pdf \
   PRESENTATION.pdf
```

---

## Final Checklist

Before your presentation:

- [ ] Convert to PDF successfully
- [ ] Review all slides for formatting
- [ ] Test on presentation computer/projector
- [ ] Have backup copy on USB drive
- [ ] Practice timing (aim for 15-20 minutes)
- [ ] Prepare for live demo
- [ ] Have monitoring URLs ready
- [ ] Test stress test script beforehand

---

## Quick Reference

### Generate PDF (Quick)
```bash
marp PRESENTATION.md --pdf
```

### Generate PDF (Professional)
```bash
marp PRESENTATION.md --pdf --theme presentation-theme.css --pdf-outlines
```

### Preview in Browser
```bash
marp PRESENTATION.md --server
```

### Export All Formats
```bash
marp PRESENTATION.md --pdf --html --pptx
```

---

## Additional Resources

- **Marp Documentation:** https://marpit.marp.app/
- **Marp CLI Guide:** https://github.com/marp-team/marp-cli
- **Theme Gallery:** https://github.com/marp-team/marp-core/tree/main/themes
- **VS Code Extension:** https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode

---

**Good luck with your presentation!** 🎤
