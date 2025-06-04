require 'rails_helper'

RSpec.describe BooksDisplaySetting do
  let(:defaults) { { shelf: 10, card: 6 } }

  describe 'view_mode: shelf' do
    let(:session) { {} }
    let(:params)  { { view: 'shelf', per: '12' } }

    it 'view_modeがshelfで、unit_per_pageがper値になる' do
      setting = described_class.new(session, params, defaults)

      expect(setting.view_mode).to eq('shelf')
      expect(setting.unit_per_page).to eq(12)
      expect(setting.books_per_shelf).to eq(12)
      expect(session[:view_mode]).to eq('shelf')
      expect(session[:shelf_per]).to eq('12')
    end
  end

  describe 'view_mode: card' do
    let(:session) { {} }
    let(:params)  { { view: 'card', column: '8' } }

    it 'view_modeがcardで、unit_per_pageがcolumn値になる' do
      setting = described_class.new(session, params, defaults)

      expect(setting.view_mode).to eq('card')
      expect(setting.unit_per_page).to eq(8)
      expect(setting.card_columns).to eq(8)
      expect(session[:view_mode]).to eq('card')
      expect(session[:card_columns]).to eq('8')
    end
  end

  describe 'paramsが空の場合' do
    let(:session) { {} }
    let(:params)  { {} }

    it 'view_modeはデフォルト(shelf)、unit_per_pageはdefaults[:shelf]になる' do
      setting = described_class.new(session, params, defaults)

      expect(setting.view_mode).to eq('shelf')
      expect(setting.unit_per_page).to eq(10)
      expect(setting.books_per_shelf).to eq(10)
    end
  end

  describe 'sessionが保持されている場合' do
    let(:session) { { view_mode: 'card', card_columns: '4' } }
    let(:params)  { {} }

    it 'sessionのview_mode/card_columnsが使われる' do
      setting = described_class.new(session, params, defaults)

      expect(setting.view_mode).to eq('card')
      expect(setting.unit_per_page).to eq(4)
      expect(setting.card_columns).to eq(4)
    end
  end
end
