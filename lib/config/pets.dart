// Mahsulot kim uchun va qanday mahsulot ekani. ERP'da bunday maydon yo'q,
// lekin bo'limlari ko'pincha aytadi ("Для Кошек › Влажный корм", "Аквариум",
// "Грумминг и уход"), shuning uchun ikkalasi shu bo'limlardan va mahsulot
// nomidan (rus, o'zbek, ingliz) o'qiladi. Yangi mahsulot "Boshqalar"ga tushsa,
// so'zni shu yerga qo'shing. Bo'limlar id bilan emas, so'z bilan topiladi —
// do'kon ularni ERP'da qayta nomlashi yoki qo'shishi mumkin.
// Saytdagi `src/config/pets.ts` bilan bir xil saqlang.

/// `other` — hech bir hayvon nomlanmagan mahsulot (aksessuar, noma'lum brend).
enum PetId { cat, dog, bird, fish, small, other }

/// Hayvon nomlari (“Mushuklar”, “Кошки”) — `l10n/` lug'atlarida.
class PetDef {
  final PetId id;
  /// Nomda yoki ERP bo'limida faqat shu hayvonni bildiradigan so'z.
  final RegExp match;
  /// Ta'm ham bo'ladigan so'z ("Felix Кролик в Желе", "Мяу с Рыбой",
  /// "Домашняя Птица") — faqat mahsulot ochiq shu hayvonga atalganda
  /// hisoblanadi: "для кроликов", "Для Птиц".
  final RegExp? addressed;
  /// Faqat shu hayvonga ozuqa qiladigan brendlar ("Вискас пауч 80гр").
  final RegExp? brands;
  const PetDef(this.id, this.match, {this.addressed, this.brands});
}

RegExp _re(String source) => RegExp(source, caseSensitive: false, unicode: true);

/// "для рыб", "д/рыб", "for fish", "baliqlar uchun".
RegExp _addressedAs(String words, String uzbek) =>
    _re('(?<!\\p{L})(?:(?:(?:для|for)\\s+|д/\\s*)(?:$words)|(?:$uzbek)\\p{L}*\\s+uchun)');

// `(?<!\p{L})` — kirillda ham ishlaydigan so'z boshi (`\b` ishlamaydi).
// O'zaklar ataylab qisqa: "кош" — кошка, кошек, кошкам.
final kPets = <PetDef>[
  PetDef(
    PetId.cat,
    _re(r'(?<!\p{L})(кош|кот[её]?н|котят|кот(?!\p{L})|киттен|kitten|cat|mushuk|мейн[\s-]?кун|maine|сфинкс|перс(?:идск|(?!\p{L})))'),
    brands: _re(r'(?<!\p{L})(whiskas|вискас|gourmet|гоурме|гурме|darling|дарлинг|felix|феликс|sheba|шеба|kitekat|китекет|perfect fit|перфект|мяу|meow)'),
  ),
  PetDef(
    PetId.dog,
    _re(r'(?<!\p{L})(собак|щен|п[её]с(?!\p{L}|ок)|dog|puppy|kuchuk|it uchun|itlar|терьер|овчарк|лабрадор)'),
    brands: _re(r'(?<!\p{L})(pedigree|педигри|chappi|чаппи|cesar|цезарь)'),
  ),
  PetDef(
    PetId.bird,
    // "Карелла" — do'konda корелла (nimfa to'tiqush) shunday yozilgan.
    _re(r"(?<!\p{L})(попуга|папуга|канарей|амадин|волнист|корелл|карелл|parrot|to['‘’ʻ]?tiqush|tuti(?!\p{L}))"),
    addressed: _addressedAs('птиц|bird', 'qush'),
  ),
  PetDef(
    PetId.fish,
    _re(r'(?<!\p{L})(аквариум|akvarium)'),
    addressed: _addressedAs('рыб|fish', 'baliq'),
    brands: _re(r'(?<!\p{L})(tetra|тетра)'),
  ),
  PetDef(
    PetId.small,
    _re(r'(?<!\p{L})(грызун|хомя|шиншил|морск\p{L}* свин|крыс|hamster|olmaxon|kemiruvchi)'),
    addressed: _addressedAs('кролик|rabbit', 'quyon'),
  ),
];

enum ProductTypeId { wet, dry, treat, vitamin, litter, care }

/// Tur nomlari ("Quruq ozuqa", "Сухой корм") — `l10n/` lug'atlarida.
class ProductTypeDef {
  final ProductTypeId id;
  final RegExp match;
  const ProductTypeDef(this.id, this.match);
}

/// Shu tartibda tekshiriladi; birinchi mos kelgani — "витамин корм" vitamin.
final kProductTypes = <ProductTypeDef>[
  ProductTypeDef(ProductTypeId.vitamin, _re(r'(?<!\p{L})(витамин|добавк|минерал|vitamin|mineral)')),
  ProductTypeDef(ProductTypeId.treat, _re(r'(?<!\p{L})(лакомств|косточк|палочк|снек|treat|snack|shirinlik)')),
  ProductTypeDef(ProductTypeId.wet, _re(r'(?<!\p{L})(пауч|консерв|влажн|паштет|желе|в соусе|pouch|wet|pauch|konserva)')),
  ProductTypeDef(ProductTypeId.litter, _re(r'(?<!\p{L})(наполнит|litter|to.?ldirgich)')),
  ProductTypeDef(ProductTypeId.care,
      _re(r'(?<!\p{L})(шампун|расч[её]с|щ[её]тк|когтерез|грум+инг|уход|shampoo|shampun|taroq|parvarish)')),
  ProductTypeDef(ProductTypeId.dry, _re(r'(?<!\p{L})(сух|корм(?!ушк)|гранул|dry(?!\p{L})|food|quruq|ozuqa)')),
];

/// Faqat "ozuqa" deydigan ERP bo'limi ("Для Птиц › Корм") — nom aniqroq aytishi mumkin ("Mineral Rio").
final kGenericFoodSection = _re(r'^\s*(корм|ozuqa)\s*$');

/// Ozuqa bo'lmagan ERP bo'limlari va mollar, nomda qanday og'irlik bo'lmasin ("капли для кошек до 3кг").
final kNotFood = _re(
    r'(?<!\p{L})(ветаптек|аквариум|игрушк|ошейник|поводок|миск|лежак|переноск|клетк|когтеточк|кормушк|лотк|латк|молочн|milk|toy|o.?yinchoq|bo.?yinbog|idish)');

/// Ozuqa qadoqlaridagi yosh bosqichi — kalkulyator tavsiyalari uchun.
final kLifeStageYoung = _re(r'(?<!\p{L})(котят|кот[её]н|киттен|kitten|щен|pupp(?:y|ies)|junior|юниор|baby)');
final kLifeStageSenior = _re(r'(?<!\p{L})(senior|сеньор|пожил|7\+|11\+|старе)');
final kLifeStageAdult = _re(r'(?<!\p{L})(adult|взросл|kattalar)');
/// "для кошек и котят" — katta hayvonga ham ozuqa, demak mushukcha ozuqasi emas.
final kLifeStageAnyAge = _re(r'(?<!\p{L})(?:(?:кош|собак)\p{L}*\s+и\s+(?:кот|щен)|(?:кот|щен)\p{L}*\s+и\s+(?:кош|собак))');

/// Sterilizatsiya qilingan hayvon ozuqasi, do'kon yozganidek: "для стерилизованных", "для стерил.", "Sterilised".
final kSterilizedWords = _re(r'(?<!\p{L})(стер[ие]л|кастр|steril|neuter|kastr)');
