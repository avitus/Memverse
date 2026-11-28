require 'rails_helper'

RSpec.describe 'Passage review word layout', type: :feature, js: true do
  it 'measures words against visible text in the current font and letter spacing' do
    login_as(FactoryBot.create(:user, confirmed_at: Time.current), scope: :user)
    visit learn_path
    practice = find('.blankified', visible: :all)
    samples = ['iiii', 'WWWW', '“Lord’s,”', 'AVATAR', '愛', '<&>', '']
    ['18px Georgia', 'italic bold 29.5px Georgia', '23px Arial'].each do |font|
      measurements = practice.evaluate_script(<<~JS, font, samples)
        (() => {
          this.style.font = arguments[0];
          this.style.letterSpacing = '-0.025em';
          const displayed = document.createElement('span');
          this.appendChild(displayed);
          const range = document.createRange();
          const rows = arguments[1].map(word => {
            displayed.textContent = word;
            range.selectNodeContents(displayed);
            return [word, range.getBoundingClientRect().width, word_width(word)];
          });
          displayed.remove();
          return rows;
        })()
      JS
      measurements.each do |word, rendered, measured|
        expect(measured).to be_within(0.05).of(rendered), "Width mismatch for #{word.inspect} in #{font}"
      end
      expect(measurements[1][1]).to be > measurements[0][1]
    end
  end

  it 'keeps each blank as wide as its answer and preserves word spacing through completion' do
    user = FactoryBot.create(:user, confirmed_at: Time.current)
    text = 'Willingly I will sing of lovingkindnesses, and the wilderness for us.'
    verse = FactoryBot.create(:verse, book: 'Psalms', chapter: 1, versenum: 1, text: text)
    FactoryBot.create(:memverse, user: user, verse: verse)
    login_as(user, scope: :user)
    visit passage_review_path

    words = find('.due-mv .full-text')
    expect(words).to have_css('input.blank-word', minimum: 3)
    # Make the text wrap and exercise a fractional font size after the blanks exist.
    words.execute_script("this.style.cssText = 'display: block; width: 136px; font-size: 23.5px'")
    verse_end = <<~JS
      (() => {
        const range = document.createRange();
        range.setStart(this.lastChild, this.lastChild.length - 3);
        range.setEnd(this.lastChild, this.lastChild.length);
        const rect = range.getBoundingClientRect();
        const verse = this.getBoundingClientRect();
        return [rect.left - verse.left, rect.top - verse.top];
      })()
    JS
    original_end = words.evaluate_script(verse_end)
    # Readers can select any blank. Start in the middle and then return to the first.
    blank = words.all('input.blank-word')[1]
    while blank
      word = blank[:name]
      width = blank.evaluate_script('this.getBoundingClientRect().width')
      rendered, measured, available = blank.evaluate_script(<<~JS)
        (function (parent, answer) {
          const probe = document.createElement('span');
          probe.style.position = 'absolute';
          probe.textContent = answer;
          parent.appendChild(probe);
          const width = probe.getBoundingClientRect().width;
          probe.remove();
          return [width, word_width(answer, parent), parent.getBoundingClientRect().width];
        })(this.closest('.full-text'), this.name)
      JS
      expect(measured).to be_within(0.05).of(rendered)
      expect(width).to be_within(0.1).of([rendered, available].min)
      blank.send_keys(word.sub(/\W+\z/, ''))
      expect(words.evaluate_script(verse_end)).to eq(original_end)
      blank = words.all('input.blank-word', minimum: 0, wait: 0).first
    end
    expect(words.evaluate_script('this.textContent')).to eq(text)
  end
end
