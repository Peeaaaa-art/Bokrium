if Rails.env.development?
  Rack::MiniProfiler.config.position = "right"
end
