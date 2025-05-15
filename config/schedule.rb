# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

set :output, "log/cron.log"
set :environment, "development"
# rbenv を手動で初期化（超重要！）
env :PATH, "/Users/hayashiakira/.rbenv/shims:/Users/hayashiakira/.rbenv/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

# rbenvの初期化＋rails runner実行を定義
job_type :runner, %Q{cd :path && export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH" && eval "$(rbenv init - bash)" && bundle exec bin/rails runner -e :environment ':task' :output}

every 1.day, at: "9:00 am" do
  runner "LineNotificationSender.send_all"
end

# 1分おきにテスト
# every 1.minute do
#   runner "LineNotificationSender.send_all"
# end
