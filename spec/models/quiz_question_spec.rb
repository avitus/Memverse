# encoding: utf-8
describe QuizQuestion do
  it "should update the difficulty after a quiz" do
    qq = FactoryBot.create(:quiz_question, :times_answered => 10, :perc_correct => 50)
    qq.update_difficulty(10, 100)  # answer count, percentage_correct
    qq.reload
    qq.times_answered.should == 20
    qq.perc_correct.should == 75.0
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

        qq.save.should be false

        qq.mc_answer = "A"
        qq.save.should be true

        qq.mc_answer = "AA"
        qq.save.should be false
      end

      it "rejects mc_options too long" do
        for option in [:mc_option_a=, :mc_option_b=, :mc_option_c=, :mc_option_d=]
          qq.send(option, "X" * 160)
          qq.save.should be false
        end
      end

      it "accepts mc_options of reasonable length" do
        for option in [:mc_option_a=, :mc_option_b=, :mc_option_c=, :mc_option_d=]
          qq.send(option, "Answer choice")
          qq.save.should be true
        end
      end
    end

    describe "references" do
      let(:uv) { FactoryBot.create(:uberverse) }
      let(:qq) { FactoryBot.create(:quiz_question, question_type: "reference", supporting_ref: uv) }

      it "does not need MC options or answer" do
        qq.question_type.should == "reference"

        for mc in [:mc_question, :mc_option_a, :mc_option_b, :mc_option_c, :mc_option_d, :mc_answer]
          qq.send(mc).should == nil
        end
      end
    end
  end
end
