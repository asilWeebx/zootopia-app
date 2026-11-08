// Do'kon ma'lumotlari — API bermaydi. Bo'sh qoldirilgan maydon shunchaki
// ko'rsatilmaydi. Saytdagi `src/config/store.ts` bilan bir xil saqlang.

/// Logodagi brend. ERP'dagi nomlar ("Zootopia", "Крытый магазин") — tashkilot
/// va filial. Shior ("Uy hayvonlari do‘koni" / "Зоомагазин") — `l10n/`da.
class Brand {
  static const name = 'Zootopiya';
}

class StoreContact {
  /// Futerda telefonlar ustida ko'rsatiladi.
  static const owner = 'Mirsoli Akramov';
  /// Futer va rasmiylashtirishda, masalan ["+998 90 123 45 67"].
  static const phones = <String>['+998 99 712 12 12'];
  /// Olib ketish manzili, masalan "Toshkent sh., ... ko'chasi 12".
  static const address = '';
  /// Manzil mo'ljali, masalan "Yopiq bozor ichida".
  static const landmark = '';
  /// Masalan "Har kuni 9:00–20:00".
  static const hours = '';
  /// Kuryer yetkazadigan hudud, masalan "Toshkent shahri".
  static const deliveryArea = '';
  /// To'liq havolalar, masalan "https://t.me/zootopiya".
  static const telegram = '';
  static const instagram = '';
}

/// Futerning pastki qatorida.
const kDeveloper = 'Mirsodiq Akramov';

/// Maxfiylik savollariga javob beradigan aloqa (maxfiylik sahifasida).
class PrivacyContact {
  static const phone = '+998 97 802 2008';
  static const email = 'asilweb9999@icloud.com';
}

/// Xarita mijoz siljitmaguncha shu yerda ochiladi: Toshkent.
const kMapCenterLat = 41.311081;
const kMapCenterLng = 69.240562;

/// "+998 90 123 45 67" → "tel:+998901234567".
String telHref(String phone) => 'tel:${phone.replaceAll(RegExp(r'[^\d+]'), '')}';
