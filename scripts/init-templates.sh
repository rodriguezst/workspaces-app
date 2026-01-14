#!/bin/bash
set -e

CODER_URL="${CODER_ACCESS_URL:-http://localhost:7080}"
TEMPLATES_DIR="/opt/coder-templates"

echo "============================================"
echo "  Coder Template Initialization"
echo "============================================"
echo ""

# Check if templates directory exists and has content

if [ ! -d "$TEMPLATES_DIR" ] || [ -z "$(ls -A $TEMPLATES_DIR 2>/dev/null)" ]; then
  echo "ERROR: No templates found in $TEMPLATES_DIR"
  exit 1
fi

# Check if user is already logged in

if ! coder users show me &>/dev/null; then
  echo "ERROR: You must be logged in to push templates."
  echo ""
  echo "Run  coder login $CODER_URL"
  echo ""
  exit 1
fi

echo "Logged in as:"
echo "$(coder users show me)"
echo ""

# Push each template

for template_dir in "$TEMPLATES_DIR"/*/; do
  if [ -d "$template_dir" ]; then
    template_name=$(basename "$template_dir")
    echo "––––––––––––––––––––"
    echo "Pushing template: $template_name"
    echo "––––––––––––––––––––"

    coder templates push "$template_name" -d "$template_dir" --yes

    echo "✓ Template '$template_name' pushed successfully"
    echo ""
  fi
done

echo "============================================"
echo "  All templates initialized!"
echo "============================================"
echo ""

