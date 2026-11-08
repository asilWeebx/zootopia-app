// Ilovadagi har bir so'z ikki tilda: rus (sukut) va o'zbek. Ikkala lug'at bir
// xil `Strings` sinfi — birida so'z qolib ketsa, ilova kompilyatsiya
// qilinmaydi. Mahsulot nomlari, ERP bo'limlari va boshqa do'kon ma'lumotlari
// bu yerda emas: ular do'kon yozganidek ko'rsatiladi. So'zlar saytdagi
// `src/i18n/dictionaries/{uz,ru}.ts`dan olingan.

import 'package:flutter/foundation.dart' show ValueNotifier;

import '../config/groups.dart';
import '../config/pets.dart';
import '../services/catalog.dart' show SortKey;
import '../services/feeding.dart' show Activity, Species, Stage;
import '../services/units.dart' show UnitKind;

part 'ru.dart';
part 'uz.dart';

enum AppLang { ru, uz }

/// Ilova tili. Sukut — rus tili; xaridor tanlovi qurilmada saqlanadi
/// (Kabinet → Til) va `main` uni ilova ochilishidan oldin o'qiydi.
final appLang = ValueNotifier<AppLang>(AppLang.ru);

/// Joriy tildagi so'zlar.
Strings get tr => stringsFor(appLang.value);

Strings stringsFor(AppLang lang) => switch (lang) {
      AppLang.ru => ru,
      AppLang.uz => uz,
    };

/// Til tugmasidagi nom — har til o'z nomi bilan.
String langName(AppLang lang) => switch (lang) {
      AppLang.ru => 'Русский',
      AppLang.uz => 'O‘zbekcha',
    };

typedef PetWords = ({String label, String forLabel});

class Strings {
  // ── Umumiy ────────────────────────────────────────────────────
  final String tagline;
  final String language;
  final String back;
  final String close;
  final String Function(String title) closeOf;
  final String loading;
  final String retry;
  final String error;
  final String decrease;
  final String increase;
  final String all;
  final String seeAll;
  final String Function(String title) seeAllOf;
  final String allProducts;
  final String Function(int n) products;
  final String Function(int n) variants;
  final String Function(int n) lines;
  final String Function(int n) cartCount;
  final String toCatalog;
  final String keepShopping;
  final String catalog;
  final String calculator;
  final String total;
  final String yes;
  final String no;

  // ── Pastki menyu ──────────────────────────────────────────────
  final String navHome;
  final String navCalculator;
  final String navCart;
  final String navAccount;

  // ── Birliklar va pul ──────────────────────────────────────────
  /// Son yoki narxdan keyingi qisqa yorliq ("dona", "шт").
  final Map<UnitKind, String> units;
  final String ml;
  final String som;
  /// Boshlang'ich narx: "5 000 so'mdan", "от 5 000 сум".
  final String Function(String amount, bool som) priceFrom;

  // ── Hayvonlar va mahsulot turlari ─────────────────────────────
  final Map<PetId, PetWords> pets;
  final Map<ProductTypeId, String> types;
  final String Function(Species species) species;

  // ── Mahsulot ──────────────────────────────────────────────────
  final String inStock;
  final String Function(String amount) stock;
  final String lowSuffix;
  final String notInStock;
  final String soldOut;
  final String lowStock;
  /// Faqat shuncha bor: savatda va kalkulyatorda.
  final String Function(String amount) onlyLeft;
  final String bestseller;
  final String weighedShort;
  final String weighedNote;
  final String details;
  final String choose;
  final String add;
  final String Function(String amount) addAmount;
  final String Function(int n) inCartVariants;
  final String addToCart;
  final String addedToCart;
  final String allInCart;
  final String allInCartLong;
  final String inCart;
  final String openCart;
  final String moreDetails;
  final String pickerVariant;
  final String pickerUnit;
  final String Function(String label) optionSoldOut;
  final String Function(String amount) optionStock;
  final String notFoundTitle;
  final String notFoundText;
  final String facts;
  final String description;

