describe Verse do

  it "should return correct mnemonic" do
    verse = Factory(:verse, :text => "This is an (extremely) important - mnemonic 'method' 'test'; don't you think?")
    verse.mnemonic.should == "T i a (e) i - m 'm' 't'; d y t?"
  end

end
