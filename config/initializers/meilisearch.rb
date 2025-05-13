Meilisearch::Rails.configuration = {
  meilisearch_url: ENV.fetch("MEILISEARCH_HOST"),
  meilisearch_api_key: ENV.fetch("MEILISEARCH_API_KEY")
}
