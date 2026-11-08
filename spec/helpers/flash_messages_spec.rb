require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  let(:messages) { ActionDispatch::Flash::FlashHash.new }

  before do
    allow(helper).to receive(:flash).and_return(messages)
  end

  it 'renders the supported tones with appropriate announcement roles' do
    %i[notice success info error alert warning].each { |type| messages[type] = "A #{type} message." }
    document = Nokogiri::HTML.fragment(helper.flash_messages(heritage: true))
    expect(document.css('.heritage-flash').length).to eq(6)
    %i[notice success info].each { |type| expect(document.at_css("#flash-#{type}")['role']).to eq('status') }
    %i[error alert warning].each { |type| expect(document.at_css("#flash-#{type}")['role']).to eq('alert') }
    expect(document.css('.flash, .gray-box-bg')).to be_empty
    expect(document.css('[aria-atomic="true"]').length).to eq(6)
  end

  it 'preserves actionable links and emphasis without rendering unsafe markup' do
    messages[:notice] = '<strong>Ready.</strong> <span>Five verses due.</span> <a href="/review" data-method="get" data-remote="true">Begin review</a><script>alert(1)</script><a href="javascript:alert(1)" onclick="alert(1)">Unsafe</a>'
    document = Nokogiri::HTML.fragment(helper.flash_messages(heritage: true))
    link = document.at_css('a[href="/review"]')
    expect(link['data-method']).to eq('get')
    expect(link['data-remote']).to eq('true')
    expect(document.at_css('strong').text).to eq('Ready.')
    expect(document.css('script, [onclick], a[href^="javascript:"]')).to be_empty
  end

  it 'omits empty messages and unrelated flash metadata' do
    messages[:notice] = ''
    messages[:timedout] = true
    expect(helper.flash_messages(heritage: true)).not_to include('heritage-flashes', 'timedout')
  end

  it 'retains the legacy rendering for layouts that do not opt into Heritage' do
    messages[:notice] = 'Saved.'
    document = Nokogiri::HTML.fragment(helper.flash_messages)
    expect(document.at_css('#flash-notice')['class']).to eq('flash gray-box-bg')
    expect(document.css('.heritage-flashes')).to be_empty
  end
end
