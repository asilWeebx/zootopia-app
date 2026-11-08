// Qaysi alohida ERP mahsulotlari ilovada tanlovli bitta mahsulot bo'lib
// ko'rinadi (`services/groups.dart` qo'llaydi). Do'kon har ta'mni o'z
// mahsuloti qilib yozadi; bu yerdagi hech narsa ERP'ni yoki buyurtma
// tarkibini o'zgartirmaydi.
//
// Mahsulotlar quyidagi bo'lim, brend va qadoq o'lchami bir xil bo'lsa
// birlashadi. Brendni alohida qoldirish uchun uni `kLineOnlyBrands`ga,
// uning bir seriyasini birlashtirish uchun seriyani `kSpelledBrands`ga qo'shing.
// Saytdagi `src/config/groups.ts` bilan bir xil saqlang.

/// Guruh mahsulotlari nimasi bilan farq qiladi — tanlagich va karta so'zlari.
enum GroupKind { flavour, type, scent }

/// Birlashadigan bo'limlar (ERP bo'lim nomining oxirgi qismi) va ulardagi tanlov nomi.
const kGroupedSections = <String, GroupKind>{
  'Влажный корм': GroupKind.flavour,
  'Консерва': GroupKind.flavour,
  'Лакомства': GroupKind.flavour,
  'Сухой корм': GroupKind.type,
  'Корм': GroupKind.type,
  'Наполнители': GroupKind.type,
};

/// Bitta brend bir necha qadoq o'lchamida keladigan, o'lchami alohida tanlanadigan bo'limlar ("5 л", "10 л").
const kSizeChoiceSections = ['Наполнители'];

/// Tanlovi turi emas, hidi bo'lgan to'ldirgich brendlari.
const kScentBrands = ['proline', 'tofu'];

class SpelledBrand {
  /// Xaridor o'qiydigan nom.
  final String name;
  /// Kichik harflarda.
  final List<String> spellings;
  const SpelledBrand(this.name, this.spellings);
}

/// Bir necha so'zli brendlar, har xil yozilishlar (ERP xatolari ham) va
/// `kLineOnlyBrands`ning nomlangan seriyalari. Boshqa har qanday brend — nomning
/// birinchi so'zi.
const kSpelledBrands = [
  SpelledBrand('Club 4 Paws', ['club 4 paws']),
  SpelledBrand('Клуб 4 Лапы', ['клуб 4 лапы']),
  SpelledBrand('Perfect Fit', ['perfect fit', 'perfect']),
  SpelledBrand('OPTI MEAL', ['opti meal']),
  SpelledBrand('PRO PLAN', ['pro plan', 'rpo plan']),
  SpelledBrand('Pro Performance', ['pro performance']),
  SpelledBrand('Purina One', ['purina one']),
  SpelledBrand('Royal Canin', ['royal canin']),
  SpelledBrand('Pet Flat', ['pet flat']),
  SpelledBrand('GimCat Snack Cream', ['gimcat snack cream']),
  SpelledBrand('GimCat Sticks', ['gimcat sticks']),
  SpelledBrand('GimCat Nutri', ['gimcat nutri']),
  SpelledBrand('TRIXIE Stick Quintet', ['trixie stick quintet']),
];

/// Nomni boshlaydigan, lekin brend bo'lmagan so'zlar: "Наполнитель TOFU LAVENDER 6L".
const kNotBrands = ['наполнитель'];

/// Bir nom ostida bir-biriga aloqasiz mol sotadigan brendlar: faqat ularning `kSpelledBrands`dagi seriyalari birlashadi.
const kLineOnlyBrands = ['gimcat', 'trixie', 'premio'];
