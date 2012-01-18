# encoding: utf-8
describe Verse do

  it "should return correct mnemonic" do
    verse = Factory(:verse, :text => "This is an (extremely) important - mnemonic 'method' 'test'; don't you think?")
    verse.mnemonic.should == "T i a (e) i - m 'm' 't'; d y t?"
  end
  
  it "mnemonic method should support Portuguese" do
    verse = Factory(:verse, :text => "Á têst for mnémonic support of thé íncredíbly speciâl Portuguese çharacters.")
    verse.mnemonic.should == "Á t f m s o t í s P ç."
  end
  
  it "should clean up the verse text" do
    verse = Factory(:verse, :text => "This is a \r\n test test   \n   test. ")
	verse.save!
    verse.text.should == "This is a test test test."
  end
end
