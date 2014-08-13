# coding: utf-8

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
MemverseApp::Application.initialize!

# Translation updates must also be reflected on quick_start
# New language codes must be defined in en.yml at least

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
  NLT:    {name: "New Living Translation (2007)", language: "en"},
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

MAJORS = {
    :NIV => "New International Version (1984)",
    :NAS => "New American Standard Bible",
    :NKJ => "New King James Version",
    :KJV => "King James Version",
    :ESV => "English Standard Version (2011)",
  }


BIBLEBOOKS = ['Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
              '1 Kings', '2 Kings','1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
              'Ecclesiastes', 'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel',
              'Amos', 'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
              'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians', 'Philippians',
              'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
              '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation']

BIBLEABBREV = ['Gen', 'Ex', 'Lev', 'Num', 'Deut', 'Josh', 'Judg', 'Ruth', '1 Sam', '2 Sam',
              '1 Kings', '2 Kings','1 Chron', '2 Chron', 'Ezra', 'Neh', 'Es', 'Job', 'Ps', 'Prov',
              'Eccl', 'Song', 'Isa', 'Jer', 'Lam', 'Ezk', 'Dan', 'Hos', 'Joel',
              'Amos', 'Obad', 'Jonah', 'Mic', 'Nahum', 'Hab', 'Zeph', 'Hag', 'Zech', 'Mal', 'Matt',
              'Mark', 'Luke', 'Jn', 'Acts', 'Rom', '1 Cor', '2 Cor', 'Gal', 'Eph', 'Phil',
              'Col', '1 Thess', '2 Thess', '1 Tim', '2 Tim', 'Tit', 'Phlm', 'Heb', 'James',
              '1 Pet', '2 Pet', '1 John', '2 John', '3 John', 'Jude', 'Rev']

SPANISHBOOKS = ['Génesis', 'Éxodo', 'Levitico', 'Números', 'Deuteronomio', 'Josué', 'Jueces', 'Rut', '1 Samuel', '2 Samuel', '1 Reyes',
                '2 Reyes', '1 Crónicas', '2 Crónicas', 'Esdras', 'Nehemías', 'Ester', 'Job', 'Salmos', 'Proverbios', 'Eclesiastés', 'Cantares',
                'Isaías', 'Jeremías', 'Lamentaciones', 'Ezequiel', 'Daniel', 'Oseas', 'Joel', 'Amós', 'Abdías', 'Jonás', 'Miqueas', 'Nahún', 'Habacuc',
                'Sofonías', 'Hageo', 'Zacarías', 'Malaquías', 'Mateo', 'Marcos', 'Lucas', 'Juan', 'Hechos', 'Romanos', '1 Corintios', '2 Corintios',
                'Gálatas', 'Efesios', 'Filipenses', 'Colosenses', '1 Tesalonicenses', '2 Tesalonicenses', '1 Timoteo', '2 Timoteo', 'Tito', 'Filemón',
                'Hebreos', 'Santiago', '1 Pedro', '2 Pedro', '1 Juan', '2 Juan', '3 Juan', 'Judas','Apocalipsis']

SPANISHABBREV = [ 'Gén', 'Éxod', 'Lev', 'Núm', 'Deut', 'Jos', 'Jue', 'Rut', '1 Sam', '2 Sam', '1 Re', '2 Re', '1 Cró', '2 Cró', 'Esd',
                  'Neh', 'Est', 'Job', 'Sal', 'Prov', 'Ecl', 'Cant', 'Is', 'Jer', 'Lam',
                  'Ez', 'Dan', 'Os', 'Jl', 'Am', 'Abd', 'Jon', 'Miq', 'Nah', 'Hab', 'Sof', 'Ag', 'Zac', 'Mal', 'Mt', 'Mc', 'Lc',
                  'Jn', 'Hech', 'Rom', '1 Cor', '2 Cor', 'Gál', 'Ef', 'Fil', 'Col', '1 Tes', '2 Tes', '1 Tim', '2 Tim', 'Tit', 'Filem',
                  'Heb', 'Sant', '1 Pe', '2 Pe', '1 Jn', '2 Jn', '3 Jn', 'Jds', 'Apoc']

MEDALS = {
  :gold   => 3,
  :silver => 2,
  :bronze => 1,
  :solo   => 0
}
