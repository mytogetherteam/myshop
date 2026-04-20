class ThailandAddressData {
  static const List<String> provinces = [
    'Bangkok', 'Amnat Charoen', 'Ang Thong', 'Bueng Kan', 'Buriram', 'Chachoengsao', 
    'Chai Nat', 'Chaiyaphum', 'Chanthaburi', 'Chiang Mai', 'Chiang Rai', 'Chonburi', 
    'Chumphon', 'Kalasin', 'Kamphaeng Phet', 'Kanchanaburi', 'Khon Kaen', 'Krabi', 
    'Lampang', 'Lamphun', 'Loei', 'Lopburi', 'Mae Hong Son', 'Maha Sarakham', 
    'Mukdahan', 'Nakhon Nayok', 'Nakhon Pathom', 'Nakhon Phanom', 'Nakhon Ratchasima', 
    'Nakhon Sawan', 'Nakhon Si Thammarat', 'Nan', 'Narathiwat', 'Nong Bua Lamphu', 
    'Nong Khai', 'Nonthaburi', 'Pathum Thani', 'Pattani', 'Phang Nga', 'Phatthalung', 
    'Phayao', 'Phetchabun', 'Phetchaburi', 'Phichit', 'Phitsanulok', 'Phra Nakhon Si Ayutthaya', 
    'Phrae', 'Phuket', 'Prachinburi', 'Prachuap Khiri Khan', 'Ranong', 'Ratchaburi', 
    'Rayong', 'Roi Et', 'Sa Kaeo', 'Sakon Nakhon', 'Samut Prakan', 'Samut Sakhon', 
    'Samut Songkhram', 'Saraburi', 'Satun', 'Sing Buri', 'Sisaket', 'Songkhla', 
    'Sukhothai', 'Suphan Buri', 'Surat Thani', 'Surin', 'Tak', 'Trang', 'Trat', 
    'Ubon Ratchathani', 'Udon Thani', 'Uthai Thani', 'Uttaradit', 'Yala', 'Yasothon'
  ];

  static const Map<String, List<String>> districtsByProvince = {
    'Bangkok': [
      'Bangkok Riverside', 'Bang Rak', 'Watthana', 'Khlong Toei', 'Huai Khwang', 
      'Chatuchak', 'Bang Kapi', 'Phaya Thai', 'Dusit', 'Phra Khanong', 'Phra Nakhon', 
      'Pom Prap Sattru Phai', 'Samphanthawong', 'Pathum Wan', 'Yan Nawa', 'Sathon', 
      'Bang Kho Laem', 'Taling Chan', 'Bang Goke Noi', 'Bang Khun Thian', 'Phasi Charoen', 
      'Nong Khaem', 'Rat Burana', 'Bang Phlat', 'Din Daeng', 'Bueng Kum', 'Sathon',
      'Bang Na', 'Min Buri', 'Lat Krabang', 'Sai Mai', 'Khan Na Yao', 'Saphan Sung', 
      'Wang Thonglang', 'Khlong Sam Wa', 'Suan Luang', 'Taling Chan', 'Bang Kaeo'
    ],
    'Chiang Mai': [
      'Mueang Chiang Mai', 'Mae Rim', 'Mae Taeng', 'Mae Wang', 'Mae Ai', 'Chai Prakan', 
      'Chiang Dao', 'Fang', 'Hang Dong', 'Hot', 'Omkoi', 'Phrao', 'Samoeng', 
      'San Kamphaeng', 'San Sai', 'Saraphi', 'Wiang Haeng'
    ],
    'Phuket': [
      'Mueang Phuket', 'Kathu', 'Thalang'
    ],
    'Chonburi': [
      'Mueang Chon Buri', 'Pattaya', 'Bang Lamung', 'Si Racha', 'Sattahip', 'Ban Bueng', 'Phanat Nikhom', 'Ko Sichang'
    ],
    'Rayong': [
      'Mueang Rayong', 'Ban Chang', 'Klaeng', 'Pluak Daeng', 'Ban Khai', 'Nikhom Phatthana'
    ],
    'Nonthaburi': [
      'Mueang Nonthaburi', 'Bang Bua Thong', 'Bang Kruai', 'Bang Yai', 'Pak Krett'
    ],
    'Samut Prakan': [
      'Mueang Samut Prakan', 'Bang Bo', 'Bang Phli', 'Phra Pradaeng', 'Phra Samut Chedi'
    ],
    'Udon Thani': [
      'Mueang Udon Thani', 'Ban Dung', 'Kumphawapi', 'Ban Phue', 'Phen', 'Nong Han'
    ],
    'Khon Kaen': [
      'Mueang Khon Kaen', 'Chum Phae', 'Ban Phai', 'Phon', 'Nong Ruea', 'Kranuan'
    ],
    'Nakhon Ratchasima': [
      'Mueang Nakhon Ratchasima', 'Pak Chong', 'Sikhiu', 'Non Sung', 'Chum Phuang', 'Phimai'
    ],
    'Ayutthaya': [
       'Phra Nakhon Si Ayutthaya', 'Bang Pa-in', 'Wang Noi', 'Uthai', 'Nakhon Luang'
    ],
    'Samui (Surat Thani)': [
      'Ko Samui', 'Ko Pha Ngan', 'Ko Tao'
    ],
    'Surat Thani': [
      'Mueang Surat Thani', 'Phanom', 'Kanchanadit', 'Don Sak', 'Chaiya', 'Wiang Sa'
    ],
    'Samut Sakhon': [
      'Mueang Samut Sakhon', 'Krathum Baen', 'Ban Phaeo'
    ],
    'Krabi': [
      'Mueang Krabi', 'Ao Luek', 'Ko Lanta', 'Nuea Khlong', 'Khao Phanom'
    ],
    'Surin': [
      'Mueang Surin', 'Chom Phra', 'Tha Tum', 'Sangkha', 'Prasat'
    ],
    'Tak': [
      'Mueang Tak', 'Mae Sot', 'Umphang', 'Ban Tak', 'Sam Ngao'
    ],
    'Trang': [
       'Mueang Trang', 'Kantang', 'Huai Yot', 'Palyan', 'Yan Ta Khao'
    ],
    'Uthai Thani': [
       'Mueang Uthai Thani', 'Nong Chang', 'Nong Khayang', 'Ban Rai'
    ],
    'Yala': [
       'Mueang Yala', 'Betong', 'Bannang Sata', 'Yaha'
    ],
    'Lopburi': [
       'Mueang Lop Buri', 'Khok Samrong', 'Chai Badan', 'Phatthana Nikhom'
    ],
    'Lampang': [
       'Mueang Lampang', 'Ko Kha', 'Thoen', 'Mae Mo', 'Ngao'
    ],
    // More basic entries for other provinces
    'Amnat Charoen': ['Mueang Amnat Charoen', 'Hua Taphan', 'Lue Amnat'],
    'Ang Thong': ['Mueang Ang Thong', 'Wiset Chai Chan', 'Pa Mok'],
    'Bueng Kan': ['Mueang Bueng Kan', 'Seka', 'So Phisai'],
    'Buriram': ['Mueang Buriram', 'Nang Rong', 'Prakhon Chai', 'Satuek'],
    'Chachoengsao': ['Mueang Chachoengsao', 'Bang Pakong', 'Phanom Sarakham'],
    'Chai Nat': ['Mueang Chai Nat', 'Sankhaburi', 'Wat Sing'],
    'Chaiyaphum': ['Mueang Chaiyaphum', 'Phu Khiao', 'Kaeng Khro'],
    'Chanthaburi': ['Mueang Chanthaburi', 'Tha Mai', 'Klung'],
    'Chiang Rai': ['Mueang Chiang Rai', 'Mae Sai', 'Mae Chan', 'Chiang Khong'],
    'Chumphon': ['Mueang Chumphon', 'Lang Suan', 'Phato'],
    'Kalasin': ['Mueang Kalasin', 'Yang Talat', 'Somdet'],
    'Kamphaeng Phet': ['Mueang Kamphaeng Phet', 'Khanu Woralaksaburi', 'Khlong Khlung'],
    'Kanchanaburi': ['Mueang Kanchanaburi', 'Tha Muang', 'Thong Pha Phum', 'Sangkhla Buri'],
    'Lamphun': ['Mueang Lamphun', 'Pa Sang', 'Ban Hong'],
    'Loei': ['Mueang Loei', 'Wang Saphung', 'Chiang Khan'],
    'Mae Hong Son': ['Mueang Mae Hong Son', 'Pai', 'Mae Sariang'],
    'Maha Sarakham': ['Mueang Maha Sarakham', 'Kantharawichai', 'Kosum Phisai'],
    'Mukdahan': ['Mueang Mukdahan', 'Khamcha-i', 'Don Tan'],
    'Nakhon Nayok': ['Mueang Nakhon Nayok', 'Ban Na', 'Ongkharak'],
    'Nakhon Pathom': ['Mueang Nakhon Pathom', 'Sam Phran', 'Nakhon Chai Si'],
    'Nakhon Phanom': ['Mueang Nakhon Phanom', 'That Phanom', 'Ban Phaeng'],
    'Nakhon Sawan': ['Mueang Nakhon Sawan', 'Lat Yao', 'Takhli'],
    'Nakhon Si Thammarat': ['Mueang Nakhon Si Thammarat', 'Thung Song', 'Pak Phanang'],
    'Nan': ['Mueang Nan', 'Pua', 'Tha Wang Pha'],
    'Narathiwat': ['Mueang Narathiwat', 'Sungai Kolok', 'Ra-ngae'],
    'Nong Bua Lamphu': ['Mueang Nong Bua Lamphu', 'Na Klang', 'Si Bun Rueang'],
    'Nong Khai': ['Mueang Nong Khai', 'Tha Bo', 'Phon Phisai'],
    'Pathum Thani': ['Mueang Pathum Thani', 'Khlong Luang', 'Thanyaburi', 'Lam Luk Ka'],
    'Pattani': ['Mueang Pattani', 'Khok Pho', 'Sai Buri'],
    'Phang Nga': ['Mueang Phang Nga', 'Takua Pa', 'Thai Mueang'],
    'Phatthalung': ['Mueang Phatthalung', 'Khuan Khanun', 'Pak Phayun'],
    'Phayao': ['Mueang Phayao', 'Chiang Kham', 'Dok Khamtai'],
    'Phetchabun': ['Mueang Phetchabun', 'Lom Sak', 'Wichian Buri'],
    'Phetchaburi': ['Mueang Phetchaburi', 'Cha-am', 'Tha Yang'],
    'Phichit': ['Mueang Phichit', 'Taphan Hin', 'Bang Mun Nak'],
    'Phitsanulok': ['Mueang Phitsanulok', 'Nakhon Thai', 'Wang Thong'],
    'Phra Nakhon Si Ayutthaya': ['Mueang Phra Nakhon Si Ayutthaya', 'Bang Pa-in', 'Wang Noi'],
    'Phrae': ['Mueang Phrae', 'Sung Men', 'Den Chai'],
    'Prachinburi': ['Mueang Prachin Buri', 'Kabin Buri', 'Si Maha Phot'],
    'Prachuap Khiri Khan': ['Mueang Prachuap Khiri Khan', 'Hua Hin', 'Pran Buri'],
    'Ranong': ['Mueang Ranong', 'Kapoe', 'La-un'],
    'Ratchaburi': ['Mueang Ratchaburi', 'Ban Pong', 'Photharam'],
    'Roi Et': ['Mueang Roi Et', 'Selaphum', 'Phon Thong'],
    'Sa Kaeo': ['Mueang Sa Kaeo', 'Aranyaprathet', 'Watthana Nakhon'],
    'Sakon Nakhon': ['Mueang Sakon Nakhon', 'Sawang Daen Din', 'Phanna Nikhom'],
    'Samut Songkhram': ['Mueang Samut Songkhram', 'Bang Khonthi', 'Amphawa'],
    'Saraburi': ['Mueang Saraburi', 'Kaeng Khoi', 'Phra Phutthabat'],
    'Satun': ['Mueang Satun', 'Khuan Don', 'La-ngu'],
    'Sing Buri': ['Mueang Sing Buri', 'In Buri', 'Bang Rachan'],
    'Sisaket': ['Mueang Si Sa Ket', 'Kantharalak', 'Rasi Salai'],
    'Songkhla': ['Mueang Songkhla', 'Hat Yai', 'Sadao', 'Ranot'],
    'Sukhothai': ['Mueang Sukhothai', 'Sawankhalok', 'Si Satchanalai'],
    'Suphan Buri': ['Mueang Suphan Buri', 'Doem Bang Nang Buat', 'Song Phi Nong'],
    'Trat': ['Mueang Trat', 'Khao Saming', 'Ko Chang'],
    'Ubon Ratchathani': ['Mueang Ubon Ratchatnai', 'Warin Chamrap', 'Det Udom'],
    'Uttaradit': ['Mueang Uttaradit', 'Phichai', 'Laplae'],
    'Yasothon': ['Mueang Yasothon', 'Kham Khuean Kaeo', 'Loeng Nok Tha'],
  };
}