  // ── Ta'mlar guruhi ────────────────────────────────────────────
  final String Function(GroupKind kind) groupPicker;
  final String Function(GroupKind kind, int n) groupCount;
  final String Function(GroupKind kind) groupChoose;
  final String Function(GroupKind kind) groupSearch;
  /// Guruhning nechta ta'mi bor: "8 tasi bor".
  final String Function(int n) groupLeft;
  final String nothingFound;
  final String volume;
  final String pack;

  // ── Ma'lumotlar jadvali ───────────────────────────────────────
  final String specForWhom;
  final String specSection;
  final String specSold;
  final String specByWeight;
  final String Function(String unit) specByPiece;
  final String specSku;

  // ── Bosh sahifa ───────────────────────────────────────────────
  final String bestEyebrow;
  final String bestTitle;
  final String openSearch;

  // ── Katalog ───────────────────────────────────────────────────
  final String searchPlaceholder;
  final String clearSearch;
  final String emptyTitle;
  final String emptyText;
  final String suggestions;
  final String filters;
  final String Function(int n) filtersActive;
  final String sort;
  final Map<SortKey, String> sortOptions;
  final String sections;
  final String show;
  final String inStockOnly;
  final String onSale;
  final String clearFilters;
  final String uncategorized;
  final String unnamed;
  /// ERP ombor guruhlari xaridorga shunday ko'rinadi (saytdagi `CATEGORY_LABELS`).
  final Map<String, String> categoryLabels;

  // ── Mahsulot sahifasidagi ozuqa maslahati ─────────────────────
  final String Function(String weight, Species species) hintTypical;
  final String Function(String amount, int days) hintLasts;
  final String Function(String who, int grams) hintDaily;
  final String hintEdit;
  final String hintCalcOwn;

  // ── Kalkulyator ───────────────────────────────────────────────
  final String calcTitle;
  final String weight;
  final String Function(String min, String max) weightRange;
  final String pouchesQuestion;
  final String pouches;
  final String Function(Species species, Stage stage) stage;
  final String Function(Activity activity) activityLabel;
  final String Function(int days) period;
  final String age;
  final String neutered;
  final String activity;
  final String periodQuestion;
  final String Function(int days) forPeriod;
  final String calcEmpty;
  final String perDay;
  final String Function(int n, int grams) pouchesPerDay;
  final String Function(int n) pouchAmount;
  final String pickFood;
  final String fitTitle;
  final String Function(int meals, int grams) meals;
  final String dry;
  final String noDry;
  final String wet;
  final String noWet;
  final String pickedTotal;
  final String addBoth;
  final String added;
  final List<String> calcNotes;
  final String neuteredMatch;
  final String stageMatch;

  // ── Savat ─────────────────────────────────────────────────────
  final String cartEmpty;
  final String cartEmptyText;
  final String clear;
  final String clearCart;
  final String clearQuestion;
  final String clearText;
  final String weighedGroup;
  final String productsGroup;
  final String cartNote;
  final String remove;
  final String checkout;

  // ── Rasmiylashtirish ──────────────────────────────────────────
  final ({String title, String text}) cash;
  final ({String title, String text}) card;
  final String nameAndPhone;
  final String addressRequired;
  final String orderFailed;
  final String checkoutEmpty;
  final String checkoutEmptyText;
  final String checkoutTitle;
  final String recipient;
  final String name;
  final String namePlaceholder;
  final String phone;
  final String delivery;
  final String courier;
  final String pickup;
  final String address;
  final String addressPlaceholder;
  final String landmark;
  final String landmarkPlaceholder;
  final String locating;
  final String locateMe;
  final String pickOnMap;
  final String located;
  final String pickupAt;
  final String pickupCall;
  final String payment;
  final String comment;
  final String commentLabel;
  final String commentPlaceholder;
  final String summary;
  final String Function(String kg) kgFood;
  final String deliveryNote;
  final String submitting;
  final String submit;
  final String orderTitle;
  final String orderNumber;
  final String orderText;

