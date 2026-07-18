@echo off
mkdir assets 2>NUL
echo Generating HTML demo...
moon run cmd/lab > assets/demo.html
echo Generating SVG demo...
moon run cmd/lab > assets/demo.svg
echo Demos generated successfully!
