
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT", 3000)

# localhostのHTTPS化
# if ENV["USE_SSL"] == "true" &&
#   File.exist?(File.expand_path("~/ssl-dev/localhost.key")) &&
#   File.exist?(File.expand_path("~/ssl-dev/localhost.crt"))

#  ssl_bind '0.0.0.0', '3000', {
#    key: File.expand_path("~/ssl-dev/localhost.key"),
#    cert: File.expand_path("~/ssl-dev/localhost.crt")
#  }
# end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Run the Solid Queue supervisor inside of Puma for single-server deployments
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# Specify the PID file. Defaults to tmp/pids/server.pid in development.
# In other environments, only set the PID file if requested.
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]


