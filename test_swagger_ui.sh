#!/bin/bash

echo "Testing Swagger UI..."
echo

# Test 1: Check if page loads
echo "1. Testing if /api page loads..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Page loads successfully (HTTP $HTTP_CODE)"
else
    echo "✗ Page failed to load (HTTP $HTTP_CODE)"
    exit 1
fi

# Test 2: Check if apidocs.json has no malformed schemas
echo
echo "2. Checking for malformed schemas..."
HAS_RESPONSE_WRAPPER=$(curl -s http://localhost:3000/apidocs.json | grep -c "ResponseWrapper" || true)
if [ "$HAS_RESPONSE_WRAPPER" = "0" ]; then
    echo "✓ No ResponseWrapper or CollectionResponseWrapper found"
else
    echo "✗ Still has ResponseWrapper schemas"
    exit 1
fi

# Test 3: Check all $refs are valid
echo
echo "3. Validating all schema references..."
curl -s http://localhost:3000/apidocs.json | jq -r '.. | objects | select(has("$ref")) | ."$ref"' | sed 's|#/definitions/||' | sort -u > /tmp/refs.txt
curl -s http://localhost:3000/apidocs.json | jq -r '.definitions | keys[]' | sort > /tmp/defs.txt
MISSING=$(comm -23 /tmp/refs.txt /tmp/defs.txt)
if [ -z "$MISSING" ]; then
    echo "✓ All schema references are valid"
else
    echo "✗ Missing definitions:"
    echo "$MISSING"
    exit 1
fi

# Test 4: Check for objects without properties or $ref
echo
echo "4. Checking for invalid object definitions..."
INVALID=$(curl -s http://localhost:3000/apidocs.json | jq -r '.definitions | to_entries[] | .key as $def | .value.properties | to_entries[] | select(.value.type == "object" and (.value.properties | not) and (.value."$ref" | not) and (.value.additionalProperties | not)) | "\($def).\(.key)"' 2>/dev/null || true)
if [ -z "$INVALID" ]; then
    echo "✓ No invalid object definitions found"
else
    echo "✗ Found invalid object definitions:"
    echo "$INVALID"
    exit 1
fi

echo
echo "✓ All checks passed! Swagger UI should work now."
