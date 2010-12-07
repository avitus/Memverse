# [ALV] mysql -u [username] -p[password] -hmysql.[domainname].com [database_name] < iso_country_list.sql

DROP TABLE IF EXISTS american_states;

CREATE TABLE `american_states` (
  `id` SMALLINT NOT NULL PRIMARY KEY,
  `abbrev` varchar(20) NOT NULL default '',
  `name` varchar(50) NOT NULL default ''
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- 
-- Dumping data for table `state_abbreviations`
-- 

INSERT INTO `american_states` (`id`, `abbrev`, `name`) VALUES ('0', 'AL', 'Alabama'),
('1', 'AK', 'Alaska'),
('2', 'AZ', 'Arizona'),
('3', 'AR', 'Arkansas'),
('4', 'CA', 'California'),
('5', 'CO', 'Colorado'),
('6', 'CT', 'Connecticut'),
('7', 'DE', 'Delware'),
('8', 'DC', 'District of Columbia'),
('9', 'FL', 'Florida'),
('10', 'GA', 'Georgia'),
('11', 'HI', 'Hawaii'),
('12', 'ID', 'Idaho'),
('13', 'IL', 'Illinois'),
('14', 'IN', 'Indiana'),
('15', 'IA', 'Iowa'),
('16', 'KS', 'Kansas'),
('17', 'KY', 'Kentucky'),
('18', 'LA', 'Louisiana'),
('19', 'ME', 'Maine'),
('20', 'MD', 'Maryland'),
('21', 'MA', 'Massachusetts'),
('22', 'MI', 'Michigan'),
('23', 'MN', 'Minnesota'),
('24', 'MS', 'Mississippi'),
('25', 'MO', 'Missouri'),
('26', 'MT', 'Montana'),
('27', 'NE', 'Nebraska'),
('28', 'NV', 'Nevada'),
('29', 'NH', 'New Hampshire'),
('30', 'NJ', 'New Jersey'),
('31', 'NM', 'New Mexico'),
('32', 'NY', 'New York'),
('33', 'NC', 'North Carolina'),
('34', 'ND', 'North Dakota'),
('35', 'OH', 'Ohio'),
('36', 'OK', 'Oklahoma'),
('37', 'OR', 'Oregon'),
('38', 'PA', 'Pennsylvania'),
('39', 'PR', 'Puerto Rico'),
('40', 'RI', 'Rhode Island'),
('41', 'SC', 'South Carolina'),
('42', 'SD', 'South Dakota'),
('43', 'TN', 'Tennessee'),
('44', 'TX', 'Texas'),
('45', 'UT', 'Utah'),
('46', 'VT', 'Vermont'),
('47', 'VI', 'Virgin Islands'),
('48', 'VA', 'Virginia'),
('49', 'WA', 'Washington'),
('50', 'WV', 'West Virginia'),
('51', 'WI', 'Wisconsin'),
('52', 'WY', 'Wyoming');
