#!/bin/bash

# Resolve token from argument or environment variable
if [ -n "$1" ]; then
  CLOUDFLARED_TOKEN="$1"
elif [ -n "$CLOUDFLARED_TOKEN" ]; then
  echo "No token argument provided, using \$CLOUDFLARED_TOKEN from environment."
else
  echo "Error: No cloudflared token provided." >&2
  echo "Usage: $0 <token>" >&2
  echo "   or: CLOUDFLARED_TOKEN=<token> $0" >&2
  exit 1
fi

# Add cloudflared.repo to /etc/yum.repos.d/
curl -fsSL https://pkg.cloudflare.com/cloudflared-ascii.repo | sudo tee /etc/yum.repos.d/cloudflared.repo

# Update repo
sudo yum update

# Install cloudflared
sudo yum install cloudflared

# Install as service
sudo cloudflared service install "$CLOUDFLARED_TOKEN"

# Or run manually
# cloudflared tunnel run --token "$CLOUDFLARED_TOKEN"
