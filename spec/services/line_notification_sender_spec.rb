require 'rails_helper'

RSpec.describe LineNotificationSender do
  describe '.send_random_memo_to' do
    let(:user) { create(:user, :with_line_user) }
    let!(:book) { create(:book, title: "サンプル本", user: user) }
    let!(:memo) { create(:memo, book: book, user: user, content: "<p>テストメモの本文です。</p>") }

    let(:mock_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }

    before do
      allow(Line::Bot::V2::MessagingApi::ApiClient).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:push_message)
    end

    it 'LINEメッセージを1件送信する' do
      described_class.send_random_memo_to(user)

      expect(mock_client).to have_received(:push_message).once do |args|
        message = args[:push_message_request].messages.first.text

        expect(message).to include("今日のあなたのメモ")
        expect(message).to include("サンプル本")
        expect(message).to include("テストメモの本文")
        expect(message).to match(%r{https?://.+/books/\d+})
      end
    end
  end
end
