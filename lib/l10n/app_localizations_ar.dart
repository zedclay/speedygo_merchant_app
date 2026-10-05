// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'SpeedyGo Merchant';

  @override
  String get brandName => 'SpeedyGo';

  @override
  String get splashTagline => 'مؤسستك. ببساطة.';

  @override
  String get splashLegacyTagline => 'فضاء التاجر';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingStart => 'ابدأ';

  @override
  String get onboardingHaveAccount => 'لدي حساب بالفعل';

  @override
  String get onboardingPage1Title => 'استقبل طلباتك';

  @override
  String get onboardingPage1Body => 'اطّلع على الطلبات الجديدة وتفاصيلها.';

  @override
  String get onboardingPage2Title => 'أتقن التحضير';

  @override
  String get onboardingPage2Body =>
      'نظّم التحضير وأشر عندما يصبح الطلب جاهزًا.';

  @override
  String get onboardingPage3Title => 'مؤسستك في متناول يدك';

  @override
  String get onboardingPage3Body =>
      'اطّلع على كتالوجك وساعات العمل ومعلومات مؤسستك.';

  @override
  String get onboardingSaveFailed => 'تعذّر حفظ المقدمة. أعد المحاولة.';

  @override
  String get onboardingPageSemantics => 'صفحة المقدمة';

  @override
  String get phoneTitle => 'أدخل رقم هاتفك';

  @override
  String get phoneSubtitle => 'سنرسل إليك رمز تحقق عبر رسالة قصيرة.';

  @override
  String get phoneHint => '555 12 34 56';

  @override
  String get phonePrefix => '+213';

  @override
  String get phoneSmsNote => 'قد تُطبَّق رسوم الرسائل القصيرة المعتادة.';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneInvalid => 'أدخل رقم هاتف جزائري صالحًا.';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get needHelp => 'هل تحتاج مساعدة؟';

  @override
  String get helpUnavailable => 'ستتوفر المساعدة في إصدار لاحق.';

  @override
  String get otpTitle => 'التحقق من الرمز';

  @override
  String get editNumber => 'تعديل';

  @override
  String get verify => 'تحقق';

  @override
  String get resend => 'إعادة إرسال الرمز';

  @override
  String resendIn(String clock) {
    return 'إعادة إرسال الرمز خلال $clock';
  }

  @override
  String get otpCooldownHint => 'يُرجى الانتظار قبل إعادة إرسال رمز';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get otpSubtitle => 'أدخل الرمز المكوّن من 6 أرقام المُرسل إلى';

  @override
  String get restoreTitle => 'استعادة الجلسة';

  @override
  String get restoreLoading => 'جاري الاتصال…';

  @override
  String get restoreOffline => 'تعذّر الاتصال بالخادم. تحقّق من اتصالك.';

  @override
  String get restoreRetry => 'إعادة المحاولة';

  @override
  String get restoreOtherAccount => 'استخدام حساب آخر';

  @override
  String get sessionExpired => 'انتهت جلستك. سجّل الدخول.';

  @override
  String get networkError => 'مشكلة في الشبكة. أعد المحاولة.';

  @override
  String get languageSaveFailed => 'تعذّر حفظ اللغة. أعد المحاولة.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get back => 'رجوع';

  @override
  String get loading => 'جاري التحميل…';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabOrders => 'الطلبات';

  @override
  String get tabCatalog => 'الكتالوج';

  @override
  String get tabReports => 'التقارير';

  @override
  String get tabProfile => 'الملف الشخصي';

  @override
  String get navReveal => 'إظهار التنقّل';

  @override
  String get homeTitle => 'الرئيسية';

  @override
  String get selectBranchTitle => 'اختر مؤسسة';

  @override
  String get selectBranchSubtitle => 'حدّد المؤسسة التي ترغب في العمل بها.';

  @override
  String get noMembershipTitle => 'لا توجد مؤسسة مرتبطة';

  @override
  String get noMembershipBody =>
      'هذا الحساب لا يملك عضوية تاجر بعد. يمكنك إنشاء ملف مؤسسة لبدء التحقق.';

  @override
  String get noMembershipInvitationsCta => 'لدي دعوة';

  @override
  String get createMerchant => 'إنشاء مؤسسة';

  @override
  String get merchantNameLabel => 'اسم المؤسسة';

  @override
  String get merchantNameHint => 'مثال: صيدلية الوسط';

  @override
  String get verificationPendingTitle => 'التحقق جارٍ';

  @override
  String get verificationPendingBody => 'تم تسجيل مؤسستك وهي بانتظار التحقق.';

  @override
  String get verificationDossierProgress => 'وثائق الملف';

  @override
  String get verificationSubmittedStep => 'تم تقديم الملف';

  @override
  String get verificationReviewStep => 'مراجعة المستندات';

  @override
  String get verificationReviewStepBody => 'قيد المراجعة من SpeedyGo';

  @override
  String get verificationFinalStep => 'الاعتماد النهائي';

  @override
  String get verificationFinalStepBody => 'بانتظار القرار';

  @override
  String get verificationTimelineTitle => 'تقدّم الملف';

  @override
  String get verificationReferenceLabel => 'المرجع';

  @override
  String get verificationReferenceFull => 'مرجع الملف';

  @override
  String get approvedTitle => 'تهانينا!';

  @override
  String get approvedSubtitle => 'تم اعتماد مؤسستك';

  @override
  String get approvedBody =>
      'لبدء استقبال الطلبات، تأكّد من أن متجرك مفتوح، وأن ساعات العمل محدّدة، وأن منتجاتك متاحة.';

  @override
  String get approvedReferenceLabel => 'مرجع التاجر';

  @override
  String get approvedReferenceFull => 'مرجع التاجر';

  @override
  String get approvedBadge => 'معتمد';

  @override
  String get approvedStepsTitle => 'خطوات الإعداد';

  @override
  String get approvedHoursTitle => 'ساعات العمل';

  @override
  String get approvedHoursBody => 'حدّد أوقات فتح متجرك';

  @override
  String get approvedCatalogTitle => 'كتالوج المنتجات';

  @override
  String get approvedCatalogBody => 'أضف أول منتجاتك';

  @override
  String get approvedAlertsTitle => 'التنبيهات والإشعارات';

  @override
  String get approvedAlertsBody => 'ابقَ على اطّلاع بالطلبات';

  @override
  String get approvedNeedBranchHint => 'متاح بعد إضافة مؤسسة';

  @override
  String get approvedNotOpenNote =>
      'الاعتماد لا يفتح متجرك تلقائيًا: تحقّق من حالته وساعات العمل والكتالوج من الرئيسية.';

  @override
  String get approvedContinue => 'الانتقال إلى الرئيسية';

  @override
  String get verificationRequestIdLabel => 'معرّف الطلب';

  @override
  String get verificationNeedHelp => 'هل تحتاج مساعدة بخصوص ملفك؟';

  @override
  String get verificationCorrectAndSubmit => 'تصحيح وإعادة الإرسال';

  @override
  String get verificationRejectedTitle => 'ملف بحاجة إلى استكمال';

  @override
  String get verificationRejectedBody =>
      'رُفض الملف. صحّح الملف الشخصي أو الوثائق عندما يُسمح بالتعديل، ثم أعد الإرسال.';

  @override
  String get verificationApprovedTitle => 'تم اعتماد المؤسسة';

  @override
  String get verificationApprovedBody =>
      'تم اعتماد مؤسستك. أكمل إضافة مؤسسة نشطة لبدء التشغيل.';

  @override
  String get suspendedTitle => 'حساب المؤسسة معلّق';

  @override
  String get suspendedBody =>
      'هذه المؤسسة معلّقة. تواصل مع دعم SpeedyGo عند الحاجة.';

  @override
  String get checklistTitle => 'وثائق الملف';

  @override
  String get accessRestrictedTitle => 'وصول مقيّد';

  @override
  String get accessRestrictedBody =>
      'ليست لديك الصلاحيات اللازمة لهذا الإجراء.';

  @override
  String get needBranchTitle => 'يلزم وجود مؤسسة';

  @override
  String get needBranchBody =>
      'أضف مؤسسة نشطة واحدة على الأقل لاستخدام الفضاء التشغيلي.';

  @override
  String get addBranch => 'إضافة مؤسسة';

  @override
  String get branchNameLabel => 'اسم المؤسسة';

  @override
  String get branchPhoneLabel => 'الهاتف';

  @override
  String get branchAddressLabel => 'العنوان';

  @override
  String get branchLatLabel => 'خط العرض';

  @override
  String get branchLngLabel => 'خط الطول';

  @override
  String get save => 'حفظ';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get operationalActive => 'نشط';

  @override
  String get operationalInactive => 'غير نشط';

  @override
  String get operationalSuspended => 'معلّق';

  @override
  String get homeNoMetrics =>
      'لا تتوفر مؤشرات مجمّعة من واجهة البرمجة في هذه المرحلة.';

  @override
  String get homeOrderCountsTitle => 'الطلبات الجارية';

  @override
  String get homeCountIncoming => 'جديدة';

  @override
  String get homeCountPreparing => 'قيد التحضير';

  @override
  String get homeCountReady => 'جاهزة';

  @override
  String get homeCountCourier => 'الموصل';

  @override
  String get homeCountCourierUnavailable => '—';

  @override
  String get homeActiveOrdersTitle => 'الطلبات النشطة';

  @override
  String get homeActiveOrdersEmpty => 'لا توجد طلبات نشطة حاليًا.';

  @override
  String get homeTreatOrder => 'معالجة الطلب';

  @override
  String get homeOpenOrder => 'عرض الطلب';

  @override
  String get homeVerificationTitle => 'تحقق بانتظار الإكمال';

  @override
  String get homeVerificationBody =>
      'أكمل ملفك للحفاظ على الوصول الكامل إلى فضاء التاجر.';

  @override
  String get homeKpiSales => 'المبيعات';

  @override
  String get homeKpiOrders => 'الطلبات';

  @override
  String get homeKpiOrdersUnit => 'مكتملة';

  @override
  String get homeKpiCurrency => 'DZD';

  @override
  String get homeKpiUnavailable => '—';

  @override
  String get refresh => 'تحديث';

  @override
  String get ordersEmpty => 'لا توجد طلبات لهذه المؤسسة.';

  @override
  String get ordersEmptyIncoming => 'لا توجد طلبات جديدة';

  @override
  String get ordersEmptyAccepted => 'لا توجد طلبات مقبولة';

  @override
  String get ordersEmptyPreparing => 'لا توجد طلبات قيد التحضير';

  @override
  String get ordersEmptyReady => 'لا توجد طلبات جاهزة';

  @override
  String get ordersEmptyCompleted => 'لا توجد طلبات مكتملة';

  @override
  String get ordersEmptyCancelled => 'لا توجد طلبات ملغاة';

  @override
  String get ordersEmptyFailed => 'لا توجد طلبات فاشلة';

  @override
  String get ordersLoadError => 'تعذّر تحميل الطلبات.';

  @override
  String get orderDetailTitle => 'طلب';

  @override
  String get orderDetailLoadError => 'تعذّر تحميل هذا الطلب.';

  @override
  String get orderFulfillmentIncoming => 'جديد';

  @override
  String get supportReportTitle => 'الإبلاغ عن مشكلة';

  @override
  String get supportShort => 'الدعم';

  @override
  String get supportContact => 'التواصل مع الدعم';

  @override
  String get supportOrderLabel => 'الطلب';

  @override
  String get supportCustomerLabel => 'العميل';

  @override
  String get supportMerchandiseLabel => 'البضائع';

  @override
  String get supportDescriptionLabel => 'وصف المشكلة';

  @override
  String get supportDescriptionHint => 'اشرح لنا ما حدث بالتفصيل...';

  @override
  String get supportSensitiveHint =>
      'يُرجى عدم تضمين بيانات حسّاسة (مثل كلمات المرور).';

  @override
  String get supportSend => 'إرسال التذكرة';

  @override
  String get supportSentTitle => 'تم إرسال البلاغ';

  @override
  String get supportSentBodyNoRef => 'تم إرسال تذكرتك إلى فريق SpeedyGo.';

  @override
  String get supportBackToOrder => 'العودة إلى الطلب';

  @override
  String get supportForbidden => 'يمكن للمالك والمديرين فقط التواصل مع الدعم.';

  @override
  String get supportSendError => 'تعذّر إرسال التذكرة. أعد المحاولة.';

  @override
  String get supportCenterTitle => 'دعم Merchant';

  @override
  String get supportNewTicket => 'تذكرة جديدة';

  @override
  String get supportActiveTickets => 'التذاكر النشطة';

  @override
  String get supportResolvedTickets => 'التذاكر المحلولة';

  @override
  String get supportNoTickets => 'لا توجد تذاكر حاليًا.';

  @override
  String get supportLoadError => 'تعذّر تحميل تذاكرك.';

  @override
  String get supportTopicsTitle => 'مواضيع شائعة';

  @override
  String get supportTopicsHint => 'اختر موضوعًا لفتح تذكرة جديدة.';

  @override
  String get supportTopicsLoadError => 'تعذّر تحميل المواضيع.';

  @override
  String get supportTopicsEmpty => 'لا توجد مواضيع متاحة حاليًا.';

  @override
  String get supportTopicLabel => 'الموضوع';

  @override
  String get supportTopicRequired => 'اختر موضوعًا.';

  @override
  String get supportSubjectLabel => 'العنوان';

  @override
  String get supportSubjectHint => 'لخّص طلبك في بضع كلمات';

  @override
  String get supportSubjectRequired => 'يرجى إدخال موضوع طلبك.';

  @override
  String get supportFaqTitle => 'الأسئلة الشائعة';

  @override
  String get supportFaqEmpty => 'لا توجد أسئلة شائعة في الوقت الحالي.';

  @override
  String get supportFaqLoadError => 'تعذّر تحميل الأسئلة الشائعة.';

  @override
  String get supportComposeTitle => 'تذكرة جديدة';

  @override
  String get supportComposeHint =>
      'صف طلبك. إذا كان الأمر يتعلق بمشكلة في طلب، استخدم «الإبلاغ عن مشكلة» من صفحة الطلب.';

  @override
  String get supportTicketTitle => 'تذكرة';

  @override
  String get supportTicketLoadError => 'تعذّر تحميل هذه التذكرة.';

  @override
  String get supportLinkedOrder => 'الطلب المرتبط';

  @override
  String get supportYou => 'أنت';

  @override
  String get supportTeam => 'دعم SpeedyGo';

  @override
  String get supportReplyHint => 'ردّك';

  @override
  String get supportReplySend => 'إرسال';

  @override
  String get supportReplyError => 'تعذّر إرسال الرد.';

  @override
  String get supportTicketFinished =>
      'هذه التذكرة مغلقة. أنشئ تذكرة جديدة عند الحاجة.';

  @override
  String get supportNoMessages => 'لا توجد رسائل.';

  @override
  String get orderListAcceptNow => 'يجب القبول فورًا';

  @override
  String get orderDetailsTitle => 'تفاصيل الطلب';

  @override
  String get orderDetailCancelledTitle => 'طلب ملغى';

  @override
  String get orderCancelledHeroBody => 'لن يُستكمل هذا الطلب.';

  @override
  String get orderCancelledByCustomer => 'أُلغي من قِبل العميل';

  @override
  String get orderRejectedByMerchant => 'مرفوض من قِبل المؤسسة';

  @override
  String get orderReasonLabel => 'السبب';

  @override
  String get orderCancelledAck => 'حسنًا';

  @override
  String get orderViewHistory => 'عرض السجل';

  @override
  String get orderCurrentStatus => 'الحالة الحالية';

  @override
  String get orderReceivedAtLabel => 'استُلم في';

  @override
  String get orderPaymentLabel => 'الدفع';

  @override
  String orderPaymentMethod(String method) {
    return 'الطريقة: $method';
  }

  @override
  String get eventCreated => 'تم استلام الطلب';

  @override
  String get eventCreatedCaption => 'طلب قدّمه العميل';

  @override
  String get eventAccepted => 'مقبول';

  @override
  String get eventAcceptedCaption => 'تم تأكيد الطلب';

  @override
  String get eventPrepStarted => 'قيد التحضير';

  @override
  String get eventPrepStartedCaption => 'بدأ التحضير';

  @override
  String get eventReady => 'جاهز';

  @override
  String get eventReadyCaption => 'جاهز للاستلام';

  @override
  String get eventRejected => 'مرفوض';

  @override
  String get eventCancelled => 'ملغى';

  @override
  String get eventCompleted => 'مكتمل';

  @override
  String get eventCompletedCaption => 'تم تسليم الطلب للعميل';

  @override
  String get eventStatusUpdate => 'تحديث الحالة';

  @override
  String get orderListLate => 'متأخر';

  @override
  String get orderHistoryToday => 'اليوم';

  @override
  String get orderHistoryYesterday => 'أمس';

  @override
  String get orderHistoryEarlier => 'سابقًا';

  @override
  String get orderFulfillmentAccepted => 'مقبول';

  @override
  String get orderFulfillmentPreparing => 'قيد التحضير';

  @override
  String get orderFulfillmentReady => 'جاهز';

  @override
  String get orderStatusCreated => 'جديد';

  @override
  String get orderStatusConfirmed => 'مؤكد';

  @override
  String get orderStatusActive => 'نشط';

  @override
  String get orderStatusCompleted => 'مكتمل';

  @override
  String get orderStatusCancelled => 'ملغى';

  @override
  String get orderStatusFailed => 'فشل';

  @override
  String get orderPaymentCod => 'الدفع عند الاستلام';

  @override
  String get orderPaymentElectronic => 'دفع إلكتروني';

  @override
  String get orderListMerchandiseLabel => 'البضائع';

  @override
  String get orderIncomingBanner => 'طلب جديد';

  @override
  String get orderReadyBanner => 'الطلب جاهز';

  @override
  String get orderSegmentActive => 'قيد التنفيذ';

  @override
  String get orderSegmentHistory => 'السجل';

  @override
  String get orderReferenceCopy => 'نسخ المرجع';

  @override
  String get orderReferenceCopied => 'تم نسخ المرجع';

  @override
  String get orderReferenceShowFull => 'عرض المرجع الكامل';

  @override
  String get orderItemsTitle => 'الأصناف';

  @override
  String get orderItemsToPrepareTitle => 'أصناف للتحضير';

  @override
  String get orderDeliveryAddress => 'عنوان التسليم';

  @override
  String get orderFinanceTitle => 'التوزيع المالي';

  @override
  String get orderFinanceGms => 'مجموع البضائع الفرعي';

  @override
  String get orderFinanceDiscount => 'خصم التاجر';

  @override
  String get orderFinanceNet => 'صافي التاجر';

  @override
  String get orderFinanceCommissionUnavailable => 'عمولة SpeedyGo';

  @override
  String get orderFinanceRestricted =>
      'العمولة والخصم وصافي التاجر مخصّصة للمالك أو المسؤول فقط.';

  @override
  String get valueUnavailable => '—';

  @override
  String get orderFinanceNetCancelledNote =>
      'مبالغ تاريخية مثبتة عند إنشاء الطلب — وليست مستحقات للدفع.';

  @override
  String get orderFinanceDeliveryFeeNote => 'رسوم التوصيل (العميل)';

  @override
  String get orderFinanceDeliveryFeeDisclaimer =>
      'رسوم التوصيل ليست إيرادًا للتاجر.';

  @override
  String get orderAccept => 'قبول';

  @override
  String get orderChoosePrepTime => 'اختيار مدة التحضير';

  @override
  String get orderReject => 'رفض';

  @override
  String get orderRejectTitle => 'رفض الطلب';

  @override
  String get orderRejectHint => 'الرفض ممكن فقط قبل القبول. يرجى ذكر السبب.';

  @override
  String get orderRejectReasonLabel => 'سبب الرفض';

  @override
  String get orderRejectConfirm => 'تأكيد الرفض';

  @override
  String get orderQuickAlreadyHandled =>
      'تمت معالجة هذا الطلب مسبقًا. تم تحديث القائمة.';

  @override
  String get orderQuickNotAllowed => 'دورك لا يسمح بهذا الإجراء.';

  @override
  String get orderQuickCheckFailed => 'تعذّر التحقق من الطلب. أعد المحاولة.';

  @override
  String get orderQuickAccepted => 'تم قبول الطلب.';

  @override
  String get orderQuickRejected => 'تم رفض الطلب.';

  @override
  String get prepAcceptTitle => 'قبول الطلب';

  @override
  String get prepEstimatedTitle => 'مدة التحضير المقدَّرة';

  @override
  String get prepConfirmAccept => 'تأكيد وقبول';

  @override
  String get prepCustomTime => 'مدة مخصّصة';

  @override
  String get prepCustomEntry => 'إدخال مخصّص';

  @override
  String prepCustomRange(String min, String max) {
    return 'بين $min و$max دقيقة';
  }

  @override
  String prepItemCount(String n) {
    return 'صنف واحد$n أصناف';
  }

  @override
  String get prepInProgress => 'قيد التنفيذ';

  @override
  String get prepCurrentShort => 'الوقت الحالي';

  @override
  String get prepNewShort => 'تقدير جديد';

  @override
  String get prepReasonHint => 'مثال: مشكلة تقنية في المطبخ…';

  @override
  String get prepRemainingTitle => 'الوقت المتبقي';

  @override
  String get prepMinutesCaption => 'دقائق';

  @override
  String get prepSecondsCaption => 'ثوانٍ';

  @override
  String get prepLateHint =>
      'تجاوز التقدير الزمني. حدّث المدة أو علِّم الطلب جاهزًا عندما يصبح كذلك.';

  @override
  String get prepUpdateAction => 'تعديل المدة';

  @override
  String get prepUpdateTitle => 'تحديث المدة';

  @override
  String get prepCurrentReady => 'الوقت المتوقع الحالي';

  @override
  String prepOriginalReady(String time) {
    return 'الابتدائي: $time';
  }

  @override
  String prepOriginalReadyLabel(String time) {
    return 'الوقت الابتدائي: $time';
  }

  @override
  String get prepBranchLabel => 'المنشأة';

  @override
  String get prepAddTime => 'إضافة وقت تحضير';

  @override
  String prepNewEstimate(String from, String to, String add) {
    return 'تقدير جديد: $to بدلًا من $from، بزيادة $add دقيقة';
  }

  @override
  String prepClockOnDay(String day, String time) {
    return 'يوم $day الساعة $time';
  }

  @override
  String prepOnDay(String day) {
    return 'يوم $day';
  }

  @override
  String prepSpokenClock(String time, String day) {
    return '$time يوم $day';
  }

  @override
  String get prepReasonOptional => 'سبب التأخير (اختياري)';

  @override
  String get prepReasonShortcutsHint => 'الاختصار يملأ السبب؛ يمكنك تعديله.';

  @override
  String get prepReasonFieldLabel => 'السبب';

  @override
  String get prepReasonBusy => 'إقبال كثيف';

  @override
  String get prepReasonLongPrep => 'تحضير طويل';

  @override
  String get prepReasonMissingIngredient => 'مكون ناقص';

  @override
  String get prepReasonOther => 'سبب آخر';

  @override
  String get prepUpdateConfirm => 'تحديث';

  @override
  String get orderStartPreparation => 'بدء التحضير';

  @override
  String get orderMarkReady => 'تعيين كجاهز';

  @override
  String get markReadyPackingTitle => 'قائمة التعبئة';

  @override
  String get markReadyPackingHint =>
      'تأكد أن جميع عناصر الطلب معبَّأة جيدًا قبل تعيينه جاهزًا.';

  @override
  String get markReadyConfirm => 'تأكيد وتعيين كجاهز';

  @override
  String get orderReadyWaitingDelivery => 'في انتظار استلام الطلب للتوصيل.';

  @override
  String get orderDeliveryStatusTitle => 'التوصيل';

  @override
  String get orderDriverAssigned => 'تم تعيين مندوب توصيل.';

  @override
  String get orderDriverCardTitle => 'مندوب التوصيل المعيَّن';

  @override
  String get orderDriverStatusLabel => 'الحالة';

  @override
  String get orderDriverEtaLabel => 'الوصول المتوقع';

  @override
  String get orderDriverEtaUnavailable => 'وقت الوصول غير متاح.';

  @override
  String get orderDriverContactUnavailable =>
      'بيانات الاتصال بالمندوب غير متاحة.';

  @override
  String get orderDriverCall => 'الاتصال بالمندوب';

  @override
  String get pickupHandoffTitle => 'رمز الاستلام';

  @override
  String get pickupHandoffWaiting => 'في انتظار تأكيد المندوب…';

  @override
  String get pickupHandoffInstruction1 =>
      'أبلغ بهذا الرمز فقط المندوب الظاهر أعلاه.';

  @override
  String get pickupHandoffInstruction2 =>
      'يجب على المندوب إدخال هذا الرمز في تطبيقه لتأكيد الاستلام.';

  @override
  String get pickupHandoffRegenerate => 'إعادة توليد الرمز';

  @override
  String get pickupHandoffConfirmed => 'تم تأكيد التسليم';

  @override
  String get pickupHandoffLoadError => 'تعذّر تحميل رمز الاستلام.';

  @override
  String get pickupHandoffRetry => 'إعادة المحاولة';

  @override
  String get orderHandoffUnsupported =>
      'تأكيد التسليم الآمن غير متاح للتاجر في هذا الإصدار.';

  @override
  String get orderHistoryTitle => 'سجل الطلب';

  @override
  String get orderReferenceLabel => 'المرجع';

  @override
  String get orderCustomerLabel => 'العميل';

  @override
  String get orderSummaryTitle => 'ملخص الطلب';

  @override
  String get deliverySearching => 'البحث عن مندوب';

  @override
  String get deliveryAssigned => 'مندوب معيَّن';

  @override
  String get deliveryPickedUp => 'تم الاستلام';

  @override
  String get deliveryArrived => 'وصل إلى العميل';

  @override
  String get deliveryToPickup => 'المندوب في الطريق إلى المؤسسة';

  @override
  String get deliveryAtPickup => 'وصل المندوب إلى المؤسسة';

  @override
  String get deliveryInTransit => 'في الطريق إلى العميل';

  @override
  String get deliveryFailed => 'فشل التوصيل';

  @override
  String get deliveryCancelled => 'أُلغي التوصيل';

  @override
  String get deliveryUnknown => 'حالة التوصيل غير متاحة';

  @override
  String get deliveryDelivered => 'تم التسليم';

  @override
  String get catalogTitle => 'كتالوج';

  @override
  String get catalogTabProducts => 'المنتجات';

  @override
  String get catalogTabCategories => 'الفئات';

  @override
  String get catalogSearchHint => 'البحث عن منتج…';

  @override
  String get catalogAllCategories => 'الكل';

  @override
  String get catalogEmptyProducts => 'لا يوجد أي منتج في هذا الكتالوج.';

  @override
  String get catalogEmptyCategories => 'لا توجد أي فئة حالياً.';

  @override
  String get catalogLoadError => 'تعذّر تحميل الكتالوج.';

  @override
  String get catalogInStock => 'متوفر';

  @override
  String get catalogOutOfStock => 'نفاد';

  @override
  String get catalogUnavailableSection =>
      'إنشاء المنتجات وتحريرها المتقدم غير مفعّلين في هذه الشاشة.';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get reportsPeriodToday => 'اليوم';

  @override
  String get reportsPeriodYesterday => 'أمس';

  @override
  String get reportsPeriodWeek => 'هذا الأسبوع';

  @override
  String get reportsPeriodMonth => 'هذا الشهر';

  @override
  String get reportsFinanceTitle => 'التفاصيل المالية';

  @override
  String get reportsGrossSales => 'المبيعات الإجمالية';

  @override
  String get reportsCommission => 'عمولة SpeedyGo';

  @override
  String get reportsMerchantNet => 'صافي التاجر';

  @override
  String get reportsDataUnavailable => 'البيانات غير متاحة';

  @override
  String get reportsDataUnavailableShort => '—';

  @override
  String get reportsOrdersMetric => 'الطلبات';

  @override
  String get reportsPrepTimeMetric => 'متوسط وقت التحضير';

  @override
  String get reportsCancellationsMetric => 'الإلغاءات';

  @override
  String get reportsTrendTitle => 'اتجاه المبيعات';

  @override
  String get reportsTopProductsTitle => 'المنتجات الأكثر مبيعاً';

  @override
  String get reportsTopProductsScreenTitle => 'أفضل المنتجات';

  @override
  String get reportsCommissionMixedRates => 'عمولة SpeedyGo (معدلات متغيرة)';

  @override
  String get reportsFinanceUnavailable => 'البيانات غير متاحة';

  @override
  String get reportsRatingsTitle => 'تقييمات العملاء';

  @override
  String get reportsRatingsEmpty => 'لا يوجد أي تقييم حالياً.';

  @override
  String get reportsRatingsCount => 'تقييم';

  @override
  String get reportsRatingsUnavailable => 'البيانات غير متاحة';

  @override
  String get reportsSettlementsTitle => 'التسويات';

  @override
  String get reportsSettlementsEmpty => 'لا توجد أي تسوية حالياً.';

  @override
  String get reportsSettlementsForbidden =>
      'التسويات مخصّصة للمالك أو المسؤول.';

  @override
  String get reportsLoadError => 'تعذّر تحميل المؤشرات.';

  @override
  String get reportsTrendUnavailable => 'البيانات غير متاحة';

  @override
  String get reportsTopProductsUnavailable => 'البيانات غير متاحة';

  @override
  String get reportsPeriodCustom => 'مخصّص';

  @override
  String get reportsPeriodSelectorLabel => 'فترة التقرير';

  @override
  String get reportsCustomRangeTooLong => 'الفترة المخصّصة محدودة بـ 93 يوماً.';

  @override
  String get reportsAverageBasketMetric => 'متوسط سلة الشراء';

  @override
  String get reportsPrepTimeNotTracked => 'غير متتبَّع';

  @override
  String get reportsMerchantDiscount => 'خصم التاجر';

  @override
  String get reportsFinanceRestricted =>
      'العمولة وصافي التاجر مخصّصان للمالك أو المسؤول.';

  @override
  String get reportsFinanceMissingSnapshot =>
      'البيانات المالية غير متاحة لبعض طلبات الفترة.';

  @override
  String get reportsRefundsCompleted => 'الاستردادات المُنجَزة';

  @override
  String get reportsRefundAdjustments => 'التعديلات المسجّلة';

  @override
  String get reportsRefundsNote =>
      'الاستردادات لا تخفّض المبيعات. لا تُحتسب عليكم سوى التعديلات المسجّلة على تسوياتكم.';

  @override
  String get reportsTrendEmpty => 'لا توجد مبيعات خلال الفترة.';

  @override
  String get reportsTopProductsEmpty => 'لم يُبَع أي منتج خلال الفترة.';

  @override
  String get reportsSeeAll => 'عرض الكل';

  @override
  String get reportsSortOrders => 'الطلبات';

  @override
  String get reportsSortRevenue => 'رقم الأعمال';

  @override
  String get reportsTopSales => 'أعلى المبيعات';

  @override
  String get reportsRankFirst => 'رقم 1';

  @override
  String get reportsDeletedProduct => 'منتج محذوف من الكتالوج';

  @override
  String get reportsSalesLoadError => 'تعذّر تحميل المبيعات.';

  @override
  String get reportsTopProductsLoadError => 'تعذّر تحميل المنتجات.';

  @override
  String reportsOrderCount(String count) {
    return 'طلب واحد$count طلبات';
  }

  @override
  String reportsTrendSemantics(String orders, String gross) {
    return 'اتجاه المبيعات: $orders طلبات، $gross';
  }

  @override
  String get reportsDailySummaryTitle => 'الملخص اليومي';

  @override
  String get reportsDailySummaryShortcut => 'الملخص اليومي';

  @override
  String get reportsDailySummaryLoadError => 'تعذّر تحميل الملخص اليومي.';

  @override
  String get reportsDailySummaryEmpty => 'لم يُنشأ أي طلب في هذا اليوم.';

  @override
  String get reportsDailySummarySalesKpi => 'المبيعات';

  @override
  String get reportsDailySummaryOrdersKpi => 'الطلبات';

  @override
  String get reportsDailySummaryPrepKpi => 'وقت التحضير';

  @override
  String get reportsDailySummaryCancellationsKpi => 'الإلغاءات';

  @override
  String get reportsDailySummaryBreakdownTitle => 'توزيع الطلبات';

  @override
  String get reportsDailySummaryDelivered => 'مُسلَّمة';

  @override
  String get reportsDailySummaryInProgress => 'قيد التنفيذ';

  @override
  String get reportsDailySummaryCancelled => 'ملغاة';

  @override
  String get reportsDailySummaryPrepEfficiencyTitle => 'كفاءة التحضير';

  @override
  String get reportsDailySummaryPrepAverage => 'المتوسط';

  @override
  String get reportsDailySummaryOnTimeRate => 'في الوقت';

  @override
  String get reportsDailySummaryCancellationMotifs => 'أسباب الإلغاء';

  @override
  String get reportsDailySummaryViewOrders => 'عرض كل طلبات اليوم';

  @override
  String reportsDailySummaryMinutes(String minutes) {
    return '$minutes د';
  }

  @override
  String reportsDailySummaryOnTimePercent(String percent) {
    return '$percent في الوقت';
  }

  @override
  String reportsDailySummaryTodayDate(String label) {
    return 'اليوم، $label';
  }

  @override
  String get deliveryImpactTitle => 'التأثير على التوصيل';

  @override
  String get deliveryImpactMayDelayDriverAssignment =>
      'قد يؤخّر التحضير البحث عن سائق.';

  @override
  String get deliveryImpactMayDelayPickup =>
      'تمّ تعيين سائق؛ قد يتأخّر الاستلام.';

  @override
  String get deliveryImpactDriverWaiting => 'السائق بانتظار الطلب.';

  @override
  String get deliveryImpactTimingUnavailable =>
      'التأثير الدقيق على التوصيل غير متاح.';

  @override
  String deliveryImpactLatestRevision(String reason) {
    return 'آخر سبب: $reason';
  }

  @override
  String get rejectReasonProductUnavailable => 'عدم توفّر المنتج';

  @override
  String get rejectReasonTooBusy => 'ازدحام شديد';

  @override
  String get rejectReasonClosingSoon => 'اقتراب الإغلاق';

  @override
  String get rejectReasonOther => 'أخرى';

  @override
  String get rejectReasonTilesHint => 'اختر سبباً ثم وضّح عند الحاجة.';

  @override
  String get catalogAddProduct => 'إضافة منتج';

  @override
  String get catalogEditProduct => 'تعديل المنتج';

  @override
  String get catalogProductDetail => 'تفاصيل المنتج';

  @override
  String get catalogAddCategory => 'إضافة فئة';

  @override
  String get catalogEditCategory => 'تعديل الفئة';

  @override
  String get catalogProductName => 'اسم المنتج (الفرنسية)';

  @override
  String get catalogProductDescription => 'الوصف (الفرنسية)';

  @override
  String get catalogProductPrice => 'السعر الأساسي';

  @override
  String get catalogProductCategory => 'الفئة';

  @override
  String get catalogProductAvailable => 'ظاهر في القائمة';

  @override
  String get catalogProductAvailableSub => 'فعّل لإتاحة المنتج';

  @override
  String get catalogSaveProduct => 'حفظ';

  @override
  String get catalogSaveProductEdits => 'حفظ التعديلات';

  @override
  String get catalogPreview => 'معاينة';

  @override
  String get catalogPreviewTitle => 'معاينة المنتج';

  @override
  String get catalogPreviewUnavailable => 'المعاينة غير متاحة حالياً.';

  @override
  String get catalogFieldRequired => 'هذا الحقل إلزامي.';

  @override
  String get catalogPriceInvalid => 'أدخل سعراً صالحاً.';

  @override
  String get catalogCategoryRequired => 'اختر فئة.';

  @override
  String get catalogSaveRetryHint =>
      'تعذّر الحفظ. تحقّق من الاتصال وأعد المحاولة.';

  @override
  String get catalogSectionInfo => 'المعلومات';

  @override
  String get catalogSectionMedia => 'الوسائط';

  @override
  String get catalogSectionPrice => 'السعر والتحضير';

  @override
  String get catalogSectionConfig => 'الإعدادات';

  @override
  String get catalogSectionAvailability => 'التوفّر';

  @override
  String get catalogSectionImage => 'صورة المنتج';

  @override
  String get catalogSectionGeneral => 'معلومات عامة';

  @override
  String get catalogSectionPriceDetails => 'السعر والتفاصيل';

  @override
  String get catalogOnlineBanner =>
      'هذا الصنف متاح حالياً للعملاء عبر الإنترنت.';

  @override
  String get catalogOfflineBanner => 'هذا الصنف غير ظاهر للعملاء.';

  @override
  String get catalogPriceWarning =>
      'تُطبَّق تغييرات السعر والتوفّر فوراً على العملاء.';

  @override
  String get catalogImagePrimary => 'الصورة الرئيسية';

  @override
  String get catalogImageAdd => 'إضافة صورة';

  @override
  String get catalogImageHint =>
      'JPG أو PNG (بحد أقصى 2 ميغابايت، وبحد أدنى 400 بكسل)';

  @override
  String get catalogImageChangePhoto => 'تغيير الصورة';

  @override
  String get catalogInStockNow => 'متوفر حالياً';

  @override
  String get catalogOutOfStockNow => 'غير متوفر حالياً';

  @override
  String get catalogCurrencySuffix => 'DZD';

  @override
  String get catalogDeleteProduct => 'حذف';

  @override
  String get catalogNeedCategory => 'أنشئ فئة أولاً لإضافة منتج.';

  @override
  String get catalogImagePick => 'اختيار صورة';

  @override
  String get catalogImageFromGallery => 'الاختيار من المعرض';

  @override
  String get catalogImageFromCamera => 'التقاط صورة';

  @override
  String get catalogImagePluginRestart =>
      'أعد تشغيل التطبيق لتفعيل اختيار الصور.';

  @override
  String get catalogImageFormatError =>
      'تنسيق غير مدعوم. استخدم صورة JPG أو PNG.';

  @override
  String get catalogImageTooSmall =>
      'الصورة صغيرة جداً. الحد الأدنى 400 × 400 بكسل.';

  @override
  String get catalogImageTooLarge =>
      'الصورة كبيرة جداً. الحد الأقصى 2 ميغابايت بعد الضغط.';

  @override
  String get catalogImageChange => 'تغيير الصورة';

  @override
  String get catalogImageRemove => 'إزالة الصورة';

  @override
  String get catalogImageUploadError => 'تعذّر إرسال الصورة.';

  @override
  String get catalogImageBindPartial =>
      'تمّ حفظ المنتج، لكن تعذّر ربط الصورة. أعد المحاولة.';

  @override
  String get catalogImageRemoteUnavailable => 'معاينة الصورة غير متاحة حالياً.';

  @override
  String get catalogSaveError => 'تعذّر الحفظ. تحقّق من الاتصال وأعد المحاولة.';

  @override
  String get catalogDeleteConfirm => 'حذف هذا المنتج؟ تُحفظ الطلبات السابقة.';

  @override
  String get catalogCategoryName => 'اسم الفئة (الفرنسية)';

  @override
  String get catalogCategoryActive => 'الظهور في القائمة';

  @override
  String get catalogCategoryActiveSub => 'عرض هذه الفئة للعملاء';

  @override
  String get catalogCategoryDetails => 'تفاصيل الفئة';

  @override
  String get catalogCategorySettings => 'الإعدادات';

  @override
  String get catalogCategoryCancel => 'إلغاء';

  @override
  String get catalogDeleteCategory => 'حذف الفئة';

  @override
  String get catalogDeleteCategoryConfirm =>
      'حذف هذه الفئة؟ يجب أن تكون فارغة.';

  @override
  String get catalogStaffReadOnly =>
      'عرض فقط — التعديلات مخصّصة للمالك أو المسؤول.';

  @override
  String get catalogCategorySearchHint => 'البحث عن فئة…';

  @override
  String get catalogFilterTooltip => 'عوامل التصفية';

  @override
  String get catalogReorder => 'إعادة الترتيب';

  @override
  String get catalogVisible => 'ظاهر';

  @override
  String get catalogHidden => 'مخفي';

  @override
  String get catalogMenuAvailability => 'إدارة التوفّر';

  @override
  String get catalogMenuDelete => 'حذف';

  @override
  String get catalogMenuDuplicate => 'تكرار';

  @override
  String get duplicateTitle => 'تكرار المنتج';

  @override
  String get duplicateSource => 'المصدر';

  @override
  String get duplicateNewName => 'الاسم الجديد للمنتج';

  @override
  String get duplicateNewNameHint => 'يُرجى تعديل الاسم قبل نشر النسخة.';

  @override
  String get duplicateNamePlaceholder => 'أدخل الاسم الجديد';

  @override
  String get duplicateClearName => 'مسح الاسم';

  @override
  String duplicateDefaultName(String name) {
    return 'نسخة من $name';
  }

  @override
  String get duplicateCopied => 'العناصر المنسوخة';

  @override
  String get duplicateImage => 'صورة المنتج';

  @override
  String get duplicateNoImage => 'صورة المنتج (لا توجد صورة)';

  @override
  String duplicatePrice(String price) {
    return 'السعر ($price)';
  }

  @override
  String get duplicateOptions => 'الخيارات والمتغيّرات';

  @override
  String get duplicateSaleUnits => 'وحدات البيع (غير مُدارة)';

  @override
  String get duplicateNotCopiedLead => 'حالة التوفّر وسجل المبيعات ';

  @override
  String get duplicateNotCopiedStrong => 'لن يتم نسخها';

  @override
  String get duplicateNotCopiedTail => ' إلى المنتج الجديد.';

  @override
  String get duplicateUnavailableInfo =>
      'ستُنشأ النسخة غير متاحة حتى تتمكّن من مراجعتها قبل تفعيلها.';

  @override
  String get duplicateCancel => 'إلغاء';

  @override
  String get duplicateCreate => 'إنشاء النسخة';

  @override
  String get duplicateCreating => 'جاري الإنشاء…';

  @override
  String get duplicateNameRequired => 'لا يمكن أن يكون الاسم فارغًا.';

  @override
  String get duplicateNameTooLong => 'الحد الأقصى 255 حرفًا.';

  @override
  String get duplicateNetworkError =>
      'انقطع الاتصال. أعد المحاولة: لن تُنشأ النسخة مرّتين.';

  @override
  String get duplicateError =>
      'تعذّر إنشاء النسخة ولم يُضف أي منتج. أعد المحاولة.';

  @override
  String get duplicateConflict =>
      'طلب النسخ هذا استُخدم بالفعل في مكان آخر. أعد فتح الشاشة ثم حاول مجددًا.';

  @override
  String get duplicateNotFound => 'المنتج غير موجود. حدّث الكتالوج.';

  @override
  String get duplicateCreated => 'تم إنشاء النسخة — غير متاحة حتى مراجعَتك.';

  @override
  String get duplicateReplayed => 'النسخة موجودة مسبقًا — جاري فتح المنتج.';

  @override
  String get duplicateForbiddenTitle => 'النسخ مقصور على المالك أو المسؤول';

  @override
  String get duplicateBackToCatalog => 'العودة إلى الكتالوج';

  @override
  String get catalogMenuViewCategory => 'عرض الفئة';

  @override
  String get catalogBulkTooltip => 'التوفّر الجماعي';

  @override
  String get catalogCategoryInUse =>
      'لا تزال هذه الفئة تحتوي على منتجات. انقلها أو احذفها أولًا.';

  @override
  String get catalogProductInUse =>
      'هذا المنتج وارد في طلبات سابقة: لا يمكن حذفه. ضعه في نفاد المخزون بدلًا من ذلك.';

  @override
  String get catalogVisibilityError => 'تعذّر تعديل الظهور. أعد المحاولة.';

  @override
  String get catalogAvailabilityError => 'تعذّر تعديل التوفّر. أعد المحاولة.';

  @override
  String get catalogNoResults => 'لا يوجد منتج يطابق هذه عوامل التصفية.';

  @override
  String get catalogNoCategoryResults => 'لا توجد فئة تطابق هذا البحث.';

  @override
  String get catalogFiltersTitle => 'البحث وعوامل التصفية';

  @override
  String get catalogFiltersReset => 'إعادة تعيين';

  @override
  String get catalogFiltersCategories => 'الفئات';

  @override
  String get catalogFiltersStatus => 'الحالة';

  @override
  String get catalogFiltersOutOfStock => 'نفاد المخزون';

  @override
  String get catalogFiltersQuality => 'مراقبة الجودة';

  @override
  String get catalogFiltersMissingImage => 'صورة ناقصة';

  @override
  String get catalogFiltersPreview => 'معاينة النتائج';

  @override
  String catalogProductsCount(String n) {
    return '$n منتج$n منتجات';
  }

  @override
  String get catalogFiltersApply => 'تطبيق عوامل التصفية';

  @override
  String get catalogCategoryDetailTitle => 'تفاصيل الفئة';

  @override
  String catalogDisplayOrder(String n) {
    return 'ترتيب العرض: $n';
  }

  @override
  String get catalogCategoryProducts => 'المنتجات';

  @override
  String get catalogCategoryEmpty => 'لا يوجد منتج في هذه الفئة.';

  @override
  String get catalogReorderTitle => 'إعادة ترتيب الفئات';

  @override
  String get catalogReorderHint => 'اسحب لتغيير ترتيب العرض.';

  @override
  String get catalogReorderSave => 'حفظ الترتيب';

  @override
  String get catalogReorderSaved => 'تم حفظ الترتيب.';

  @override
  String get catalogReorderPartial => 'تعذّر نقل بعض الفئات. أعد المحاولة.';

  @override
  String get catalogAvailabilityTitle => 'توفّر المنتج';

  @override
  String get catalogAvailabilityNote =>
      'لا تؤثّر التعديلات على الطلبات المقبولة مسبقًا.';

  @override
  String get catalogAvailabilityState => 'حالة التوفّر';

  @override
  String get catalogAvailableOption => 'متاح';

  @override
  String get catalogAvailableOptionSub => 'ظاهر وقابل للطلب فورًا.';

  @override
  String get catalogOutOfStockOptionSub =>
      'يُعرض كغير متاح حتى إعادة التفعيل يدويًا.';

  @override
  String get catalogAvailabilitySave => 'حفظ التوفّر';

  @override
  String get catalogAvailabilitySaved => 'تم حفظ التوفّر.';

  @override
  String get catalogBulkTitle => 'التوفّر الجماعي';

  @override
  String get catalogBulkNote =>
      'تُطبَّق التعديلات فورًا على تطبيق العميل. ولا تؤثّر على الطلبات الجارية.';

  @override
  String get catalogBulkSelection => 'تحديد متعدّد';

  @override
  String get catalogBulkNewStatus => 'الحالة الجديدة';

  @override
  String get catalogBulkSelectAll => 'تحديد الكل';

  @override
  String get catalogBulkClear => 'مسح التحديد';

  @override
  String get catalogBulkApply => 'تطبيق';

  @override
  String catalogBulkDone(String n) {
    return 'تم تحديث $n منتج.تم تحديث $n منتجات.';
  }

  @override
  String catalogBulkFailed(String n) {
    return 'تعذّر تحديث $n منتج.تعذّر تحديث $n منتجات.';
  }

  @override
  String get catalogUncategorized => 'بدون فئة';

  @override
  String get catalogDeleteTitle => 'حذف المنتج';

  @override
  String get catalogDeleteWarningTitle => 'لا يمكن حذف منتج سبق طلبه.';

  @override
  String get catalogDeleteWarningBody =>
      'تحتفظ الطلبات السابقة بنسختها من المنتج. إذا رُفض الحذف، ضع المنتج في نفاد المخزون.';

  @override
  String get catalogDeleteHideOption => 'وضع في نفاد المخزون';

  @override
  String get catalogDeleteHideOptionSub =>
      'يبقى المنتج محفوظًا وقابلًا للتعديل، لكنه لم يعد قابلًا للطلب.';

  @override
  String get catalogDeleteRecommended => 'موصى به';

  @override
  String get catalogDeleteHardOption => 'حذف نهائي';

  @override
  String get catalogDeleteHardOptionSub =>
      'يزيل المنتج ومتغيّراته وإضافاته. غير ممكن إن وُجد في طلب.';

  @override
  String get catalogDeleteHardConfirm => 'حذف نهائي';

  @override
  String get catalogDeleted => 'تم حذف المنتج.';

  @override
  String get catalogMarkedOutOfStock => 'تم وضع المنتج في نفاد المخزون.';

  @override
  String get catalogVariantsTitle => 'المتغيّرات الإلزامية';

  @override
  String get catalogVariantsInfo =>
      'تتطلّب المتغيّرات الإلزامية من العميل اختيار خيار قبل إضافة المنتج إلى السلة.';

  @override
  String get catalogVariantsSubtitle =>
      'اضبط الخيارات المطلوبة قبل الإضافة إلى السلة.';

  @override
  String get catalogExtrasTitle => 'الإضافات الاختيارية';

  @override
  String get catalogExtrasSubtitle => 'خيارات اختيارية يمكن للعميل إضافتها.';

  @override
  String get catalogRequiredTag => 'إلزامي';

  @override
  String get catalogSingleChoice => 'اختيار واحد';

  @override
  String get catalogAddChoice => 'إضافة اختيار';

  @override
  String get catalogAddOption => 'إضافة خيار';

  @override
  String get catalogAddVariantGroup => 'إضافة مجموعة متغيّرات';

  @override
  String get catalogAddExtrasGroup => 'مجموعة إضافات جديدة';

  @override
  String get catalogNewGroup => 'مجموعة جديدة';

  @override
  String get catalogGroupName => 'اسم المجموعة (فرنسي)';

  @override
  String get catalogGroupNameHint => 'مثال: صلصة';

  @override
  String get catalogOptionName => 'اسم الاختيار';

  @override
  String get catalogOptionPrice => 'السعر (+)';

  @override
  String get catalogMaxSelectionsLabel => 'الحد الأقصى للاختيارات';

  @override
  String get catalogGroupRequiredSwitch => 'اختيار إلزامي';

  @override
  String get catalogGroupRequiredSub => 'يجب على العميل اختيار خيار.';

  @override
  String get catalogGroupSave => 'حفظ المجموعة';

  @override
  String get catalogGroupDelete => 'حذف المجموعة';

  @override
  String get catalogGroupDeleteConfirm =>
      'حذف هذه المجموعة وجميع خياراتها؟ الطلبات السابقة لن تتغيّر.';

  @override
  String get catalogOptionDelete => 'حذف الخيار';

  @override
  String get catalogOptionAvailable => 'الخيار متاح';

  @override
  String get catalogOptionsEmpty => 'لا توجد اختيارات حاليًا.';

  @override
  String get catalogGroupsLoadError => 'تعذّر تحميل خيارات المنتج.';

  @override
  String get catalogGroupInvalid =>
      'تحقّق من عدد الاختيارات (الحد الأدنى ≤ الحد الأقصى).';

  @override
  String get catalogSaveFirstForOptions =>
      'احفظ المنتج لضبط متغيّراته وإضافاته.';

  @override
  String catalogGroupsCount(String n) {
    return 'لا توجد مجموعاتمجموعة واحدة$n مجموعات';
  }

  @override
  String get catalogLastUpdated => 'آخر تحديث';

  @override
  String get catalogCustomerPreview => 'معاينة العميل';

  @override
  String get catalogEditGroup => 'تعديل المجموعة';

  @override
  String get catalogProductDetailTitle => 'تفاصيل المنتج';

  @override
  String get catalogDetailInfo => 'المعلومات';

  @override
  String get catalogDetailName => 'الاسم (فرنسي)';

  @override
  String get catalogDetailPricing => 'التسعير';

  @override
  String get catalogDetailPrice => 'السعر الأساسي';

  @override
  String get catalogDetailAppearance => 'المظهر في التطبيق';

  @override
  String get catalogDetailAvailable => 'المنتج متاح';

  @override
  String get catalogDetailNoDescription => 'لا يوجد وصف.';

  @override
  String get catalogDetailNoOptions => 'لم يُضبط أي متغيّر أو إضافة.';

  @override
  String catalogRequiredSummary(String rule) {
    return 'إلزامي · $rule';
  }

  @override
  String catalogOptionalSummary(String max) {
    return 'اختياري · الحد الأقصى $max';
  }

  @override
  String get catalogCropTitle => 'صورة المنتج';

  @override
  String get catalogCropTipsTitle => 'نصائح لصورة جيدة';

  @override
  String get catalogCropTip1 =>
      'استخدم خلفية محايدة ونظيفة (أبيض أو خشب فاتح).';

  @override
  String get catalogCropTip2 => 'تأكّد من إضاءة جيدة، ويفضّل أن تكون طبيعية.';

  @override
  String catalogCropTip3(String name) {
    return 'ضع المنتج في وسط الإطار.ضع المنتج (« $name ») في وسط الإطار.';
  }

  @override
  String get catalogCropFormat =>
      'الصيغة: JPG، PNG (حد أقصى 2 ميغابايت، حد أدنى 400 بكسل)';

  @override
  String get catalogCropUse => 'استخدام هذه الصورة';

  @override
  String get catalogCropRotate => 'تدوير';

  @override
  String get catalogCropZoom => 'تكبير';

  @override
  String get catalogCropRemove => 'حذف الصورة';

  @override
  String get contractFieldUnavailable => 'غير متاح حاليًا';

  @override
  String get catalogFieldNameAr => 'اسم المنتج (عربي)';

  @override
  String get catalogFieldDescAr => 'الوصف (عربي)';

  @override
  String get catalogFieldPrepTime => 'وقت التحضير';

  @override
  String get catalogFieldSaleUnit => 'وحدة البيع';

  @override
  String get sellingUnitTitle => 'وحدات البيع';

  @override
  String get sellingUnitCalloutTitle => 'دقة الوحدة';

  @override
  String get sellingUnitCalloutBody =>
      'اختر الوحدة الدقيقة لتجنّب أي لبس أثناء التحضير. ستُعرض هذه الوحدة للعملاء (مثال: 1 500 DZD / طبق). الكميات أعداد صحيحة: لا بيع بالوزن.';

  @override
  String get sellingUnitPreviewLabel => 'معاينة العميل';

  @override
  String get sellingUnitPreviewNoPrice => '— DZD';

  @override
  String get sellingUnitCommon => 'الوحدات الشائعة';

  @override
  String get sellingUnitPackaging => 'التعبئة';

  @override
  String get sellingUnitNone => 'بدون وحدة';

  @override
  String get sellingUnitNoneSub => 'يُعرض السعر دون وحدة.';

  @override
  String get sellingUnitNotSet => 'غير محدّدة';

  @override
  String get sellingUnitCustomName => 'اسم الوحدة (فرنسي)';

  @override
  String get sellingUnitCustomHint => 'مثال: كورنيه';

  @override
  String get sellingUnitApply => 'تطبيق الوحدة';

  @override
  String get sellingUnitReadOnly =>
      'يمكن للمالك والمديرين فقط تعديل وحدة البيع.';

  @override
  String get catalogFieldVariants => 'المتغيّرات الإلزامية';

  @override
  String get catalogFieldExtras => 'الإضافات الاختيارية';

  @override
  String get catalogFieldCategoryNameAr => 'اسم الفئة (عربي)';

  @override
  String get catalogFieldCategoryDesc => 'وصف الفئة (اختياري)';

  @override
  String get storeCoverTitle => 'الشعار والغلاف';

  @override
  String get storeCoverPick => 'اختيار غلاف';

  @override
  String get storeCoverReplace => 'استبدال';

  @override
  String get storeCoverSave => 'حفظ التعديلات';

  @override
  String get storeCoverRemove => 'حذف';

  @override
  String get storeCoverSection => 'صورة الغلاف';

  @override
  String get storeCoverSectionHint => 'يجب أن تمثّل صورة الغلاف مؤسستك.';

  @override
  String get storeLogoSection => 'شعار المتجر';

  @override
  String get storeLogoSectionHint =>
      'يجب أن يبقى الشعار واضحًا حتى بالحجم الصغير.';

  @override
  String get storeLogoEdit => 'تعديل';

  @override
  String get storeLogoAdd => 'إضافة';

  @override
  String get storeLogoRemove => 'حذف';

  @override
  String get storeLogoEmpty => 'لا يوجد شعار';

  @override
  String get storeLogoPending => 'تم اختيار شعار جديد — احفظ لتطبيقه.';

  @override
  String get storeLogoTooSmall =>
      'الشعار صغير جدًا. الحد الأدنى 128 × 128 بكسل.';

  @override
  String get storeLogoTooLarge =>
      'الشعار كبير جدًا. الحد الأقصى 1 ميغابايت بعد الضغط.';

  @override
  String get storeLogoUploadError => 'تعذّر رفع الشعار.';

  @override
  String get storeLogoBindPartial =>
      'نجح الرفع، لكن تعذّر ربط الشعار. أعد المحاولة.';

  @override
  String get storeLogoRemoved => 'تم حذف الشعار.';

  @override
  String get storeLogoRemoveError => 'تعذّر حذف الشعار. أعد المحاولة.';

  @override
  String get storeLogoRemoteUnavailable => 'معاينة الشعار غير متاحة حاليًا.';

  @override
  String get storeMediaPartialSaved =>
      'تم حفظ الشعار، لكن الغلاف فشل. أعد المحاولة.';

  @override
  String get storeCoverHint => 'JPEG أو PNG، حد أقصى 2 ميغابايت.';

  @override
  String get storeCoverUploadError => 'تعذّر إرسال صورة الغلاف.';

  @override
  String get storeCoverBindPartial =>
      'تم الإرسال بنجاح، لكن تعذّر ربط صورة الغلاف. يُرجى المحاولة مجددًا.';

  @override
  String get storeCoverRemoteUnavailable =>
      'معاينة صورة الغلاف غير متاحة حاليًا.';

  @override
  String get storeCustomerPreviewTitle => 'معاينة العميل';

  @override
  String get storeCustomerPreviewHint =>
      'الملاحظات والمدة التقديرية غير متاحة حاليًا.';

  @override
  String get storeAddressTitle => 'الاتصال وعنوان المتجر';

  @override
  String get storeAddressSave => 'حفظ التعديلات';

  @override
  String get storeAddressConfirmMap => 'تعديل على الخريطة';

  @override
  String get storeAddressSaveError =>
      'تعذّر الحفظ. تحقّق من الاتصال وحاول مجددًا.';

  @override
  String get storeAddressBanner =>
      'قد يؤثّر تعديل العنوان على مناطق التوصيل والعمليات الجارية.';

  @override
  String get storeAddressCoordsSection => 'الإحداثيات';

  @override
  String get storeAddressSection => 'العنوان';

  @override
  String get storeAddressPhone => 'رقم الهاتف';

  @override
  String get storeAddressPhoneHint =>
      'الرقم المُبلَّغ لسائقي التوصيل عند الاستلام.';

  @override
  String get storeAddressDetailed => 'العنوان التفصيلي';

  @override
  String get storeAddressLocationSummary => 'الموقع مؤكَّد';

  @override
  String get storeAddressPublicContact => 'جهة اتصال عامة (اختياري)';

  @override
  String get storeAddressWilaya => 'الولاية';

  @override
  String get storeAddressCommune => 'البلدية';

  @override
  String get adminLocationChoose => 'اختيار';

  @override
  String get adminLocationSearchHint => 'بحث…';

  @override
  String get adminLocationEmpty => 'لا توجد نتائج';

  @override
  String get adminLocationLoadError =>
      'تعذّر تحميل القائمة. يُرجى المحاولة مجددًا.';

  @override
  String get adminLocationRetry => 'إعادة المحاولة';

  @override
  String get adminLocationWilayaRequired => 'اختر الولاية أولًا.';

  @override
  String get adminLocationPairRequired => 'الولاية والبلدية مطلوبتان.';

  @override
  String get storeAddressPickupHints => 'تعليمات الاستلام';

  @override
  String get storeProfileMediaSub => 'الشعار وصورة الغلاف';

  @override
  String get storeProfileMediaUnavailable => 'غير متاح';

  @override
  String get storeProfilePrepUnavailable => 'غير متاح';

  @override
  String get storeProfilePreviewUnavailable => 'معاينة العميل غير متاحة.';

  @override
  String get profileSettingsTitle => 'الإعدادات';

  @override
  String get storeProfileTitle => 'ملف المتجر';

  @override
  String get storeProfileCustomerPreview => 'معاينة العميل';

  @override
  String get storeProfileGeneral => 'المعلومات العامة';

  @override
  String get storeProfileGeneralSub => 'اسم المتجر وحالته';

  @override
  String get storeGeneralTitle => 'المعلومات العامة';

  @override
  String get storeGeneralBranchName => 'اسم الفرع';

  @override
  String get storeGeneralBranchNameHint => 'يُعرض للعملاء لهذا الفرع.';

  @override
  String get storeGeneralMerchantName => 'اسم التجارة';

  @override
  String get storeGeneralMerchantLocked =>
      'اسم موثَّق من SpeedyGo: غير قابل للتعديل هنا.';

  @override
  String get storeGeneralReadOnly =>
      'يمكن للمالك والمدير فقط تعديل هذه المعلومات.';

  @override
  String get storeGeneralPhoneElsewhere =>
      'يُعدَّل الهاتف من «العنوان والموقع».';

  @override
  String get storeGeneralSave => 'حفظ';

  @override
  String get storeGeneralSaved => 'تم حفظ معلومات الفرع.';

  @override
  String get storeGeneralNameAr => 'الاسم بالعربية';

  @override
  String get storeGeneralNameArHint =>
      'اختياري. يُعرض للعملاء الناطقين بالعربية.';

  @override
  String get storeGeneralDescription => 'وصف مختصر';

  @override
  String get storeGeneralDescriptionHint => 'اختياري. قدّم فرعك في بضع جمل.';

  @override
  String get storeGeneralPublicEmail => 'البريد الإلكتروني العام';

  @override
  String get storeGeneralPublicEmailHint =>
      'اختياري. عنوان اتصال ظاهر للعملاء.';

  @override
  String get storeGeneralEmailInvalid => 'عنوان البريد الإلكتروني غير صالح.';

  @override
  String get storeGeneralPreviewTitle => 'معاينة العميل';

  @override
  String get storeGeneralPreviewOpen => 'مفتوح';

  @override
  String get storeGeneralPreviewClosed => 'مغلق';

  @override
  String get storeProfileCategory => 'فئة الفرع';

  @override
  String get storeProfileCategorySub => 'نوع النشاط الظاهر للعملاء';

  @override
  String get storeCategoryTitle => 'فئة الفرع';

  @override
  String get storeCategorySubtitle => 'اختر الفئة التي تصف نشاطك بأفضل شكل.';

  @override
  String get storeCategorySearch => 'البحث عن فئة...';

  @override
  String get storeCategoryInfo =>
      'فئة واحدة لكل فرع. تحدّد مكان ظهوره في تطبيق العميل.';

  @override
  String get storeCategoryReadOnly => 'يمكن للمالك والمديرين فقط تعديل الفئة.';

  @override
  String get storeCategorySave => 'حفظ';

  @override
  String get storeCategoryClear => 'إزالة الفئة';

  @override
  String get storeCategorySaved => 'تم حفظ الفئة.';

  @override
  String get storeCategoryCleared => 'تمت إزالة الفئة.';

  @override
  String get storeCategoryNotSet => 'غير محدّدة';

  @override
  String get storeCategoryEmpty => 'لا توجد فئات متاحة حاليًا.';

  @override
  String get storeCategoryNoMatch => 'لا توجد فئة مطابقة.';

  @override
  String get storeCategoryLoadError => 'تعذّر تحميل الفئات.';

  @override
  String get storeCategorySaveError => 'تعذّر الحفظ. يُرجى المحاولة مجددًا.';

  @override
  String get storeCategoryForbidden => 'دورك لا يسمح بتعديل هذا الفرع.';

  @override
  String get storeCategoryRestricted => 'حالة التجارة لا تسمح بهذا التعديل.';

  @override
  String get storeGeneralNameRequired => 'لا يمكن أن يكون الاسم فارغًا.';

  @override
  String get storeGeneralSaveError => 'تعذّر الحفظ. يُرجى المحاولة مجددًا.';

  @override
  String get storeGeneralForbidden => 'دورك لا يسمح بتعديل هذا الفرع.';

  @override
  String get storeGeneralRestricted => 'حالة التجارة لا تسمح بهذا التعديل.';

  @override
  String get storeProfileMedia => 'الوسائط والشعارات';

  @override
  String get storeProfileAddress => 'العنوان والموقع';

  @override
  String get storeProfileAddressSub => 'الهاتف والعنوان وموقع GPS';

  @override
  String get storeProfileHours => 'ساعات العمل';

  @override
  String get storeProfileHoursSub => 'أيام الفتح والاستراحات';

  @override
  String get storeProfilePrep => 'إعدادات التحضير';

  @override
  String get storeProfileSettings => 'إعدادات الحساب';

  @override
  String get storeProfileSettingsSub => 'الحساب والتفضيلات وتسجيل الخروج';

  @override
  String get storeProfileNotifications => 'الإشعارات';

  @override
  String get storeProfileNotificationsSub => 'مركز التنبيهات';

  @override
  String get openingHoursTitle => 'ساعات العمل';

  @override
  String get openingHoursEmpty => 'لا توجد ساعات عمل مُعدَّة لهذا الفرع.';

  @override
  String get openingHoursSave => 'حفظ ساعات العمل';

  @override
  String get openingHoursSaved => 'تم حفظ ساعات العمل.';

  @override
  String get openingHoursLoadError => 'تعذّر تحميل ساعات العمل.';

  @override
  String get openingHoursSaveError => 'تعذّر حفظ ساعات العمل.';

  @override
  String get openingHoursInvalid =>
      'رُفضت الساعات: تحقّق من التداخلات، بما في ذلك ما بعد منتصف الليل.';

  @override
  String get openingHoursConflict =>
      'تغيّرت الساعات من جهة أخرى. تم إعادة التحميل — تحقّق ثم حاول مجددًا.';

  @override
  String get openingHoursClosed => 'مغلق';

  @override
  String get openingHoursUsual => 'الساعات المعتادة';

  @override
  String get openingHoursNotConfigured => 'لا توجد ساعات مُعدَّة';

  @override
  String get openingHoursOpenNow => 'مفتوح حاليًا';

  @override
  String get openingHoursClosedNow => 'مغلق حاليًا';

  @override
  String get openingHoursInfo =>
      'يمكن للعملاء الطلب فقط خلال ساعات عملك. تُطبَّق التعديلات فور الحفظ.';

  @override
  String get openingHoursStaffReadOnly =>
      'للقراءة فقط: يمكن للمالك والمديرين فقط تعديل ساعات العمل.';

  @override
  String get openingHoursOpens => 'الفتح';

  @override
  String get openingHoursCloses => 'الإغلاق';

  @override
  String get openingHoursEditorHint =>
      'حتى 3 فترات في اليوم. إذا كان الإغلاق قبل الفتح، تنتهي الفترة في اليوم التالي.';

  @override
  String get openingHoursAddRange => 'إضافة فترة';

  @override
  String get openingHoursRemoveRange => 'حذف الفترة';

  @override
  String get openingHoursApply => 'تطبيق';

  @override
  String get openingHoursNextDay => 'تنتهي في اليوم التالي';

  @override
  String get openingHoursAllDay => 'مفتوح على مدار الساعة';

  @override
  String get openingHoursDayClosedHint => 'بدون فترة: سيُعدّ اليوم مغلقًا.';

  @override
  String get openingHoursIssueOverlap => 'الفترات متداخلة.';

  @override
  String get openingHoursIssueZero =>
      'يجب أن يختلف وقتا الفتح والإغلاق (00:00–00:00 ليوم كامل).';

  @override
  String get openingHoursIssueTooMany => 'الحد الأقصى 3 فترات في اليوم.';

  @override
  String get hoursExceptionsTitle => 'ساعات استثنائية';

  @override
  String get hoursExceptionsNavSub => 'العطل والإغلاقات المؤقتة';

  @override
  String get hoursExceptionsBanner =>
      'تستبدل هذه الساعات ساعاتك المعتادة فقط للتواريخ المحددة.';

  @override
  String get hoursExceptionsUpcoming => 'الاستثناءات القادمة';

  @override
  String get hoursExceptionsEmpty => 'لا توجد استثناءات قادمة.';

  @override
  String get hoursExceptionsAdd => 'إضافة استثناء';

  @override
  String get hoursExceptionsEdit => 'تعديل الاستثناء';

  @override
  String get hoursExceptionsDate => 'التاريخ';

  @override
  String get hoursExceptionsDateHint => 'اختيار تاريخ';

  @override
  String get hoursExceptionsDateTaken =>
      'هذا التاريخ لديه استثناء بالفعل: سيُستبدل عند الحفظ.';

  @override
  String get hoursExceptionsStatus => 'الحالة';

  @override
  String get hoursExceptionsOpen => 'مفتوح';

  @override
  String get hoursExceptionsClosed => 'مغلق';

  @override
  String get hoursExceptionsHours => 'ساعات معدَّلة';

  @override
  String get hoursExceptionsTo => 'إلى';

  @override
  String get hoursExceptionsLabel => 'السبب';

  @override
  String get hoursExceptionsLabelHint => 'مثال: عطلة رسمية، أشغال…';

  @override
  String get hoursExceptionsMessage => 'رسالة للعملاء (اختياري)';

  @override
  String get hoursExceptionsMessageHint =>
      'يُحفظ مع الاستثناء. غير معروض بعد في تطبيق العميل.';

  @override
  String get hoursExceptionsCancel => 'إلغاء';

  @override
  String get hoursExceptionsSave => 'حفظ ساعات العمل';

  @override
  String get hoursExceptionsSaved => 'تم حفظ الاستثناء.';

  @override
  String get hoursExceptionsDeleted => 'تم حذف الاستثناء.';

  @override
  String get hoursExceptionsDeleteTitle => 'حذف الاستثناء؟';

  @override
  String hoursExceptionsDeleteBody(String date) {
    return 'سيعود $date إلى ساعاتك المعتادة.';
  }

  @override
  String get hoursExceptionsDeleteConfirm => 'حذف';

  @override
  String get hoursExceptionsLoadError => 'تعذّر تحميل الساعات الاستثنائية.';

  @override
  String get hoursExceptionsSaveError =>
      'تعذّر حفظ الاستثناء. تم الاحتفاظ بإدخالاتك.';

  @override
  String get hoursExceptionsDeleteError =>
      'تعذّر حذف الاستثناء. يُرجى المحاولة مجددًا.';

  @override
  String get hoursExceptionsConflict =>
      'تم تعديل هذا التاريخ من جهة أخرى. أُعيد تحميل القائمة: تحقّق ثم احفظ مجددًا.';

  @override
  String get hoursExceptionsInvalid =>
      'رُفض الاستثناء: تحقّق من التاريخ (من اليوم إلى +365 يومًا) والفترات.';

  @override
  String get hoursExceptionsWeeklyRequired => 'أعدّ الساعات المعتادة أولًا.';

  @override
  String get hoursExceptionsTooMany =>
      'عدد كبير من الاستثناءات القادمة (100 كحد أقصى).';

  @override
  String get hoursExceptionsStaffReadOnly =>
      'للقراءة فقط: يمكن للمالك والمديرين فقط تعديل الساعات الاستثنائية.';

  @override
  String get hoursExceptionsDateRequired => 'اختر تاريخًا.';

  @override
  String get hoursExceptionsLabelRequired => 'أدخل سببًا.';

  @override
  String get hoursExceptionsIntervalsRequired =>
      'أضف فترة زمنية واحدة على الأقل.';

  @override
  String get hoursExceptionsSameDay =>
      'يجب أن تنتهي كل فترة في اليوم نفسه (00:00 = منتصف الليل).';

  @override
  String get hoursExceptionsHelpTitle => 'ترتيب التطبيق';

  @override
  String get hoursExceptionsHelpBody =>
      'يُطبَّق الإغلاق الإجباري أو المؤقت للفرع دائمًا أولًا. وإلا يستبدل الاستثناء الساعات المعتادة لتاريخه (بتوقيت الجزائر). وتتبع الأيام الأخرى الساعات المعتادة.';

  @override
  String get hoursExceptionsHelpOk => 'حسنًا';

  @override
  String hoursExceptionsToday(String label) {
    return 'استثناء اليوم: $label';
  }

  @override
  String get availabilityTitle => 'حالة المتجر';

  @override
  String get availabilityEstablishment => 'الفرع';

  @override
  String get availabilityOpen => 'مفتوح';

  @override
  String get availabilityClosed => 'مغلق';

  @override
  String get availabilityFollowSchedule => 'وفق الساعات';

  @override
  String get availabilityForceClosed => 'مغلق';

  @override
  String get availabilitySave => 'حفظ التعديلات';

  @override
  String get availabilitySaving => 'جاري الحفظ…';

  @override
  String get availabilitySaved => 'تم حفظ حالة المتجر.';

  @override
  String get availabilityClosureSaved => 'تم حفظ الإغلاق.';

  @override
  String get availabilityLoadError => 'تعذّر تحميل حالة المتجر.';

  @override
  String get availabilitySaveError => 'تعذّر حفظ حالة المتجر.';

  @override
  String get availabilityConflict =>
      'تغيّرت الحالة من جهة أخرى. تم إعادة التحميل — تحقّق ثم حاول مجددًا.';

  @override
  String get availabilityReopenTitle => 'إعادة الفتح وفق الساعات';

  @override
  String get availabilityReopenOutsideHoursBody =>
      'أنت خارج الساعات الأسبوعية. سيبقى المتجر مغلقًا حتى موعد الفتح التالي.';

  @override
  String get availabilityConfirmReopen => 'تأكيد';

  @override
  String get availabilityToday => 'اليوم';

  @override
  String get availabilityClosedToday => 'مغلق اليوم';

  @override
  String get availabilityModifyHours => 'تعديل';

  @override
  String get availabilityQuickPause => 'إيقاف سريع';

  @override
  String get availabilityQuickPauseHint => 'إغلاق مؤقت بسبب ضغط في المطبخ.';

  @override
  String get availabilityPause30 => '30 دقيقة';

  @override
  String get availabilityPause60 => '1 ساعة';

  @override
  String get availabilityActiveOrdersUnknown => 'طلبات قيد التنفيذ';

  @override
  String get availabilityCloseWarningTitle => 'تنبيه: إغلاق فوري';

  @override
  String get availabilityStaffReadOnly =>
      'للقراءة فقط: يمكن للمالك والمديرين فقط تعديل حالة المتجر.';

  @override
  String get availabilityBannerOpenTitle => 'المتجر متصل';

  @override
  String get availabilityBannerOpenBody =>
      'يمكن للعملاء تقديم الطلبات وعرض قائمتك بشكل طبيعي.';

  @override
  String get availabilityBannerClosedTitle => 'المتجر غير متصل';

  @override
  String get availabilityBannerClosedBody =>
      'لم يعد بإمكان العملاء تقديم طلبات جديدة.';

  @override
  String get availabilityBannerScheduleClosedTitle =>
      'حسب أوقات العمل — مغلق حالياً';

  @override
  String get availabilityBannerScheduleClosedBody =>
      'يتبع المتجر الجدول الزمني. سيفتح تلقائياً في الساعات القادمة.';

  @override
  String get availabilityReasonPeak => 'ضغط مرتفع (المطبخ)';

  @override
  String get availabilityReasonTechnical => 'مشكلة تقنية';

  @override
  String get availabilityReasonStock => 'نفاد المخزون';

  @override
  String get availabilityReasonLunch => 'استراحة الغداء';

  @override
  String get temporaryClosureTitle => 'إغلاق مؤقت';

  @override
  String get temporaryClosureActionRequired => 'إجراء مطلوب';

  @override
  String get temporaryClosureImpactLead =>
      'سيؤدي الإغلاق إلى تعليق قبول الطلبات الجديدة. ';

  @override
  String get temporaryClosureImpactNone => 'لا توجد طلبات قيد المعالجة.';

  @override
  String get temporaryClosureImpactUnknown =>
      'ستُبقى الطلبات قيد المعالجة ويجب تحضيرها.';

  @override
  String get temporaryClosureReason => 'سبب الإغلاق';

  @override
  String get temporaryClosureReopen => 'إعادة الفتح المخططة';

  @override
  String get temporaryClosure30m => 'خلال 30 دقيقة';

  @override
  String get temporaryClosure1h => 'خلال ساعة واحدة';

  @override
  String get temporaryClosurePickTime => 'اختر وقتاً…';

  @override
  String get temporaryClosureIndefinite => 'غير محدد (يدوي)';

  @override
  String get temporaryClosureImageImpact =>
      'التأثير على ظهورك: سيرى العملاء منشأتك على أنها «مغلق مؤقتاً».';

  @override
  String get temporaryClosureStaffReadOnly =>
      'يمكن للمالك والمديرين فقط إغلاق المتجر.';

  @override
  String get temporaryClosurePastTime =>
      'وقت إعادة الفتح قد مضى. اختر وقتاً جديداً.';

  @override
  String get temporaryClosureMessage => 'رسالة للعميل';

  @override
  String get temporaryClosureOptional => 'اختياري';

  @override
  String get temporaryClosureMessageHint =>
      'مثال: نحن ممتلئون حالياً، عد إلينا بعد 30 دقيقة!';

  @override
  String get temporaryClosureManualReopenHint =>
      'يمكنك إعادة الفتح يدوياً في أي وقت.';

  @override
  String get temporaryClosureConfirm => 'تأكيد الإغلاق';

  @override
  String get storeProfileAvailability => 'حالة المتجر';

  @override
  String get storeProfileAvailabilitySub =>
      'حسب أوقات العمل، الإغلاق، والاستراحة';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات حالياً.';

  @override
  String get notificationsLoadError => 'تعذّر تحميل الإشعارات.';

  @override
  String get notificationsToday => 'اليوم';

  @override
  String get notificationsYesterday => 'أمس';

  @override
  String get notificationsJustNow => 'الآن';

  @override
  String get notificationsMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get notificationsFilterAll => 'الكل';

  @override
  String get notificationsFilterOrders => 'الطلبات';

  @override
  String get notificationsOpenDetails => 'التفاصيل';

  @override
  String get notificationsOrderStale => 'هذا الطلب لم يعد بانتظار القبول.';

  @override
  String get alertNewOrder => 'طلب جديد';

  @override
  String get alertReceivedAt => 'استُلم في';

  @override
  String get alertPayment => 'الدفع';

  @override
  String get alertViewDetails => 'عرض التفاصيل';

  @override
  String get alertRefuse => 'رفض';

  @override
  String get alertItems => 'الأصناف';

  @override
  String get alertOrderTotal => 'المجموع الفرعي للبضائع';

  @override
  String get alertOrderLabel => 'طلب';

  @override
  String get alertDismiss => 'إغلاق';

  @override
  String get alertSeeList => 'عرض القائمة';

  @override
  String get notifSettingsTitle => 'إعدادات الإشعارات';

  @override
  String get notifSettingsScreenTitle => 'التنبيهات';

  @override
  String get notifSettingsOsEnabled =>
      'إذن iOS مفعّل. الإشعارات الفورية الأصلية غير مفعّلة بعد.';

  @override
  String get notifSettingsOsDenied =>
      'إذن iOS مرفوض (يمكن تعديله من الإعدادات). الإشعارات الفورية الأصلية غير مفعّلة بعد.';

  @override
  String get notifSettingsOsNotAsked => 'إذن الإشعارات: لم يُمنح بعد.';

  @override
  String get notifSettingsOsOpen => 'إعدادات النظام';

  @override
  String get notifSettingsSwitchesNote => 'فقط عندما يكون التطبيق مفتوحاً.';

  @override
  String get notifSettingsInAppSection => 'داخل التطبيق';

  @override
  String get notifSettingsCriticalWarning =>
      'لا يمكن كتم تنبيهات الطلبات الواردة الحرجة بالكامل دون خطر التأخير.';

  @override
  String get notifSettingsPushNotConfigured => 'غير مهيأ';

  @override
  String get notifSettingsSoundSection => 'التنبيهات الصوتية';

  @override
  String get notifSettingsSound => 'نغمة الطلبات الجديدة';

  @override
  String get notifSettingsVibrationSection => 'الاهتزاز';

  @override
  String get notifSettingsVibration => 'اهتزاز عند ورود طلب';

  @override
  String get notifSettingsPushSection => 'تنبيهات Push';

  @override
  String get notifSettingsOsEnabledPush => 'إذن الإشعارات: مفعّل.';

  @override
  String get notifSettingsOsDeniedPush =>
      'إذن الإشعارات مرفوض: فعّله من إعدادات النظام.';

  @override
  String get notifSettingsNativePush => 'الإشعارات خارج التطبيق';

  @override
  String get notifSettingsNativePushSub => 'التطبيق مغلق أو في الخلفية.';

  @override
  String get notifSettingsLockScreenNote =>
      'المعاينة على شاشة القفل: حسب إعدادات النظام.';

  @override
  String get notifPushStatusRegistered => 'هذا الجهاز مسجّل لاستلام الإشعارات.';

  @override
  String get notifPushStatusPending => 'جاري تسجيل الجهاز…';

  @override
  String get notifPushStatusDenied => 'الإذن مرفوض: لا إشعارات خارج التطبيق.';

  @override
  String get notifPushStatusDisabled => 'معطّلة على هذا الجهاز.';

  @override
  String get notifPushStatusTokenUnavailable =>
      'رمز الإشعار غير متاح على هذا الجهاز.';

  @override
  String get notifPushStatusFailed =>
      'تعذّر التسجيل حالياً. أعد المحاولة لاحقاً.';

  @override
  String get pushOrderInaccessible => 'هذا الطلب غير متاح لهذا الحساب.';

  @override
  String get notifSettingsForeground => 'التنبيهات داخل التطبيق';

  @override
  String get notifSettingsPushUnavailable =>
      'الإشعارات خارج التطبيق غير متاحة بعد.';

  @override
  String get notifSettingsPushBlocked =>
      'الإشعارات الفورية الأصلية (APNs/FCM) غير مهيأة: إذن iOS وحده لا يكفي.';

  @override
  String get notifSettingsSave => 'حفظ الإعدادات';

  @override
  String get notifSettingsSaved => 'تم حفظ الإعدادات.';

  @override
  String get profileRole => 'الدور';

  @override
  String get profileMerchant => 'التجارة';

  @override
  String get profileBranch => 'المنشأة';

  @override
  String get profileRoleOwner => 'المالك';

  @override
  String get profileRoleManager => 'المسؤول';

  @override
  String get profileRoleStaff => 'الفريق';

  @override
  String get profileSectionAccount => 'الحساب';

  @override
  String get profileSectionStore => 'المنشأة';

  @override
  String get profileSectionOps => 'عمليات المتجر';

  @override
  String get profileSectionPrefs => 'التفضيلات';

  @override
  String get profileSectionSupport => 'الدعم والشؤون القانونية';

  @override
  String get profileInfoReadonly => 'معلومات التجارة';

  @override
  String get profileBranchStatus => 'الحالة التشغيلية';

  @override
  String get profileUnavailableItem => 'غير متاح في هذا الإصدار';

  @override
  String get switchBranch => 'تغيير المنشأة';

  @override
  String get logoutConfirmTitle => 'تسجيل الخروج';

  @override
  String get logoutConfirmBody =>
      'هل تريد فعلاً تسجيل الخروج من SpeedyGo Merchant؟';

  @override
  String get logoutConfirmAction => 'تسجيل الخروج';

  @override
  String get settingsProfileRow => 'الملف الشخصي';

  @override
  String get settingsNotificationsOff => 'معطّل';

  @override
  String get settingsSupportSection => 'الدعم';

  @override
  String get settingsHelpCenter => 'مركز المساعدة';

  @override
  String get logoutConnected => 'متصل';

  @override
  String get logoutWarningTitle => 'تنبيه بشأن العمليات الجارية';

  @override
  String get logoutActiveOrders => 'الطلبات قيد المعالجة';

  @override
  String get logoutStoreState => 'حالة المتجر';

  @override
  String get logoutStoreOpen => 'مفتوح';

  @override
  String get logoutStoreClosed => 'مغلق';

  @override
  String get logoutHandoverAdvice =>
      'تأكد من توفر مسؤول آخر لمعالجة الطلبات قبل تسجيل الخروج.';

  @override
  String get logoutDataPreserved => 'ستُحفظ بياناتك والكتالوج وسجل الطلبات.';

  @override
  String get logoutCancel => 'إلغاء والرجوع';

  @override
  String get cancel => 'إلغاء';

  @override
  String get attentionRequired => 'بعض المستندات تتطلب انتباهك.';

  @override
  String get submitVerification => 'إرسال الملف';

  @override
  String get submitVerificationUnavailable =>
      'الإرسال غير ممكن بعد: مستندات إلزامية ناقصة أو غير مكتملة.';

  @override
  String get permissionDenied => 'رُفض الإذن من الخادم.';

  @override
  String get regTitle => 'التسجيل';

  @override
  String get regStepOf => 'الخطوة';

  @override
  String get regAccountTitle => 'إعداد الحساب';

  @override
  String get regRoleLabel => 'الدور';

  @override
  String get regOwner => 'المالك';

  @override
  String get regOperator => 'المشغّل';

  @override
  String get regOwnerHint => 'أنشئ تجارتك وأدرها بصفتك المالك.';

  @override
  String get regOperatorHint =>
      'الانضمام إلى تجارة قائمة يتطلب دعوة والرمز الذي يقدّمه المالك.';

  @override
  String get regOperatorUnsupported =>
      'للانضمام إلى تجارة، افتح الدعوات المستلمة وأدخل الرمز الذي قدّمه المالك. SpeedyGo لا يرسل رسائل SMS.';

  @override
  String get regOperatorOpenInvitations => 'عرض دعواتي';

  @override
  String get regSelectRole => 'اختر دوراً للمتابعة.';

  @override
  String get regContactTitle => 'بيانات الاتصال';

  @override
  String get regAccountContinue => 'متابعة التسجيل';

  @override
  String get regVerifiedPhone => 'رقم الهاتف (موثَّق)';

  @override
  String get regVerifiedPhoneHint =>
      'تم التحقق من هذا الرقم عند تسجيل الدخول. لا يمكن تعديله هنا.';

  @override
  String get regEmailUnsupported =>
      'لا يمكن تسجيل البريد الإلكتروني في هذه المرحلة.';

  @override
  String get regConsentUnsupported =>
      'اطّلع على الشروط العامة وسياسة الخصوصية لـ SpeedyGo قبل المتابعة.';

  @override
  String get regActivityTitle => 'معلومات التجارة';

  @override
  String get regActivityBody => 'أدخل الاسم الذي ستُعرَّف به تجارتك.';

  @override
  String get regLegalIdUnsupported =>
      'تُرفع وثائق الهوية المهنية في مرحلة المستندات.';

  @override
  String get regDocsTitle => 'مستندات المؤسسة';

  @override
  String get regDocsBody => 'أضف المستندات المطلوبة.';

  @override
  String get regDocsRequired => 'ارفع جميع المستندات الإلزامية قبل المتابعة.';

  @override
  String get regDocsTipsTitle => 'نصائح لالتقاط واضح';

  @override
  String get regDocsTipLight => 'فضّل إضاءة طبيعية ومتساوية لتجنب الظلال.';

  @override
  String get regDocsTipFrame =>
      'حدّد إطار المستند جيداً: يجب أن تظهر جميع الزوايا.';

  @override
  String get regDocsFormats =>
      'الصيغ المقبولة: PDF أو JPEG أو PNG (10 ميغابايت كحد أقصى).';

  @override
  String get regDocsContinue => 'متابعة';

  @override
  String get regDocsContinueFinal => 'المتابعة إلى المرحلة الأخيرة';

  @override
  String get regDocsAppBar => 'التحقق';

  @override
  String get regDocsTipFlash =>
      'عطّل الفلاش لتجنب الانعكاسات على الأسطح البلاستيكية.';

  @override
  String get regDocsPrivacy =>
      'تُرسل مستنداتك إلى SpeedyGo فقط للتحقق من تجارتك.';

  @override
  String get regFileTooLarge => 'الملف كبير جداً (الحد الأقصى 10 ميغابايت).';

  @override
  String get regFileTypeUnsupported =>
      'صيغة غير مقبولة. استخدم PDF أو JPEG أو PNG.';

  @override
  String get regPickerUnavailable =>
      'تعذّر فتح منتقي الملفات. أعد المحاولة بعد إعادة تشغيل التطبيق.';

  @override
  String get regPickDocument => 'إضافة';

  @override
  String get regReplaceDocument => 'استبدال';

  @override
  String get regEstablishmentTitle => 'تفاصيل المنشأة';

  @override
  String get regEstablishmentBody => 'أدخل معلومات منشأتك.';

  @override
  String get regIdentitySection => 'اسم المنشأة';

  @override
  String get regBranchNameFrLabel => 'اسم المنشأة';

  @override
  String get regCommerceContext => 'التجارة';

  @override
  String get regContactSection => 'جهة اتصال المنشأة';

  @override
  String get regCategorySection => 'الفئة';

  @override
  String get regCategoryReadonly => 'ستُحدَّد الفئة بعد التحقق.';

  @override
  String get regAddressSection => 'العنوان والموقع';

  @override
  String get regAddressGuidance => 'أدخل عنوان منشأتك.';

  @override
  String get regAddressExactLabel => 'العنوان الدقيق';

  @override
  String get regPickupPlace => 'موقع الاستلام';

  @override
  String get regChooseOnMap => 'اختيار على الخريطة';

  @override
  String get regLocationConfirmed => 'تم تأكيد الموقع';

  @override
  String get regLocationEdit => 'تعديل';

  @override
  String get regLocationRequired =>
      'أكّد موقع الاستلام على الخريطة قبل المتابعة.';

  @override
  String get regLocationPickerTitle => 'موقع المتجر';

  @override
  String get regLocationConfirm => 'تأكيد الموقع';

  @override
  String get regLocationUseGps => 'استخدام موقعي';

  @override
  String get regLocationMoveHint =>
      'حرّك الخريطة لوضع الدبوس على موقع الاستلام، أو استخدم موقعك عبر GPS.';

  @override
  String get regLocationGpsSuggestion =>
      'موقع GPS مقترح — أكّد فقط إذا كان موقع استلام المنشأة.';

  @override
  String get regLocationDenied =>
      'رُفض إذن الموقع. ضع الدبوس يدويًا على الخريطة.';

  @override
  String get regLocationDeniedForever =>
      'الموقع معطّل لتطبيق SpeedyGo. فعّله من الإعدادات، أو ضع الدبوس يدويًا.';

  @override
  String get regLocationServicesDisabled =>
      'خدمات الموقع معطّلة. ضع الدبوس يدويًا على الخريطة.';

  @override
  String get regLocationUnavailable =>
      'موقع GPS غير متاح. ضع الدبوس يدويًا على الخريطة.';

  @override
  String get regBranchPhoneLabel => 'رقم الهاتف';

  @override
  String get regBranchPhoneHint =>
      'رقم اتصال المنشأة (مختلف عن رقم تسجيل الدخول).';

  @override
  String get regPreviewLabel => 'معاينة (بيانات مُدخَلة — غير منشورة)';

  @override
  String get regBranchIncomplete => 'اسم المنشأة ورقم هاتفها وعنوانها مطلوبة.';

  @override
  String get regCoordsInvalid =>
      'خط العرض (−90…90) وخط الطول (−180…180) غير صالحين.';

  @override
  String get regCoordsConfirmHint => 'حدّد موقع الاستلام على الخريطة، ثم أكّد.';

  @override
  String get regReviewTitle => 'المراجعة';

  @override
  String get regReviewDocsTitle => 'المستندات القانونية';

  @override
  String get regReviewBranchTitle => 'المنشأة';

  @override
  String get regReviewLocation => 'الموقع';

  @override
  String get regReviewBody =>
      'يُرجى التحقّق بعناية من معلوماتك قبل الإرسال النهائي لتجنّب أي تأخير في الاعتماد.';

  @override
  String get regSubmit => 'إرسال للتحقق';

  @override
  String get regCorrectionTitle => 'تصحيح الملف';

  @override
  String get regCorrectionActionRequired => 'إجراء مطلوب';

  @override
  String get regCorrectionDetails => 'تفاصيل الملف';

  @override
  String get regCorrectionSubmit => 'إرسال التصحيحات';

  @override
  String get regContinue => 'متابعة';

  @override
  String get regEdit => 'تعديل';

  @override
  String get regMissingSteps => 'أكمل ملفك';

  @override
  String get regRejectionNoReason =>
      'يلزم إجراء تصحيحات. حدّث المستندات المعنية ثم أعد الإرسال.';

  @override
  String get regApprovedNext =>
      'تم اعتماد تجارتك. أكمل بعد ذلك ساعات العمل والكتالوج عند توفّرهما.';

  @override
  String get legalSectionTitle => 'الشروط والإقرار';

  @override
  String get legalSectionBody =>
      'قبل الإرسال، اقرأ الشروط التالية ووافق عليها. تُسجَّل موافقتك مع الملف.';

  @override
  String get legalTermsLabel =>
      'لقد قرأتُ وأوافق على الشروط العامة للتاجر SpeedyGo.';

  @override
  String get legalDeclarationLabel =>
      'أُقرّ بأن معلومات الملف ومستنداته دقيقة وكاملة.';

  @override
  String legalVersionTag(String version) {
    return 'الإصدار $version';
  }

  @override
  String get legalLoading => 'جاري تحميل الشروط…';

  @override
  String get legalLoadFailed =>
      'تعذّر تحميل الشروط. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get legalIncomplete => 'الشروط غير متاحة حاليًا. أعد المحاولة لاحقًا.';

  @override
  String get legalRetry => 'إعادة المحاولة';

  @override
  String get legalConsentRequired =>
      'وافق على الشروط وإقرار الدقّة لإرسال الملف.';

  @override
  String get legalVersionOutdated =>
      'تم تحديث الشروط. أعد قراءتها ثم وافق عليها مجددًا قبل الإرسال.';

  @override
  String get legalConsentHint => 'ضع علامة على الخانتين لتفعيل الإرسال.';

  @override
  String get legalContentLink => 'مرجع النص';

  @override
  String get issuesTitle => 'نقاط يجب تصحيحها';

  @override
  String get issuesApplicationTitle => 'معلومات الملف';

  @override
  String get issuesDocumentTitle => 'مستندات يجب استبدالها';

  @override
  String get issuesReplaceDocument => 'استبدال هذا المستند';

  @override
  String get issuesResolved => 'تم التصحيح';

  @override
  String get issuesFixHint =>
      'صحّح النقاط أعلاه (واستبدل المستندات المعنية إن وُجدت)، ووافق مجددًا على الشروط، ثم أرسل الملف.';

  @override
  String issuesRemaining(String count) {
    return 'نقطة واحدة متبقية للتصحيح$count نقاط متبقية للتصحيح';
  }

  @override
  String get dossierAttemptLabel => 'المحاولة رقم';

  @override
  String get dossierSubmittedAtLabel => 'أُرسل في';

  @override
  String get dossierReviewedAtLabel => 'رُوجع في';

  @override
  String get dossierConsentLabel => 'تم قبول الشروط';

  @override
  String dossierConsentVersions(String terms, String declaration) {
    return 'الشروط $terms · الإقرار $declaration';
  }

  @override
  String get settingsTeamRow => 'إدارة الفريق';

  @override
  String get settingsTeamInvitationsRow => 'الدعوات المستلمة';

  @override
  String get teamTitle => 'الموظفون والصلاحيات';

  @override
  String get teamStoreContext => 'إدارة الفريق';

  @override
  String get teamActiveMembers => 'الأعضاء النشطون';

  @override
  String get teamPendingInvitations => 'الدعوات قيد الانتظار';

  @override
  String get teamRolesSummary => 'ملخّص الأدوار';

  @override
  String get teamRoleOwner => 'المالك';

  @override
  String get teamRoleManager => 'المسؤول';

  @override
  String get teamRoleStaff => 'الفريق';

  @override
  String get teamOwnerBadge => 'إداري';

  @override
  String get teamSelfBadge => 'أنت';

  @override
  String get teamPhoneUnavailable => 'الرقم غير متاح';

  @override
  String get teamRevoke => 'إلغاء الصلاحية';

  @override
  String get teamChangeRole => 'تعديل الدور';

  @override
  String get teamRegenerateCode => 'إعادة إنشاء الرمز';

  @override
  String get teamCancelInvitation => 'إلغاء';

  @override
  String get teamInviteMember => 'دعوة عضو';

  @override
  String get teamInvitationExpired => 'منتهية';

  @override
  String teamRoleLine(String role) {
    return 'الدور: $role';
  }

  @override
  String teamExpiresOn(String date) {
    return 'تنتهي في $date';
  }

  @override
  String get teamEmptyMembers => 'لا يوجد أعضاء نشطون حاليًا.';

  @override
  String get teamEmptyInvitations => 'لا توجد دعوات قيد الانتظار.';

  @override
  String get teamLoadError =>
      'تعذّر تحميل الفريق. تحقّق من اتصالك ثم أعد المحاولة.';

  @override
  String get teamForbiddenTitle => 'وصول مقيّد';

  @override
  String get teamForbiddenBody => 'إدارة الفريق مخصّصة للمالكين والمسؤولين.';

  @override
  String get teamSummaryOwner => 'يدعو الأعضاء ويعدّل الأدوار ويلغي صلاحياتهم.';

  @override
  String get teamSummaryManager =>
      'يطّلع على قائمة الفريق والدعوات. لا يمكنه الدعوة ولا تعديل الأدوار ولا إلغاء الصلاحيات.';

  @override
  String get teamSummaryStaff => 'لا يملك صلاحية إدارة الفريق.';

  @override
  String get teamSummaryScope =>
      'تغطي الصلاحيات جميع منشآت التجارة: لا يوجد وصول حسب المنشأة.';

  @override
  String get teamInviteTitle => 'دعوة عضو';

  @override
  String get teamInviteHint =>
      'لا يُرسل SpeedyGo رسالة SMS ولا بريدًا إلكترونيًا. سيُسلَّم إليك رمز قبول: انقله بنفسك إلى الشخص المدعو.';

  @override
  String get teamInvitePhoneLabel => 'رقم الهاتف';

  @override
  String get teamInvitePhoneHint => '550 12 34 56';

  @override
  String get teamInvitePhoneHelper =>
      'الرقم الذي يستخدمه الشخص لتسجيل الدخول إلى SpeedyGo.';

  @override
  String get teamInvitePhoneInvalid =>
      'أدخل رقم هاتف محمول جزائري صالحًا (9 أرقام).';

  @override
  String get teamInviteRoleLabel => 'الدور';

  @override
  String get teamInviteCreate => 'إنشاء الدعوة';

  @override
  String get teamRoleManagerHint =>
      'يمكنه الاطّلاع على الفريق. بلا صلاحيات إدارة.';

  @override
  String get teamRoleStaffHint => 'وصول تشغيلي، دون صلاحية إدارة الفريق.';

  @override
  String get teamCodeTitle => 'رمز القبول';

  @override
  String get teamCodeRegeneratedTitle => 'رمز قبول جديد';

  @override
  String get teamCodeRegeneratedNote => 'الرمز السابق لم يعد صالحًا.';

  @override
  String get teamCodeCopy => 'نسخ الرمز';

  @override
  String get teamCodeCopied => 'تم نسخ الرمز.';

  @override
  String get teamCodeDone => 'إنهاء';

  @override
  String get teamRevokeTitle => 'إلغاء الصلاحية؟';

  @override
  String get teamRevoked => 'تم إلغاء الصلاحية.';

  @override
  String get teamCancelInviteTitle => 'إلغاء الدعوة؟';

  @override
  String teamCancelInviteBody(String phone) {
    return 'رمز القبول الخاص بـ $phone لن يعود صالحًا.';
  }

  @override
  String get teamCancelInviteConfirm => 'إلغاء الدعوة';

  @override
  String get teamKeep => 'إبقاء';

  @override
  String get teamInviteCancelled => 'تم إلغاء الدعوة.';

  @override
  String get teamRoleSheetTitle => 'تعديل الدور';

  @override
  String get teamRoleSheetHint =>
      'إذا قلّل الدور من صلاحياته، تُغلق جلسات العضو ويتعيّن عليه إعادة تسجيل الدخول.';

  @override
  String get teamRoleSave => 'حفظ';

  @override
  String get teamRoleUpdated => 'تم تحديث الدور.';

  @override
  String get teamErrorGeneric => 'تعذّر تنفيذ الإجراء حاليًا. أعد المحاولة.';

  @override
  String get teamErrorConflict =>
      'تغيّرت القائمة في الأثناء. تم تحديثها الآن: تحقّق ثم أعد المحاولة.';

  @override
  String get teamErrorDuplicateMember => 'هذا الرقم جزء من الفريق بالفعل.';

  @override
  String get teamErrorDuplicateInvite =>
      'توجد دعوة قيد الانتظار لهذا الرقم بالفعل.';

  @override
  String get teamErrorOwnerProtected => 'لا يمكن تعديل المالك من هنا.';

  @override
  String get teamErrorSelf => 'لا يمكنك تعديل صلاحيتك الخاصة.';

  @override
  String get teamErrorInviteGone => 'هذه الدعوة لم تعد موجودة.';

  @override
  String get teamErrorInviteExpired =>
      'انتهت صلاحية هذه الدعوة. اطلب رمزًا جديدًا من المالك.';

  @override
  String get teamErrorCodeInvalid => 'الرمز غير صحيح.';

  @override
  String get teamErrorPhoneMismatch => 'هذه الدعوة موجّهة إلى رقم آخر.';

  @override
  String get teamErrorInvalidInput => 'تحقّق من الرقم والدور ثم أعد المحاولة.';

  @override
  String get teamInvitationsTitle => 'الدعوات المستلمة';

  @override
  String get teamInvitationsHint =>
      'دعوات موجّهة إلى رقمك. أدخل الرمز الذي قدّمه المالك لقبولها.';

  @override
  String get teamInvitationsEmpty => 'لا توجد دعوات قيد الانتظار لرقمك.';

  @override
  String get teamInvitationsLoadError => 'تعذّر تحميل دعواتك. أعد المحاولة.';

  @override
  String get teamAccept => 'قبول';

  @override
  String get teamAcceptTitle => 'إدخال رمز القبول';

  @override
  String get teamAcceptCodeLabel => 'الرمز المقدَّم من المالك';

  @override
  String get teamAcceptCodeInvalid =>
      'يتكوّن الرمز من 64 حرفًا (أرقام وحروف من a إلى f).';

  @override
  String get teamAcceptConfirm => 'قبول الدعوة';

  @override
  String get settingsLanguageRow => 'اللغة';

  @override
  String get languageSettingsTitle => 'اللغة';

  @override
  String get languageSettingsSubtitle =>
      'اختر لغة التطبيق. يُطبَّق التغيير فورًا.';

  @override
  String get languageOptionFrench => 'Français';

  @override
  String get languageOptionArabic => 'العربية';

  @override
  String get languageApply => 'تطبيق التغييرات';

  @override
  String get languageApplied => 'تم تحديث اللغة.';

  @override
  String get languageBilingualTitle => 'اللغة / Langue';

  @override
  String get languagePreviewNote =>
      'تتبدل نصوص الواجهة بين الفرنسية والعربية. تبقى بيانات العمل دون تغيير.';
}
