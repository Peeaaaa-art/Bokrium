set :output, "log/cron.log"
set :environment, "development"

env :PATH, "/Users/hayashiakira/.rbenv/shims:/Users/hayashiakira/.rbenv/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

job_type :runner, %Q{cd :path && export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH" && eval "$(rbenv init - bash)" && bundle exec bin/rails runner -e :environment ':task' :output}

every 1.day, at: "9:00 am" do
  runner "LineNotificationSender.send_all"
end

# 1分おきにテスト
# every 1.minute do
#   runner "LineNotificationSender.send_all"
# end
