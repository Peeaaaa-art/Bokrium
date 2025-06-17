threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# if defined?(Rails) && Rails.env.development? && ENV["USE_SSL"] == "true"
#   key_path  = File.expand_path("~/ssl-dev/localhost.key")
#   cert_path = File.expand_path("~/ssl-dev/localhost.crt")

#   if File.exist?(key_path) && File.exist?(cert_path)
#     ssl_bind "0.0.0.0", "3000", {
#       key: key_path,
#       cert: cert_path
#     }
#   end
# else
#   port ENV.fetch("PORT", 8080)
#   bind "tcp://0.0.0.0:#{ENV.fetch("PORT", 8080)}"  # ★ 追加：Fly の警告を抑止するため
# end

port ENV.fetch("PORT")

plugin :tmp_restart
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
