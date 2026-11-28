require 'rails_helper'

RSpec.describe 'Heritage Add Verse', type: :feature, js: true do
  around do |example|
    original = ENV['MEMVERSE_HERITAGE']
    ENV['MEMVERSE_HERITAGE'] = '1'
    example.run
  ensure
    ENV['MEMVERSE_HERITAGE'] = original
  end

  it 'keeps the search in place while browsing results and saves a selected verse' do
    user = FactoryBot.create(:user, confirmed_at: Time.current, translation: 'NIV')
    verses = (1..12).map do |n|
      FactoryBot.create(:verse, book_index: 19, book: 'Psalms', chapter: 37, versenum: n, translation: 'NIV',
                        text: "Verse #{n} has enough words to wrap naturally on a narrow screen.")
    end
    login_as(user, scope: :user)
    visit add_verse_path
    expect(page).to have_field('Reference or words from a verse')
    expect(page).to have_no_link('Browse popular verses', exact: false)
    page.execute_script(<<~JS)
      const fetchOriginal = window.fetch.bind(window);
      const waitForRelease = new Promise(resolve => { window.releaseLookup = resolve; });
      window.fetch = async (url, options) => {
        if (String(url).startsWith('/lookup_passage.json')) await waitForRelease;
        return fetchOriginal(url, options);
      };
    JS
    fill_in 'Reference or words from a verse', with: 'Psalm 37:1–12'
    expect(page).to have_css('.av-search [data-searching] .av-translation-icon')
    expect(page.find('.av-search [role="status"]', visible: :all).text(:all)).to eq('Searching…')
    page.execute_script('window.releaseLookup()')
    expect(page).to have_css('h2#results-label', exact_text: '12 verses')
    expect(page).to have_no_css('.av-search [data-searching]')
    expect(page).to have_css('.av-verses article', count: 12)
    expect(find_field('Reference or words from a verse')[:placeholder]).to eq('Enter a reference or phrase')
    browser = page.driver.browser
    [1200, 390, 320].each do |width|
      browser.execute_cdp('Emulation.setDeviceMetricsOverride', width: width, height: 800, deviceScaleFactor: 1, mobile: false)
      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const list = document.querySelector('.av-verses');
          const input = document.querySelector('#verse-query');
          const top = input.getBoundingClientRect().top;
          const windowScroll = window.scrollY;
          list.scrollTop = list.scrollHeight;
          const end = list.lastElementChild.getBoundingClientRect().bottom;
          const scrolled = list.scrollTop > 0 && Math.abs(end - list.getBoundingClientRect().bottom) <= 2;
          list.scrollTop = 0;
          return scrolled && window.scrollY === windowScroll && input.getBoundingClientRect().top === top;
        })()
      JS
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
    expect(page).to have_css('h2#results-label', exact_text: '1 verse')
    expect(page).to have_css('.av-verses article .mv-add-status', text: 'In your verses')
  ensure
    browser&.execute_cdp('Emulation.clearDeviceMetricsOverride')
  end
end
