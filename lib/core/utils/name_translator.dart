import 'package:flutter/material.dart';

extension ArabicNameExtension on String {
  /// Converts English names to Arabic using a simple dictionary and transliteration fallback.
  /// If the current locale is not Arabic, returns the original string.
  String toArabicName(BuildContext context) {
    if (this.isEmpty) return this;
    
    final locale = Localizations.maybeLocaleOf(context);
    if (locale?.languageCode != 'ar') {
      return this;
    }

    // NEW: If string already contains Arabic characters, don't try to translate
    bool containsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(this);
    if (containsArabic) return this;

    // 1. Check strict dictionary for famous players or exact matches
    final normalizedInput = this.trim().toLowerCase();
    if (_famousPlayersMap.containsKey(normalizedInput)) {
      return _famousPlayersMap[normalizedInput]!;
    }

    // 2. Check word by word for known partials (e.g. "Mohamed", "Salah")
    final words = this.trim().split(RegExp(r'\s+'));
    List<String> translatedWords = [];
    
    for (var word in words) {
      final normalizedWord = word.toLowerCase();
      if (_famousPlayersMap.containsKey(normalizedWord)) {
        translatedWords.add(_famousPlayersMap[normalizedWord]!);
      } else {
        // 3. Fallback: Transliteration
        translatedWords.add(_transliterate(word));
      }
    }

    return translatedWords.join(' ');
  }

  // Basic map for famous/common names to ensure accuracy
  static const Map<String, String> _famousPlayersMap = {
    'mohamed': 'محمد',
    'salah': 'صلاح',
    'lionel': 'ليونيل',
    'messi': 'ميسي',
    'cristiano': 'كريستيانو',
    'ronaldo': 'رونالدو',
    'kylian': 'كيليان',
    'mbappe': 'مبابي',
    'erling': 'إيرلينغ',
    'haaland': 'هالاند',
    'kevin': 'كيفين',
    'de bruyne': 'دي بروين',
    'neymar': 'نيمار',
    'vinicius': 'فينيسيوس',
    'junior': 'جونيور',
    'lewandowski': 'ليفاندوفسكي',
    'robert': 'روبرت',
    'karim': 'كريم',
    'benzema': 'بنزيما',
    'luka': 'لوكا',
    'modric': 'مودريتش',
    'virgil': 'فيرجيل',
    'van dijk': 'فان دايك',
    'alisson': 'أليسون',
    'ederson': 'إيدرسون',
    'rashford': 'راشفورد',
    'marcus': 'ماركوس',
    'bruno': 'برونو',
    'fernandes': 'فيرنانديز',
    'saka': 'ساكا',
    'bukayo': 'بوكايو',
    'son': 'سون',
    'heung-min': 'هيونغ مين',
    'kane': 'كين',
    'harry': 'هاري',
    'bellingham': 'بيلينجهام',
    'jude': 'جود',
    'pedri': 'بيدري',
    'gavi': 'جافي',
    'mbappé': 'مبابي',
    'ali': 'علي',
    'ahmed': 'أحمد',
    'omar': 'عمر',
    'hassan': 'حسن',
    'ibrahim': 'إبراهيم',
    'abdullah': 'عبدالله',
    'yousef': 'يوسف',
    'taremi': 'طارمي',
    'mahrez': 'محرز',
    'riyad': 'رياض',
    'hakimi': 'حكيمي',
    'achraf': 'أشرف',
    'ziyech': 'زياش',
    'hakim': 'حكيم',
    'bounou': 'بونو',
    'yassine': 'ياسين',
    'amrabat': 'أمرابط',
    'sofyan': 'سفيان',
    'mane': 'ماني',
    'sadio': 'ساديو',
    'mendy': 'ميندي',
    'koulibaly': 'كوليبالي',
    'silva': 'سيلفا',
    'bernardo': 'برناردو',
    'ruben': 'روبن',
    'dias': 'دياز',
    'cancelo': 'كانسيلو',
    'joao': 'جواو',
    'felix': 'فيليكس',
    'martinez': 'مارتينيز',
    'emiliano': 'إيميليانو',
    'lautaro': 'لاوتارو',
    'alvarez': 'ألفاريز',
    'julian': 'جوليان',
    'enzo': 'إنزو',
    'fernandez': 'فيرنانديز',
    'mac allister': 'ماك أليستر',
    'alexis': 'أليكسيس',
    'gabriel': 'غابرييل',
    'martin': 'مارتن',
    'odegaard': 'أوديغارد',
    'rice': 'رايس',
    'declan': 'ديكلان',
    'foden': 'فودين',
    'phil': 'فيل',
    'grealish': 'غريليش',
    'jack': 'جاك',
    'stones': 'ستونز',
    'john': 'جون',
    'walker': 'ووكر',
    'kyle': 'كايل',
    'rodri': 'رودري',
    'gundogan': 'غوندوغان',
    'ilkay': 'إيلكاي',
    'kroos': 'كروس',
    'toni': 'توني',
    'camavinga': 'كامافينجا',
    'eduardo': 'إدواردو',
    'tchouameni': 'تشواميني',
    'aurelien': 'أوريلين',
    'valverde': 'فالفيردي',
    'federico': 'فيديريكو',
    'courtois': 'كورتوا',
    'thibaut': 'تيبو',
    'militao': 'ميليتاو',
    'eder': 'إيدير',
    'rudiger': 'روديجر',
    'antonio': 'أنطونيو',
    'alaba': 'ألابا',
    'david': 'ديفيد',
    'carvajal': 'كارفخال',
    'dani': 'داني',
    'ter stegen': 'تير شتيغن',
    'marc-andre': 'مارك أندريه',
    'araujo': 'أراوخو',
    'ronald': 'رونالد',
    'kounde': 'كوندي',
    'jules': 'جول',
    'christensen': 'كريستنسن',
    'andreas': 'أندرياس',
    'balde': 'بالدي',
    'alejandro': 'أليخاندرو',
    'frenkie': 'فرينكي',
    'de jong': 'دي يونغ',
    'raphinha': 'رافينيا',
    'yamal': 'يامال',
    'lamine': 'لامين',
    'musiala': 'موسيالا',
    'jamal': 'جمال',
    'wirtz': 'فيرتز',
    'florian': 'فلوريان',
    'leao': 'لياو',
    'rafael': 'رافاييل',
    'theo': 'تيو',
    'maignan': 'ماينان',
    'mike': 'مايك',
    'osimhen': 'أوسيمين',
    'victor': 'فيكتور',
    'kvaratskhelia': 'كفاراتسخيليا',
    'khvicha': 'خفيشا',
    'dybala': 'ديبالا',
    'paulo': 'باولو',
    'lukaku': 'لوكاكو',
    'romelu': 'روميلو',
    'saliba': 'ساليبا',
    'william': 'ويليام',
    'jesus': 'جيسوس',
    'havertz': 'هافيرتز',
    'kai': 'كاي',
    'pulisic': 'بوليسيتش',
    'christian': 'كريستيان',
    'giroud': 'جيرو',
    'olivier': 'أوليفييه',
    'muller': 'مولر',
    'thomas': 'توماس',
    'sane': 'ساني',
    'leroy': 'ليروي',
    'coman': 'كومان',
    'kingsley': 'كينغسلي',
    'neuer': 'نوير',
    'manuel': 'مانويل',
    'upamecano': 'أوباميكانو',
    'dayot': 'دايوت',
    'kim': 'كيم',
    'min-jae': 'مين جاي',
    'davies': 'ديفيز',
    'alphonso': 'ألفونسو',
    'kimmich': 'كيميتش',
    'joshua': 'جوشوا',
    'goretzka': 'غوريتسكا',
    'leon': 'ليون',
    'gnabry': 'غنابري',
    'serge': 'سيرج',
    'arsenal': 'آرسنال',
    'chelsea': 'تشيلسي',
    'liverpool': 'ليفربول',
    'manchester city': 'مانشستر سيتي',
    'manchester united': 'مانشستر يونايتد',
    'tottenham': 'توتنهام',
    'hotspur': 'هوتسبر',
    'newcastle': 'نيوكاسل',
    'aston villa': 'أستون فيلا',
    'west ham': 'وست هام',
    'brighton': 'برايتون',
    'wolves': 'وولفز',
    'everton': 'إيفرتون',
    'crystal palace': 'كريستال بالاس',
    'brentford': 'برينتفورد',
    'nottingham forest': 'نوتينغهام فورست',
    'burnley': 'بيرنلي',
    'sheffield united': 'شيفيلد يونايتد',
    'luton town': 'لوتون تاون',
    'bournemouth': 'بورنموث',
    'fulham': 'فولهام',
  };

