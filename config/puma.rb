threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

if defined?(Rails) && Rails.env.development? && ENV["USE_SSL"] == "true"
  key_path  = File.expand_path("~/ssl-dev/localhost.key")
  cert_path = File.expand_path("~/ssl-dev/localhost.crt")

  if File.exist?(key_path) && File.exist?(cert_path)
    ssl_bind "0.0.0.0", "3000", {
      key: key_path,
      cert: cert_path
    }
  end
else
  port ENV.fetch("PORT", 3000)
end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
