# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.3
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# 共通のシステムパッケージ + Node.js 追加
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    libjpeg62-turbo-dev \
    libpng-dev \
    libyaml-dev \
    libffi-dev \
    node-gyp \
    python-is-python3 \
    postgresql-client \
    gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

# ビルドステージ
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    pkg-config

# Node.js パッケージインストール
COPY package.json package-lock.json ./
RUN npm install

# Ruby Gem インストール
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# アプリ本体をコピー
COPY . .

# JSビルド（例: esbuild/tailwind等）
RUN npm run build

# bootsnapプリコンパイル（任意）
RUN bundle exec bootsnap precompile app/ lib/

# ❌ digest競合を避けるため削除
# RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# 実行ステージ
FROM base

# Gemとアプリ一式をコピー
COPY --from=build ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=build /rails /rails

# ✅ ここが重要！assets:precompile 済みのpublic/assetsを含める
COPY --from=build /rails/public/assets /rails/public/assets

# パーミッション整備
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp public/assets

# 非rootで実行
USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 8080
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]