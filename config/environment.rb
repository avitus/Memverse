# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
MemverseApp::Application.initialize!  

TRANSLATIONS = { 
    :NIV => "New International Version",
    :NAS => "New American Standard Bible", 
    :NKJ => "New King James Version", 
    :KJV => "King James Version",
    :RSV => "Revised Standard Version",
    :NRS => "New Revised Standard Version",                          
    :ESV => "English Standard Version",
    :NLT => "New Living Translation",
    :IRV => "New International Reader's Version",
    :UKJ => "Updated King James Version",
    :GRK => "Biblical Greek",
    :NVI => "Nueva Version Internacional",
    :RVR => "Reina-Valera 1960",
    :AFR => "Afrikaans 1983 Translation",
    :NBV => "De Nieuwe Bijbelvertaling",
    :SPB => "Svenska Folkbibeln" 
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

