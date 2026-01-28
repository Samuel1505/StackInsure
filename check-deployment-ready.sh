#!/bin/bash
echo "=== Checking All Contracts for Deployment ==="
echo ""
ERRORS=0
for file in contracts/*.clar; do
    if [ "$file" != "contracts/stackin.clar" ]; then
        name=$(basename "$file")
        echo -n "Checking $name... "
        result=$(clarinet check "$file" 2>&1)
        if echo "$result" | grep -q "successfully checked"; then
            # Check for critical errors (not just warnings)
            if echo "$result" | grep -q "^error:"; then
                echo "✗ HAS ERRORS"
                echo "$result" | grep "^error:" | head -3
                ((ERRORS++))
            else
                echo "✓ READY"
            fi
        else
            echo "✗ FAILED"
            echo "$result" | grep -E "(error|failed)" | head -3
            ((ERRORS++))
        fi
    fi
done
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✓ All contracts are ready for deployment!"
    exit 0
else
    echo "✗ $ERRORS contract(s) have errors"
    exit 1
fi
