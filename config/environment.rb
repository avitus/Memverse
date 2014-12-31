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
  KJV:    {name: "King James Version (Modernized/1987)", language: "en"},
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
  GRK:    {name: "Biblical Greek (SBLGNT)", language: "en"},
  SMP:    {name: "Scottish Metrical Psalter", language: "en"},
  SMPB:   {name: "Scottish Metrical Psalter: B", language: "en"},
  SMPC:   {name: "Scottish Metrical Psalter: C", language: "en"},
  AKJ:    {name: "Authorized King James Version (1769)", language: "en"},
  GW:     {name: "God's Word Translation", language: "en"},
  GNT:    {name: "Good News Translation", language: "en"},
  NVI:    {name: "Nueva Version Internacional", language: "es"},
  RVR:    {name: "Reina-Valera 1960", language: "es"},
  NBLH:   {name: "Nueva Biblia Latinoamericana de Hoy", language: "es"},
  LBLA:   {name: "La Biblia de las Américas", language: "es"},
  LSV:    {name: "Louis Segond 1910", language: "fr"},
  MGK:    {name: "Modern Greek", language: "gk"},
  HCV:    {name: "Haitian Creole Version", language: "ht"},
  TMB:    {name: "Terjemahan Baru", language: "id"},
  ICE:    {name: "Icelandic Bible (2007)", language: "is"},
  LND:    {name: "La Nuova Diodati", language: "it"},
  KRV:    {name: "Korean Revised Version", language: "ko"},
  HSV:    {name: "Herziene Statenvertaling", language: "nl"},
  NBV:    {name: "De Nieuwe Bijbelvertaling", language: "nl"},
  RDC:    {name: "Romanian Dumitru Cornilescu Translation", language: "ro"},
  MBB:    {name: "Magandang Balita Biblia", language: "tl"},
  TAB:    {name: "Tagalog Ang Biblia", language: "tl"},
  TCL02:  {name: "Kutsal Kitap Yeni Çeviri", language: "tr"},
  ACF:    {name: "Almeida Corrigida e Fiel", language: "pt"},
  ARA:    {name: "Almeida Revista e Atualizada", language: "pt"},
  SPB:    {name: "Svenska Folkbibeln", language: "sv"},
  CCB:    {name: "Chinese Contemporary Bible", language: "zh"},
}

MAJORS = {
    :NIV => "New International Version (1984)",
    :NAS => "New American Standard Bible",
    :NKJ => "New King James Version",
    :KJV => "King James Version (Authorized)",
    :ESV => "English Standard Version (2011)",
  }

# Because hashes retain the order in which elements were inserted,
# calling BIBLEBOOKS[:en].values[i-1] will return ith English book name.

BIBLEBOOKS = Hash.new

BIBLEBOOKS[:en] = {"Gen"=>"Genesis", "Ex"=>"Exodus", "Lev"=>"Leviticus",
  "Num"=>"Numbers", "Deut"=>"Deuteronomy", "Josh"=>"Joshua", "Judg"=>"Judges",
  "Ruth"=>"Ruth", "1 Sam"=>"1 Samuel", "2 Sam"=>"2 Samuel",
  "1 Kings"=>"1 Kings", "2 Kings"=>"2 Kings", "1 Chron"=>"1 Chronicles",
  "2 Chron"=>"2 Chronicles", "Ezra"=>"Ezra", "Neh"=>"Nehemiah", "Es"=>"Esther",
  "Job"=>"Job", "Ps"=>"Psalms", "Prov"=>"Proverbs", "Eccl"=>"Ecclesiastes",
  "Song"=>"Song of Songs", "Isa"=>"Isaiah", "Jer"=>"Jeremiah",
  "Lam"=>"Lamentations", "Ezk"=>"Ezekiel", "Dan"=>"Daniel", "Hos"=>"Hosea",
  "Joel"=>"Joel", "Amos"=>"Amos", "Obad"=>"Obadiah", "Jonah"=>"Jonah",
  "Mic"=>"Micah", "Nahum"=>"Nahum", "Hab"=>"Habakkuk", "Zeph"=>"Zephaniah",
  "Hag"=>"Haggai", "Zech"=>"Zechariah", "Mal"=>"Malachi", "Matt"=>"Matthew",
  "Mark"=>"Mark", "Luke"=>"Luke", "Jn"=>"John", "Acts"=>"Acts",
  "Rom"=>"Romans", "1 Cor"=>"1 Corinthians", "2 Cor"=>"2 Corinthians",
  "Gal"=>"Galatians", "Eph"=>"Ephesians", "Phil"=>"Philippians",
  "Col"=>"Colossians", "1 Thess"=>"1 Thessalonians", "2 Thess"=>"2 Thessalonians",
  "1 Tim"=>"1 Timothy", "2 Tim"=>"2 Timothy", "Tit"=>"Titus", "Phlm"=>"Philemon",
  "Heb"=>"Hebrews", "James"=>"James", "1 Pet"=>"1 Peter", "2 Pet"=>"2 Peter",
  "1 John"=>"1 John", "2 John"=>"2 John", "3 John"=>"3 John", "Jude"=>"Jude", "Rev"=>"Revelation"}

