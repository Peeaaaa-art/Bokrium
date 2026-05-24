# AGENTS.md

## Development Environment

This project is developed with Docker Compose.

- Use the `web` service for normal development tasks.
- Use the `web-test` service for RSpec.
- Do not run RSpec through `docker compose exec web ...`; the `web` service runs with `RAILS_ENV=development`, which can cause local-only failures such as Host Authorization errors and Vite dev-server proxy errors.

Common development commands:

```sh
docker compose up web
docker compose run --rm web bundle exec rails db:migrate
docker compose run --rm web bundle exec rails console
```

## RSpec

Run tests through `web-test`. This service sets the test environment and runs the same preparation steps needed locally:

- `RAILS_ENV=test`
- `RACK_ENV=test`
- `NODE_ENV=test`
- `VITE_RUBY_ENV=test`
- `APP_HOST=http://localhost:3000`
- `bin/vite build --clear --mode=test`
- `bin/rails db:prepare`

Examples:

```sh
docker compose run --rm web-test
docker compose run --rm web-test bundle exec rspec
docker compose run --rm web-test bundle exec rspec spec/models/memo_spec.rb
docker compose run --rm web-test bundle exec rspec spec/requests/pages_spec.rb
```

For faster repeated runs after the test assets and database are already prepared, skip the preparation step:

```sh
docker compose run --rm -e SKIP_TEST_PREPARE=1 web-test bundle exec rspec spec/models/memo_spec.rb
```