  static String _transliterate(String word) {
    if (word.isEmpty) return word;
    
    // Very basic transliteration logic, covers standard English mapping dynamically
    // In production, an AI or complete library is ideal, but this gives a readable approximation.
    String w = word.toLowerCase();
    
    w = w.replaceAll('sh', 'ش');
    w = w.replaceAll('ch', 'تش');
    w = w.replaceAll('th', 'ث');
    w = w.replaceAll('ph', 'ف');
    w = w.replaceAll('kh', 'خ');
    w = w.replaceAll('gh', 'غ');
    
    // Vowels (simplistic approximation)
    w = w.replaceAll('ee', 'ي');
    w = w.replaceAll('oo', 'و');
    
    // Consonants
    Map<String, String> mappedLetters = {
      'a': 'ا', 'b': 'ب', 'c': 'ك', 'd': 'د', 'e': 'ي', 'f': 'ف',
      'g': 'غ', 'h': 'ه', 'i': 'ي', 'j': 'ج', 'k': 'ك', 'l': 'ل',
      'm': 'م', 'n': 'ن', 'o': 'و', 'p': 'ب', 'q': 'ق', 'r': 'ر',
      's': 'س', 't': 'ت', 'u': 'و', 'v': 'ف', 'w': 'و', 'x': 'كس',
      'y': 'ي', 'z': 'ز',
    };
    
    StringBuffer result = StringBuffer();
    for (int i = 0; i < w.length; i++) {
        String char = w[i];
        if (mappedLetters.containsKey(char)) {
            result.write(mappedLetters[char]);
        } else {
            result.write(char);
        }
    }
    
    // Cleanup repeating arabic vowels/letters that look unnatural at the start
    String transliterated = result.toString();
    if (transliterated.startsWith('ا') && word.toLowerCase().startsWith('a')) {
       transliterated = 'أ' + transliterated.substring(1);
    }
    
    return transliterated;
  }
}
