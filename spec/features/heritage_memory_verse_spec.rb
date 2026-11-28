require 'rails_helper'

RSpec.describe 'Heritage memory verse detail', type: :feature, js: true do
  around do |example|
    original = ENV['MEMVERSE_HERITAGE']
    ENV['MEMVERSE_HERITAGE'] = '1'
    example.run
  ensure
    ENV['MEMVERSE_HERITAGE'] = original
  end

  it 'shows the saved Scripture, navigates the collection, and lets its owner manage reviews and tags' do
    user = FactoryBot.create(:user, confirmed_at: Time.current)
    first, middle, last = (1..3).map do |number|
      verse = FactoryBot.create(:verse, chapter: 121, versenum: number, translation: 'KJV')
      FactoryBot.create(:memverse, verse: verse, user: user)
    end
    middle.verse.update_column(:text, 'My help cometh from the LORD, which made heaven and earth.')
    middle.verse.tag_list.add('Help')
    middle.verse.save!
    middle.update_columns(next_test: Date.new(2026, 12, 2), test_interval: 14, status: 'Learning')

    login_as(user, scope: :user)
    visit memory_verse_path(middle)
    expect(page).to have_css('h1', exact_text: 'Psalm 121:2')
    expect(page).to have_css('.verse-version', text: /King James Version/i)
    expect(find('.verse-scripture').text).to eq(middle.verse.text)
    expect(find('a[rel=prev]')[:href]).to end_with(memory_verse_path(first))
    expect(find('a[rel=next]')[:href]).to end_with(memory_verse_path(last))
    find('a[rel=next]').click
    expect(page).to have_css('h1', exact_text: 'Psalm 121:3')
    find('a[rel=prev]').click

    click_button 'Pause reviews'
    expect(page).to have_css('.verse-pill', text: 'Pending')
    expect(page).to have_css('dd', exact_text: 'Unscheduled')
    click_button 'Resume reviews'
    expect(page).to have_css('.verse-pill', text: 'Learning')
    expect(page).to have_css('dd', exact_text: 'Dec 2, 2026')

    find('button[aria-label="Add Help to your tags"]').click
    expect(page).to have_css('button[aria-label="Remove Help tag"]')
    find('.verse-tag-editor summary').click
    fill_in 'Tag name', with: 'trust'
    click_button 'Add tag'
    expect(page).to have_link('Trust', href: show_verses_with_tag_path(tag: 'Trust', tl: 'KJV'))
    accept_confirm { find('button[aria-label="Remove Trust tag"]').click }
    expect(page).to have_no_css('button[aria-label="Remove Trust tag"]')
    expect(middle.reload.tags.pluck(:name)).to eq(['Help'])

    browser = page.driver.browser
    [1200, 390].each do |width|
      browser.execute_cdp('Emulation.setDeviceMetricsOverride', width: width, height: 900, deviceScaleFactor: 1, mobile: false)
      left, right = page.evaluate_script("Array.from(document.querySelectorAll('.verse-panel'), el => el.getBoundingClientRect().left)")
      expect(right > left).to eq(width > 640)
      expect(page.evaluate_script("document.querySelector('.verse-folio').getBoundingClientRect().right <= innerWidth")).to be(true)
    end
  ensure
    browser&.execute_cdp('Emulation.clearDeviceMetricsOverride')
  end
end
