require 'rails_helper'

RSpec.describe 'Heritage passage review', type: :feature, js: true do
  around do |example|
    original = ENV['MEMVERSE_HERITAGE']
    ENV['MEMVERSE_HERITAGE'] = '1'
    example.run
  ensure
    ENV['MEMVERSE_HERITAGE'] = original
  end

  it 'keeps the paragraph intact while a completed verse is rated and edited in its margin' do
    user = FactoryBot.create(:user, confirmed_at: Time.current)
    verses = (1..2).map do |number|
      verse = FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: number, text: 'A short passage for reading.')
      FactoryBot.create(:memverse, user: user, verse: verse)
    end
    login_as(user, scope: :user)
    visit passage_review_path
    expect(page).to have_css('.reading-paragraph .heritage-review-verse', count: 2)
    expect(page).to have_no_css('.rating-options', visible: true)
    first_verse = all('.heritage-review-verse').first
    while (blank = first_verse.all('input.blank-word', minimum: 0, wait: 0).first)
      blank.send_keys(blank[:name])
    end
    first_verse.find('button[aria-label="Verse 1, 4 of 5, Good"]').click
    chip = first_verse.find('button[aria-label="Verse 1, rated 4. Change rating"]')
    chip.click
    first_verse.find('button[aria-label="Verse 1, 3 of 5, Fair"]').click
    expect(first_verse).to have_css('button[aria-label="Verse 1, rated 3. Change rating"]')
    expect(page).to have_text('1 of 2 verses rated')
    expect(verses.first.reload.attempts).to eq(1)
    original_size = page.current_window.size
    [1280, 390, 320].each do |width|
      page.current_window.resize_to(width, 800)
      expect(page.evaluate_script(<<~JS)).to be(true)
        (() => {
          const rect = selector => document.querySelector(selector).getBoundingClientRect();
          const heading = rect('.heritage-passage-heading'), p = rect('.reading-paragraph');
          const textEnd = p.right - parseFloat(getComputedStyle(document.querySelector('.reading-paragraph')).paddingRight);
          const chip = rect('.saved-grade'), anchor = rect('.verse-end');
          return Math.abs((heading.left + heading.right - p.left - textEnd) / 2) < 2 &&
            chip.left > textEnd && Math.abs(chip.y + chip.height / 2 - anchor.top) < 18 &&
            chip.right <= innerWidth && document.documentElement.scrollWidth <= innerWidth;
        })()
      JS
    end
  ensure
    page.current_window.resize_to(*original_size) if original_size
  end
end
