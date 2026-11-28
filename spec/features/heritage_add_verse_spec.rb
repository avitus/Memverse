require 'rails_helper'

RSpec.describe 'Heritage Add Verse', type: :feature, js: true do
  around do |example|
    original = ENV['MEMVERSE_HERITAGE']
    ENV['MEMVERSE_HERITAGE'] = '1'
    example.run
  ensure
    ENV['MEMVERSE_HERITAGE'] = original
  end

  it 'places each real add action beside its reference and persists the selected verse' do
    user = FactoryBot.create(:user, confirmed_at: Time.current, translation: 'NIV')
    verses = (1..2).map do |n|
      FactoryBot.create(:verse, book_index: 19, book: 'Psalms', chapter: 37, versenum: n, translation: 'NIV',
                        text: "Verse #{n} has enough words to wrap naturally on a narrow screen.")
    end
    login_as(user, scope: :user)
    visit add_verse_path
    fill_in 'Reference or words from a verse', with: 'Psalm 37:1–2'
    expect(page).to have_css('.av-verses article', count: 2)
    browser = page.driver.browser
    [1200, 390, 320].each do |width|
      browser.execute_cdp('Emulation.setDeviceMetricsOverride', width: width, height: 800, deviceScaleFactor: 1, mobile: false)
      expect(page.evaluate_script(<<~JS)).to be(true)
        Array.from(document.querySelectorAll('.av-verses article')).every(article => {
          const button = article.querySelector('button'), style = getComputedStyle(button);
          const action = button.getBoundingClientRect(), text = article.querySelector('p').getBoundingClientRect();
          const ref = article.querySelector('h3').getBoundingClientRect();
          return action.left > ref.right && Math.abs(action.right - text.right) < 2 && action.bottom <= text.top &&
            action.height >= 44 && style.borderTopWidth === '1px' && style.borderRadius === '4px' &&
            style.color === 'rgb(152, 81, 47)' && text.right <= innerWidth;
        })
      JS
    end
    first('.av-verses article').find_button('+ Add verse').click
    expect(first('.av-verses article')).to have_text('✓ In your verses')
    expect(user.memverses.pluck(:verse_id)).to eq([verses.first.id])
    visit add_verse_path
    fill_in 'Reference or words from a verse', with: 'Psalm 37:1'
    expect(page).to have_css('.av-verses article .mv-add-status', text: 'In your verses')
  ensure
    browser&.execute_cdp('Emulation.clearDeviceMetricsOverride')
  end
end
