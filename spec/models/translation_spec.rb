describe Translation do

  describe ".exclude" do
    it "should not exclude NIV" do
      all_translations = Translation.exclude(nil)

      all_translations[:NIV].should_not == nil
    end

    it "should exclude NIV" do
      translations = Translation.exclude(:NIV)

      translations[:NIV].should == nil
    end
  end

  describe ".find" do
    it "should return translation when valid abbreviation" do
      Translation.find("NIV").should == {name: "New International Version (1984)", language: "en"}
    end

    it "should return nil when invalid abbreviation" do
      Translation.find("AAA").should == nil
    end
  end

  describe ".select_options" do
    it "should return Rails-style options_for_select" do
      Translation.select_options["English (EN)"].class.should == Array
      Translation.select_options["English (EN)"].first.should == ["Amplified Bible (Classic Edition) (1987) (AMP)", "AMP"]
    end
  end

  describe ".with_lang" do
    it "should limit to particular language" do
      Translation.with_lang("es").should == [
        ["La Biblia de las Américas (LBLA)", "LBLA"],
        ["Nueva Biblia Latinoamericana de Hoy (NBLH)", "NBLH"],
        ["Nueva Version Internacional (NVI)", "NVI"],
        ["Reina-Valera 1960 (RVR)", "RVR"]
      ]
    end
  end

end
