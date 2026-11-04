require 'rails_helper'

RSpec.describe QuizQuestion, '#grade_answer' do
  context 'with a multiple choice question' do
    let(:question) { described_class.new(question_type: 'mcq', mc_answer: 'B') }

    it 'gives 10 points for the right option in either case' do
      expect(question.grade_answer('B')).to eq(10)
      expect(question.grade_answer(' b ')).to eq(10)
    end

    it 'gives nothing for a wrong or empty option' do
      expect(question.grade_answer('a')).to eq(0)
      expect(question.grade_answer('')).to eq(0)
      expect(question.grade_answer(nil)).to eq(0)
    end
  end

  context 'with a reference question' do
    let(:question) { described_class.new(question_type: 'reference', passage: 'Psalm 23:1') }

    it 'gives 10 points for the exact reference, ignoring case and spacing' do
      expect(question.grade_answer('psalm   23:1')).to eq(10)
    end

    it 'treats Psalm and Psalms as the same book' do
      expect(question.grade_answer('Psalms 23:1')).to eq(10)
    end

    it 'gives partial credit for book, chapter and verse' do
      expect(question.grade_answer('Psalm 1:9')).to eq(2)
      expect(question.grade_answer('Genesis 23:9')).to eq(3)
      expect(question.grade_answer('Genesis 9:1')).to eq(5)
    end

    it 'gives nothing for an answer that is not a reference' do
      expect(question.grade_answer('the shepherd psalm')).to eq(0)
      expect(question.grade_answer('')).to eq(0)
    end
  end

  context 'with a recitation question' do
    let(:question) { described_class.new(question_type: 'recitation', passage: 'John 11:35') }

    before do
      allow(question).to receive(:passage_translations).and_return(
        'NIV' => 'Jesus wept.',
        'KJV' => 'Jesus wept, and the people saw.'
      )
    end

    it 'gives 10 points for a perfect recitation, ignoring case and punctuation' do
      expect(question.grade_answer('JESUS WEPT', translation: 'NIV')).to eq(10)
    end

    it 'grades against the translation of the user' do
      expect(question.grade_answer('Jesus wept and the people saw', translation: 'KJV')).to eq(10)
      expect(question.grade_answer('Jesus wept', translation: 'KJV')).to eq(6)
    end

    it 'takes off one point per word wrong and never goes below zero' do
      expect(question.grade_answer('Jesus cried', translation: 'NIV')).to eq(9)
      expect(question.grade_answer(('word ' * 40).strip, translation: 'NIV')).to eq(0)
    end

    it 'gives nothing for an empty answer' do
      expect(question.grade_answer('   ', translation: 'NIV')).to eq(0)
    end

    it 'gives nothing when the translation has no text to compare' do
      expect(question.grade_answer('Jesus wept', translation: 'XXX')).to eq(0)
    end
  end
end
