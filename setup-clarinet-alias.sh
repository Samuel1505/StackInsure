#!/bin/bash
# Setup script to make clarinet check work correctly

echo "Setting up clarinet check alias..."

# Add to .bashrc if not already there
if ! grep -q "clarinet check" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# StackInsure: Fixed clarinet check" >> ~/.bashrc
    echo "alias clarinet='function _clarinet() { if [ \"\$1\" = \"check\" ] && [ -f ./clarinet-check-fixed ]; then ./clarinet-check-fixed \"\${@:2}\"; else /home/admin/.cargo/bin/clarinet \"\$@\"; fi; }; _clarinet'" >> ~/.bashrc
    echo "✓ Added alias to ~/.bashrc"
    echo "Run: source ~/.bashrc or restart terminal"
else
    echo "Alias already exists in ~/.bashrc"
fi

# Also create a local wrapper
cat > clarinet-local << 'WRAPPER'
#!/bin/bash
if [ "$1" = "check" ] && [ -f ./clarinet-check-fixed ]; then
    ./clarinet-check-fixed "${@:2}"
else
    /home/admin/.cargo/bin/clarinet "$@"
fi
WRAPPER
chmod +x clarinet-local
echo "✓ Created local clarinet wrapper: ./clarinet-local"
echo ""
echo "Usage options:"
echo "  1. Use the wrapper directly: ./clarinet-check-fixed"
echo "  2. Use local wrapper: ./clarinet-local check"
echo "  3. Source ~/.bashrc and use: clarinet check"
