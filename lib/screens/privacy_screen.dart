import 'package:flutter/material.dart';

import '../config/store.dart';
import '../config/theme.dart';
import '../l10n/strings.dart';
import '../widgets/layout/page.dart';
import 'navigation.dart';

/// Maxfiylik siyosati — saytdagi `/privacy` (`PrivacyUz.tsx`, `PrivacyRu.tsx`),
/// ilova tilida. Ikkala matn bir xil shartlarni aytadi.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = _Doc();
    return DetailPage(
      title: tr.privacy,
      slivers: [
        SliverToBoxAdapter(
          child: Gutter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: kSpace6, vertical: kSpace8),
              decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(kRadiusXl), boxShadow: kShadowSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr.privacyUpdated(tr.privacyDate), style: sans(kTextSm, color: kMuted)),
                  const SizedBox(height: kSpace6),
                  ...switch (appLang.value) {
                    AppLang.ru => _ru(d),
                    AppLang.uz => _uz(d),
                  },
                  d.contacts(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Matn bo'laklari: xatboshi, sarlavha, ro'yxat, eslatma, aloqa.
class _Doc {
  final body = sans(kTextMd, color: kInkSoft, height: 1.55);
  late final bold = body.copyWith(color: kInk, fontWeight: FontWeight.w700);

  TextSpan t(String s) => TextSpan(text: s);
  TextSpan b(String s) => TextSpan(text: s, style: bold);

  Widget p(List<InlineSpan> spans) => Padding(
        padding: const EdgeInsets.only(bottom: kSpace3),
        child: Text.rich(TextSpan(style: body, children: spans)),
      );

  Widget h2(String text) => Padding(
        padding: const EdgeInsets.only(top: kSpace8, bottom: kSpace3),
        child: Text(text, style: display(kTextLg, color: kBrand)),
      );

  Widget ul(List<List<InlineSpan>> items) => Padding(
        padding: const EdgeInsets.only(left: kSpace2, bottom: kSpace4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: kSpace2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: body),
                    Expanded(child: Text.rich(TextSpan(style: body, children: item))),
                  ],
                ),
              ),
          ],
        ),
      );

  /// Yashil fondagi eslatma; [strong] qalin yoziladi.
  Widget note(String before, String strong, String after) => Container(
        margin: const EdgeInsets.only(bottom: kSpace3),
        padding: const EdgeInsets.symmetric(horizontal: kSpace4, vertical: kSpace3),
        decoration: BoxDecoration(color: kBrandSoft, borderRadius: BorderRadius.circular(kRadiusMd)),
        child: Text.rich(TextSpan(style: sans(kTextSm, color: kBrand, height: 1.55), children: [
          t(before),
          TextSpan(text: strong, style: sans(kTextSm, color: kBrand, weight: FontWeight.w700)),
          t(after),
        ])),
      );

  Widget contacts() {
    TextSpan link(String s) => TextSpan(
          text: s,
          style: body.copyWith(color: kBrand, fontWeight: FontWeight.w600, decoration: TextDecoration.underline, decorationColor: kBrand),
        );
    final phone = appLang.value == AppLang.ru ? 'Телефон' : 'Telefon';
    return Padding(
      padding: const EdgeInsets.only(left: kSpace2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => openExternal(telHref(PrivacyContact.phone)),
            child: Text.rich(TextSpan(style: body, children: [t('•  $phone: '), link(PrivacyContact.phone)])),
          ),
          const SizedBox(height: kSpace2),
          GestureDetector(
            onTap: () => openExternal('mailto:${PrivacyContact.email}'),
            child: Text.rich(TextSpan(style: body, children: [t('•  Email: '), link(PrivacyContact.email)])),
          ),
        ],
      ),
    );
  }
}

