#!/bin/bash
# Make all scripts executable

echo "Setting execute permissions for scripts..."

chmod +x setup.sh
chmod +x creds_setup.sh
chmod +x scripts/fence_setup.sh
chmod +x scripts/arborist_setup.sh

echo "✓ All scripts are now executable"