BIBLEBOOKS[:es] = {"Gén"=>"Génesis", "Éxod"=>"Éxodo", "Lev"=>"Levitico",
  "Núm"=>"Números", "Deut"=>"Deuteronomio", "Jos"=>"Josué", "Jue"=>"Jueces",
  "Rut"=>"Rut", "1 Sam"=>"1 Samuel", "2 Sam"=>"2 Samuel", "1 Re"=>"1 Reyes",
  "2 Re"=>"2 Reyes", "1 Cró"=>"1 Crónicas", "2 Cró"=>"2 Crónicas",
  "Esd"=>"Esdras", "Neh"=>"Nehemías", "Est"=>"Ester", "Job"=>"Job",
  "Sal"=>"Salmos", "Prov"=>"Proverbios", "Ecl"=>"Eclesiastés",
  "Cant"=>"Cantares", "Is"=>"Isaías", "Jer"=>"Jeremías",
  "Lam"=>"Lamentaciones", "Ez"=>"Ezequiel", "Dan"=>"Daniel", "Os"=>"Oseas",
  "Jl"=>"Joel", "Am"=>"Amós", "Abd"=>"Abdías", "Jon"=>"Jonás",
  "Miq"=>"Miqueas", "Nah"=>"Nahún", "Hab"=>"Habacuc", "Sof"=>"Sofonías",
  "Ag"=>"Hageo", "Zac"=>"Zacarías", "Mal"=>"Malaquías", "Mt"=>"Mateo",
  "Mc"=>"Marcos", "Lc"=>"Lucas", "Jn"=>"Juan", "Hech"=>"Hechos",
  "Rom"=>"Romanos", "1 Cor"=>"1 Corintios", "2 Cor"=>"2 Corintios",
  "Gál"=>"Gálatas", "Ef"=>"Efesios", "Fil"=>"Filipenses", "Col"=>"Colosenses",
  "1 Tes"=>"1 Tesalonicenses", "2 Tes"=>"2 Tesalonicenses",
  "1 Tim"=>"1 Timoteo", "2 Tim"=>"2 Timoteo", "Tit"=>"Tito",
  "Filem"=>"Filemón", "Heb"=>"Hebreos", "Sant"=>"Santiago", "1 Pe"=>"1 Pedro",
  "2 Pe"=>"2 Pedro", "1 Jn"=>"1 Juan", "2 Jn"=>"2 Juan", "3 Jn"=>"3 Juan",
  "Jds"=>"Judas", "Apoc"=>"Apocalipsis"}

