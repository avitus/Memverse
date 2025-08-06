require 'spec_helper'

describe Translation do

  describe ".exclude" do
    it "should not exclude NIV" do
      all_translations = Translation.exclude(nil)

      expect(all_translations[:NIV]).not_to eq(nil)
    end

    it "should exclude NIV" do
      translations = Translation.exclude(:NIV)

      expect(translations[:NIV]).to eq(nil)
    end
  end

  describe ".find" do
    it "should return translation when valid abbreviation" do
      expect(Translation.find("NIV")).to eq({name: "New International Version (1984)", language: "en"})
    end

    it "should return nil when invalid abbreviation" do
      expect(Translation.find("AAA")).to eq(nil)
    end
  end

  describe ".select_options" do
    it "should return Rails-style options_for_select" do
      expect(Translation.select_options["English (EN)"].class).to eq(Array)
      expect(Translation.select_options["English (EN)"].first).to eq(["Amplified Bible (Classic Edition) (1987) (AMP)", "AMP"])
    end
  end

  describe ".with_lang" do
    it "should limit to particular language" do
      expect(Translation.with_lang("es")).to eq([
        ["La Biblia de las Américas (LBLA)", "LBLA"],
        ["Nueva Biblia Latinoamericana de Hoy (NBLH)", "NBLH"],
        ["Nueva Version Internacional (NVI)", "NVI"],
        ["Reina-Valera 1960 (RVR)", "RVR"]
      ])
    end
  end

end
