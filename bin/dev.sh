#!/usr/bin/env sh

if ! command -v foreman >/dev/null 2>&1; then
  echo "Installing foreman..."
  gem install foreman
fi

exec foreman start -f Procfile.dev "$@"