# Mapping name to itself; can add Chinese abbreviations later, if they exist.
BIBLEBOOKS[:zh] = {"创世记"=>"创世记", "出埃及"=>"出埃及", "利未记"=>"利未记", "民数记"=>"民数记",
  "申命记"=>"申命记", "约书亚记"=>"约书亚记", "士师记"=>"士师记", "路得记"=>"路得记", "撒母耳记上"=>"撒母耳记上",
  "撒母耳记下"=>"撒母耳记下", "列王纪上"=>"列王纪上", "列王纪下"=>"列王纪下", "历代志上"=>"历代志上",
  "历代志下"=>"历代志下", "以斯拉记"=>"以斯拉记", "尼希米记"=>"尼希米记", "以斯帖记"=>"以斯帖记", "约伯记"=>"约伯记",
  "诗篇"=>"诗篇", "箴言"=>"箴言", "传道书"=>"传道书", "雅歌"=>"雅歌", "以赛亚书"=>"以赛亚书",
  "耶利米书"=>"耶利米书", "耶利米哀歌"=>"耶利米哀歌", "以西结书"=>"以西结书", "但以理书"=>"但以理书",
  "何西阿书"=>"何西阿书", "约珥书"=>"约珥书", "阿摩司书"=>"阿摩司书", "俄巴底亚书"=>"俄巴底亚书", "约拿书"=>"约拿书",
  "弥迦书"=>"弥迦书", "那鸿书"=>"那鸿书", "哈巴谷书"=>"哈巴谷书", "西番雅书"=>"西番雅书", "哈该书"=>"哈该书",
  "撒迦利亚书"=>"撒迦利亚书", "玛拉基书"=>"玛拉基书", "马太福音"=>"马太福音", "马可福音"=>"马可福音",
  "路加福音"=>"路加福音", "约翰福音"=>"约翰福音", "使徒行传"=>"使徒行传", "罗马书"=>"罗马书",
  "哥林多前书"=>"哥林多前书", "哥林多后书"=>"哥林多后书", "加拉太书"=>"加拉太书", "以弗所书"=>"以弗所书",
  "腓立比书"=>"腓立比书", "歌罗西书"=>"歌罗西书", "帖撒罗尼迦前书"=>"帖撒罗尼迦前书", "帖撒罗尼迦后书"=>"帖撒罗尼迦后书",
  "提摩太前书"=>"提摩太前书", "提摩太后书"=>"提摩太后书", "提多书"=>"提多书", "腓利门书"=>"腓利门书",
  "希伯来书"=>"希伯来书", "雅各书"=>"雅各书", "彼得前书"=>"彼得前书", "彼得后书"=>"彼得后书", "约翰一书"=>"约翰一书",
  "约翰二书"=>"约翰二书", "约翰三书"=>"约翰三书", "犹大书"=>"犹大书", "启示录"=>"启示录"}

BIBLEBOOKS[:ko] = {"창세기"=>"창세기", "출애굽기"=>"출애굽기", "레위기"=>"레위기", "민수기"=>"민수기",
  "신명기"=>"신명기", "여호수아"=>"여호수아", "사사기"=>"사사기", "룻기"=>"룻기", "사무엘상"=>"사무엘상",
  "사무엘하"=>"사무엘하", "열왕기상"=>"열왕기상", "열왕기하"=>"열왕기하", "역대상"=>"역대상", "역대하"=>"역대하",
  "에스라"=>"에스라", "느헤미야"=>"느헤미야", "에스더"=>"에스더", "욥기"=>"욥기", "시편"=>"시편",
  "잠언"=>"잠언", "전도서"=>"전도서", "아가"=>"아가", "이사야"=>"이사야", "예레미야"=>"예레미야",
  "예레미야애가"=>"예레미야애가", "에스겔"=>"에스겔", "다니엘"=>"다니엘", "호세아"=>"호세아", "요엘"=>"요엘",
  "아모스"=>"아모스", "오바댜"=>"오바댜", "요나"=>"요나", "미가"=>"미가", "나훔"=>"나훔", "하박국"=>"하박국",
  "스바냐"=>"스바냐", "학개"=>"학개", "스가랴"=>"스가랴", "말라기"=>"말라기", "마태복음"=>"마태복음",
  "마가복음"=>"마가복음", "누가복음"=>"누가복음", "요한복음"=>"요한복음", "사도행전"=>"사도행전",
  "로마서"=>"로마서", "고린도전서"=>"고린도전서", "고린도후서"=>"고린도후서", "갈라디아서"=>"갈라디아서",
  "에베소서"=>"에베소서", "빌립보서"=>"빌립보서", "골로새서"=>"골로새서", "데살로니가전서"=>"데살로니가전서",
  "데살로니가후서"=>"데살로니가후서", "디모데전서"=>"디모데전서", "디모데후서"=>"디모데후서", "디도서"=>"디도서",
  "빌레몬서"=>"빌레몬서", "히브리서"=>"히브리서", "야고보서"=>"야고보서", "베드로전서"=>"베드로전서",
  "베드로후서"=>"베드로후서", "요한일서"=>"요한일서", "요한2서"=>"요한2서", "요한3서"=>"요한3서",
  "유다서"=>"유다서", "요한계시록"=>"요한계시록"}

MEDALS = {
  :gold   => 3,
  :silver => 2,
  :bronze => 1,
  :solo   => 0
}
