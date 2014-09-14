class Translation

  # Returns TRANSLATIONS without given translation(s).
  #
  # @param trans [Symbol, Array<Symbol>] translation or translations to exclude
  # @return [Hash] translations
  def self.exclude(trans = nil)
    translations = TRANSLATIONS.dup

    if trans.is_a?(Array)
      trans.each { |k| translations.delete(k) }
    elsif trans.is_a?(Symbol)
      translations.delete(trans)
    end

    translations
  end

  # Returns the translation name and language from abbreviation
  #
  # @param abbrev [String, Symbol] abbreviation of translation
  # @return [Hash] the abbreviation name and language hash, from
  #    TRANSLATIONS.
  #
  # @example Lookup ESV
  #   Translation.find("ESV") #=> {:name=>"English Standard Version (2011)", :language=>"en"}
  def self.find(abbrev)
    TRANSLATIONS[abbrev.try(:to_sym)]
  end

  # Get and sort translations with given language.
  #
  # @param lang [String] the language abbreviation (e.g., "en")
  # @param trans [Hash] translations to filter (default: TRANSLATIONS)
  #
  # @return [Array] translations, nicely formatted, with abbreviation
  #
  # @example Get Spanish ("es") translations
  #    Translation.with_lang("es") #=> [["La Biblia de las Américas (LBLA)", "LBLA"],
  #                                #    ["Nueva Biblia Latinoamericana de Hoy (NBLH)", "NBLH"],
  #                                #    ["Nueva Version Internacional (NVI)", "NVI"],
  #                                #    ["Reina-Valera 1960 (RVR)", "RVR"]]
  def self.with_lang(lang, trans = TRANSLATIONS)
    trans_ = Array.new

    trans.each {|key, val|
      trans_ << ["#{val[:name]} (#{key})", key.to_s] if val[:language] == lang
    }

    return trans_.sort
  end

  # Get and sort translations with given language.
  #
  # @param lang [String] the language abbreviation (e.g., "en")
  # @param trans [Hash] translations to filter (default: TRANSLATIONS)
  #
  # @return [Array] hashes of translations (name and abbreviation)
  #
  # @example Get Spanish ("es") translations
  #    Translation.with_lang_for_api("es") #=> [{:Name=>"La Biblia de las Américas", :Abbreviation=>"LBLA"},
  #                                        #    {:Name=>"Nueva Biblia Latinoamericana de Hoy", :Abbreviation=>"NBLH"},
  #                                        #    {:Name=>"Nueva Version Internacional", :Abbreviation=>"NVI"},
  #                                        #    {:Name=>"Reina-Valera 1960", :Abbreviation=>"RVR"}]
  def self.with_lang_for_api(lang, trans = TRANSLATIONS)
    trans_ = Array.new

    trans.each {|key, val|
      trans_ << {Name: val[:name], Abbreviation: key.to_s} if val[:language] == lang
    }

    return trans_.sort_by {|hash| hash[:Name]}
  end

  # Returns translations ready for Rails grouped_options_for_select
  #
  # @param opts [Hash] options
  # @option opts [Symbol, Array<Symbol>] :except The translation(s) to exclude
  #
  # @return [Hash] languages in user's language, with the translations
  #   for each language. Languages are sorted by key (e.g., EN, ES, etc.) with
  #   user's language first, and translations sorted within the languages.
  def self.select_options(opts = {})
    translations = Translation.exclude(opts[:except] || nil)
    languages = []; select = {}

    # Get language name -- in user's language, if possible
    lang_name = lambda { |abbrev| I18n.t abbrev.to_s, scope: [:language]  }

    # get array of all languages
    translations.each_value {|value| languages << value[:language]}
    # sort languages, put user's first, and remove duplicates
    languages = languages.sort.unshift(I18n.locale).uniq

    for lang in languages
      select["#{lang_name.call(lang)} (#{lang.upcase})"] =
        Translation.with_lang(lang, translations)
    end

    select
  end

  # Returns translations ready for API TranslationsController index action
  #
  # @return [Array] languages in user's language, with the translations
  #   for each language. Languages are sorted by key (e.g., EN, ES, etc.) with
  #   user's language first, and translations sorted within the languages.
  def self.for_api(opts = {})
    translations = Translation.exclude(opts[:except] || nil)
    languages = []; output = []

    # Get language name -- in user's language, if possible
    lang_name = lambda { |abbrev| I18n.t abbrev.to_s, scope: [:language]  }

    # get array of all languages
    translations.each_value {|value| languages << value[:language]}
    # sort languages, put user's first, and remove duplicates
    languages = languages.sort.unshift(I18n.locale).uniq

    for lang in languages
      trans = Translation.with_lang_for_api(lang.to_s, translations)

      output << { Name: lang_name.call(lang),
                  Abbreviation: lang.upcase.to_s,
                  Translations: trans }
    end

    output
  end

end
