# syntax=docker/dockerfile:1

ARG RUBY_VERSION=4.0.1
# イメージのハッシュ固定（再現性・タグ書き換え対策）
FROM ruby:${RUBY_VERSION}-slim-trixie@sha256:24df04f7b0606fa2f83119ce2f5a16ef9b4242bec82268879b51488a4655ded2 AS base

WORKDIR /rails

# hadolint ignore=DL3008
# 全パッケージのバージョン固定は、Debian のセキュリティ更新時にビルドが壊れやすいため。
# 再現性はベースイメージ (ruby:4.0.1-slim-trixie) と同一 RUN 内の apt-get update で担保する。
# CVE-2025-15467 対策: セキュリティアップデートを適用してから他パッケージをインストールする。
RUN apt-get update -qq && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install --no-install-recommends -y \
    curl \
    libjemalloc2 \
    libvips \
    postgresql-client \
    gnupg && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test

FROM base AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
# 同上（base ステージのコメントを参照）
# CVE-2025-15467 対策: セキュリティアップデートを適用してから他パッケージをインストールする。
RUN apt-get update -qq && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libffi-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libyaml-dev \
    node-gyp \
    pkg-config \
    python-is-python3 && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y nodejs && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

COPY package.json package-lock.json ./
RUN npm install

COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v '~> 4.0' && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN ./bin/vite build && \
    bundle exec bootsnap precompile app/ lib/

FROM base

COPY --from=build ${BUNDLE_PATH} ${BUNDLE_PATH}
COPY --from=build /rails /rails

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp

USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 8080
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]
