# iso_country_list.sql
#
# This will create and then populate a MySQL table with a list of the names and
# ISO 3166 codes for countries in existence as of the date below.
#
# Usage:
#    mysql -u username -ppassword database_name < ./iso_country_list.sql
#
# [ALV] mysql -u [username] -p[password] -hmysql.[domainname].com [database_name] < iso_country_list.sql
#
# For updates to this file, see http://27.org/isocountrylist/
# For more about ISO 3166, see http://www.iso.ch/iso/en/prods-services/iso3166ma/02iso-3166-code-lists/list-en1.html
#
# Created by getisocountrylist.pl on Sun Nov  2 14:59:20 2003.
# Wm. Rhodes <iso_country_list@27.org>
#

# DROP TABLE IF EXISTS countries;
# 
# CREATE TABLE IF NOT EXISTS countries (
#   id SMALLINT NOT NULL PRIMARY KEY,
#   iso CHAR(2) NOT NULL,
#   name VARCHAR(80) NOT NULL,
#   printable_name VARCHAR(80) NOT NULL,
#   iso3 CHAR(3),
#   numcode SMALLINT
# );
# ACW commented out 01Feb2012 since loading countries was ruining db/schema.rb. Now countries should be loaded after rake db:schema:load

INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('1','AF','AFGHANISTAN','Afghanistan','AFG','004');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('2','AL','ALBANIA','Albania','ALB','008');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('3','DZ','ALGERIA','Algeria','DZA','012');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('4','AS','AMERICAN SAMOA','American Samoa','ASM','016');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('5','AD','ANDORRA','Andorra','AND','020');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('6','AO','ANGOLA','Angola','AGO','024');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('7','AI','ANGUILLA','Anguilla','AIA','660');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('8','AQ','ANTARCTICA','Antarctica',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('9','AG','ANTIGUA AND BARBUDA','Antigua and Barbuda','ATG','028');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('10','AR','ARGENTINA','Argentina','ARG','032');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('11','AM','ARMENIA','Armenia','ARM','051');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('12','AW','ARUBA','Aruba','ABW','533');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('13','AU','AUSTRALIA','Australia','AUS','036');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('14','AT','AUSTRIA','Austria','AUT','040');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('15','AZ','AZERBAIJAN','Azerbaijan','AZE','031');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('16','BS','BAHAMAS','Bahamas','BHS','044');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('17','BH','BAHRAIN','Bahrain','BHR','048');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('18','BD','BANGLADESH','Bangladesh','BGD','050');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('19','BB','BARBADOS','Barbados','BRB','052');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('20','BY','BELARUS','Belarus','BLR','112');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('21','BE','BELGIUM','Belgium','BEL','056');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('22','BZ','BELIZE','Belize','BLZ','084');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('23','BJ','BENIN','Benin','BEN','204');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('24','BM','BERMUDA','Bermuda','BMU','060');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('25','BT','BHUTAN','Bhutan','BTN','064');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('26','BO','BOLIVIA','Bolivia','BOL','068');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('27','BA','BOSNIA AND HERZEGOVINA','Bosnia and Herzegovina','BIH','070');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('28','BW','BOTSWANA','Botswana','BWA','072');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('29','BV','BOUVET ISLAND','Bouvet Island',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('30','BR','BRAZIL','Brazil','BRA','076');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('31','IO','BRITISH INDIAN OCEAN TERRITORY','British Indian Ocean Territory',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('32','BN','BRUNEI DARUSSALAM','Brunei Darussalam','BRN','096');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('33','BG','BULGARIA','Bulgaria','BGR','100');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('34','BF','BURKINA FASO','Burkina Faso','BFA','854');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('35','BI','BURUNDI','Burundi','BDI','108');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('36','KH','CAMBODIA','Cambodia','KHM','116');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('37','CM','CAMEROON','Cameroon','CMR','120');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('38','CA','CANADA','Canada','CAN','124');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('39','CV','CAPE VERDE','Cape Verde','CPV','132');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('40','KY','CAYMAN ISLANDS','Cayman Islands','CYM','136');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('41','CF','CENTRAL AFRICAN REPUBLIC','Central African Republic','CAF','140');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('42','TD','CHAD','Chad','TCD','148');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('43','CL','CHILE','Chile','CHL','152');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('44','CN','CHINA','China','CHN','156');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('45','CX','CHRISTMAS ISLAND','Christmas Island',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('46','CC','COCOS (KEELING) ISLANDS','Cocos (Keeling) Islands',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('47','CO','COLOMBIA','Colombia','COL','170');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('48','KM','COMOROS','Comoros','COM','174');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('49','CG','CONGO','Congo','COG','178');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('50','CD','CONGO, THE DEMOCRATIC REPUBLIC OF THE','Congo, the Democratic Republic of the','COD','180');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('51','CK','COOK ISLANDS','Cook Islands','COK','184');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('52','CR','COSTA RICA','Costa Rica','CRI','188');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('53','CI','COTE D\'IVOIRE','Cote D\'Ivoire','CIV','384');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('54','HR','CROATIA','Croatia','HRV','191');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('55','CU','CUBA','Cuba','CUB','192');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('56','CY','CYPRUS','Cyprus','CYP','196');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('57','CZ','CZECH REPUBLIC','Czech Republic','CZE','203');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('58','DK','DENMARK','Denmark','DNK','208');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('59','DJ','DJIBOUTI','Djibouti','DJI','262');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('60','DM','DOMINICA','Dominica','DMA','212');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('61','DO','DOMINICAN REPUBLIC','Dominican Republic','DOM','214');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('62','EC','ECUADOR','Ecuador','ECU','218');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('63','EG','EGYPT','Egypt','EGY','818');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('64','SV','EL SALVADOR','El Salvador','SLV','222');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('65','GQ','EQUATORIAL GUINEA','Equatorial Guinea','GNQ','226');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('66','ER','ERITREA','Eritrea','ERI','232');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('67','EE','ESTONIA','Estonia','EST','233');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('68','ET','ETHIOPIA','Ethiopia','ETH','231');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('69','FK','FALKLAND ISLANDS (MALVINAS)','Falkland Islands (Malvinas)','FLK','238');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('70','FO','FAROE ISLANDS','Faroe Islands','FRO','234');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('71','FJ','FIJI','Fiji','FJI','242');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('72','FI','FINLAND','Finland','FIN','246');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('73','FR','FRANCE','France','FRA','250');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('74','GF','FRENCH GUIANA','French Guiana','GUF','254');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('75','PF','FRENCH POLYNESIA','French Polynesia','PYF','258');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('76','TF','FRENCH SOUTHERN TERRITORIES','French Southern Territories',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('77','GA','GABON','Gabon','GAB','266');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('78','GM','GAMBIA','Gambia','GMB','270');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('79','GE','GEORGIA','Georgia','GEO','268');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('80','DE','GERMANY','Germany','DEU','276');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('81','GH','GHANA','Ghana','GHA','288');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('82','GI','GIBRALTAR','Gibraltar','GIB','292');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('83','GR','GREECE','Greece','GRC','300');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('84','GL','GREENLAND','Greenland','GRL','304');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('85','GD','GRENADA','Grenada','GRD','308');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('86','GP','GUADELOUPE','Guadeloupe','GLP','312');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('87','GU','GUAM','Guam','GUM','316');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('88','GT','GUATEMALA','Guatemala','GTM','320');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('89','GN','GUINEA','Guinea','GIN','324');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('90','GW','GUINEA-BISSAU','Guinea-Bissau','GNB','624');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('91','GY','GUYANA','Guyana','GUY','328');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('92','HT','HAITI','Haiti','HTI','332');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('93','HM','HEARD ISLAND AND MCDONALD ISLANDS','Heard Island and Mcdonald Islands',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('94','VA','HOLY SEE (VATICAN CITY STATE)','Holy See (Vatican City State)','VAT','336');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('95','HN','HONDURAS','Honduras','HND','340');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('96','HK','HONG KONG','Hong Kong','HKG','344');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('97','HU','HUNGARY','Hungary','HUN','348');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('98','IS','ICELAND','Iceland','ISL','352');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('99','IN','INDIA','India','IND','356');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('100','ID','INDONESIA','Indonesia','IDN','360');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('101','IR','IRAN, ISLAMIC REPUBLIC OF','Iran, Islamic Republic of','IRN','364');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('102','IQ','IRAQ','Iraq','IRQ','368');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('103','IE','IRELAND','Ireland','IRL','372');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('104','IL','ISRAEL','Israel','ISR','376');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('105','IT','ITALY','Italy','ITA','380');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('106','JM','JAMAICA','Jamaica','JAM','388');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('107','JP','JAPAN','Japan','JPN','392');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('108','JO','JORDAN','Jordan','JOR','400');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('109','KZ','KAZAKHSTAN','Kazakhstan','KAZ','398');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('110','KE','KENYA','Kenya','KEN','404');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('111','KI','KIRIBATI','Kiribati','KIR','296');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('112','KP','KOREA, DEMOCRATIC PEOPLE\'S REPUBLIC OF','Korea, Democratic People\'s Republic of','PRK','408');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('113','KR','KOREA, REPUBLIC OF','Korea, Republic of','KOR','410');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('114','KW','KUWAIT','Kuwait','KWT','414');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('115','KG','KYRGYZSTAN','Kyrgyzstan','KGZ','417');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('116','LA','LAO PEOPLE\'S DEMOCRATIC REPUBLIC','Lao People\'s Democratic Republic','LAO','418');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('117','LV','LATVIA','Latvia','LVA','428');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('118','LB','LEBANON','Lebanon','LBN','422');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('119','LS','LESOTHO','Lesotho','LSO','426');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('120','LR','LIBERIA','Liberia','LBR','430');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('121','LY','LIBYAN ARAB JAMAHIRIYA','Libyan Arab Jamahiriya','LBY','434');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('122','LI','LIECHTENSTEIN','Liechtenstein','LIE','438');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('123','LT','LITHUANIA','Lithuania','LTU','440');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('124','LU','LUXEMBOURG','Luxembourg','LUX','442');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('125','MO','MACAO','Macao','MAC','446');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('126','MK','MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF','Macedonia, the Former Yugoslav Republic of','MKD','807');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('127','MG','MADAGASCAR','Madagascar','MDG','450');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('128','MW','MALAWI','Malawi','MWI','454');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('129','MY','MALAYSIA','Malaysia','MYS','458');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('130','MV','MALDIVES','Maldives','MDV','462');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('131','ML','MALI','Mali','MLI','466');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('132','MT','MALTA','Malta','MLT','470');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('133','MH','MARSHALL ISLANDS','Marshall Islands','MHL','584');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('134','MQ','MARTINIQUE','Martinique','MTQ','474');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('135','MR','MAURITANIA','Mauritania','MRT','478');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('136','MU','MAURITIUS','Mauritius','MUS','480');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('137','YT','MAYOTTE','Mayotte',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('138','MX','MEXICO','Mexico','MEX','484');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('139','FM','MICRONESIA, FEDERATED STATES OF','Micronesia, Federated States of','FSM','583');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('140','MD','MOLDOVA, REPUBLIC OF','Moldova, Republic of','MDA','498');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('141','MC','MONACO','Monaco','MCO','492');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('142','MN','MONGOLIA','Mongolia','MNG','496');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('143','MS','MONTSERRAT','Montserrat','MSR','500');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('144','MA','MOROCCO','Morocco','MAR','504');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('145','MZ','MOZAMBIQUE','Mozambique','MOZ','508');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('146','MM','MYANMAR','Myanmar','MMR','104');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('147','NA','NAMIBIA','Namibia','NAM','516');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('148','NR','NAURU','Nauru','NRU','520');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('149','NP','NEPAL','Nepal','NPL','524');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('150','NL','NETHERLANDS','Netherlands','NLD','528');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('151','AN','NETHERLANDS ANTILLES','Netherlands Antilles','ANT','530');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('152','NC','NEW CALEDONIA','New Caledonia','NCL','540');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('153','NZ','NEW ZEALAND','New Zealand','NZL','554');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('154','NI','NICARAGUA','Nicaragua','NIC','558');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('155','NE','NIGER','Niger','NER','562');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('156','NG','NIGERIA','Nigeria','NGA','566');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('157','NU','NIUE','Niue','NIU','570');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('158','NF','NORFOLK ISLAND','Norfolk Island','NFK','574');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('159','MP','NORTHERN MARIANA ISLANDS','Northern Mariana Islands','MNP','580');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('160','NO','NORWAY','Norway','NOR','578');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('161','OM','OMAN','Oman','OMN','512');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('162','PK','PAKISTAN','Pakistan','PAK','586');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('163','PW','PALAU','Palau','PLW','585');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('164','PS','PALESTINIAN TERRITORY, OCCUPIED','Palestinian Territory, Occupied',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('165','PA','PANAMA','Panama','PAN','591');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('166','PG','PAPUA NEW GUINEA','Papua New Guinea','PNG','598');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('167','PY','PARAGUAY','Paraguay','PRY','600');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('168','PE','PERU','Peru','PER','604');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('169','PH','PHILIPPINES','Philippines','PHL','608');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('170','PN','PITCAIRN','Pitcairn','PCN','612');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('171','PL','POLAND','Poland','POL','616');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('172','PT','PORTUGAL','Portugal','PRT','620');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('173','PR','PUERTO RICO','Puerto Rico','PRI','630');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('174','QA','QATAR','Qatar','QAT','634');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('175','RE','REUNION','Reunion','REU','638');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('176','RO','ROMANIA','Romania','ROM','642');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('177','RU','RUSSIAN FEDERATION','Russian Federation','RUS','643');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('178','RW','RWANDA','Rwanda','RWA','646');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('179','SH','SAINT HELENA','Saint Helena','SHN','654');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('180','KN','SAINT KITTS AND NEVIS','Saint Kitts and Nevis','KNA','659');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('181','LC','SAINT LUCIA','Saint Lucia','LCA','662');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('182','PM','SAINT PIERRE AND MIQUELON','Saint Pierre and Miquelon','SPM','666');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('183','VC','SAINT VINCENT AND THE GRENADINES','Saint Vincent and the Grenadines','VCT','670');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('184','WS','SAMOA','Samoa','WSM','882');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('185','SM','SAN MARINO','San Marino','SMR','674');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('186','ST','SAO TOME AND PRINCIPE','Sao Tome and Principe','STP','678');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('187','SA','SAUDI ARABIA','Saudi Arabia','SAU','682');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('188','SN','SENEGAL','Senegal','SEN','686');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('189','CS','SERBIA AND MONTENEGRO','Serbia and Montenegro',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('190','SC','SEYCHELLES','Seychelles','SYC','690');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('191','SL','SIERRA LEONE','Sierra Leone','SLE','694');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('192','SG','SINGAPORE','Singapore','SGP','702');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('193','SK','SLOVAKIA','Slovakia','SVK','703');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('194','SI','SLOVENIA','Slovenia','SVN','705');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('195','SB','SOLOMON ISLANDS','Solomon Islands','SLB','090');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('196','SO','SOMALIA','Somalia','SOM','706');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('197','ZA','SOUTH AFRICA','South Africa','ZAF','710');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('198','GS','SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS','South Georgia and the South Sandwich Islands',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('199','ES','SPAIN','Spain','ESP','724');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('200','LK','SRI LANKA','Sri Lanka','LKA','144');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('201','SD','SUDAN','Sudan','SDN','736');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('202','SR','SURINAME','Suriname','SUR','740');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('203','SJ','SVALBARD AND JAN MAYEN','Svalbard and Jan Mayen','SJM','744');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('204','SZ','SWAZILAND','Swaziland','SWZ','748');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('205','SE','SWEDEN','Sweden','SWE','752');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('206','CH','SWITZERLAND','Switzerland','CHE','756');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('207','SY','SYRIAN ARAB REPUBLIC','Syrian Arab Republic','SYR','760');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('208','TW','TAIWAN','Taiwan','TWN','158');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('209','TJ','TAJIKISTAN','Tajikistan','TJK','762');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('210','TZ','TANZANIA, UNITED REPUBLIC OF','Tanzania, United Republic of','TZA','834');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('211','TH','THAILAND','Thailand','THA','764');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('212','TL','TIMOR-LESTE','Timor-Leste',NULL,NULL);
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('213','TG','TOGO','Togo','TGO','768');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('214','TK','TOKELAU','Tokelau','TKL','772');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('215','TO','TONGA','Tonga','TON','776');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('216','TT','TRINIDAD AND TOBAGO','Trinidad and Tobago','TTO','780');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('217','TN','TUNISIA','Tunisia','TUN','788');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('218','TR','TURKEY','Turkey','TUR','792');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('219','TM','TURKMENISTAN','Turkmenistan','TKM','795');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('220','TC','TURKS AND CAICOS ISLANDS','Turks and Caicos Islands','TCA','796');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('221','TV','TUVALU','Tuvalu','TUV','798');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('222','UG','UGANDA','Uganda','UGA','800');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('223','UA','UKRAINE','Ukraine','UKR','804');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('224','AE','UNITED ARAB EMIRATES','United Arab Emirates','ARE','784');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('225','GB','UNITED KINGDOM','United Kingdom','GBR','826');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('226','US','UNITED STATES','United States','USA','840');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('227','UY','URUGUAY','Uruguay','URY','858');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('228','UZ','UZBEKISTAN','Uzbekistan','UZB','860');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('229','VU','VANUATU','Vanuatu','VUT','548');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('230','VE','VENEZUELA','Venezuela','VEN','862');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('231','VN','VIET NAM','Viet Nam','VNM','704');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('232','VG','VIRGIN ISLANDS, BRITISH','Virgin Islands, British','VGB','092');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('233','VI','VIRGIN ISLANDS, U.S.','Virgin Islands, U.s.','VIR','850');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('234','WF','WALLIS AND FUTUNA','Wallis and Futuna','WLF','876');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('235','EH','WESTERN SAHARA','Western Sahara','ESH','732');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('236','YE','YEMEN','Yemen','YEM','887');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('237','ZM','ZAMBIA','Zambia','ZMB','894');
INSERT INTO countries (id, iso, name, printable_name, iso3, numcode) VALUES ('238','ZW','ZIMBABWE','Zimbabwe','ZWE','716');
