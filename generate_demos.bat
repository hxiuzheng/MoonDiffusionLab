@echo off
mkdir assets 2>NUL
echo Generating HTML demo...
moon run cmd/export_html > assets/demo.html
echo Generating SVG demo...
moon run cmd/export_svg > assets/demo.svg
echo Demos generated successfully!