List<Widget> _uz(_Doc d) => [
      d.p([
        d.t('Ushbu Maxfiylik siyosati '),
        d.b(Brand.name),
        d.t(' ilovasi va veb-sayti (keyingi o‘rinlarda — «Ilova») foydalanuvchilarining shaxsiy ma’lumotlari qanday to‘planishi, ishlatilishi va himoyalanishini tushuntiradi. Ilovadan foydalanish orqali siz ushbu shartlarga rozilik bildirasiz.'),
      ]),
      d.h2('1. Qanday ma’lumotlar to‘planadi'),
      d.p([d.t('Biz faqat xizmatni ko‘rsatish uchun zarur bo‘lgan ma’lumotlarni to‘playmiz:')]),
      d.ul([
        [d.b('Ism va telefon raqami'), d.t(' — buyurtmani rasmiylashtirish va siz bilan bog‘lanish uchun;')],
        [d.b('Yetkazib berish manzili va mo‘ljal'), d.t(' — buyurtmani yetkazish uchun;')],
        [
          d.b('Joylashuv (GPS koordinatalari)'),
          d.t(' — faqat siz «Meni topish» yoki «Xaritadan belgilash» tugmasini bosganingizda, yetkazish manzilini aniqlash uchun;'),
        ],
        [d.b('Buyurtmalar tarixi'), d.t(' — xarid qilingan mahsulotlar, summa va to‘lov usuli;')],
        [
          d.b('Qurilmangizdagi ma’lumotlar'),
          d.t(' — savat, mijoz ID raqamingiz va ozuqa kalkulyatoriga kiritganlaringiz brauzeringizda saqlanadi, keyingi tashrifda qayta yozmasligingiz uchun;'),
        ],
        [d.b('Texnik ma’lumotlar'), d.t(' — ilovaning to‘g‘ri ishlashi uchun qurilma va ulanish haqidagi umumiy ma’lumotlar.')],
      ]),
      d.note(
        'Joylashuv ma’lumoti ',
        'faqat siz ruxsat berganingizda',
        ' va faqat yetkazib berish manzilini aniqlash uchun ishlatiladi. Biz sizni orqa fonda kuzatmaymiz.',
      ),
      d.h2('2. Ma’lumotlardan qanday foydalanamiz'),
      d.ul([
        [d.t('Buyurtmalarni qabul qilish, tayyorlash va yetkazib berish;')],
        [d.t('Buyurtma holati bo‘yicha siz bilan bog‘lanish;')],
        [d.t('To‘lovni rasmiylashtirish (naqd yoki karta);')],
        [d.t('Xizmat sifatini yaxshilash va xatoliklarni tuzatish.')],
      ]),
      d.h2('3. Ma’lumotlarni uchinchi tomonlarga berish'),
      d.p([
        d.t('Biz sizning shaxsiy ma’lumotlaringizni '),
        d.b('sotmaymiz'),
        d.t(' va reklama maqsadida uchinchi tomonlarga bermaymiz. Ma’lumotlar faqat quyidagi hollarda ulashilishi mumkin:'),
      ]),
      d.ul([
        [d.b('Kuryer / yetkazib beruvchi'), d.t(' bilan — buyurtmani manzilingizga yetkazish uchun (ism, telefon, manzil);')],
        [d.b('OpenStreetMap'), d.t(' xarita xizmati bilan — xaritada belgilangan nuqtaning manzilini aniqlash uchun (faqat koordinatalar);')],
        [d.t('Qonun talab qilgan hollarda — vakolatli davlat organlari rasmiy so‘roviga binoan.')],
      ]),
      d.h2('4. Ma’lumotlarni saqlash va himoya'),
      d.p([
        d.t('Ma’lumotlar himoyalangan serverda saqlanadi va ruxsatsiz kirishdan himoya qilinadi. Biz ma’lumotlarni faqat xizmat ko‘rsatish uchun zarur bo‘lgan muddat davomida saqlaymiz.'),
      ]),
      d.h2('5. Bolalar maxfiyligi'),
      d.p([d.t('Ilova bolalarga mo‘ljallanmagan va biz 13 yoshgacha bo‘lgan bolalardan bilib turib ma’lumot to‘plamaymiz.')]),
      d.h2('6. O‘zgarishlar'),
      d.p([
        d.t('Ushbu siyosat vaqti-vaqti bilan yangilanishi mumkin. O‘zgarishlar ushbu sahifada e’lon qilinadi va yangilanish sanasi yuqorida ko‘rsatiladi.'),
      ]),
      d.h2('7. Biz bilan bog‘lanish'),
      d.p([d.t('Maxfiylik bo‘yicha savollaringiz bo‘lsa, biz bilan bog‘laning:')]),
    ];

