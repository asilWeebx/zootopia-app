// ERP bo'limlarining tartibi va ildiz guruhi. Ombor guruhlarining xaridor
// ko'radigan nomlari ("Весовой" → "Tortib sotiladi" / "На развес") —
// `l10n/` lug'atlaridagi `categoryLabels`.
// Saytdagi `src/config/catalog.ts` bilan bir xil saqlang.

/// ERP'dagi bo'limlar ro'yxati yuqoridan pastga, subbo'limlar ular bor birinchi
/// bo'lim ostida (Для Собак'niki Для Кошек'niki bilan bir tartibda). ERP'ning
/// "Bo'limlar" panelidan 2026-11-06 da ko'chirilgan — API tartib bermaydi, id
/// tartibi ham u emas. Panel o'zgarsa yangilang; bu yerda yo'q bo'lim shulardan
/// keyin turadi.
const kCategoryOrder = [
  'Аквариум',
  'Смеси',
  'Для Кошек',
  'Влажный корм',
  'Сухой корм',
  'Консерва',
  'Лакомства',
  'Витамины и добавки',
  'Наполнители',
  'Латки',
  'Игрушки',
  'Для Собак',
  'Для Птиц',
  'Клетки',
  'Корм',
  'Для Грызунов',
  'Ветаптека',
  'Ошейники / Поводки',
  'Переноски и Домики',
  'Грумминг и уход',
  'Миски',
];

/// Bo'limning `kCategoryOrder`dagi o'rni; ro'yxatda yo'qlar hammasi undan keyingi bitta o'rinda.
int categoryRank(String name) {
  final rank = kCategoryOrder.indexOf(name.trim());
  return rank < 0 ? kCategoryOrder.length : rank;
}

/// ERP'ning ildiz guruhi. To'g'ridan-to'g'ri shu yerdagi mahsulotlarning
/// haqiqiy kategoriyasi yo'q — ular "Boshqa mahsulotlar"da chiqadi.
final kRootCategory = RegExp(r'^(корневая группа|root|asosiy guruh)$', caseSensitive: false, unicode: true);
