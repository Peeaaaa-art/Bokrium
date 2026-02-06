# ReDoS 対策: 正規表現の実行時間を制限する（Ruby 3.2+）
# 悪意ある入力による長時間マッチを防ぎ、サービス停止を軽減する
# NOTE: タイムアウト時の例外 (Regexp::TimeoutError) は ApplicationController で安全に処理する
Regexp.timeout = 1