List<Widget> _ru(_Doc d) => [
      d.p([
        d.t('Настоящая Политика конфиденциальности объясняет, как собираются, используются и защищаются персональные данные пользователей приложения и сайта '),
        d.b(Brand.name),
        d.t(' (далее — «Приложение»). Пользуясь Приложением, вы соглашаетесь с этими условиями.'),
      ]),
      d.h2('1. Какие данные мы собираем'),
      d.p([d.t('Мы собираем только данные, необходимые для оказания услуги:')]),
      d.ul([
        [d.b('Имя и номер телефона'), d.t(' — чтобы оформить заказ и связаться с вами;')],
        [d.b('Адрес доставки и ориентир'), d.t(' — чтобы доставить заказ;')],
        [
          d.b('Местоположение (GPS-координаты)'),
          d.t(' — только когда вы нажимаете «Найти меня» или «Отметить на карте», чтобы определить адрес доставки;'),
        ],
        [d.b('История заказов'), d.t(' — купленные товары, сумма и способ оплаты;')],
        [
          d.b('Данные на вашем устройстве'),
          d.t(' — корзина, ваш ID клиента и данные, введённые в калькулятор корма, хранятся в вашем браузере, чтобы не вводить их заново при следующем посещении;'),
        ],
        [d.b('Технические данные'), d.t(' — общие сведения об устройстве и подключении, необходимые для корректной работы Приложения.')],
      ]),
      d.note(
        'Данные о местоположении используются ',
        'только с вашего разрешения',
        ' и только для определения адреса доставки. Мы не отслеживаем вас в фоновом режиме.',
      ),
      d.h2('2. Как мы используем данные'),
      d.ul([
        [d.t('Приём, подготовка и доставка заказов;')],
        [d.t('Связь с вами по поводу статуса заказа;')],
        [d.t('Оформление оплаты (наличными или картой);')],
        [d.t('Улучшение качества сервиса и исправление ошибок.')],
      ]),
      d.h2('3. Передача данных третьим лицам'),
      d.p([
        d.t('Мы '),
        d.b('не продаём'),
        d.t(' ваши персональные данные и не передаём их третьим лицам в рекламных целях. Данные могут быть переданы только в следующих случаях:'),
      ]),
      d.ul([
        [d.b('Курьеру / службе доставки'), d.t(' — чтобы доставить заказ по вашему адресу (имя, телефон, адрес);')],
        [d.b('Картографическому сервису OpenStreetMap'), d.t(' — чтобы определить адрес точки, отмеченной на карте (только координаты);')],
        [d.t('В случаях, предусмотренных законом, — по официальному запросу уполномоченных государственных органов.')],
      ]),
      d.h2('4. Хранение и защита данных'),
      d.p([
        d.t('Данные хранятся на защищённом сервере и защищены от несанкционированного доступа. Мы храним данные только в течение срока, необходимого для оказания услуги.'),
      ]),
      d.h2('5. Конфиденциальность детей'),
      d.p([d.t('Приложение не предназначено для детей, и мы сознательно не собираем данные детей младше 13 лет.')]),
      d.h2('6. Изменения'),
      d.p([d.t('Эта политика может время от времени обновляться. Изменения публикуются на этой странице, а дата обновления указывается выше.')]),
      d.h2('7. Как с нами связаться'),
      d.p([d.t('Если у вас есть вопросы о конфиденциальности, свяжитесь с нами:')]),
    ];
