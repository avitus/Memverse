# encoding: utf-8
require 'rails_helper'

describe QuizQuestion do
  describe "#update_difficulty" do
    it "should update the difficulty after a quiz" do
      qq = FactoryBot.create(:quiz_question, :times_answered => 10, :perc_correct => 50)
      qq.update_difficulty(10, 100)  # answer count, percentage_correct
      qq.reload
      expect(qq.times_answered).to eq(20)
      expect(qq.perc_correct).to eq(75.0)
    end

    it "should handle first time answers correctly" do
      qq = FactoryBot.create(:quiz_question, :times_answered => 0, :perc_correct => 50)
      qq.update_difficulty(5, 80)  # 5 people answered, 80% correct
      qq.reload
      expect(qq.times_answered).to eq(5)
      expect(qq.perc_correct).to eq(80.0)
    end

    it "should calculate weighted average correctly" do
      qq = FactoryBot.create(:quiz_question, :times_answered => 100, :perc_correct => 60)
      # 100 previous answers at 60% correct = 6000 points
      # 20 new answers at 90% correct = 1800 points
      # Total: 7800 points / 120 answers = 65%
      qq.update_difficulty(20, 90)
      qq.reload
      expect(qq.times_answered).to eq(120)
      expect(qq.perc_correct).to eq(65.0)
    end

    it "should handle zero percent correct" do
      qq = FactoryBot.create(:quiz_question, :times_answered => 10, :perc_correct => 80)
      qq.update_difficulty(10, 0)  # Everyone got it wrong
      qq.reload
      expect(qq.times_answered).to eq(20)
      expect(qq.perc_correct).to eq(40.0)  # (10*80 + 10*0) / 20 = 40
    end

    it "should handle edge case of zero new answers" do
      qq = FactoryBot.create(:quiz_question, :times_answered => 10, :perc_correct => 50)
      qq.update_difficulty(0, 100)  # No new answers
      qq.reload
      expect(qq.times_answered).to eq(10)
      expect(qq.perc_correct).to eq(50.0)  # Should remain unchanged
    end

    it "should persist changes to database" do
      qq = FactoryBot.create(:quiz_question, :times_answered => 5, :perc_correct => 40)
      qq.update_difficulty(5, 60)
      
      # Verify changes are persisted by loading fresh from database
      fresh_qq = QuizQuestion.find(qq.id)
      expect(fresh_qq.times_answered).to eq(10)
      expect(fresh_qq.perc_correct).to eq(50.0)
    end
  end

  describe "validations" do

    describe "MCQ's" do
      let(:qq) { FactoryBot.create(:quiz_question, question_type: "mcq",
                mc_question: "What is the answer", mc_option_a: "Wrong",
                mc_option_b: "Right", mc_option_c: "Wrong",
                mc_option_d: "Wrong", mc_answer: "B") }

      it "validates length of mc_answer" do
        qq.question_type = "mcq"
        qq.mc_answer = ""

        expect(qq.save).to be false

        qq.mc_answer = "A"
        expect(qq.save).to be true

        qq.mc_answer = "AA"
        expect(qq.save).to be false
      end

      it "rejects mc_options too long" do
        for option in [:mc_option_a=, :mc_option_b=, :mc_option_c=, :mc_option_d=]
          qq.send(option, "X" * 160)
          expect(qq.save).to be false
        end
      end

      it "accepts mc_options of reasonable length" do
        for option in [:mc_option_a=, :mc_option_b=, :mc_option_c=, :mc_option_d=]
          qq.send(option, "Answer choice")
          expect(qq.save).to be true
        end
      end
    end

    describe "references" do
      let(:uv) { FactoryBot.create(:uberverse) }
      let(:qq) { FactoryBot.create(:quiz_question, question_type: "reference", supporting_ref: uv) }

      it "does not need MC options or answer" do
        expect(qq.question_type).to eq("reference")

        for mc in [:mc_question, :mc_option_a, :mc_option_b, :mc_option_c, :mc_option_d, :mc_answer]
          expect(qq.send(mc)).to eq(nil)
        end
      end
    end
  end
end