  // ── Xarita va joylashuv ───────────────────────────────────────
  final String mapClose;
  final String zoomIn;
  final String zoomOut;
  final String mapLocate;
  final String mapPicked;
  final String mapNoAddress;
  final String mapConfirm;
  final String geoOff;
  final String geoDenied;
  final String geoBlocked;

  // ── Xatolar va do'kon holati ──────────────────────────────────
  final String network;
  final String Function(int status) apiStatus;
  final String Function(String name) optionGone;
  final String Function(String name, String left, String asked) overStock;
  final String Function(String name) soldOutOf;
  final String authTitle;
  final String unavailableTitle;
  final String authText;
  final String unavailableText;

  // ── Rasm oynasi ───────────────────────────────────────────────
  final String photo;
  final String lightboxHint;

  // ── Kabinet ───────────────────────────────────────────────────
  final String loginTitle;
  final String loginText;
  final String idRequired;
  final String checking;
  final String signIn;
  final String loadFailed;
  final String Function(String code) customerId;
  final String debt;
  final String credit;
  final String totalSales;
  final String sales;
  final String orders;
  final String payments;
  final String haptics;
  final String callShop;
  final String privacy;
  final String logout;
  final String noSales;
  final String noOrders;
  final String noPayments;
  final String Function(int n) saleN;
  final String Function(int n) orderN;
  final String Function(String amount) debtOf;
  final String paid;
  final String debtLeft;
  final String Function(String currency) debtIn;
  final String Function(String rate) rate;
  final List<String> months;
  final Map<String, String> paymentMethods;
  final Map<String, String> statuses;

  // ── Maxfiylik ─────────────────────────────────────────────────
  final String Function(String date) privacyUpdated;
  final String privacyDate;

