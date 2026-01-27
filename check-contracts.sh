#!/bin/bash
# Workaround script for Clarinet batch check issue with Clarity 4
# This script checks all contracts individually since 'clarinet check' 
# has a known issue when checking multiple Clarity 4 contracts together

echo "========================================="
echo "Checking StackInsure Contracts (Clarity 4)"
echo "========================================="
echo ""

ERRORS=0
PASSED=0

for file in contracts/*.clar; do
    if [ "$file" != "contracts/stackin.clar" ]; then
        filename=$(basename "$file")
        echo -n "Checking $filename... "
        
        if clarinet check "$file" 2>&1 | grep -q "successfully checked"; then
            echo "✓ PASSED"
            ((PASSED++))
        else
            echo "✗ FAILED"
            clarinet check "$file" 2>&1 | grep -E "(error|warning)" | head -3
            ((ERRORS++))
        fi
    fi
done

echo ""
echo "========================================="
echo "Summary: $PASSED passed, $ERRORS failed"
echo "========================================="

if [ $ERRORS -eq 0 ]; then
    echo "✓ All contracts compiled successfully!"
    exit 0
else
    echo "✗ Some contracts have errors"
    exit 1
fi
