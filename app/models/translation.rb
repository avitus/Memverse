class Translation

  # Please ensure that any new language codes are defined in en.yml at least

  # Translation updates must also be reflected on quick_start

  TRANSLATIONS = {
    AFR:    {name: "Afrikaans 1983 Translation", language: "af"},
    AFR53:  {name: "Afrikaans 1953 Translation", language: "af"},
    LUT84:  {name: "Luther Bibel 1984", language: "de"},
    LUT:    {name: "Luther Bibel 1545", language: "de"},
    SCH:    {name: "Schlachter 2000", language: "de"},
    NIV:    {name: "New International Version (1984)", language: "en"},
    NNV:    {name: "New International Version (2011)", language: "en"},
    NAS:    {name: "New American Standard Bible", language: "en"},
    NKJ:    {name: "New King James Version", language: "en"},
    KJV:    {name: "King James Version", language: "en"},
    RSV:    {name: "Revised Standard Version", language: "en"},
    NRS:    {name: "New Revised Standard Version", language: "en"},
    ESV:    {name: "English Standard Version (2011)", language: "en"},
    ESV07:  {name: "English Standard Version (2007)", language: "en"},
    NLT:    {name: "New Living Translation", language: "en"},
    CEV:    {name: "Contemporary English Version", language: "en"},
    HCS:    {name: "Holman Christian Standard Bible", language: "en"},
    DTL:    {name: "Darby Translation", language: "en"},
    MSG:    {name: "The Message", language: "en"},
    AMP:    {name: "Amplified Bible", language: "en"},
    IRV:    {name: "New International Reader's Version", language: "en"},
    NCV:    {name: "New Century Version", language: "en"},
    UKJ:    {name: "Updated King James Version", language: "en"},
    GEN:    {name: "Geneva Bible", language: "en"},
    GRK:    {name: "Biblical Greek", language: "en"},
    SMP:    {name: "Scottish Metrical Psalter", language: "en"},
    SMPB:   {name: "Scottish Metrical Psalter: B", language: "en"},
    SMPC:   {name: "Scottish Metrical Psalter: C", language: "en"},
    AKJ:    {name: "Authorized King James Version", language: "en"},
    GW:     {name: "God's Word Translation", language: "en"},
    GNT:    {name: "Good News Translation", language: "en"},
    NVI:    {name: "Nueva Version Internacional", language: "es"},
    RVR:    {name: "Reina-Valera 1960", language: "es"},
    NBLH:   {name: "Nueva Biblia Latinoamericana de Hoy", language: "es"},
    LBLA:   {name: "La Biblia de las Américas", language: "es"},
    LSV:    {name: "Louis Segond 1910", language: "fr"},
    HCV:    {name: "Haitian Creole Version", language: "ht"},
    TMB:    {name: "Terjemahan Baru", language: "id"},
    ICE:    {name: "Icelandic Bible (2007)", language: "is"},
    LND:    {name: "La Nuova Diodati", language: "it"},
    HSV:    {name: "Herziene Statenvertaling", language: "nl"},
    NBV:    {name: "De Nieuwe Bijbelvertaling", language: "nl"},
    MBB:    {name: "Magandang Balita Biblia", language: "tl"},
    ACF:    {name: "Almeida Corrigida e Fiel", language: "pt"},
    ARA:    {name: "Almeida Revista e Atualizada", language: "pt"},
    SPB:    {name: "Svenska Folkbibeln", language: "sv"},
  }

  # Public: Return TRANSLATIONS without given translation(s).
  #
  # trans - The Symbol or Array of Symbols for the translation(s) to exclude
  #
  # Returns the Hash of translations.
  def self.exclude(trans)
    translations = TRANSLATIONS.dup

    if trans.is_a?(Array)
      trans.each { |k| translations.delete(k) }
    else
      translations.delete(trans)
    end

    translations
  end

  # Public: Get and sort translations with given language.
  #
  # lang  - String for the language abbreviation (e.g., "en").
  # trans - Hash of translations to filter (default: TRANSLATIONS).
  #
  # Returns Array of translations, nicely formatted, with abbreviation.
  #   Example: ["Version Name (VN)", "VN"]
  def self.with_lang(lang, trans = TRANSLATIONS)
    trans_ = Array.new

    trans.each {|key, val|
      trans_ << ["#{val[:name]} (#{key})", key.to_s] if val[:language] == lang
    }

    return trans_.sort
  end

  # Public: Return translations ready for Rails grouped_options_for_select
  #
  # options - Hash of options (default: {}):
  #           :except - The Symbol or Array of Symbols of translations
  #                     to exclude
  #
  # Returns the Hash of languages in user's language, with the translations
  #   for each language. Languages are sorted by key (e.g., EN, ES, etc.) with
  #   user's language first, and translations sorted within the languages.
  def self.select_options(options = {})
    translations = TRANSLATIONS.dup, languages = [], select = {}

    translations = Translation.exclude(options[:except]) if options[:except]

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

end
