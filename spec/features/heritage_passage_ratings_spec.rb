require 'rails_helper'

RSpec.describe 'Heritage passage review', type: :feature, js: true do
  around do |example|
    original = ENV['MEMVERSE_HERITAGE']
    ENV['MEMVERSE_HERITAGE'] = '1'
    example.run
  ensure
    ENV['MEMVERSE_HERITAGE'] = original
  end

  it 'hands focus to an offscreen blank without scrolling the word just typed' do
    user = FactoryBot.create(:user, confirmed_at: Time.current)
    verse = FactoryBot.create(:verse, book: 'Romans', chapter: 8, versenum: 1,
                              text: 'Wilderness by a river with thanksgiving.')
    FactoryBot.create(:memverse, user: user, verse: verse)
    login_as(user, scope: :user)
    visit passage_review_path
    first_blank, second_blank = all('.heritage-review-verse input.blank-word', minimum: 2)

    # Put the first blank at the bottom of the viewport with the next on a wrapped line.
    first_blank.execute_script(<<~JS)
      const paragraph = this.closest('p');
      paragraph.style.cssText = 'padding: 0; width: 155px; margin-top: 100vh';
      window.scrollBy({ top: this.getBoundingClientRect().bottom - innerHeight + 3, behavior: 'instant' });
      this.focus({ preventScroll: true });
    JS
    expect(second_blank.evaluate_script('this.getBoundingClientRect().top >= innerHeight')).to be(true)
    first_blank.send_keys('Wilder')
    scroll_position = page.evaluate_script('scrollY')
    first_blank.send_keys('ness')
    expect(page).to have_css('input[name="thanksgiving."]:focus')
    expect(page.evaluate_script('scrollY')).to eq(scroll_position)
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
    original_size = page.current_window.size
    page.current_window.resize_to(390, 800)
    find('.heritage-reading-settings summary').click
    select 'Large', from: 'passage-reading-size'
    find('.heritage-reading-settings summary').click
    first_verse, next_verse = all('.heritage-review-verse')
    next_number = next_verse.find('.versenum')
    # Smooth navigation is for passage changes. A completed word, including
    # the last one, must keep its ink and the surrounding text in the viewport.
    glyph_position = <<~JS
      (() => {
        const range = document.createRange();
        range.setStart(this.firstChild, 0);
        range.setEnd(this.firstChild, 1);
        const rect = range.getBoundingClientRect();
        return [rect.x, rect.y];
      })()
    JS
    position = '[this.offsetLeft, this.offsetTop]'
    next_position = next_number.evaluate_script(position)
    while (blank = first_verse.all('input.blank-word', minimum: 0, wait: 0).first)
      word = blank[:name].sub(/\W+\z/, '')
      ink = blank.find(:xpath, 'preceding-sibling::span', visible: :all)
      blank.send_keys(word[0])
      typed_position = ink.evaluate_script(glyph_position)
      following_position = next_number.evaluate_script('this.getBoundingClientRect().y')
      blank.send_keys(word[1..])
      expect(ink.evaluate_script(glyph_position)).to eq(typed_position)
      expect(next_number.evaluate_script('this.getBoundingClientRect().y')).to eq(following_position)
      expect(next_number.evaluate_script(position)).to eq(next_position)
    end
    expect(page.evaluate_script('document.activeElement.getAttribute("aria-label")')).to eq('Verse 1, 1 of 5, Forgot')
    expect(first_verse.find('.full-text').evaluate_script('this.textContent')).to eq('1A short passage for reading.')
    first_verse.find('button[aria-label="Verse 1, 4 of 5, Good"]').click
    chip = first_verse.find('button[aria-label="Verse 1, rated 4. Change rating"]')
    chip.click
    first_verse.find('button[aria-label="Verse 1, 3 of 5, Fair"]').click
    expect(first_verse).to have_css('button[aria-label="Verse 1, rated 3. Change rating"]')
    expect(page).to have_text('1 of 2 verses rated')
    expect(verses.first.reload.attempts).to eq(1)
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
