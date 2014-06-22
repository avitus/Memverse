# encoding: utf-8
describe QuizQuestion do
	it "should update the difficulty after a quiz" do
		qq = FactoryGirl.create(:quiz_question, times_answered: 10, perc_correct: 50)
		qq.update_difficulty(10, 100)  # answer count, percentage_correct
		qq.reload
    qq.times_answered.should == 20
		qq.perc_correct.should == 75.0
	end
end