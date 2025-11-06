#!/bin/bash
# Quick script to generate presentation PDF

set -e

echo "📊 Generating Presentation PDF..."
echo ""

# Check if marp is installed
if ! command -v marp &> /dev/null; then
    echo "❌ Marp CLI not found!"
    echo ""
    echo "Install it with:"
    echo "  npm install -g @marp-team/marp-cli"
    echo ""
    echo "Or use Docker:"
    echo "  docker run --rm -v \$PWD:/home/marp/app/ marpteam/marp-cli PRESENTATION.md --pdf"
    exit 1
fi

echo "✓ Marp CLI found"
echo ""

# Generate PDF with professional theme
echo "Generating PDF with custom theme..."
marp PRESENTATION.md \
  --pdf \
  --allow-local-files \
  --theme presentation-theme.css \
  --pdf-outlines \
  --html

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Success! PDF generated:"
    echo "   📄 PRESENTATION.pdf"
    echo ""

    # Show file size
    if [ -f "PRESENTATION.pdf" ]; then
        SIZE=$(du -h PRESENTATION.pdf | cut -f1)
        echo "   File size: $SIZE"
        PAGES=$(pdfinfo PRESENTATION.pdf 2>/dev/null | grep Pages | awk '{print $2}')
        if [ ! -z "$PAGES" ]; then
            echo "   Pages: $PAGES"
        fi
    fi

    echo ""
    echo "📁 Location: $(pwd)/PRESENTATION.pdf"
    echo ""
    echo "💡 Tips:"
    echo "   - Open with: xdg-open PRESENTATION.pdf"
    echo "   - Preview: marp PRESENTATION.md --server"
    echo "   - Print version: See PRESENTATION_HOWTO.md"
else
    echo ""
    echo "❌ Failed to generate PDF"
    echo "   Check PRESENTATION_HOWTO.md for troubleshooting"
    exit 1
fi
