#!/bin/bash
# Workaround script to check all contracts individually
echo "Checking all contracts individually..."
for file in contracts/*.clar; do
    if [ "$file" != "contracts/stackin.clar" ]; then
        echo -n "Checking $(basename $file)... "
        if clarinet check "$file" 2>&1 | grep -q "successfully checked"; then
            echo "✓ OK"
        else
            echo "✗ FAILED"
            clarinet check "$file" 2>&1 | grep error
        fi
    fi
done
echo "Done!"