  const Strings({
    required this.tagline,
    required this.language,
    required this.back,
    required this.close,
    required this.closeOf,
    required this.loading,
    required this.retry,
    required this.error,
    required this.decrease,
    required this.increase,
    required this.all,
    required this.seeAll,
    required this.seeAllOf,
    required this.allProducts,
    required this.products,
    required this.variants,
    required this.lines,
    required this.cartCount,
    required this.toCatalog,
    required this.keepShopping,
    required this.catalog,
    required this.calculator,
    required this.total,
    required this.yes,
    required this.no,
    required this.navHome,
    required this.navCalculator,
    required this.navCart,
    required this.navAccount,
    required this.units,
    required this.ml,
    required this.som,
    required this.priceFrom,
    required this.pets,
    required this.types,
    required this.species,
    required this.inStock,
    required this.stock,
    required this.lowSuffix,
    required this.notInStock,
    required this.soldOut,
    required this.lowStock,
    required this.onlyLeft,
    required this.bestseller,
    required this.weighedShort,
    required this.weighedNote,
    required this.details,
    required this.choose,
    required this.add,
    required this.addAmount,
    required this.inCartVariants,
    required this.addToCart,
    required this.addedToCart,
    required this.allInCart,
    required this.allInCartLong,
    required this.inCart,
    required this.openCart,
    required this.moreDetails,
    required this.pickerVariant,
    required this.pickerUnit,
    required this.optionSoldOut,
    required this.optionStock,
    required this.notFoundTitle,
    required this.notFoundText,
    required this.facts,
    required this.description,
    required this.groupPicker,
    required this.groupCount,
    required this.groupChoose,
    required this.groupSearch,
    required this.groupLeft,
    required this.nothingFound,
    required this.volume,
    required this.pack,
    required this.specForWhom,
    required this.specSection,
    required this.specSold,
    required this.specByWeight,
    required this.specByPiece,
    required this.specSku,
    required this.bestEyebrow,
    required this.bestTitle,
    required this.openSearch,
    required this.searchPlaceholder,
    required this.clearSearch,
    required this.emptyTitle,
    required this.emptyText,
    required this.suggestions,
    required this.filters,
    required this.filtersActive,
    required this.sort,
    required this.sortOptions,
    required this.sections,
    required this.show,
    required this.inStockOnly,
    required this.onSale,
    required this.clearFilters,
    required this.uncategorized,
    required this.unnamed,
    required this.categoryLabels,
    required this.hintTypical,
    required this.hintLasts,
    required this.hintDaily,
    required this.hintEdit,
    required this.hintCalcOwn,
    required this.calcTitle,
    required this.weight,
    required this.weightRange,
    required this.pouchesQuestion,
    required this.pouches,
    required this.stage,
    required this.activityLabel,
    required this.period,
    required this.age,
    required this.neutered,
    required this.activity,
    required this.periodQuestion,
    required this.forPeriod,
    required this.calcEmpty,
    required this.perDay,
    required this.pouchesPerDay,
    required this.pouchAmount,
    required this.pickFood,
    required this.fitTitle,
    required this.meals,
    required this.dry,
    required this.noDry,
    required this.wet,
    required this.noWet,
    required this.pickedTotal,
    required this.addBoth,
    required this.added,
    required this.calcNotes,
    required this.neuteredMatch,
    required this.stageMatch,
    required this.cartEmpty,
    required this.cartEmptyText,
    required this.clear,
    required this.clearCart,
    required this.clearQuestion,
    required this.clearText,
    required this.weighedGroup,
    required this.productsGroup,
    required this.cartNote,
    required this.remove,
    required this.checkout,
    required this.cash,
    required this.card,
    required this.nameAndPhone,
    required this.addressRequired,
    required this.orderFailed,
    required this.checkoutEmpty,
    required this.checkoutEmptyText,
    required this.checkoutTitle,
    required this.recipient,
    required this.name,
    required this.namePlaceholder,
    required this.phone,
    required this.delivery,
    required this.courier,
    required this.pickup,
    required this.address,
    required this.addressPlaceholder,
    required this.landmark,
    required this.landmarkPlaceholder,
    required this.locating,
    required this.locateMe,
    required this.pickOnMap,
    required this.located,
    required this.pickupAt,
    required this.pickupCall,
    required this.payment,
    required this.comment,
    required this.commentLabel,
    required this.commentPlaceholder,
    required this.summary,
    required this.kgFood,
    required this.deliveryNote,
    required this.submitting,
    required this.submit,
    required this.orderTitle,
    required this.orderNumber,
    required this.orderText,
    required this.mapClose,
    required this.zoomIn,
    required this.zoomOut,
    required this.mapLocate,
    required this.mapPicked,
    required this.mapNoAddress,
    required this.mapConfirm,
    required this.geoOff,
    required this.geoDenied,
    required this.geoBlocked,
    required this.network,
    required this.apiStatus,
    required this.optionGone,
    required this.overStock,
    required this.soldOutOf,
    required this.authTitle,
    required this.unavailableTitle,
    required this.authText,
    required this.unavailableText,
    required this.photo,
    required this.lightboxHint,
    required this.loginTitle,
    required this.loginText,
    required this.idRequired,
    required this.checking,
    required this.signIn,
    required this.loadFailed,
    required this.customerId,
    required this.debt,
    required this.credit,
    required this.totalSales,
    required this.sales,
    required this.orders,
    required this.payments,
    required this.haptics,
    required this.callShop,
    required this.privacy,
    required this.logout,
    required this.noSales,
    required this.noOrders,
    required this.noPayments,
    required this.saleN,
    required this.orderN,
    required this.debtOf,
    required this.paid,
    required this.debtLeft,
    required this.debtIn,
    required this.rate,
    required this.months,
    required this.paymentMethods,
    required this.statuses,
    required this.privacyUpdated,
    required this.privacyDate,
  });

  /// "kg" / "кг".
  String get kg => units[UnitKind.kg]!;

  /// "g" / "г".
  String get g => units[UnitKind.g]!;

  String petLabel(PetId id) => pets[id]!.label;
  String petForLabel(PetId id) => pets[id]!.forLabel;
}
