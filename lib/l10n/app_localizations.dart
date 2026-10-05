import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('ar'),
  ];

  /// Merchant UI string appName
  ///
  /// In fr, this message translates to:
  /// **'SpeedyGo Merchant'**
  String get appName;

  /// Merchant UI string brandName
  ///
  /// In fr, this message translates to:
  /// **'SpeedyGo'**
  String get brandName;

  /// Merchant UI string splashTagline
  ///
  /// In fr, this message translates to:
  /// **'Votre commerce. Simplement.'**
  String get splashTagline;

  /// Merchant UI string splashLegacyTagline
  ///
  /// In fr, this message translates to:
  /// **'Espace commerçant'**
  String get splashLegacyTagline;

  /// Merchant UI string onboardingSkip
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// Merchant UI string onboardingNext
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// Merchant UI string onboardingStart
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// Merchant UI string onboardingHaveAccount
  ///
  /// In fr, this message translates to:
  /// **'J’ai déjà un compte'**
  String get onboardingHaveAccount;

  /// Merchant UI string onboardingPage1Title
  ///
  /// In fr, this message translates to:
  /// **'Recevez vos commandes'**
  String get onboardingPage1Title;

  /// Merchant UI string onboardingPage1Body
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez les nouvelles commandes et consultez leurs détails.'**
  String get onboardingPage1Body;

  /// Merchant UI string onboardingPage2Title
  ///
  /// In fr, this message translates to:
  /// **'Maîtrisez la préparation'**
  String get onboardingPage2Title;

  /// Merchant UI string onboardingPage2Body
  ///
  /// In fr, this message translates to:
  /// **'Organisez la préparation et indiquez quand une commande est prête.'**
  String get onboardingPage2Body;

  /// Merchant UI string onboardingPage3Title
  ///
  /// In fr, this message translates to:
  /// **'Votre commerce, à portée de main'**
  String get onboardingPage3Title;

  /// Merchant UI string onboardingPage3Body
  ///
  /// In fr, this message translates to:
  /// **'Retrouvez votre catalogue, vos horaires et les informations de votre établissement.'**
  String get onboardingPage3Body;

  /// Merchant UI string onboardingSaveFailed
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer l’introduction. Réessayez.'**
  String get onboardingSaveFailed;

  /// Merchant UI string onboardingPageSemantics
  ///
  /// In fr, this message translates to:
  /// **'Page d’introduction'**
  String get onboardingPageSemantics;

  /// Merchant UI string phoneTitle
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre numéro de téléphone'**
  String get phoneTitle;

  /// Merchant UI string phoneSubtitle
  ///
  /// In fr, this message translates to:
  /// **'Nous vous enverrons un code de vérification par SMS.'**
  String get phoneSubtitle;

  /// Merchant UI string phoneHint
  ///
  /// In fr, this message translates to:
  /// **'555 12 34 56'**
  String get phoneHint;

  /// Merchant UI string phonePrefix
  ///
  /// In fr, this message translates to:
  /// **'+213'**
  String get phonePrefix;

  /// Merchant UI string phoneSmsNote
  ///
  /// In fr, this message translates to:
  /// **'Les frais de SMS standard peuvent s’appliquer.'**
  String get phoneSmsNote;

  /// Merchant UI string phoneLabel
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneLabel;

  /// Merchant UI string phoneInvalid
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro algérien valide.'**
  String get phoneInvalid;

  /// Merchant UI string continueLabel
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueLabel;

  /// Merchant UI string needHelp
  ///
  /// In fr, this message translates to:
  /// **'Besoin d’aide ?'**
  String get needHelp;

  /// Merchant UI string helpUnavailable
  ///
  /// In fr, this message translates to:
  /// **'L’assistance sera disponible dans une prochaine version.'**
  String get helpUnavailable;

  /// Merchant UI string otpTitle
  ///
  /// In fr, this message translates to:
  /// **'Vérification du code'**
  String get otpTitle;

  /// Merchant UI string editNumber
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editNumber;

  /// Merchant UI string verify
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get verify;

  /// Merchant UI string resend
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resend;

  /// Merchant UI string resendIn
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code dans {clock}'**
  String resendIn(String clock);

  /// Merchant UI string otpCooldownHint
  ///
  /// In fr, this message translates to:
  /// **'Patientez avant de renvoyer un code'**
  String get otpCooldownHint;

  /// Merchant UI string resendCode
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// Merchant UI string otpSubtitle
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code à 6 chiffres envoyé au'**
  String get otpSubtitle;

  /// Merchant UI string restoreTitle
  ///
  /// In fr, this message translates to:
  /// **'Restauration de la session'**
  String get restoreTitle;

  /// Merchant UI string restoreLoading
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours…'**
  String get restoreLoading;

  /// Merchant UI string restoreOffline
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur. Vérifiez votre connexion.'**
  String get restoreOffline;

  /// Merchant UI string restoreRetry
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get restoreRetry;

  /// Merchant UI string restoreOtherAccount
  ///
  /// In fr, this message translates to:
  /// **'Utiliser un autre compte'**
  String get restoreOtherAccount;

  /// Merchant UI string sessionExpired
  ///
  /// In fr, this message translates to:
  /// **'Votre session a expiré. Connectez-vous.'**
  String get sessionExpired;

  /// Merchant UI string networkError
  ///
  /// In fr, this message translates to:
  /// **'Problème de réseau. Réessayez.'**
  String get networkError;

  /// Merchant UI string languageSaveFailed
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer la langue. Réessayez.'**
  String get languageSaveFailed;

  /// Merchant UI string retry
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// Merchant UI string refreshStatus
  ///
  /// In fr, this message translates to:
  /// **'Actualiser le statut'**
  String get refreshStatus;

  /// Merchant UI string back
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// Merchant UI string loading
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get loading;

  /// Merchant UI string tabHome
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// Merchant UI string tabOrders
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get tabOrders;

  /// Merchant UI string tabCatalog
  ///
  /// In fr, this message translates to:
  /// **'Catalogue'**
  String get tabCatalog;

  /// Merchant UI string tabReports
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get tabReports;

  /// Merchant UI string tabProfile
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// Merchant UI string navReveal
  ///
  /// In fr, this message translates to:
  /// **'Afficher la navigation'**
  String get navReveal;

  /// Merchant UI string homeTitle
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get homeTitle;

  /// Merchant UI string selectBranchTitle
  ///
  /// In fr, this message translates to:
  /// **'Choisir un établissement'**
  String get selectBranchTitle;

  /// Merchant UI string selectBranchSubtitle
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez l’établissement avec lequel vous souhaitez travailler.'**
  String get selectBranchSubtitle;

  /// Merchant UI string noMembershipTitle
  ///
  /// In fr, this message translates to:
  /// **'Aucun commerce associé'**
  String get noMembershipTitle;

  /// Merchant UI string noMembershipBody
  ///
  /// In fr, this message translates to:
  /// **'Ce compte n’a pas encore d’adhésion commerçant. Vous pouvez créer un profil commerce pour démarrer la vérification.'**
  String get noMembershipBody;

  /// Merchant UI string noMembershipInvitationsCta
  ///
  /// In fr, this message translates to:
  /// **'J’ai une invitation'**
  String get noMembershipInvitationsCta;

  /// Merchant UI string createMerchant
  ///
  /// In fr, this message translates to:
  /// **'Créer un commerce'**
  String get createMerchant;

  /// Merchant UI string merchantNameLabel
  ///
  /// In fr, this message translates to:
  /// **'Nom du commerce'**
  String get merchantNameLabel;

  /// Merchant UI string merchantNameHint
  ///
  /// In fr, this message translates to:
  /// **'Ex. Pharmacie du Centre'**
  String get merchantNameHint;

  /// Merchant UI string verificationPendingTitle
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours'**
  String get verificationPendingTitle;

  /// Merchant UI string verificationPendingBody
  ///
  /// In fr, this message translates to:
  /// **'Votre commerce est enregistré et en attente de vérification.'**
  String get verificationPendingBody;

  /// Merchant UI string verificationDossierProgress
  ///
  /// In fr, this message translates to:
  /// **'Pièces du dossier'**
  String get verificationDossierProgress;

  /// Merchant UI string verificationSubmittedStep
  ///
  /// In fr, this message translates to:
  /// **'Dossier soumis'**
  String get verificationSubmittedStep;

  /// Merchant UI string verificationReviewStep
  ///
  /// In fr, this message translates to:
  /// **'Examen des documents'**
  String get verificationReviewStep;

  /// Merchant UI string verificationReviewStepBody
  ///
  /// In fr, this message translates to:
  /// **'En cours d’examen par SpeedyGo'**
  String get verificationReviewStepBody;

  /// Merchant UI string verificationFinalStep
  ///
  /// In fr, this message translates to:
  /// **'Validation finale'**
  String get verificationFinalStep;

  /// Merchant UI string verificationFinalStepBody
  ///
  /// In fr, this message translates to:
  /// **'En attente de décision'**
  String get verificationFinalStepBody;

  /// Merchant UI string verificationTimelineTitle
  ///
  /// In fr, this message translates to:
  /// **'Progression du dossier'**
  String get verificationTimelineTitle;

  /// Merchant UI string verificationReferenceLabel
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get verificationReferenceLabel;

  /// Merchant UI string verificationReferenceFull
  ///
  /// In fr, this message translates to:
  /// **'Référence du dossier'**
  String get verificationReferenceFull;

  /// Merchant UI string approvedTitle
  ///
  /// In fr, this message translates to:
  /// **'Félicitations !'**
  String get approvedTitle;

  /// Merchant UI string approvedSubtitle
  ///
  /// In fr, this message translates to:
  /// **'Votre établissement est approuvé'**
  String get approvedSubtitle;

  /// Merchant UI string approvedBody
  ///
  /// In fr, this message translates to:
  /// **'Pour commencer à recevoir des commandes, assurez-vous que votre magasin est ouvert, que vos horaires sont définis et que vos produits sont disponibles.'**
  String get approvedBody;

  /// Merchant UI string approvedReferenceLabel
  ///
  /// In fr, this message translates to:
  /// **'RÉFÉRENCE MERCHANT'**
  String get approvedReferenceLabel;

  /// Merchant UI string approvedReferenceFull
  ///
  /// In fr, this message translates to:
  /// **'Référence Merchant'**
  String get approvedReferenceFull;

  /// Merchant UI string approvedBadge
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get approvedBadge;

  /// Merchant UI string approvedStepsTitle
  ///
  /// In fr, this message translates to:
  /// **'Étapes de configuration'**
  String get approvedStepsTitle;

  /// Merchant UI string approvedHoursTitle
  ///
  /// In fr, this message translates to:
  /// **'Horaires d’ouverture'**
  String get approvedHoursTitle;

  /// Merchant UI string approvedHoursBody
  ///
  /// In fr, this message translates to:
  /// **'Configurez quand vous êtes ouvert'**
  String get approvedHoursBody;

  /// Merchant UI string approvedCatalogTitle
  ///
  /// In fr, this message translates to:
  /// **'Catalogue de produits'**
  String get approvedCatalogTitle;

  /// Merchant UI string approvedCatalogBody
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez vos premiers articles'**
  String get approvedCatalogBody;

  /// Merchant UI string approvedAlertsTitle
  ///
  /// In fr, this message translates to:
  /// **'Alertes et notifications'**
  String get approvedAlertsTitle;

  /// Merchant UI string approvedAlertsBody
  ///
  /// In fr, this message translates to:
  /// **'Restez informé des commandes'**
  String get approvedAlertsBody;

  /// Merchant UI string approvedNeedBranchHint
  ///
  /// In fr, this message translates to:
  /// **'Disponible après l’ajout d’un établissement'**
  String get approvedNeedBranchHint;

  /// Merchant UI string approvedNotOpenNote
  ///
  /// In fr, this message translates to:
  /// **'L’approbation n’ouvre pas votre magasin automatiquement : vérifiez son statut, vos horaires et votre catalogue depuis l’accueil.'**
  String get approvedNotOpenNote;

  /// Merchant UI string approvedContinue
  ///
  /// In fr, this message translates to:
  /// **'Accéder à l’accueil marchand'**
  String get approvedContinue;

  /// Merchant UI string verificationRequestIdLabel
  ///
  /// In fr, this message translates to:
  /// **'ID DE DEMANDE'**
  String get verificationRequestIdLabel;

  /// Merchant UI string verificationNeedHelp
  ///
  /// In fr, this message translates to:
  /// **'Besoin d’aide pour votre dossier ?'**
  String get verificationNeedHelp;

  /// Merchant UI string verificationCorrectAndSubmit
  ///
  /// In fr, this message translates to:
  /// **'Corriger et soumettre'**
  String get verificationCorrectAndSubmit;

  /// Merchant UI string verificationRejectedTitle
  ///
  /// In fr, this message translates to:
  /// **'Dossier à compléter'**
  String get verificationRejectedTitle;

  /// Merchant UI string verificationRejectedBody
  ///
  /// In fr, this message translates to:
  /// **'Le dossier a été refusé. Corrigez le profil ou les pièces lorsque l’édition est autorisée, puis soumettez à nouveau.'**
  String get verificationRejectedBody;

  /// Merchant UI string verificationApprovedTitle
  ///
  /// In fr, this message translates to:
  /// **'Commerce approuvé'**
  String get verificationApprovedTitle;

  /// Merchant UI string verificationApprovedBody
  ///
  /// In fr, this message translates to:
  /// **'Votre commerce est approuvé. Complétez un établissement actif pour l’exploitation.'**
  String get verificationApprovedBody;

  /// Merchant UI string suspendedTitle
  ///
  /// In fr, this message translates to:
  /// **'Compte commerce suspendu'**
  String get suspendedTitle;

  /// Merchant UI string suspendedBody
  ///
  /// In fr, this message translates to:
  /// **'Ce commerce est suspendu. Contactez le support SpeedyGo si besoin.'**
  String get suspendedBody;

  /// Merchant UI string checklistTitle
  ///
  /// In fr, this message translates to:
  /// **'Pièces du dossier'**
  String get checklistTitle;

  /// Merchant UI string accessRestrictedTitle
  ///
  /// In fr, this message translates to:
  /// **'Accès restreint'**
  String get accessRestrictedTitle;

  /// Merchant UI string accessRestrictedBody
  ///
  /// In fr, this message translates to:
  /// **'Vous n’avez pas les droits nécessaires pour cette action.'**
  String get accessRestrictedBody;

  /// Merchant UI string needBranchTitle
  ///
  /// In fr, this message translates to:
  /// **'Établissement requis'**
  String get needBranchTitle;

  /// Merchant UI string needBranchBody
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins un établissement actif pour utiliser l’espace opérationnel.'**
  String get needBranchBody;

  /// Merchant UI string addBranch
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un établissement'**
  String get addBranch;

  /// Merchant UI string branchNameLabel
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’établissement'**
  String get branchNameLabel;

  /// Merchant UI string branchPhoneLabel
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get branchPhoneLabel;

  /// Merchant UI string branchAddressLabel
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get branchAddressLabel;

  /// Merchant UI string branchLatLabel
  ///
  /// In fr, this message translates to:
  /// **'Latitude'**
  String get branchLatLabel;

  /// Merchant UI string branchLngLabel
  ///
  /// In fr, this message translates to:
  /// **'Longitude'**
  String get branchLngLabel;

  /// Merchant UI string save
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Merchant UI string logout
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// Merchant UI string operationalActive
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get operationalActive;

  /// Merchant UI string operationalInactive
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get operationalInactive;

  /// Merchant UI string operationalSuspended
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get operationalSuspended;

  /// Merchant UI string homeNoMetrics
  ///
  /// In fr, this message translates to:
  /// **'Aucun indicateur agrégé n’est fourni par l’API dans cette phase.'**
  String get homeNoMetrics;

  /// Merchant UI string homeOrderCountsTitle
  ///
  /// In fr, this message translates to:
  /// **'Commandes en cours'**
  String get homeOrderCountsTitle;

  /// Merchant UI string homeCountIncoming
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux'**
  String get homeCountIncoming;

  /// Merchant UI string homeCountPreparing
  ///
  /// In fr, this message translates to:
  /// **'En prép.'**
  String get homeCountPreparing;

  /// Merchant UI string homeCountReady
  ///
  /// In fr, this message translates to:
  /// **'Prêts'**
  String get homeCountReady;

  /// Merchant UI string homeCountCourier
  ///
  /// In fr, this message translates to:
  /// **'Livreur'**
  String get homeCountCourier;

  /// Merchant UI string homeCountCourierUnavailable
  ///
  /// In fr, this message translates to:
  /// **'—'**
  String get homeCountCourierUnavailable;

  /// Merchant UI string homeActiveOrdersTitle
  ///
  /// In fr, this message translates to:
  /// **'Commandes actives'**
  String get homeActiveOrdersTitle;

  /// Merchant UI string homeActiveOrdersEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande active pour le moment.'**
  String get homeActiveOrdersEmpty;

  /// Merchant UI string homeTreatOrder
  ///
  /// In fr, this message translates to:
  /// **'Traiter la commande'**
  String get homeTreatOrder;

  /// Merchant UI string homeOpenOrder
  ///
  /// In fr, this message translates to:
  /// **'Voir la commande'**
  String get homeOpenOrder;

  /// Merchant UI string homeVerificationTitle
  ///
  /// In fr, this message translates to:
  /// **'Vérification à finaliser'**
  String get homeVerificationTitle;

  /// Merchant UI string homeVerificationBody
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre dossier pour conserver l’accès complet à votre espace marchand.'**
  String get homeVerificationBody;

  /// Merchant UI string homeKpiSales
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get homeKpiSales;

  /// Merchant UI string homeKpiOrders
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get homeKpiOrders;

  /// Merchant UI string homeKpiOrdersUnit
  ///
  /// In fr, this message translates to:
  /// **'terminées'**
  String get homeKpiOrdersUnit;

  /// Merchant UI string homeKpiCurrency
  ///
  /// In fr, this message translates to:
  /// **'DZD'**
  String get homeKpiCurrency;

  /// Merchant UI string homeKpiUnavailable
  ///
  /// In fr, this message translates to:
  /// **'—'**
  String get homeKpiUnavailable;

  /// Merchant UI string refresh
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// Merchant UI string ordersEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande pour cet établissement.'**
  String get ordersEmpty;

  /// Merchant UI string ordersEmptyIncoming
  ///
  /// In fr, this message translates to:
  /// **'Aucune nouvelle commande'**
  String get ordersEmptyIncoming;

  /// Merchant UI string ordersEmptyAccepted
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande acceptée'**
  String get ordersEmptyAccepted;

  /// Merchant UI string ordersEmptyPreparing
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande en préparation'**
  String get ordersEmptyPreparing;

  /// Merchant UI string ordersEmptyReady
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande prête'**
  String get ordersEmptyReady;

  /// Merchant UI string ordersEmptyCompleted
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande terminée'**
  String get ordersEmptyCompleted;

  /// Merchant UI string ordersEmptyCancelled
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande annulée'**
  String get ordersEmptyCancelled;

  /// Merchant UI string ordersEmptyFailed
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande échouée'**
  String get ordersEmptyFailed;

  /// Merchant UI string ordersLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les commandes.'**
  String get ordersLoadError;

  /// Merchant UI string orderDetailTitle
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get orderDetailTitle;

  /// Merchant UI string orderDetailLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger cette commande.'**
  String get orderDetailLoadError;

  /// Merchant UI string orderFulfillmentIncoming
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get orderFulfillmentIncoming;

  /// Merchant UI string supportReportTitle
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get supportReportTitle;

  /// Merchant UI string supportShort
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get supportShort;

  /// Merchant UI string supportContact
  ///
  /// In fr, this message translates to:
  /// **'Contacter le support'**
  String get supportContact;

  /// Merchant UI string supportOrderLabel
  ///
  /// In fr, this message translates to:
  /// **'COMMANDE'**
  String get supportOrderLabel;

  /// Merchant UI string supportCustomerLabel
  ///
  /// In fr, this message translates to:
  /// **'CLIENT'**
  String get supportCustomerLabel;

  /// Merchant UI string supportMerchandiseLabel
  ///
  /// In fr, this message translates to:
  /// **'MARCHANDISES'**
  String get supportMerchandiseLabel;

  /// Merchant UI string supportDescriptionLabel
  ///
  /// In fr, this message translates to:
  /// **'Description du problème'**
  String get supportDescriptionLabel;

  /// Merchant UI string supportDescriptionHint
  ///
  /// In fr, this message translates to:
  /// **'Expliquez-nous ce qui s’est passé en détail...'**
  String get supportDescriptionHint;

  /// Merchant UI string supportSensitiveHint
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ne pas inclure de données sensibles (ex : mots de passe).'**
  String get supportSensitiveHint;

  /// Merchant UI string supportSend
  ///
  /// In fr, this message translates to:
  /// **'Envoyer le ticket'**
  String get supportSend;

  /// Merchant UI string supportSentTitle
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé'**
  String get supportSentTitle;

  /// Merchant UI string supportSentBodyNoRef
  ///
  /// In fr, this message translates to:
  /// **'Votre ticket a été transmis à l’équipe SpeedyGo.'**
  String get supportSentBodyNoRef;

  /// Merchant UI string supportBackToOrder
  ///
  /// In fr, this message translates to:
  /// **'Retour à la commande'**
  String get supportBackToOrder;

  /// Merchant UI string supportForbidden
  ///
  /// In fr, this message translates to:
  /// **'Seuls le propriétaire et les gérants peuvent contacter le support.'**
  String get supportForbidden;

  /// Merchant UI string supportSendError
  ///
  /// In fr, this message translates to:
  /// **'Le ticket n’a pas pu être envoyé. Réessayez.'**
  String get supportSendError;

  /// Merchant UI string supportCenterTitle
  ///
  /// In fr, this message translates to:
  /// **'Support Merchant'**
  String get supportCenterTitle;

  /// Merchant UI string supportNewTicket
  ///
  /// In fr, this message translates to:
  /// **'Nouveau ticket'**
  String get supportNewTicket;

  /// Merchant UI string supportActiveTickets
  ///
  /// In fr, this message translates to:
  /// **'Tickets actifs'**
  String get supportActiveTickets;

  /// Merchant UI string supportResolvedTickets
  ///
  /// In fr, this message translates to:
  /// **'Tickets résolus'**
  String get supportResolvedTickets;

  /// Merchant UI string supportNoTickets
  ///
  /// In fr, this message translates to:
  /// **'Aucun ticket pour le moment.'**
  String get supportNoTickets;

  /// Merchant UI string supportLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos tickets.'**
  String get supportLoadError;

  /// Merchant UI string supportTopicsTitle
  ///
  /// In fr, this message translates to:
  /// **'Sujets fréquents'**
  String get supportTopicsTitle;

  /// Merchant UI string supportTopicsHint
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un sujet pour ouvrir un nouveau ticket.'**
  String get supportTopicsHint;

  /// Merchant UI string supportTopicsLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les sujets.'**
  String get supportTopicsLoadError;

  /// Merchant UI string supportTopicsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun sujet disponible pour le moment.'**
  String get supportTopicsEmpty;

  /// Merchant UI string supportTopicLabel
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get supportTopicLabel;

  /// Merchant UI string supportTopicRequired
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un sujet.'**
  String get supportTopicRequired;

  /// Merchant UI string supportSubjectLabel
  ///
  /// In fr, this message translates to:
  /// **'Objet'**
  String get supportSubjectLabel;

  /// Merchant UI string supportSubjectHint
  ///
  /// In fr, this message translates to:
  /// **'Résumez votre demande en quelques mots'**
  String get supportSubjectHint;

  /// Merchant UI string supportSubjectRequired
  ///
  /// In fr, this message translates to:
  /// **'Indiquez l’objet de votre demande.'**
  String get supportSubjectRequired;

  /// Merchant UI string supportFaqTitle
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get supportFaqTitle;

  /// Merchant UI string supportFaqEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune question fréquente pour le moment.'**
  String get supportFaqEmpty;

  /// Merchant UI string supportFaqLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la FAQ.'**
  String get supportFaqLoadError;

  /// Merchant UI string supportComposeTitle
  ///
  /// In fr, this message translates to:
  /// **'Nouveau ticket'**
  String get supportComposeTitle;

  /// Merchant UI string supportComposeHint
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre demande. Pour un problème sur une commande, utilisez « Signaler un problème » depuis la commande.'**
  String get supportComposeHint;

  /// Merchant UI string supportTicketTitle
  ///
  /// In fr, this message translates to:
  /// **'Ticket'**
  String get supportTicketTitle;

  /// Merchant UI string supportTicketLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce ticket.'**
  String get supportTicketLoadError;

  /// Merchant UI string supportLinkedOrder
  ///
  /// In fr, this message translates to:
  /// **'Commande liée'**
  String get supportLinkedOrder;

  /// Merchant UI string supportYou
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get supportYou;

  /// Merchant UI string supportTeam
  ///
  /// In fr, this message translates to:
  /// **'Support SpeedyGo'**
  String get supportTeam;

  /// Merchant UI string supportReplyHint
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse'**
  String get supportReplyHint;

  /// Merchant UI string supportReplySend
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get supportReplySend;

  /// Merchant UI string supportReplyError
  ///
  /// In fr, this message translates to:
  /// **'La réponse n’a pas pu être envoyée.'**
  String get supportReplyError;

  /// Merchant UI string supportTicketFinished
  ///
  /// In fr, this message translates to:
  /// **'Ce ticket est clos. Créez un nouveau ticket si besoin.'**
  String get supportTicketFinished;

  /// Merchant UI string supportNoMessages
  ///
  /// In fr, this message translates to:
  /// **'Aucun message.'**
  String get supportNoMessages;

  /// Merchant UI string orderListAcceptNow
  ///
  /// In fr, this message translates to:
  /// **'À accepter immédiatement'**
  String get orderListAcceptNow;

  /// Merchant UI string orderDetailsTitle
  ///
  /// In fr, this message translates to:
  /// **'Détails de la commande'**
  String get orderDetailsTitle;

  /// Merchant UI string orderDetailCancelledTitle
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée'**
  String get orderDetailCancelledTitle;

  /// Merchant UI string orderCancelledHeroBody
  ///
  /// In fr, this message translates to:
  /// **'Cette commande n’aboutira pas.'**
  String get orderCancelledHeroBody;

  /// Merchant UI string orderCancelledByCustomer
  ///
  /// In fr, this message translates to:
  /// **'Annulée par le client'**
  String get orderCancelledByCustomer;

  /// Merchant UI string orderRejectedByMerchant
  ///
  /// In fr, this message translates to:
  /// **'Refusée par le commerce'**
  String get orderRejectedByMerchant;

  /// Merchant UI string orderReasonLabel
  ///
  /// In fr, this message translates to:
  /// **'Raison'**
  String get orderReasonLabel;

  /// Merchant UI string orderCancelledAck
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get orderCancelledAck;

  /// Merchant UI string orderViewHistory
  ///
  /// In fr, this message translates to:
  /// **'Voir l’historique'**
  String get orderViewHistory;

  /// Merchant UI string orderCurrentStatus
  ///
  /// In fr, this message translates to:
  /// **'Statut actuel'**
  String get orderCurrentStatus;

  /// Merchant UI string orderReceivedAtLabel
  ///
  /// In fr, this message translates to:
  /// **'Reçue à'**
  String get orderReceivedAtLabel;

  /// Merchant UI string orderPaymentLabel
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get orderPaymentLabel;

  /// Merchant UI string orderPaymentMethod
  ///
  /// In fr, this message translates to:
  /// **'Méthode : {method}'**
  String orderPaymentMethod(String method);

  /// Merchant UI string eventCreated
  ///
  /// In fr, this message translates to:
  /// **'Commande reçue'**
  String get eventCreated;

  /// Merchant UI string eventCreatedCaption
  ///
  /// In fr, this message translates to:
  /// **'Commande passée par le client'**
  String get eventCreatedCaption;

  /// Merchant UI string eventAccepted
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get eventAccepted;

  /// Merchant UI string eventAcceptedCaption
  ///
  /// In fr, this message translates to:
  /// **'Commande confirmée'**
  String get eventAcceptedCaption;

  /// Merchant UI string eventPrepStarted
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get eventPrepStarted;

  /// Merchant UI string eventPrepStartedCaption
  ///
  /// In fr, this message translates to:
  /// **'Préparation démarrée'**
  String get eventPrepStartedCaption;

  /// Merchant UI string eventReady
  ///
  /// In fr, this message translates to:
  /// **'Préparée'**
  String get eventReady;

  /// Merchant UI string eventReadyCaption
  ///
  /// In fr, this message translates to:
  /// **'Prête pour la collecte'**
  String get eventReadyCaption;

  /// Merchant UI string eventRejected
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get eventRejected;

  /// Merchant UI string eventCancelled
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get eventCancelled;

  /// Merchant UI string eventCompleted
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get eventCompleted;

  /// Merchant UI string eventCompletedCaption
  ///
  /// In fr, this message translates to:
  /// **'Commande livrée au client'**
  String get eventCompletedCaption;

  /// Merchant UI string eventStatusUpdate
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour du statut'**
  String get eventStatusUpdate;

  /// Merchant UI string orderListLate
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get orderListLate;

  /// Merchant UI string orderHistoryToday
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get orderHistoryToday;

  /// Merchant UI string orderHistoryYesterday
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get orderHistoryYesterday;

  /// Merchant UI string orderHistoryEarlier
  ///
  /// In fr, this message translates to:
  /// **'Plus tôt'**
  String get orderHistoryEarlier;

  /// Merchant UI string orderFulfillmentAccepted
  ///
  /// In fr, this message translates to:
  /// **'Acceptée'**
  String get orderFulfillmentAccepted;

  /// Merchant UI string orderFulfillmentPreparing
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get orderFulfillmentPreparing;

  /// Merchant UI string orderFulfillmentReady
  ///
  /// In fr, this message translates to:
  /// **'Prête'**
  String get orderFulfillmentReady;

  /// Merchant UI string orderStatusCreated
  ///
  /// In fr, this message translates to:
  /// **'Créée'**
  String get orderStatusCreated;

  /// Merchant UI string orderStatusConfirmed
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get orderStatusConfirmed;

  /// Merchant UI string orderStatusActive
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get orderStatusActive;

  /// Merchant UI string orderStatusCompleted
  ///
  /// In fr, this message translates to:
  /// **'Terminée'**
  String get orderStatusCompleted;

  /// Merchant UI string orderStatusCancelled
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get orderStatusCancelled;

  /// Merchant UI string orderStatusFailed
  ///
  /// In fr, this message translates to:
  /// **'Échouée'**
  String get orderStatusFailed;

  /// Merchant UI string orderPaymentCod
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison'**
  String get orderPaymentCod;

  /// Merchant UI string orderPaymentElectronic
  ///
  /// In fr, this message translates to:
  /// **'Paiement électronique'**
  String get orderPaymentElectronic;

  /// Merchant UI string orderListMerchandiseLabel
  ///
  /// In fr, this message translates to:
  /// **'Marchandises'**
  String get orderListMerchandiseLabel;

  /// Merchant UI string orderIncomingBanner
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle commande'**
  String get orderIncomingBanner;

  /// Merchant UI string orderReadyBanner
  ///
  /// In fr, this message translates to:
  /// **'Commande prête'**
  String get orderReadyBanner;

  /// Merchant UI string orderSegmentActive
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get orderSegmentActive;

  /// Merchant UI string orderSegmentHistory
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get orderSegmentHistory;

  /// Merchant UI string orderReferenceCopy
  ///
  /// In fr, this message translates to:
  /// **'Copier la référence'**
  String get orderReferenceCopy;

  /// Merchant UI string orderReferenceCopied
  ///
  /// In fr, this message translates to:
  /// **'Référence copiée'**
  String get orderReferenceCopied;

  /// Merchant UI string orderReferenceShowFull
  ///
  /// In fr, this message translates to:
  /// **'Afficher la référence complète'**
  String get orderReferenceShowFull;

  /// Merchant UI string orderItemsTitle
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get orderItemsTitle;

  /// Merchant UI string orderItemsToPrepareTitle
  ///
  /// In fr, this message translates to:
  /// **'Articles à préparer'**
  String get orderItemsToPrepareTitle;

  /// Merchant UI string orderDeliveryAddress
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get orderDeliveryAddress;

  /// Merchant UI string orderFinanceTitle
  ///
  /// In fr, this message translates to:
  /// **'Répartition financière'**
  String get orderFinanceTitle;

  /// Merchant UI string orderFinanceGms
  ///
  /// In fr, this message translates to:
  /// **'Sous-total marchandises'**
  String get orderFinanceGms;

  /// Merchant UI string orderFinanceDiscount
  ///
  /// In fr, this message translates to:
  /// **'Remise commerçant'**
  String get orderFinanceDiscount;

  /// Merchant UI string orderFinanceNet
  ///
  /// In fr, this message translates to:
  /// **'Net commerçant'**
  String get orderFinanceNet;

  /// Merchant UI string orderFinanceCommissionUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Commission SpeedyGo'**
  String get orderFinanceCommissionUnavailable;

  /// Merchant UI string orderFinanceRestricted
  ///
  /// In fr, this message translates to:
  /// **'Commission, remise et net commerçant réservés au propriétaire ou au responsable.'**
  String get orderFinanceRestricted;

  /// Merchant UI string valueUnavailable
  ///
  /// In fr, this message translates to:
  /// **'—'**
  String get valueUnavailable;

  /// Merchant UI string orderFinanceNetCancelledNote
  ///
  /// In fr, this message translates to:
  /// **'Montants historiques figés au moment de la commande — pas un paiement dû.'**
  String get orderFinanceNetCancelledNote;

  /// Merchant UI string orderFinanceDeliveryFeeNote
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison (client)'**
  String get orderFinanceDeliveryFeeNote;

  /// Merchant UI string orderFinanceDeliveryFeeDisclaimer
  ///
  /// In fr, this message translates to:
  /// **'Les frais de livraison ne sont pas un revenu commerçant.'**
  String get orderFinanceDeliveryFeeDisclaimer;

  /// Merchant UI string orderAccept
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get orderAccept;

  /// Merchant UI string orderChoosePrepTime
  ///
  /// In fr, this message translates to:
  /// **'Choisir le temps de préparation'**
  String get orderChoosePrepTime;

  /// Merchant UI string orderReject
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get orderReject;

  /// Merchant UI string orderRejectTitle
  ///
  /// In fr, this message translates to:
  /// **'Refuser la commande'**
  String get orderRejectTitle;

  /// Merchant UI string orderRejectHint
  ///
  /// In fr, this message translates to:
  /// **'Le refus n’est possible qu’avant acceptation. Indiquez un motif.'**
  String get orderRejectHint;

  /// Merchant UI string orderRejectReasonLabel
  ///
  /// In fr, this message translates to:
  /// **'Motif du refus'**
  String get orderRejectReasonLabel;

  /// Merchant UI string orderRejectConfirm
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le refus'**
  String get orderRejectConfirm;

  /// Merchant UI string orderQuickAlreadyHandled
  ///
  /// In fr, this message translates to:
  /// **'Cette commande a déjà été traitée. La liste est actualisée.'**
  String get orderQuickAlreadyHandled;

  /// Merchant UI string orderQuickNotAllowed
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle ne permet pas cette action.'**
  String get orderQuickNotAllowed;

  /// Merchant UI string orderQuickCheckFailed
  ///
  /// In fr, this message translates to:
  /// **'Impossible de vérifier la commande. Réessayez.'**
  String get orderQuickCheckFailed;

  /// Merchant UI string orderQuickAccepted
  ///
  /// In fr, this message translates to:
  /// **'Commande acceptée.'**
  String get orderQuickAccepted;

  /// Merchant UI string orderQuickRejected
  ///
  /// In fr, this message translates to:
  /// **'Commande refusée.'**
  String get orderQuickRejected;

  /// Merchant UI string prepAcceptTitle
  ///
  /// In fr, this message translates to:
  /// **'Accepter la commande'**
  String get prepAcceptTitle;

  /// Merchant UI string prepEstimatedTitle
  ///
  /// In fr, this message translates to:
  /// **'Temps de préparation estimé'**
  String get prepEstimatedTitle;

  /// Merchant UI string prepConfirmAccept
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et accepter'**
  String get prepConfirmAccept;

  /// Merchant UI string prepCustomTime
  ///
  /// In fr, this message translates to:
  /// **'Temps personnalisé'**
  String get prepCustomTime;

  /// Merchant UI string prepCustomEntry
  ///
  /// In fr, this message translates to:
  /// **'Saisie personnalisée'**
  String get prepCustomEntry;

  /// Merchant UI string prepCustomRange
  ///
  /// In fr, this message translates to:
  /// **'Entre {min} et {max} minutes'**
  String prepCustomRange(String min, String max);

  /// Merchant UI string prepItemCount
  ///
  /// In fr, this message translates to:
  /// **'1 article{n} articles'**
  String prepItemCount(String n);

  /// Merchant UI string prepInProgress
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get prepInProgress;

  /// Merchant UI string prepCurrentShort
  ///
  /// In fr, this message translates to:
  /// **'Heure actuelle'**
  String get prepCurrentShort;

  /// Merchant UI string prepNewShort
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle estimation'**
  String get prepNewShort;

  /// Merchant UI string prepReasonHint
  ///
  /// In fr, this message translates to:
  /// **'Ex : problème technique en cuisine…'**
  String get prepReasonHint;

  /// Merchant UI string prepRemainingTitle
  ///
  /// In fr, this message translates to:
  /// **'Temps restant'**
  String get prepRemainingTitle;

  /// Merchant UI string prepMinutesCaption
  ///
  /// In fr, this message translates to:
  /// **'MINUTES'**
  String get prepMinutesCaption;

  /// Merchant UI string prepSecondsCaption
  ///
  /// In fr, this message translates to:
  /// **'SECONDES'**
  String get prepSecondsCaption;

  /// Merchant UI string prepLateHint
  ///
  /// In fr, this message translates to:
  /// **'L’estimation est dépassée. Mettez à jour le temps ou marquez la commande prête quand elle l’est.'**
  String get prepLateHint;

  /// Merchant UI string prepUpdateAction
  ///
  /// In fr, this message translates to:
  /// **'Modifier temps'**
  String get prepUpdateAction;

  /// Merchant UI string prepUpdateTitle
  ///
  /// In fr, this message translates to:
  /// **'Mise à jour du temps'**
  String get prepUpdateTitle;

  /// Merchant UI string prepCurrentReady
  ///
  /// In fr, this message translates to:
  /// **'Heure prévue actuelle'**
  String get prepCurrentReady;

  /// Merchant UI string prepOriginalReady
  ///
  /// In fr, this message translates to:
  /// **'Initiale : {time}'**
  String prepOriginalReady(String time);

  /// Merchant UI string prepOriginalReadyLabel
  ///
  /// In fr, this message translates to:
  /// **'Heure initiale : {time}'**
  String prepOriginalReadyLabel(String time);

  /// Merchant UI string prepBranchLabel
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get prepBranchLabel;

  /// Merchant UI string prepAddTime
  ///
  /// In fr, this message translates to:
  /// **'Ajouter du temps de préparation'**
  String get prepAddTime;

  /// Merchant UI string prepNewEstimate
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle estimation : {to} au lieu de {from}, plus {add} minutes'**
  String prepNewEstimate(String from, String to, String add);

  /// Merchant UI string prepClockOnDay
  ///
  /// In fr, this message translates to:
  /// **'le {day} à {time}'**
  String prepClockOnDay(String day, String time);

  /// Merchant UI string prepOnDay
  ///
  /// In fr, this message translates to:
  /// **'le {day}'**
  String prepOnDay(String day);

  /// Merchant UI string prepSpokenClock
  ///
  /// In fr, this message translates to:
  /// **'{time} le {day}'**
  String prepSpokenClock(String time, String day);

  /// Merchant UI string prepReasonOptional
  ///
  /// In fr, this message translates to:
  /// **'Raison du retard (optionnel)'**
  String get prepReasonOptional;

  /// Merchant UI string prepReasonShortcutsHint
  ///
  /// In fr, this message translates to:
  /// **'Un raccourci remplit le motif ; vous pouvez le modifier.'**
  String get prepReasonShortcutsHint;

  /// Merchant UI string prepReasonFieldLabel
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get prepReasonFieldLabel;

  /// Merchant UI string prepReasonBusy
  ///
  /// In fr, this message translates to:
  /// **'Forte affluence'**
  String get prepReasonBusy;

  /// Merchant UI string prepReasonLongPrep
  ///
  /// In fr, this message translates to:
  /// **'Préparation longue'**
  String get prepReasonLongPrep;

  /// Merchant UI string prepReasonMissingIngredient
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient manquant'**
  String get prepReasonMissingIngredient;

  /// Merchant UI string prepReasonOther
  ///
  /// In fr, this message translates to:
  /// **'Autre raison'**
  String get prepReasonOther;

  /// Merchant UI string prepUpdateConfirm
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get prepUpdateConfirm;

  /// Merchant UI string orderStartPreparation
  ///
  /// In fr, this message translates to:
  /// **'Démarrer la préparation'**
  String get orderStartPreparation;

  /// Merchant UI string orderMarkReady
  ///
  /// In fr, this message translates to:
  /// **'Marquer comme prête'**
  String get orderMarkReady;

  /// Merchant UI string markReadyPackingTitle
  ///
  /// In fr, this message translates to:
  /// **'Liste de colisage'**
  String get markReadyPackingTitle;

  /// Merchant UI string markReadyPackingHint
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez que tous les éléments de la commande sont bien emballés avant de la marquer prête.'**
  String get markReadyPackingHint;

  /// Merchant UI string markReadyConfirm
  ///
  /// In fr, this message translates to:
  /// **'Confirmer et marquer prête'**
  String get markReadyConfirm;

  /// Merchant UI string orderReadyWaitingDelivery
  ///
  /// In fr, this message translates to:
  /// **'En attente de prise en charge pour la livraison.'**
  String get orderReadyWaitingDelivery;

  /// Merchant UI string orderDeliveryStatusTitle
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get orderDeliveryStatusTitle;

  /// Merchant UI string orderDriverAssigned
  ///
  /// In fr, this message translates to:
  /// **'Un livreur est assigné.'**
  String get orderDriverAssigned;

  /// Merchant UI string orderDriverCardTitle
  ///
  /// In fr, this message translates to:
  /// **'Livreur assigné'**
  String get orderDriverCardTitle;

  /// Merchant UI string orderDriverStatusLabel
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get orderDriverStatusLabel;

  /// Merchant UI string orderDriverEtaLabel
  ///
  /// In fr, this message translates to:
  /// **'Arrivée estimée'**
  String get orderDriverEtaLabel;

  /// Merchant UI string orderDriverEtaUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Heure d’arrivée indisponible.'**
  String get orderDriverEtaUnavailable;

  /// Merchant UI string orderDriverContactUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Contact du livreur indisponible.'**
  String get orderDriverContactUnavailable;

  /// Merchant UI string orderDriverCall
  ///
  /// In fr, this message translates to:
  /// **'Appeler le livreur'**
  String get orderDriverCall;

  /// Merchant UI string pickupHandoffTitle
  ///
  /// In fr, this message translates to:
  /// **'Code de retrait'**
  String get pickupHandoffTitle;

  /// Merchant UI string pickupHandoffWaiting
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation par le livreur…'**
  String get pickupHandoffWaiting;

  /// Merchant UI string pickupHandoffInstruction1
  ///
  /// In fr, this message translates to:
  /// **'Communiquez ce code uniquement au livreur affiché ci-dessus.'**
  String get pickupHandoffInstruction1;

  /// Merchant UI string pickupHandoffInstruction2
  ///
  /// In fr, this message translates to:
  /// **'Le livreur doit saisir ce code dans son application pour confirmer la récupération.'**
  String get pickupHandoffInstruction2;

  /// Merchant UI string pickupHandoffRegenerate
  ///
  /// In fr, this message translates to:
  /// **'Régénérer le code'**
  String get pickupHandoffRegenerate;

  /// Merchant UI string pickupHandoffConfirmed
  ///
  /// In fr, this message translates to:
  /// **'Remise confirmée'**
  String get pickupHandoffConfirmed;

  /// Merchant UI string pickupHandoffLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le code de retrait.'**
  String get pickupHandoffLoadError;

  /// Merchant UI string pickupHandoffRetry
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get pickupHandoffRetry;

  /// Merchant UI string orderHandoffUnsupported
  ///
  /// In fr, this message translates to:
  /// **'La confirmation de remise sécurisée n’est pas disponible pour le commerçant dans cette version.'**
  String get orderHandoffUnsupported;

  /// Merchant UI string orderHistoryTitle
  ///
  /// In fr, this message translates to:
  /// **'Historique de la commande'**
  String get orderHistoryTitle;

  /// Merchant UI string orderReferenceLabel
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get orderReferenceLabel;

  /// Merchant UI string orderCustomerLabel
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get orderCustomerLabel;

  /// Merchant UI string orderSummaryTitle
  ///
  /// In fr, this message translates to:
  /// **'Résumé de la commande'**
  String get orderSummaryTitle;

  /// Merchant UI string deliverySearching
  ///
  /// In fr, this message translates to:
  /// **'Recherche de livreur'**
  String get deliverySearching;

  /// Merchant UI string deliveryAssigned
  ///
  /// In fr, this message translates to:
  /// **'Livreur assigné'**
  String get deliveryAssigned;

  /// Merchant UI string deliveryPickedUp
  ///
  /// In fr, this message translates to:
  /// **'Récupérée'**
  String get deliveryPickedUp;

  /// Merchant UI string deliveryArrived
  ///
  /// In fr, this message translates to:
  /// **'Arrivé chez le client'**
  String get deliveryArrived;

  /// Merchant UI string deliveryToPickup
  ///
  /// In fr, this message translates to:
  /// **'Livreur en route vers le commerce'**
  String get deliveryToPickup;

  /// Merchant UI string deliveryAtPickup
  ///
  /// In fr, this message translates to:
  /// **'Livreur arrivé au commerce'**
  String get deliveryAtPickup;

  /// Merchant UI string deliveryInTransit
  ///
  /// In fr, this message translates to:
  /// **'En route vers le client'**
  String get deliveryInTransit;

  /// Merchant UI string deliveryFailed
  ///
  /// In fr, this message translates to:
  /// **'Livraison échouée'**
  String get deliveryFailed;

  /// Merchant UI string deliveryCancelled
  ///
  /// In fr, this message translates to:
  /// **'Livraison annulée'**
  String get deliveryCancelled;

  /// Merchant UI string deliveryUnknown
  ///
  /// In fr, this message translates to:
  /// **'Statut de livraison indisponible'**
  String get deliveryUnknown;

  /// Merchant UI string deliveryDelivered
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get deliveryDelivered;

  /// Merchant UI string catalogTitle
  ///
  /// In fr, this message translates to:
  /// **'Catalogue'**
  String get catalogTitle;

  /// Merchant UI string catalogTabProducts
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get catalogTabProducts;

  /// Merchant UI string catalogTabCategories
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get catalogTabCategories;

  /// Merchant UI string catalogSearchHint
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un produit…'**
  String get catalogSearchHint;

  /// Merchant UI string catalogAllCategories
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get catalogAllCategories;

  /// Merchant UI string catalogEmptyProducts
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit dans ce catalogue.'**
  String get catalogEmptyProducts;

  /// Merchant UI string catalogEmptyCategories
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie pour le moment.'**
  String get catalogEmptyCategories;

  /// Merchant UI string catalogLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le catalogue.'**
  String get catalogLoadError;

  /// Merchant UI string catalogInStock
  ///
  /// In fr, this message translates to:
  /// **'En stock'**
  String get catalogInStock;

  /// Merchant UI string catalogOutOfStock
  ///
  /// In fr, this message translates to:
  /// **'Rupture'**
  String get catalogOutOfStock;

  /// Merchant UI string catalogUnavailableSection
  ///
  /// In fr, this message translates to:
  /// **'La création et l’édition avancées de produits ne sont pas branchées dans cet écran.'**
  String get catalogUnavailableSection;

  /// Merchant UI string reportsTitle
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get reportsTitle;

  /// Merchant UI string reportsPeriodToday
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get reportsPeriodToday;

  /// Merchant UI string reportsPeriodYesterday
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get reportsPeriodYesterday;

  /// Merchant UI string reportsPeriodWeek
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get reportsPeriodWeek;

  /// Merchant UI string reportsPeriodMonth
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get reportsPeriodMonth;

  /// Merchant UI string reportsFinanceTitle
  ///
  /// In fr, this message translates to:
  /// **'Détails financiers'**
  String get reportsFinanceTitle;

  /// Merchant UI string reportsGrossSales
  ///
  /// In fr, this message translates to:
  /// **'Ventes brutes'**
  String get reportsGrossSales;

  /// Merchant UI string reportsCommission
  ///
  /// In fr, this message translates to:
  /// **'Commission SpeedyGo'**
  String get reportsCommission;

  /// Merchant UI string reportsMerchantNet
  ///
  /// In fr, this message translates to:
  /// **'Net commerçant'**
  String get reportsMerchantNet;

  /// Merchant UI string reportsDataUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Données indisponibles'**
  String get reportsDataUnavailable;

  /// Merchant UI string reportsDataUnavailableShort
  ///
  /// In fr, this message translates to:
  /// **'—'**
  String get reportsDataUnavailableShort;

  /// Merchant UI string reportsOrdersMetric
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get reportsOrdersMetric;

  /// Merchant UI string reportsPrepTimeMetric
  ///
  /// In fr, this message translates to:
  /// **'Temps prép. moy.'**
  String get reportsPrepTimeMetric;

  /// Merchant UI string reportsCancellationsMetric
  ///
  /// In fr, this message translates to:
  /// **'Annulations'**
  String get reportsCancellationsMetric;

  /// Merchant UI string reportsTrendTitle
  ///
  /// In fr, this message translates to:
  /// **'Tendance des ventes'**
  String get reportsTrendTitle;

  /// Merchant UI string reportsTopProductsTitle
  ///
  /// In fr, this message translates to:
  /// **'Produits les plus vendus'**
  String get reportsTopProductsTitle;

  /// Merchant UI string reportsTopProductsScreenTitle
  ///
  /// In fr, this message translates to:
  /// **'Top produits'**
  String get reportsTopProductsScreenTitle;

  /// Merchant UI string reportsCommissionMixedRates
  ///
  /// In fr, this message translates to:
  /// **'Commission SpeedyGo (taux variables)'**
  String get reportsCommissionMixedRates;

  /// Merchant UI string reportsFinanceUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Données indisponibles'**
  String get reportsFinanceUnavailable;

  /// Merchant UI string reportsRatingsTitle
  ///
  /// In fr, this message translates to:
  /// **'Notes clients'**
  String get reportsRatingsTitle;

  /// Merchant UI string reportsRatingsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune note pour le moment.'**
  String get reportsRatingsEmpty;

  /// Merchant UI string reportsRatingsCount
  ///
  /// In fr, this message translates to:
  /// **'avis'**
  String get reportsRatingsCount;

  /// Merchant UI string reportsRatingsUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Données indisponibles'**
  String get reportsRatingsUnavailable;

  /// Merchant UI string reportsSettlementsTitle
  ///
  /// In fr, this message translates to:
  /// **'Règlements'**
  String get reportsSettlementsTitle;

  /// Merchant UI string reportsSettlementsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun règlement pour le moment.'**
  String get reportsSettlementsEmpty;

  /// Merchant UI string reportsSettlementsForbidden
  ///
  /// In fr, this message translates to:
  /// **'Les règlements sont réservés au propriétaire ou au responsable.'**
  String get reportsSettlementsForbidden;

  /// Merchant UI string reportsLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les indicateurs.'**
  String get reportsLoadError;

  /// Merchant UI string reportsTrendUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Données indisponibles'**
  String get reportsTrendUnavailable;

  /// Merchant UI string reportsTopProductsUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Données indisponibles'**
  String get reportsTopProductsUnavailable;

  /// Merchant UI string reportsPeriodCustom
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get reportsPeriodCustom;

  /// Merchant UI string reportsPeriodSelectorLabel
  ///
  /// In fr, this message translates to:
  /// **'Période du rapport'**
  String get reportsPeriodSelectorLabel;

  /// Merchant UI string reportsCustomRangeTooLong
  ///
  /// In fr, this message translates to:
  /// **'La période personnalisée est limitée à 93 jours.'**
  String get reportsCustomRangeTooLong;

  /// Merchant UI string reportsAverageBasketMetric
  ///
  /// In fr, this message translates to:
  /// **'Panier moyen'**
  String get reportsAverageBasketMetric;

  /// Merchant UI string reportsPrepTimeNotTracked
  ///
  /// In fr, this message translates to:
  /// **'Non suivi'**
  String get reportsPrepTimeNotTracked;

  /// Merchant UI string reportsMerchantDiscount
  ///
  /// In fr, this message translates to:
  /// **'Remise commerçant'**
  String get reportsMerchantDiscount;

  /// Merchant UI string reportsFinanceRestricted
  ///
  /// In fr, this message translates to:
  /// **'Commission et net commerçant réservés au propriétaire ou au responsable.'**
  String get reportsFinanceRestricted;

  /// Merchant UI string reportsFinanceMissingSnapshot
  ///
  /// In fr, this message translates to:
  /// **'Données financières indisponibles pour certaines commandes de la période.'**
  String get reportsFinanceMissingSnapshot;

  /// Merchant UI string reportsRefundsCompleted
  ///
  /// In fr, this message translates to:
  /// **'Remboursements finalisés'**
  String get reportsRefundsCompleted;

  /// Merchant UI string reportsRefundAdjustments
  ///
  /// In fr, this message translates to:
  /// **'Ajustements enregistrés'**
  String get reportsRefundAdjustments;

  /// Merchant UI string reportsRefundsNote
  ///
  /// In fr, this message translates to:
  /// **'Les remboursements ne réduisent pas les ventes. Seuls les ajustements enregistrés sur vos règlements vous sont imputés.'**
  String get reportsRefundsNote;

  /// Merchant UI string reportsTrendEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune vente sur la période.'**
  String get reportsTrendEmpty;

  /// Merchant UI string reportsTopProductsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit vendu sur la période.'**
  String get reportsTopProductsEmpty;

  /// Merchant UI string reportsSeeAll
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get reportsSeeAll;

  /// Merchant UI string reportsSortOrders
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get reportsSortOrders;

  /// Merchant UI string reportsSortRevenue
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d’affaires'**
  String get reportsSortRevenue;

  /// Merchant UI string reportsTopSales
  ///
  /// In fr, this message translates to:
  /// **'Top des ventes'**
  String get reportsTopSales;

  /// Merchant UI string reportsRankFirst
  ///
  /// In fr, this message translates to:
  /// **'N°1'**
  String get reportsRankFirst;

  /// Merchant UI string reportsDeletedProduct
  ///
  /// In fr, this message translates to:
  /// **'Produit retiré du catalogue'**
  String get reportsDeletedProduct;

  /// Merchant UI string reportsSalesLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les ventes.'**
  String get reportsSalesLoadError;

  /// Merchant UI string reportsTopProductsLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les produits.'**
  String get reportsTopProductsLoadError;

  /// Merchant UI string reportsOrderCount
  ///
  /// In fr, this message translates to:
  /// **'1 commande{count} commandes'**
  String reportsOrderCount(String count);

  /// Merchant UI string reportsTrendSemantics
  ///
  /// In fr, this message translates to:
  /// **'Tendance des ventes : {orders} commandes, {gross}'**
  String reportsTrendSemantics(String orders, String gross);

  /// Merchant UI string reportsDailySummaryTitle
  ///
  /// In fr, this message translates to:
  /// **'Résumé quotidien'**
  String get reportsDailySummaryTitle;

  /// Merchant UI string reportsDailySummaryShortcut
  ///
  /// In fr, this message translates to:
  /// **'Résumé quotidien'**
  String get reportsDailySummaryShortcut;

  /// Merchant UI string reportsDailySummaryLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le résumé quotidien.'**
  String get reportsDailySummaryLoadError;

  /// Merchant UI string reportsDailySummaryEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande créée pour cette journée.'**
  String get reportsDailySummaryEmpty;

  /// Merchant UI string reportsDailySummarySalesKpi
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get reportsDailySummarySalesKpi;

  /// Merchant UI string reportsDailySummaryOrdersKpi
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get reportsDailySummaryOrdersKpi;

  /// Merchant UI string reportsDailySummaryPrepKpi
  ///
  /// In fr, this message translates to:
  /// **'Temps Prép.'**
  String get reportsDailySummaryPrepKpi;

  /// Merchant UI string reportsDailySummaryCancellationsKpi
  ///
  /// In fr, this message translates to:
  /// **'Annulations'**
  String get reportsDailySummaryCancellationsKpi;

  /// Merchant UI string reportsDailySummaryBreakdownTitle
  ///
  /// In fr, this message translates to:
  /// **'Répartition des commandes'**
  String get reportsDailySummaryBreakdownTitle;

  /// Merchant UI string reportsDailySummaryDelivered
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get reportsDailySummaryDelivered;

  /// Merchant UI string reportsDailySummaryInProgress
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get reportsDailySummaryInProgress;

  /// Merchant UI string reportsDailySummaryCancelled
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get reportsDailySummaryCancelled;

  /// Merchant UI string reportsDailySummaryPrepEfficiencyTitle
  ///
  /// In fr, this message translates to:
  /// **'Efficacité de préparation'**
  String get reportsDailySummaryPrepEfficiencyTitle;

  /// Merchant UI string reportsDailySummaryPrepAverage
  ///
  /// In fr, this message translates to:
  /// **'Moyenne'**
  String get reportsDailySummaryPrepAverage;

  /// Merchant UI string reportsDailySummaryOnTimeRate
  ///
  /// In fr, this message translates to:
  /// **'À l’heure'**
  String get reportsDailySummaryOnTimeRate;

  /// Merchant UI string reportsDailySummaryCancellationMotifs
  ///
  /// In fr, this message translates to:
  /// **'Motifs d’annulation'**
  String get reportsDailySummaryCancellationMotifs;

  /// Merchant UI string reportsDailySummaryViewOrders
  ///
  /// In fr, this message translates to:
  /// **'Voir toutes les commandes du jour'**
  String get reportsDailySummaryViewOrders;

  /// Merchant UI string reportsDailySummaryMinutes
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String reportsDailySummaryMinutes(String minutes);

  /// Merchant UI string reportsDailySummaryOnTimePercent
  ///
  /// In fr, this message translates to:
  /// **'{percent} à l’heure'**
  String reportsDailySummaryOnTimePercent(String percent);

  /// Merchant UI string reportsDailySummaryTodayDate
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui, {label}'**
  String reportsDailySummaryTodayDate(String label);

  /// Merchant UI string deliveryImpactTitle
  ///
  /// In fr, this message translates to:
  /// **'Impact sur la livraison'**
  String get deliveryImpactTitle;

  /// Merchant UI string deliveryImpactMayDelayDriverAssignment
  ///
  /// In fr, this message translates to:
  /// **'La préparation peut retarder la recherche d’un livreur.'**
  String get deliveryImpactMayDelayDriverAssignment;

  /// Merchant UI string deliveryImpactMayDelayPickup
  ///
  /// In fr, this message translates to:
  /// **'Un livreur est assigné; le retrait peut être retardé.'**
  String get deliveryImpactMayDelayPickup;

  /// Merchant UI string deliveryImpactDriverWaiting
  ///
  /// In fr, this message translates to:
  /// **'Le livreur attend la commande.'**
  String get deliveryImpactDriverWaiting;

  /// Merchant UI string deliveryImpactTimingUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Impact exact sur la livraison indisponible.'**
  String get deliveryImpactTimingUnavailable;

  /// Merchant UI string deliveryImpactLatestRevision
  ///
  /// In fr, this message translates to:
  /// **'Dernier motif : {reason}'**
  String deliveryImpactLatestRevision(String reason);

  /// Merchant UI string rejectReasonProductUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Indisponibilité produit'**
  String get rejectReasonProductUnavailable;

  /// Merchant UI string rejectReasonTooBusy
  ///
  /// In fr, this message translates to:
  /// **'Trop occupé'**
  String get rejectReasonTooBusy;

  /// Merchant UI string rejectReasonClosingSoon
  ///
  /// In fr, this message translates to:
  /// **'Fermeture proche'**
  String get rejectReasonClosingSoon;

  /// Merchant UI string rejectReasonOther
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get rejectReasonOther;

  /// Merchant UI string rejectReasonTilesHint
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un motif puis précisez si nécessaire.'**
  String get rejectReasonTilesHint;

  /// Merchant UI string catalogAddProduct
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un produit'**
  String get catalogAddProduct;

  /// Merchant UI string catalogEditProduct
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get catalogEditProduct;

  /// Merchant UI string catalogProductDetail
  ///
  /// In fr, this message translates to:
  /// **'Détail du produit'**
  String get catalogProductDetail;

  /// Merchant UI string catalogAddCategory
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une catégorie'**
  String get catalogAddCategory;

  /// Merchant UI string catalogEditCategory
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get catalogEditCategory;

  /// Merchant UI string catalogProductName
  ///
  /// In fr, this message translates to:
  /// **'Nom du produit (Français)'**
  String get catalogProductName;

  /// Merchant UI string catalogProductDescription
  ///
  /// In fr, this message translates to:
  /// **'Description (Français)'**
  String get catalogProductDescription;

  /// Merchant UI string catalogProductPrice
  ///
  /// In fr, this message translates to:
  /// **'Prix de base'**
  String get catalogProductPrice;

  /// Merchant UI string catalogProductCategory
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get catalogProductCategory;

  /// Merchant UI string catalogProductAvailable
  ///
  /// In fr, this message translates to:
  /// **'Visible dans le menu'**
  String get catalogProductAvailable;

  /// Merchant UI string catalogProductAvailableSub
  ///
  /// In fr, this message translates to:
  /// **'Activer pour rendre disponible'**
  String get catalogProductAvailableSub;

  /// Merchant UI string catalogSaveProduct
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get catalogSaveProduct;

  /// Merchant UI string catalogSaveProductEdits
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get catalogSaveProductEdits;

  /// Merchant UI string catalogPreview
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get catalogPreview;

  /// Merchant UI string catalogPreviewTitle
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du produit'**
  String get catalogPreviewTitle;

  /// Merchant UI string catalogPreviewUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Aperçu non disponible actuellement.'**
  String get catalogPreviewUnavailable;

  /// Merchant UI string catalogFieldRequired
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get catalogFieldRequired;

  /// Merchant UI string catalogPriceInvalid
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un prix valide.'**
  String get catalogPriceInvalid;

  /// Merchant UI string catalogCategoryRequired
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une catégorie.'**
  String get catalogCategoryRequired;

  /// Merchant UI string catalogSaveRetryHint
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Vérifiez la connexion et réessayez.'**
  String get catalogSaveRetryHint;

  /// Merchant UI string catalogSectionInfo
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get catalogSectionInfo;

  /// Merchant UI string catalogSectionMedia
  ///
  /// In fr, this message translates to:
  /// **'Médias'**
  String get catalogSectionMedia;

  /// Merchant UI string catalogSectionPrice
  ///
  /// In fr, this message translates to:
  /// **'Prix et préparation'**
  String get catalogSectionPrice;

  /// Merchant UI string catalogSectionConfig
  ///
  /// In fr, this message translates to:
  /// **'Configuration'**
  String get catalogSectionConfig;

  /// Merchant UI string catalogSectionAvailability
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get catalogSectionAvailability;

  /// Merchant UI string catalogSectionImage
  ///
  /// In fr, this message translates to:
  /// **'Image du produit'**
  String get catalogSectionImage;

  /// Merchant UI string catalogSectionGeneral
  ///
  /// In fr, this message translates to:
  /// **'Informations générales'**
  String get catalogSectionGeneral;

  /// Merchant UI string catalogSectionPriceDetails
  ///
  /// In fr, this message translates to:
  /// **'Prix et détails'**
  String get catalogSectionPriceDetails;

  /// Merchant UI string catalogOnlineBanner
  ///
  /// In fr, this message translates to:
  /// **'Cet article est actuellement en ligne pour les clients.'**
  String get catalogOnlineBanner;

  /// Merchant UI string catalogOfflineBanner
  ///
  /// In fr, this message translates to:
  /// **'Cet article n’est pas visible pour les clients.'**
  String get catalogOfflineBanner;

  /// Merchant UI string catalogPriceWarning
  ///
  /// In fr, this message translates to:
  /// **'Les changements de prix et de disponibilité sont appliqués immédiatement aux clients.'**
  String get catalogPriceWarning;

  /// Merchant UI string catalogImagePrimary
  ///
  /// In fr, this message translates to:
  /// **'Image principale'**
  String get catalogImagePrimary;

  /// Merchant UI string catalogImageAdd
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get catalogImageAdd;

  /// Merchant UI string catalogImageHint
  ///
  /// In fr, this message translates to:
  /// **'JPG, PNG (max. 2 Mo, min. 400 px)'**
  String get catalogImageHint;

  /// Merchant UI string catalogImageChangePhoto
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get catalogImageChangePhoto;

  /// Merchant UI string catalogInStockNow
  ///
  /// In fr, this message translates to:
  /// **'Actuellement en stock'**
  String get catalogInStockNow;

  /// Merchant UI string catalogOutOfStockNow
  ///
  /// In fr, this message translates to:
  /// **'Actuellement indisponible'**
  String get catalogOutOfStockNow;

  /// Merchant UI string catalogCurrencySuffix
  ///
  /// In fr, this message translates to:
  /// **'DZD'**
  String get catalogCurrencySuffix;

  /// Merchant UI string catalogDeleteProduct
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get catalogDeleteProduct;

  /// Merchant UI string catalogNeedCategory
  ///
  /// In fr, this message translates to:
  /// **'Créez d’abord une catégorie pour ajouter un produit.'**
  String get catalogNeedCategory;

  /// Merchant UI string catalogImagePick
  ///
  /// In fr, this message translates to:
  /// **'Choisir une image'**
  String get catalogImagePick;

  /// Merchant UI string catalogImageFromGallery
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get catalogImageFromGallery;

  /// Merchant UI string catalogImageFromCamera
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get catalogImageFromCamera;

  /// Merchant UI string catalogImagePluginRestart
  ///
  /// In fr, this message translates to:
  /// **'Redémarrez l’application pour activer la sélection de photos.'**
  String get catalogImagePluginRestart;

  /// Merchant UI string catalogImageFormatError
  ///
  /// In fr, this message translates to:
  /// **'Format non pris en charge. Utilisez une photo JPG ou PNG.'**
  String get catalogImageFormatError;

  /// Merchant UI string catalogImageTooSmall
  ///
  /// In fr, this message translates to:
  /// **'Image trop petite. Minimum 400 × 400 pixels.'**
  String get catalogImageTooSmall;

  /// Merchant UI string catalogImageTooLarge
  ///
  /// In fr, this message translates to:
  /// **'Image trop lourde. Maximum 2 Mo après compression.'**
  String get catalogImageTooLarge;

  /// Merchant UI string catalogImageChange
  ///
  /// In fr, this message translates to:
  /// **'Changer l’image'**
  String get catalogImageChange;

  /// Merchant UI string catalogImageRemove
  ///
  /// In fr, this message translates to:
  /// **'Retirer l’image'**
  String get catalogImageRemove;

  /// Merchant UI string catalogImageUploadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’envoyer l’image.'**
  String get catalogImageUploadError;

  /// Merchant UI string catalogImageBindPartial
  ///
  /// In fr, this message translates to:
  /// **'Produit enregistré, mais l’image n’a pas pu être liée. Réessayez.'**
  String get catalogImageBindPartial;

  /// Merchant UI string catalogImageRemoteUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de l’image non disponible actuellement.'**
  String get catalogImageRemoteUnavailable;

  /// Merchant UI string catalogSaveError
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Vérifiez la connexion et réessayez.'**
  String get catalogSaveError;

  /// Merchant UI string catalogDeleteConfirm
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce produit ? Les commandes historiques sont conservées.'**
  String get catalogDeleteConfirm;

  /// Merchant UI string catalogCategoryName
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie (Français)'**
  String get catalogCategoryName;

  /// Merchant UI string catalogCategoryActive
  ///
  /// In fr, this message translates to:
  /// **'Visibilité dans le menu'**
  String get catalogCategoryActive;

  /// Merchant UI string catalogCategoryActiveSub
  ///
  /// In fr, this message translates to:
  /// **'Afficher cette catégorie aux clients'**
  String get catalogCategoryActiveSub;

  /// Merchant UI string catalogCategoryDetails
  ///
  /// In fr, this message translates to:
  /// **'Détails de la catégorie'**
  String get catalogCategoryDetails;

  /// Merchant UI string catalogCategorySettings
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get catalogCategorySettings;

  /// Merchant UI string catalogCategoryCancel
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get catalogCategoryCancel;

  /// Merchant UI string catalogDeleteCategory
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie'**
  String get catalogDeleteCategory;

  /// Merchant UI string catalogDeleteCategoryConfirm
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette catégorie ? Elle doit être vide.'**
  String get catalogDeleteCategoryConfirm;

  /// Merchant UI string catalogStaffReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Consultation seule — modifications réservées au propriétaire ou responsable.'**
  String get catalogStaffReadOnly;

  /// Merchant UI string catalogCategorySearchHint
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une catégorie…'**
  String get catalogCategorySearchHint;

  /// Merchant UI string catalogFilterTooltip
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get catalogFilterTooltip;

  /// Merchant UI string catalogReorder
  ///
  /// In fr, this message translates to:
  /// **'Réorganiser'**
  String get catalogReorder;

  /// Merchant UI string catalogVisible
  ///
  /// In fr, this message translates to:
  /// **'Visible'**
  String get catalogVisible;

  /// Merchant UI string catalogHidden
  ///
  /// In fr, this message translates to:
  /// **'Masqué'**
  String get catalogHidden;

  /// Merchant UI string catalogMenuAvailability
  ///
  /// In fr, this message translates to:
  /// **'Gérer la disponibilité'**
  String get catalogMenuAvailability;

  /// Merchant UI string catalogMenuDelete
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get catalogMenuDelete;

  /// Merchant UI string catalogMenuDuplicate
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get catalogMenuDuplicate;

  /// Merchant UI string duplicateTitle
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer le produit'**
  String get duplicateTitle;

  /// Merchant UI string duplicateSource
  ///
  /// In fr, this message translates to:
  /// **'Source'**
  String get duplicateSource;

  /// Merchant UI string duplicateNewName
  ///
  /// In fr, this message translates to:
  /// **'Nouveau nom du produit'**
  String get duplicateNewName;

  /// Merchant UI string duplicateNewNameHint
  ///
  /// In fr, this message translates to:
  /// **'Veuillez modifier le nom avant de publier la copie.'**
  String get duplicateNewNameHint;

  /// Merchant UI string duplicateNamePlaceholder
  ///
  /// In fr, this message translates to:
  /// **'Entrez le nouveau nom'**
  String get duplicateNamePlaceholder;

  /// Merchant UI string duplicateClearName
  ///
  /// In fr, this message translates to:
  /// **'Effacer le nom'**
  String get duplicateClearName;

  /// Merchant UI string duplicateDefaultName
  ///
  /// In fr, this message translates to:
  /// **'Copie de {name}'**
  String duplicateDefaultName(String name);

  /// Merchant UI string duplicateCopied
  ///
  /// In fr, this message translates to:
  /// **'Éléments copiés'**
  String get duplicateCopied;

  /// Merchant UI string duplicateImage
  ///
  /// In fr, this message translates to:
  /// **'Image du produit'**
  String get duplicateImage;

  /// Merchant UI string duplicateNoImage
  ///
  /// In fr, this message translates to:
  /// **'Image du produit (aucune image)'**
  String get duplicateNoImage;

  /// Merchant UI string duplicatePrice
  ///
  /// In fr, this message translates to:
  /// **'Prix ({price})'**
  String duplicatePrice(String price);

  /// Merchant UI string duplicateOptions
  ///
  /// In fr, this message translates to:
  /// **'Options et variantes'**
  String get duplicateOptions;

  /// Merchant UI string duplicateSaleUnits
  ///
  /// In fr, this message translates to:
  /// **'Unités de vente (non gérées)'**
  String get duplicateSaleUnits;

  /// Merchant UI string duplicateNotCopiedLead
  ///
  /// In fr, this message translates to:
  /// **'Le statut de disponibilité et l’historique des ventes '**
  String get duplicateNotCopiedLead;

  /// Merchant UI string duplicateNotCopiedStrong
  ///
  /// In fr, this message translates to:
  /// **'ne seront pas'**
  String get duplicateNotCopiedStrong;

  /// Merchant UI string duplicateNotCopiedTail
  ///
  /// In fr, this message translates to:
  /// **' copiés vers le nouveau produit.'**
  String get duplicateNotCopiedTail;

  /// Merchant UI string duplicateUnavailableInfo
  ///
  /// In fr, this message translates to:
  /// **'La copie sera créée indisponible afin que vous puissiez la vérifier avant de l’activer.'**
  String get duplicateUnavailableInfo;

  /// Merchant UI string duplicateCancel
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get duplicateCancel;

  /// Merchant UI string duplicateCreate
  ///
  /// In fr, this message translates to:
  /// **'Créer la copie'**
  String get duplicateCreate;

  /// Merchant UI string duplicateCreating
  ///
  /// In fr, this message translates to:
  /// **'Création…'**
  String get duplicateCreating;

  /// Merchant UI string duplicateNameRequired
  ///
  /// In fr, this message translates to:
  /// **'Le nom ne peut pas être vide.'**
  String get duplicateNameRequired;

  /// Merchant UI string duplicateNameTooLong
  ///
  /// In fr, this message translates to:
  /// **'Maximum 255 caractères.'**
  String get duplicateNameTooLong;

  /// Merchant UI string duplicateNetworkError
  ///
  /// In fr, this message translates to:
  /// **'Connexion interrompue. Réessayez : la copie ne sera pas créée deux fois.'**
  String get duplicateNetworkError;

  /// Merchant UI string duplicateError
  ///
  /// In fr, this message translates to:
  /// **'La copie n’a pas pu être créée et aucun produit n’a été ajouté. Réessayez.'**
  String get duplicateError;

  /// Merchant UI string duplicateConflict
  ///
  /// In fr, this message translates to:
  /// **'Cette demande de copie a déjà servi ailleurs. Rouvrez l’écran puis réessayez.'**
  String get duplicateConflict;

  /// Merchant UI string duplicateNotFound
  ///
  /// In fr, this message translates to:
  /// **'Produit introuvable. Actualisez le catalogue.'**
  String get duplicateNotFound;

  /// Merchant UI string duplicateCreated
  ///
  /// In fr, this message translates to:
  /// **'Copie créée — indisponible jusqu’à votre vérification.'**
  String get duplicateCreated;

  /// Merchant UI string duplicateReplayed
  ///
  /// In fr, this message translates to:
  /// **'Copie déjà créée — ouverture du produit.'**
  String get duplicateReplayed;

  /// Merchant UI string duplicateForbiddenTitle
  ///
  /// In fr, this message translates to:
  /// **'Duplication réservée au propriétaire ou au responsable'**
  String get duplicateForbiddenTitle;

  /// Merchant UI string duplicateBackToCatalog
  ///
  /// In fr, this message translates to:
  /// **'Retour au catalogue'**
  String get duplicateBackToCatalog;

  /// Merchant UI string catalogMenuViewCategory
  ///
  /// In fr, this message translates to:
  /// **'Voir la catégorie'**
  String get catalogMenuViewCategory;

  /// Merchant UI string catalogBulkTooltip
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité groupée'**
  String get catalogBulkTooltip;

  /// Merchant UI string catalogCategoryInUse
  ///
  /// In fr, this message translates to:
  /// **'Cette catégorie contient encore des produits. Déplacez-les ou supprimez-les d’abord.'**
  String get catalogCategoryInUse;

  /// Merchant UI string catalogProductInUse
  ///
  /// In fr, this message translates to:
  /// **'Ce produit figure dans des commandes passées : il ne peut pas être supprimé. Mettez-le en rupture à la place.'**
  String get catalogProductInUse;

  /// Merchant UI string catalogVisibilityError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier la visibilité. Réessayez.'**
  String get catalogVisibilityError;

  /// Merchant UI string catalogAvailabilityError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier la disponibilité. Réessayez.'**
  String get catalogAvailabilityError;

  /// Merchant UI string catalogNoResults
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit ne correspond à ces filtres.'**
  String get catalogNoResults;

  /// Merchant UI string catalogNoCategoryResults
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie ne correspond à cette recherche.'**
  String get catalogNoCategoryResults;

  /// Merchant UI string catalogFiltersTitle
  ///
  /// In fr, this message translates to:
  /// **'Recherche et Filtres'**
  String get catalogFiltersTitle;

  /// Merchant UI string catalogFiltersReset
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get catalogFiltersReset;

  /// Merchant UI string catalogFiltersCategories
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get catalogFiltersCategories;

  /// Merchant UI string catalogFiltersStatus
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get catalogFiltersStatus;

  /// Merchant UI string catalogFiltersOutOfStock
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get catalogFiltersOutOfStock;

  /// Merchant UI string catalogFiltersQuality
  ///
  /// In fr, this message translates to:
  /// **'Contrôle qualité'**
  String get catalogFiltersQuality;

  /// Merchant UI string catalogFiltersMissingImage
  ///
  /// In fr, this message translates to:
  /// **'Image manquante'**
  String get catalogFiltersMissingImage;

  /// Merchant UI string catalogFiltersPreview
  ///
  /// In fr, this message translates to:
  /// **'Aperçu des résultats'**
  String get catalogFiltersPreview;

  /// Merchant UI string catalogProductsCount
  ///
  /// In fr, this message translates to:
  /// **'{n} produit{n} produits'**
  String catalogProductsCount(String n);

  /// Merchant UI string catalogFiltersApply
  ///
  /// In fr, this message translates to:
  /// **'Appliquer les filtres'**
  String get catalogFiltersApply;

  /// Merchant UI string catalogCategoryDetailTitle
  ///
  /// In fr, this message translates to:
  /// **'Détails de la catégorie'**
  String get catalogCategoryDetailTitle;

  /// Merchant UI string catalogDisplayOrder
  ///
  /// In fr, this message translates to:
  /// **'Ordre d’affichage : {n}'**
  String catalogDisplayOrder(String n);

  /// Merchant UI string catalogCategoryProducts
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get catalogCategoryProducts;

  /// Merchant UI string catalogCategoryEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit dans cette catégorie.'**
  String get catalogCategoryEmpty;

  /// Merchant UI string catalogReorderTitle
  ///
  /// In fr, this message translates to:
  /// **'Réorganiser les catégories'**
  String get catalogReorderTitle;

  /// Merchant UI string catalogReorderHint
  ///
  /// In fr, this message translates to:
  /// **'Faites glisser pour modifier l’ordre d’affichage.'**
  String get catalogReorderHint;

  /// Merchant UI string catalogReorderSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer l’ordre'**
  String get catalogReorderSave;

  /// Merchant UI string catalogReorderSaved
  ///
  /// In fr, this message translates to:
  /// **'Ordre enregistré.'**
  String get catalogReorderSaved;

  /// Merchant UI string catalogReorderPartial
  ///
  /// In fr, this message translates to:
  /// **'Certaines catégories n’ont pas pu être déplacées. Réessayez.'**
  String get catalogReorderPartial;

  /// Merchant UI string catalogAvailabilityTitle
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité du produit'**
  String get catalogAvailabilityTitle;

  /// Merchant UI string catalogAvailabilityNote
  ///
  /// In fr, this message translates to:
  /// **'Les modifications n’affectent pas les commandes déjà acceptées.'**
  String get catalogAvailabilityNote;

  /// Merchant UI string catalogAvailabilityState
  ///
  /// In fr, this message translates to:
  /// **'État de disponibilité'**
  String get catalogAvailabilityState;

  /// Merchant UI string catalogAvailableOption
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get catalogAvailableOption;

  /// Merchant UI string catalogAvailableOptionSub
  ///
  /// In fr, this message translates to:
  /// **'Visible et commandable immédiatement.'**
  String get catalogAvailableOptionSub;

  /// Merchant UI string catalogOutOfStockOptionSub
  ///
  /// In fr, this message translates to:
  /// **'Affiché comme indisponible jusqu’à réactivation manuelle.'**
  String get catalogOutOfStockOptionSub;

  /// Merchant UI string catalogAvailabilitySave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la disponibilité'**
  String get catalogAvailabilitySave;

  /// Merchant UI string catalogAvailabilitySaved
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité enregistrée.'**
  String get catalogAvailabilitySaved;

  /// Merchant UI string catalogBulkTitle
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité groupée'**
  String get catalogBulkTitle;

  /// Merchant UI string catalogBulkNote
  ///
  /// In fr, this message translates to:
  /// **'Les modifications s’appliquent immédiatement sur l’application client. Elles n’affectent pas les commandes en cours.'**
  String get catalogBulkNote;

  /// Merchant UI string catalogBulkSelection
  ///
  /// In fr, this message translates to:
  /// **'Sélection multiple'**
  String get catalogBulkSelection;

  /// Merchant UI string catalogBulkNewStatus
  ///
  /// In fr, this message translates to:
  /// **'Nouveau statut'**
  String get catalogBulkNewStatus;

  /// Merchant UI string catalogBulkSelectAll
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get catalogBulkSelectAll;

  /// Merchant UI string catalogBulkClear
  ///
  /// In fr, this message translates to:
  /// **'Effacer la sélection'**
  String get catalogBulkClear;

  /// Merchant UI string catalogBulkApply
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get catalogBulkApply;

  /// Merchant UI string catalogBulkDone
  ///
  /// In fr, this message translates to:
  /// **'{n} produit mis à jour.{n} produits mis à jour.'**
  String catalogBulkDone(String n);

  /// Merchant UI string catalogBulkFailed
  ///
  /// In fr, this message translates to:
  /// **'{n} produit n’a pas pu être mis à jour.{n} produits n’ont pas pu être mis à jour.'**
  String catalogBulkFailed(String n);

  /// Merchant UI string catalogUncategorized
  ///
  /// In fr, this message translates to:
  /// **'Sans catégorie'**
  String get catalogUncategorized;

  /// Merchant UI string catalogDeleteTitle
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le produit'**
  String get catalogDeleteTitle;

  /// Merchant UI string catalogDeleteWarningTitle
  ///
  /// In fr, this message translates to:
  /// **'Un produit déjà commandé ne peut pas être supprimé.'**
  String get catalogDeleteWarningTitle;

  /// Merchant UI string catalogDeleteWarningBody
  ///
  /// In fr, this message translates to:
  /// **'Les commandes passées gardent leur copie du produit. Si la suppression est refusée, mettez le produit en rupture.'**
  String get catalogDeleteWarningBody;

  /// Merchant UI string catalogDeleteHideOption
  ///
  /// In fr, this message translates to:
  /// **'Mettre en rupture'**
  String get catalogDeleteHideOption;

  /// Merchant UI string catalogDeleteHideOptionSub
  ///
  /// In fr, this message translates to:
  /// **'Le produit reste enregistré et modifiable, mais n’est plus commandable.'**
  String get catalogDeleteHideOptionSub;

  /// Merchant UI string catalogDeleteRecommended
  ///
  /// In fr, this message translates to:
  /// **'Recommandé'**
  String get catalogDeleteRecommended;

  /// Merchant UI string catalogDeleteHardOption
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get catalogDeleteHardOption;

  /// Merchant UI string catalogDeleteHardOptionSub
  ///
  /// In fr, this message translates to:
  /// **'Retire le produit, ses variantes et suppléments. Impossible s’il figure dans une commande.'**
  String get catalogDeleteHardOptionSub;

  /// Merchant UI string catalogDeleteHardConfirm
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get catalogDeleteHardConfirm;

  /// Merchant UI string catalogDeleted
  ///
  /// In fr, this message translates to:
  /// **'Produit supprimé.'**
  String get catalogDeleted;

  /// Merchant UI string catalogMarkedOutOfStock
  ///
  /// In fr, this message translates to:
  /// **'Produit mis en rupture.'**
  String get catalogMarkedOutOfStock;

  /// Merchant UI string catalogVariantsTitle
  ///
  /// In fr, this message translates to:
  /// **'Variantes obligatoires'**
  String get catalogVariantsTitle;

  /// Merchant UI string catalogVariantsInfo
  ///
  /// In fr, this message translates to:
  /// **'Les variantes obligatoires demandent au client de choisir une option avant d’ajouter le produit au panier.'**
  String get catalogVariantsInfo;

  /// Merchant UI string catalogVariantsSubtitle
  ///
  /// In fr, this message translates to:
  /// **'Configurez les options requises avant l’ajout au panier.'**
  String get catalogVariantsSubtitle;

  /// Merchant UI string catalogExtrasTitle
  ///
  /// In fr, this message translates to:
  /// **'Suppléments optionnels'**
  String get catalogExtrasTitle;

  /// Merchant UI string catalogExtrasSubtitle
  ///
  /// In fr, this message translates to:
  /// **'Options facultatives que le client peut ajouter.'**
  String get catalogExtrasSubtitle;

  /// Merchant UI string catalogRequiredTag
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get catalogRequiredTag;

  /// Merchant UI string catalogSingleChoice
  ///
  /// In fr, this message translates to:
  /// **'Sélection unique'**
  String get catalogSingleChoice;

  /// Merchant UI string catalogAddChoice
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un choix'**
  String get catalogAddChoice;

  /// Merchant UI string catalogAddOption
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une option'**
  String get catalogAddOption;

  /// Merchant UI string catalogAddVariantGroup
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un groupe de variantes'**
  String get catalogAddVariantGroup;

  /// Merchant UI string catalogAddExtrasGroup
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe de suppléments'**
  String get catalogAddExtrasGroup;

  /// Merchant UI string catalogNewGroup
  ///
  /// In fr, this message translates to:
  /// **'Nouveau groupe'**
  String get catalogNewGroup;

  /// Merchant UI string catalogGroupName
  ///
  /// In fr, this message translates to:
  /// **'Nom du groupe (Français)'**
  String get catalogGroupName;

  /// Merchant UI string catalogGroupNameHint
  ///
  /// In fr, this message translates to:
  /// **'ex : Sauce'**
  String get catalogGroupNameHint;

  /// Merchant UI string catalogOptionName
  ///
  /// In fr, this message translates to:
  /// **'Nom du choix'**
  String get catalogOptionName;

  /// Merchant UI string catalogOptionPrice
  ///
  /// In fr, this message translates to:
  /// **'Prix (+)'**
  String get catalogOptionPrice;

  /// Merchant UI string catalogMaxSelectionsLabel
  ///
  /// In fr, this message translates to:
  /// **'Sélections maximum'**
  String get catalogMaxSelectionsLabel;

  /// Merchant UI string catalogGroupRequiredSwitch
  ///
  /// In fr, this message translates to:
  /// **'Choix obligatoire'**
  String get catalogGroupRequiredSwitch;

  /// Merchant UI string catalogGroupRequiredSub
  ///
  /// In fr, this message translates to:
  /// **'Le client doit choisir une option.'**
  String get catalogGroupRequiredSub;

  /// Merchant UI string catalogGroupSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le groupe'**
  String get catalogGroupSave;

  /// Merchant UI string catalogGroupDelete
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le groupe'**
  String get catalogGroupDelete;

  /// Merchant UI string catalogGroupDeleteConfirm
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce groupe et toutes ses options ? Les commandes passées ne sont pas modifiées.'**
  String get catalogGroupDeleteConfirm;

  /// Merchant UI string catalogOptionDelete
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’option'**
  String get catalogOptionDelete;

  /// Merchant UI string catalogOptionAvailable
  ///
  /// In fr, this message translates to:
  /// **'Option disponible'**
  String get catalogOptionAvailable;

  /// Merchant UI string catalogOptionsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun choix pour le moment.'**
  String get catalogOptionsEmpty;

  /// Merchant UI string catalogGroupsLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les options du produit.'**
  String get catalogGroupsLoadError;

  /// Merchant UI string catalogGroupInvalid
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez le nombre de sélections (minimum ≤ maximum).'**
  String get catalogGroupInvalid;

  /// Merchant UI string catalogSaveFirstForOptions
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez le produit pour configurer ses variantes et suppléments.'**
  String get catalogSaveFirstForOptions;

  /// Merchant UI string catalogGroupsCount
  ///
  /// In fr, this message translates to:
  /// **'Aucun groupe1 groupe{n} groupes'**
  String catalogGroupsCount(String n);

  /// Merchant UI string catalogLastUpdated
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour'**
  String get catalogLastUpdated;

  /// Merchant UI string catalogCustomerPreview
  ///
  /// In fr, this message translates to:
  /// **'Aperçu client'**
  String get catalogCustomerPreview;

  /// Merchant UI string catalogEditGroup
  ///
  /// In fr, this message translates to:
  /// **'Modifier le groupe'**
  String get catalogEditGroup;

  /// Merchant UI string catalogProductDetailTitle
  ///
  /// In fr, this message translates to:
  /// **'Détails du Produit'**
  String get catalogProductDetailTitle;

  /// Merchant UI string catalogDetailInfo
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get catalogDetailInfo;

  /// Merchant UI string catalogDetailName
  ///
  /// In fr, this message translates to:
  /// **'Nom (Français)'**
  String get catalogDetailName;

  /// Merchant UI string catalogDetailPricing
  ///
  /// In fr, this message translates to:
  /// **'Tarification'**
  String get catalogDetailPricing;

  /// Merchant UI string catalogDetailPrice
  ///
  /// In fr, this message translates to:
  /// **'Prix de base'**
  String get catalogDetailPrice;

  /// Merchant UI string catalogDetailAppearance
  ///
  /// In fr, this message translates to:
  /// **'Apparence sur l’application'**
  String get catalogDetailAppearance;

  /// Merchant UI string catalogDetailAvailable
  ///
  /// In fr, this message translates to:
  /// **'Produit disponible'**
  String get catalogDetailAvailable;

  /// Merchant UI string catalogDetailNoDescription
  ///
  /// In fr, this message translates to:
  /// **'Aucune description.'**
  String get catalogDetailNoDescription;

  /// Merchant UI string catalogDetailNoOptions
  ///
  /// In fr, this message translates to:
  /// **'Aucune variante ni supplément configuré.'**
  String get catalogDetailNoOptions;

  /// Merchant UI string catalogRequiredSummary
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire · {rule}'**
  String catalogRequiredSummary(String rule);

  /// Merchant UI string catalogOptionalSummary
  ///
  /// In fr, this message translates to:
  /// **'Facultatif · Maximum {max}'**
  String catalogOptionalSummary(String max);

  /// Merchant UI string catalogCropTitle
  ///
  /// In fr, this message translates to:
  /// **'Image du produit'**
  String get catalogCropTitle;

  /// Merchant UI string catalogCropTipsTitle
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour une belle photo'**
  String get catalogCropTipsTitle;

  /// Merchant UI string catalogCropTip1
  ///
  /// In fr, this message translates to:
  /// **'Utilisez un fond neutre et propre (blanc ou bois clair).'**
  String get catalogCropTip1;

  /// Merchant UI string catalogCropTip2
  ///
  /// In fr, this message translates to:
  /// **'Assurez-vous d’avoir un bon éclairage, de préférence naturel.'**
  String get catalogCropTip2;

  /// Merchant UI string catalogCropTip3
  ///
  /// In fr, this message translates to:
  /// **'Centrez le produit dans le cadre.Centrez le produit (« {name} ») dans le cadre.'**
  String catalogCropTip3(String name);

  /// Merchant UI string catalogCropFormat
  ///
  /// In fr, this message translates to:
  /// **'Format : JPG, PNG (max. 2 Mo, min. 400 px)'**
  String get catalogCropFormat;

  /// Merchant UI string catalogCropUse
  ///
  /// In fr, this message translates to:
  /// **'Utiliser cette image'**
  String get catalogCropUse;

  /// Merchant UI string catalogCropRotate
  ///
  /// In fr, this message translates to:
  /// **'Pivoter'**
  String get catalogCropRotate;

  /// Merchant UI string catalogCropZoom
  ///
  /// In fr, this message translates to:
  /// **'Zoomer'**
  String get catalogCropZoom;

  /// Merchant UI string catalogCropRemove
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’image'**
  String get catalogCropRemove;

  /// Merchant UI string contractFieldUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Non disponible actuellement'**
  String get contractFieldUnavailable;

  /// Merchant UI string catalogFieldNameAr
  ///
  /// In fr, this message translates to:
  /// **'Nom du produit (Arabe)'**
  String get catalogFieldNameAr;

  /// Merchant UI string catalogFieldDescAr
  ///
  /// In fr, this message translates to:
  /// **'Description (Arabe)'**
  String get catalogFieldDescAr;

  /// Merchant UI string catalogFieldPrepTime
  ///
  /// In fr, this message translates to:
  /// **'Temps de prép.'**
  String get catalogFieldPrepTime;

  /// Merchant UI string catalogFieldSaleUnit
  ///
  /// In fr, this message translates to:
  /// **'Unité de vente'**
  String get catalogFieldSaleUnit;

  /// Merchant UI string sellingUnitTitle
  ///
  /// In fr, this message translates to:
  /// **'Unités de vente'**
  String get sellingUnitTitle;

  /// Merchant UI string sellingUnitCalloutTitle
  ///
  /// In fr, this message translates to:
  /// **'Précision de l’unité'**
  String get sellingUnitCalloutTitle;

  /// Merchant UI string sellingUnitCalloutBody
  ///
  /// In fr, this message translates to:
  /// **'Choisissez l’unité exacte pour éviter toute confusion lors de la préparation. Cette unité sera affichée aux clients (ex : 1 500 DZD / Plat). Les quantités sont entières : pas de vente au poids.'**
  String get sellingUnitCalloutBody;

  /// Merchant UI string sellingUnitPreviewLabel
  ///
  /// In fr, this message translates to:
  /// **'Aperçu client'**
  String get sellingUnitPreviewLabel;

  /// Merchant UI string sellingUnitPreviewNoPrice
  ///
  /// In fr, this message translates to:
  /// **'— DZD'**
  String get sellingUnitPreviewNoPrice;

  /// Merchant UI string sellingUnitCommon
  ///
  /// In fr, this message translates to:
  /// **'Unités courantes'**
  String get sellingUnitCommon;

  /// Merchant UI string sellingUnitPackaging
  ///
  /// In fr, this message translates to:
  /// **'Conditionnement'**
  String get sellingUnitPackaging;

  /// Merchant UI string sellingUnitNone
  ///
  /// In fr, this message translates to:
  /// **'Aucune unité'**
  String get sellingUnitNone;

  /// Merchant UI string sellingUnitNoneSub
  ///
  /// In fr, this message translates to:
  /// **'Le prix est affiché sans unité.'**
  String get sellingUnitNoneSub;

  /// Merchant UI string sellingUnitNotSet
  ///
  /// In fr, this message translates to:
  /// **'Non définie'**
  String get sellingUnitNotSet;

  /// Merchant UI string sellingUnitCustomName
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’unité (Français)'**
  String get sellingUnitCustomName;

  /// Merchant UI string sellingUnitCustomHint
  ///
  /// In fr, this message translates to:
  /// **'ex : Cornet'**
  String get sellingUnitCustomHint;

  /// Merchant UI string sellingUnitApply
  ///
  /// In fr, this message translates to:
  /// **'Appliquer l’unité'**
  String get sellingUnitApply;

  /// Merchant UI string sellingUnitReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Seuls le propriétaire et les gérants peuvent modifier l’unité de vente.'**
  String get sellingUnitReadOnly;

  /// Merchant UI string catalogFieldVariants
  ///
  /// In fr, this message translates to:
  /// **'Variantes obligatoires'**
  String get catalogFieldVariants;

  /// Merchant UI string catalogFieldExtras
  ///
  /// In fr, this message translates to:
  /// **'Suppléments optionnels'**
  String get catalogFieldExtras;

  /// Merchant UI string catalogFieldCategoryNameAr
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie (Arabe)'**
  String get catalogFieldCategoryNameAr;

  /// Merchant UI string catalogFieldCategoryDesc
  ///
  /// In fr, this message translates to:
  /// **'Description de la catégorie (Optionnel)'**
  String get catalogFieldCategoryDesc;

  /// Merchant UI string storeCoverTitle
  ///
  /// In fr, this message translates to:
  /// **'Logo et Couverture'**
  String get storeCoverTitle;

  /// Merchant UI string storeCoverPick
  ///
  /// In fr, this message translates to:
  /// **'Choisir une couverture'**
  String get storeCoverPick;

  /// Merchant UI string storeCoverReplace
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get storeCoverReplace;

  /// Merchant UI string storeCoverSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get storeCoverSave;

  /// Merchant UI string storeCoverRemove
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get storeCoverRemove;

  /// Merchant UI string storeCoverSection
  ///
  /// In fr, this message translates to:
  /// **'Photo de couverture'**
  String get storeCoverSection;

  /// Merchant UI string storeCoverSectionHint
  ///
  /// In fr, this message translates to:
  /// **'La photo de couverture doit représenter votre établissement.'**
  String get storeCoverSectionHint;

  /// Merchant UI string storeLogoSection
  ///
  /// In fr, this message translates to:
  /// **'Logo du magasin'**
  String get storeLogoSection;

  /// Merchant UI string storeLogoSectionHint
  ///
  /// In fr, this message translates to:
  /// **'Le logo doit être lisible même en petit format.'**
  String get storeLogoSectionHint;

  /// Merchant UI string storeLogoEdit
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get storeLogoEdit;

  /// Merchant UI string storeLogoAdd
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get storeLogoAdd;

  /// Merchant UI string storeLogoRemove
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get storeLogoRemove;

  /// Merchant UI string storeLogoEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun logo'**
  String get storeLogoEmpty;

  /// Merchant UI string storeLogoPending
  ///
  /// In fr, this message translates to:
  /// **'Nouveau logo sélectionné — enregistrez pour l’appliquer.'**
  String get storeLogoPending;

  /// Merchant UI string storeLogoTooSmall
  ///
  /// In fr, this message translates to:
  /// **'Logo trop petit. Minimum 128 × 128 pixels.'**
  String get storeLogoTooSmall;

  /// Merchant UI string storeLogoTooLarge
  ///
  /// In fr, this message translates to:
  /// **'Logo trop lourd. Maximum 1 Mo après compression.'**
  String get storeLogoTooLarge;

  /// Merchant UI string storeLogoUploadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’envoyer le logo.'**
  String get storeLogoUploadError;

  /// Merchant UI string storeLogoBindPartial
  ///
  /// In fr, this message translates to:
  /// **'Envoi réussi, mais le logo n’a pas pu être lié. Réessayez.'**
  String get storeLogoBindPartial;

  /// Merchant UI string storeLogoRemoved
  ///
  /// In fr, this message translates to:
  /// **'Logo supprimé.'**
  String get storeLogoRemoved;

  /// Merchant UI string storeLogoRemoveError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le logo. Réessayez.'**
  String get storeLogoRemoveError;

  /// Merchant UI string storeLogoRemoteUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du logo non disponible actuellement.'**
  String get storeLogoRemoteUnavailable;

  /// Merchant UI string storeMediaPartialSaved
  ///
  /// In fr, this message translates to:
  /// **'Le logo est enregistré, mais la couverture a échoué. Réessayez.'**
  String get storeMediaPartialSaved;

  /// Merchant UI string storeCoverHint
  ///
  /// In fr, this message translates to:
  /// **'JPEG ou PNG, max. 2 Mo.'**
  String get storeCoverHint;

  /// Merchant UI string storeCoverUploadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’envoyer la couverture.'**
  String get storeCoverUploadError;

  /// Merchant UI string storeCoverBindPartial
  ///
  /// In fr, this message translates to:
  /// **'Envoi réussi, mais la couverture n’a pas pu être liée. Réessayez.'**
  String get storeCoverBindPartial;

  /// Merchant UI string storeCoverRemoteUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la couverture non disponible actuellement.'**
  String get storeCoverRemoteUnavailable;

  /// Merchant UI string storeCustomerPreviewTitle
  ///
  /// In fr, this message translates to:
  /// **'Aperçu client'**
  String get storeCustomerPreviewTitle;

  /// Merchant UI string storeCustomerPreviewHint
  ///
  /// In fr, this message translates to:
  /// **'Notes et délai estimé non disponibles actuellement.'**
  String get storeCustomerPreviewHint;

  /// Merchant UI string storeAddressTitle
  ///
  /// In fr, this message translates to:
  /// **'Contact et Adresse du magasin'**
  String get storeAddressTitle;

  /// Merchant UI string storeAddressSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get storeAddressSave;

  /// Merchant UI string storeAddressConfirmMap
  ///
  /// In fr, this message translates to:
  /// **'Modifier sur la carte'**
  String get storeAddressConfirmMap;

  /// Merchant UI string storeAddressSaveError
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Vérifiez la connexion et réessayez.'**
  String get storeAddressSaveError;

  /// Merchant UI string storeAddressBanner
  ///
  /// In fr, this message translates to:
  /// **'La modification de l’adresse peut affecter vos zones de livraison et les opérations en cours.'**
  String get storeAddressBanner;

  /// Merchant UI string storeAddressCoordsSection
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées'**
  String get storeAddressCoordsSection;

  /// Merchant UI string storeAddressSection
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get storeAddressSection;

  /// Merchant UI string storeAddressPhone
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get storeAddressPhone;

  /// Merchant UI string storeAddressPhoneHint
  ///
  /// In fr, this message translates to:
  /// **'Numéro communiqué aux livreurs pour le retrait.'**
  String get storeAddressPhoneHint;

  /// Merchant UI string storeAddressDetailed
  ///
  /// In fr, this message translates to:
  /// **'Adresse détaillée'**
  String get storeAddressDetailed;

  /// Merchant UI string storeAddressLocationSummary
  ///
  /// In fr, this message translates to:
  /// **'Emplacement confirmé'**
  String get storeAddressLocationSummary;

  /// Merchant UI string storeAddressPublicContact
  ///
  /// In fr, this message translates to:
  /// **'Contact public (Optionnel)'**
  String get storeAddressPublicContact;

  /// Merchant UI string storeAddressWilaya
  ///
  /// In fr, this message translates to:
  /// **'Wilaya'**
  String get storeAddressWilaya;

  /// Merchant UI string storeAddressCommune
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get storeAddressCommune;

  /// Merchant UI string adminLocationChoose
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get adminLocationChoose;

  /// Merchant UI string adminLocationSearchHint
  ///
  /// In fr, this message translates to:
  /// **'Rechercher…'**
  String get adminLocationSearchHint;

  /// Merchant UI string adminLocationEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get adminLocationEmpty;

  /// Merchant UI string adminLocationLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la liste. Réessayez.'**
  String get adminLocationLoadError;

  /// Merchant UI string adminLocationRetry
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get adminLocationRetry;

  /// Merchant UI string adminLocationWilayaRequired
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez d’abord une wilaya.'**
  String get adminLocationWilayaRequired;

  /// Merchant UI string adminLocationPairRequired
  ///
  /// In fr, this message translates to:
  /// **'Wilaya et commune sont obligatoires.'**
  String get adminLocationPairRequired;

  /// Merchant UI string storeAddressPickupHints
  ///
  /// In fr, this message translates to:
  /// **'Instructions de retrait'**
  String get storeAddressPickupHints;

  /// Merchant UI string storeProfileMediaSub
  ///
  /// In fr, this message translates to:
  /// **'Logo et photo de couverture'**
  String get storeProfileMediaSub;

  /// Merchant UI string storeProfileMediaUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get storeProfileMediaUnavailable;

  /// Merchant UI string storeProfilePrepUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get storeProfilePrepUnavailable;

  /// Merchant UI string storeProfilePreviewUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Aperçu client indisponible.'**
  String get storeProfilePreviewUnavailable;

  /// Merchant UI string profileSettingsTitle
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get profileSettingsTitle;

  /// Merchant UI string storeProfileTitle
  ///
  /// In fr, this message translates to:
  /// **'Profil magasin'**
  String get storeProfileTitle;

  /// Merchant UI string storeProfileCustomerPreview
  ///
  /// In fr, this message translates to:
  /// **'Aperçu client'**
  String get storeProfileCustomerPreview;

  /// Merchant UI string storeProfileGeneral
  ///
  /// In fr, this message translates to:
  /// **'Informations générales'**
  String get storeProfileGeneral;

  /// Merchant UI string storeProfileGeneralSub
  ///
  /// In fr, this message translates to:
  /// **'Nom et statut du commerce'**
  String get storeProfileGeneralSub;

  /// Merchant UI string storeGeneralTitle
  ///
  /// In fr, this message translates to:
  /// **'Informations générales'**
  String get storeGeneralTitle;

  /// Merchant UI string storeGeneralBranchName
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’établissement'**
  String get storeGeneralBranchName;

  /// Merchant UI string storeGeneralBranchNameHint
  ///
  /// In fr, this message translates to:
  /// **'Affiché aux clients pour cet établissement.'**
  String get storeGeneralBranchNameHint;

  /// Merchant UI string storeGeneralMerchantName
  ///
  /// In fr, this message translates to:
  /// **'Nom du commerce'**
  String get storeGeneralMerchantName;

  /// Merchant UI string storeGeneralMerchantLocked
  ///
  /// In fr, this message translates to:
  /// **'Nom vérifié par SpeedyGo : non modifiable ici.'**
  String get storeGeneralMerchantLocked;

  /// Merchant UI string storeGeneralReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Seuls le propriétaire et le gérant peuvent modifier ces informations.'**
  String get storeGeneralReadOnly;

  /// Merchant UI string storeGeneralPhoneElsewhere
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone se modifie dans « Adresse et Emplacement ».'**
  String get storeGeneralPhoneElsewhere;

  /// Merchant UI string storeGeneralSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get storeGeneralSave;

  /// Merchant UI string storeGeneralSaved
  ///
  /// In fr, this message translates to:
  /// **'Informations de l’établissement enregistrées.'**
  String get storeGeneralSaved;

  /// Merchant UI string storeGeneralNameAr
  ///
  /// In fr, this message translates to:
  /// **'Nom en arabe'**
  String get storeGeneralNameAr;

  /// Merchant UI string storeGeneralNameArHint
  ///
  /// In fr, this message translates to:
  /// **'Optionnel. Affiché aux clients arabophones.'**
  String get storeGeneralNameArHint;

  /// Merchant UI string storeGeneralDescription
  ///
  /// In fr, this message translates to:
  /// **'Description courte'**
  String get storeGeneralDescription;

  /// Merchant UI string storeGeneralDescriptionHint
  ///
  /// In fr, this message translates to:
  /// **'Optionnel. Présentez votre établissement en quelques phrases.'**
  String get storeGeneralDescriptionHint;

  /// Merchant UI string storeGeneralPublicEmail
  ///
  /// In fr, this message translates to:
  /// **'E-mail public'**
  String get storeGeneralPublicEmail;

  /// Merchant UI string storeGeneralPublicEmailHint
  ///
  /// In fr, this message translates to:
  /// **'Optionnel. Adresse de contact visible par les clients.'**
  String get storeGeneralPublicEmailHint;

  /// Merchant UI string storeGeneralEmailInvalid
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get storeGeneralEmailInvalid;

  /// Merchant UI string storeGeneralPreviewTitle
  ///
  /// In fr, this message translates to:
  /// **'Aperçu client'**
  String get storeGeneralPreviewTitle;

  /// Merchant UI string storeGeneralPreviewOpen
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get storeGeneralPreviewOpen;

  /// Merchant UI string storeGeneralPreviewClosed
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get storeGeneralPreviewClosed;

  /// Merchant UI string storeProfileCategory
  ///
  /// In fr, this message translates to:
  /// **'Catégorie de l’établissement'**
  String get storeProfileCategory;

  /// Merchant UI string storeProfileCategorySub
  ///
  /// In fr, this message translates to:
  /// **'Type de commerce affiché aux clients'**
  String get storeProfileCategorySub;

  /// Merchant UI string storeCategoryTitle
  ///
  /// In fr, this message translates to:
  /// **'Catégorie de l’établissement'**
  String get storeCategoryTitle;

  /// Merchant UI string storeCategorySubtitle
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la catégorie qui décrit le mieux votre activité.'**
  String get storeCategorySubtitle;

  /// Merchant UI string storeCategorySearch
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une catégorie...'**
  String get storeCategorySearch;

  /// Merchant UI string storeCategoryInfo
  ///
  /// In fr, this message translates to:
  /// **'Une seule catégorie par établissement. Elle détermine où il apparaît dans l’application client.'**
  String get storeCategoryInfo;

  /// Merchant UI string storeCategoryReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Seuls le propriétaire et les gérants peuvent modifier la catégorie.'**
  String get storeCategoryReadOnly;

  /// Merchant UI string storeCategorySave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get storeCategorySave;

  /// Merchant UI string storeCategoryClear
  ///
  /// In fr, this message translates to:
  /// **'Retirer la catégorie'**
  String get storeCategoryClear;

  /// Merchant UI string storeCategorySaved
  ///
  /// In fr, this message translates to:
  /// **'Catégorie enregistrée.'**
  String get storeCategorySaved;

  /// Merchant UI string storeCategoryCleared
  ///
  /// In fr, this message translates to:
  /// **'Catégorie retirée.'**
  String get storeCategoryCleared;

  /// Merchant UI string storeCategoryNotSet
  ///
  /// In fr, this message translates to:
  /// **'Non définie'**
  String get storeCategoryNotSet;

  /// Merchant UI string storeCategoryEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie disponible pour le moment.'**
  String get storeCategoryEmpty;

  /// Merchant UI string storeCategoryNoMatch
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie ne correspond.'**
  String get storeCategoryNoMatch;

  /// Merchant UI string storeCategoryLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les catégories.'**
  String get storeCategoryLoadError;

  /// Merchant UI string storeCategorySaveError
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Réessayez.'**
  String get storeCategorySaveError;

  /// Merchant UI string storeCategoryForbidden
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle ne permet pas de modifier cet établissement.'**
  String get storeCategoryForbidden;

  /// Merchant UI string storeCategoryRestricted
  ///
  /// In fr, this message translates to:
  /// **'Le statut du commerce ne permet pas cette modification.'**
  String get storeCategoryRestricted;

  /// Merchant UI string storeGeneralNameRequired
  ///
  /// In fr, this message translates to:
  /// **'Le nom ne peut pas être vide.'**
  String get storeGeneralNameRequired;

  /// Merchant UI string storeGeneralSaveError
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible. Réessayez.'**
  String get storeGeneralSaveError;

  /// Merchant UI string storeGeneralForbidden
  ///
  /// In fr, this message translates to:
  /// **'Votre rôle ne permet pas de modifier cet établissement.'**
  String get storeGeneralForbidden;

  /// Merchant UI string storeGeneralRestricted
  ///
  /// In fr, this message translates to:
  /// **'Le statut du commerce ne permet pas cette modification.'**
  String get storeGeneralRestricted;

  /// Merchant UI string storeProfileMedia
  ///
  /// In fr, this message translates to:
  /// **'Médias et Logos'**
  String get storeProfileMedia;

  /// Merchant UI string storeProfileAddress
  ///
  /// In fr, this message translates to:
  /// **'Adresse et Emplacement'**
  String get storeProfileAddress;

  /// Merchant UI string storeProfileAddressSub
  ///
  /// In fr, this message translates to:
  /// **'Téléphone, adresse et position GPS'**
  String get storeProfileAddressSub;

  /// Merchant UI string storeProfileHours
  ///
  /// In fr, this message translates to:
  /// **'Horaires d’ouverture'**
  String get storeProfileHours;

  /// Merchant UI string storeProfileHoursSub
  ///
  /// In fr, this message translates to:
  /// **'Jours d’ouverture, pauses'**
  String get storeProfileHoursSub;

  /// Merchant UI string storeProfilePrep
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de préparation'**
  String get storeProfilePrep;

  /// Merchant UI string storeProfileSettings
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get storeProfileSettings;

  /// Merchant UI string storeProfileSettingsSub
  ///
  /// In fr, this message translates to:
  /// **'Compte, préférences, déconnexion'**
  String get storeProfileSettingsSub;

  /// Merchant UI string storeProfileNotifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get storeProfileNotifications;

  /// Merchant UI string storeProfileNotificationsSub
  ///
  /// In fr, this message translates to:
  /// **'Centre d’alertes'**
  String get storeProfileNotificationsSub;

  /// Merchant UI string openingHoursTitle
  ///
  /// In fr, this message translates to:
  /// **'Horaires d’ouverture'**
  String get openingHoursTitle;

  /// Merchant UI string openingHoursEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucun horaire configuré pour cet établissement.'**
  String get openingHoursEmpty;

  /// Merchant UI string openingHoursSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les horaires'**
  String get openingHoursSave;

  /// Merchant UI string openingHoursSaved
  ///
  /// In fr, this message translates to:
  /// **'Horaires enregistrés.'**
  String get openingHoursSaved;

  /// Merchant UI string openingHoursLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les horaires.'**
  String get openingHoursLoadError;

  /// Merchant UI string openingHoursSaveError
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer les horaires.'**
  String get openingHoursSaveError;

  /// Merchant UI string openingHoursInvalid
  ///
  /// In fr, this message translates to:
  /// **'Horaires refusés : vérifiez les chevauchements, y compris après minuit.'**
  String get openingHoursInvalid;

  /// Merchant UI string openingHoursConflict
  ///
  /// In fr, this message translates to:
  /// **'Les horaires ont changé ailleurs. Rechargement effectué — vérifiez puis réessayez.'**
  String get openingHoursConflict;

  /// Merchant UI string openingHoursClosed
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get openingHoursClosed;

  /// Merchant UI string openingHoursUsual
  ///
  /// In fr, this message translates to:
  /// **'Horaires habituels'**
  String get openingHoursUsual;

  /// Merchant UI string openingHoursNotConfigured
  ///
  /// In fr, this message translates to:
  /// **'Aucun horaire configuré'**
  String get openingHoursNotConfigured;

  /// Merchant UI string openingHoursOpenNow
  ///
  /// In fr, this message translates to:
  /// **'Ouvert actuellement'**
  String get openingHoursOpenNow;

  /// Merchant UI string openingHoursClosedNow
  ///
  /// In fr, this message translates to:
  /// **'Fermé actuellement'**
  String get openingHoursClosedNow;

  /// Merchant UI string openingHoursInfo
  ///
  /// In fr, this message translates to:
  /// **'Les clients peuvent commander uniquement pendant vos heures d’ouverture. Les modifications sont appliquées dès l’enregistrement.'**
  String get openingHoursInfo;

  /// Merchant UI string openingHoursStaffReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule : seuls le propriétaire et les gérants peuvent modifier les horaires.'**
  String get openingHoursStaffReadOnly;

  /// Merchant UI string openingHoursOpens
  ///
  /// In fr, this message translates to:
  /// **'Ouverture'**
  String get openingHoursOpens;

  /// Merchant UI string openingHoursCloses
  ///
  /// In fr, this message translates to:
  /// **'Fermeture'**
  String get openingHoursCloses;

  /// Merchant UI string openingHoursEditorHint
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à 3 plages par jour. Une fermeture avant l’ouverture se termine le lendemain.'**
  String get openingHoursEditorHint;

  /// Merchant UI string openingHoursAddRange
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une plage'**
  String get openingHoursAddRange;

  /// Merchant UI string openingHoursRemoveRange
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la plage'**
  String get openingHoursRemoveRange;

  /// Merchant UI string openingHoursApply
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get openingHoursApply;

  /// Merchant UI string openingHoursNextDay
  ///
  /// In fr, this message translates to:
  /// **'Se termine le lendemain'**
  String get openingHoursNextDay;

  /// Merchant UI string openingHoursAllDay
  ///
  /// In fr, this message translates to:
  /// **'Ouvert 24 h/24'**
  String get openingHoursAllDay;

  /// Merchant UI string openingHoursDayClosedHint
  ///
  /// In fr, this message translates to:
  /// **'Aucune plage : le jour sera fermé.'**
  String get openingHoursDayClosedHint;

  /// Merchant UI string openingHoursIssueOverlap
  ///
  /// In fr, this message translates to:
  /// **'Les plages se chevauchent.'**
  String get openingHoursIssueOverlap;

  /// Merchant UI string openingHoursIssueZero
  ///
  /// In fr, this message translates to:
  /// **'L’ouverture et la fermeture doivent être différentes (00:00–00:00 pour 24 h).'**
  String get openingHoursIssueZero;

  /// Merchant UI string openingHoursIssueTooMany
  ///
  /// In fr, this message translates to:
  /// **'Maximum 3 plages par jour.'**
  String get openingHoursIssueTooMany;

  /// Merchant UI string hoursExceptionsTitle
  ///
  /// In fr, this message translates to:
  /// **'Horaires exceptionnels'**
  String get hoursExceptionsTitle;

  /// Merchant UI string hoursExceptionsNavSub
  ///
  /// In fr, this message translates to:
  /// **'Jours fériés, fermetures ponctuelles'**
  String get hoursExceptionsNavSub;

  /// Merchant UI string hoursExceptionsBanner
  ///
  /// In fr, this message translates to:
  /// **'Ces horaires remplacent vos horaires habituels uniquement pour les dates sélectionnées.'**
  String get hoursExceptionsBanner;

  /// Merchant UI string hoursExceptionsUpcoming
  ///
  /// In fr, this message translates to:
  /// **'Exceptions à venir'**
  String get hoursExceptionsUpcoming;

  /// Merchant UI string hoursExceptionsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune exception à venir.'**
  String get hoursExceptionsEmpty;

  /// Merchant UI string hoursExceptionsAdd
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une exception'**
  String get hoursExceptionsAdd;

  /// Merchant UI string hoursExceptionsEdit
  ///
  /// In fr, this message translates to:
  /// **'Modifier l’exception'**
  String get hoursExceptionsEdit;

  /// Merchant UI string hoursExceptionsDate
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get hoursExceptionsDate;

  /// Merchant UI string hoursExceptionsDateHint
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une date'**
  String get hoursExceptionsDateHint;

  /// Merchant UI string hoursExceptionsDateTaken
  ///
  /// In fr, this message translates to:
  /// **'Cette date a déjà une exception : l’enregistrement la remplacera.'**
  String get hoursExceptionsDateTaken;

  /// Merchant UI string hoursExceptionsStatus
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get hoursExceptionsStatus;

  /// Merchant UI string hoursExceptionsOpen
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get hoursExceptionsOpen;

  /// Merchant UI string hoursExceptionsClosed
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get hoursExceptionsClosed;

  /// Merchant UI string hoursExceptionsHours
  ///
  /// In fr, this message translates to:
  /// **'Horaires modifiés'**
  String get hoursExceptionsHours;

  /// Merchant UI string hoursExceptionsTo
  ///
  /// In fr, this message translates to:
  /// **'à'**
  String get hoursExceptionsTo;

  /// Merchant UI string hoursExceptionsLabel
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get hoursExceptionsLabel;

  /// Merchant UI string hoursExceptionsLabelHint
  ///
  /// In fr, this message translates to:
  /// **'ex : Jour férié, Travaux…'**
  String get hoursExceptionsLabelHint;

  /// Merchant UI string hoursExceptionsMessage
  ///
  /// In fr, this message translates to:
  /// **'Message pour les clients (Optionnel)'**
  String get hoursExceptionsMessage;

  /// Merchant UI string hoursExceptionsMessageHint
  ///
  /// In fr, this message translates to:
  /// **'Enregistré avec l’exception. Pas encore affiché dans l’application client.'**
  String get hoursExceptionsMessageHint;

  /// Merchant UI string hoursExceptionsCancel
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get hoursExceptionsCancel;

  /// Merchant UI string hoursExceptionsSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les horaires'**
  String get hoursExceptionsSave;

  /// Merchant UI string hoursExceptionsSaved
  ///
  /// In fr, this message translates to:
  /// **'Exception enregistrée.'**
  String get hoursExceptionsSaved;

  /// Merchant UI string hoursExceptionsDeleted
  ///
  /// In fr, this message translates to:
  /// **'Exception supprimée.'**
  String get hoursExceptionsDeleted;

  /// Merchant UI string hoursExceptionsDeleteTitle
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’exception ?'**
  String get hoursExceptionsDeleteTitle;

  /// Merchant UI string hoursExceptionsDeleteBody
  ///
  /// In fr, this message translates to:
  /// **'Le {date} reprendra vos horaires habituels.'**
  String hoursExceptionsDeleteBody(String date);

  /// Merchant UI string hoursExceptionsDeleteConfirm
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get hoursExceptionsDeleteConfirm;

  /// Merchant UI string hoursExceptionsLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les horaires exceptionnels.'**
  String get hoursExceptionsLoadError;

  /// Merchant UI string hoursExceptionsSaveError
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer l’exception. Vos saisies sont conservées.'**
  String get hoursExceptionsSaveError;

  /// Merchant UI string hoursExceptionsDeleteError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer l’exception. Réessayez.'**
  String get hoursExceptionsDeleteError;

  /// Merchant UI string hoursExceptionsConflict
  ///
  /// In fr, this message translates to:
  /// **'Cette date a été modifiée ailleurs. La liste a été rechargée : vérifiez puis enregistrez à nouveau.'**
  String get hoursExceptionsConflict;

  /// Merchant UI string hoursExceptionsInvalid
  ///
  /// In fr, this message translates to:
  /// **'Exception refusée : vérifiez la date (aujourd’hui à +365 jours) et les plages.'**
  String get hoursExceptionsInvalid;

  /// Merchant UI string hoursExceptionsWeeklyRequired
  ///
  /// In fr, this message translates to:
  /// **'Configurez d’abord les horaires habituels.'**
  String get hoursExceptionsWeeklyRequired;

  /// Merchant UI string hoursExceptionsTooMany
  ///
  /// In fr, this message translates to:
  /// **'Trop d’exceptions à venir (100 maximum).'**
  String get hoursExceptionsTooMany;

  /// Merchant UI string hoursExceptionsStaffReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule : seuls le propriétaire et les gérants peuvent modifier les horaires exceptionnels.'**
  String get hoursExceptionsStaffReadOnly;

  /// Merchant UI string hoursExceptionsDateRequired
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une date.'**
  String get hoursExceptionsDateRequired;

  /// Merchant UI string hoursExceptionsLabelRequired
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un motif.'**
  String get hoursExceptionsLabelRequired;

  /// Merchant UI string hoursExceptionsIntervalsRequired
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez au moins une plage horaire.'**
  String get hoursExceptionsIntervalsRequired;

  /// Merchant UI string hoursExceptionsSameDay
  ///
  /// In fr, this message translates to:
  /// **'Chaque plage doit finir le même jour (00:00 = minuit).'**
  String get hoursExceptionsSameDay;

  /// Merchant UI string hoursExceptionsHelpTitle
  ///
  /// In fr, this message translates to:
  /// **'Ordre d’application'**
  String get hoursExceptionsHelpTitle;

  /// Merchant UI string hoursExceptionsHelpBody
  ///
  /// In fr, this message translates to:
  /// **'Une fermeture forcée ou temporaire de l’établissement s’applique toujours en premier. Sinon, une exception remplace les horaires habituels pour sa date (heure d’Alger). Les autres jours suivent les horaires habituels.'**
  String get hoursExceptionsHelpBody;

  /// Merchant UI string hoursExceptionsHelpOk
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get hoursExceptionsHelpOk;

  /// Merchant UI string hoursExceptionsToday
  ///
  /// In fr, this message translates to:
  /// **'Exception aujourd’hui : {label}'**
  String hoursExceptionsToday(String label);

  /// Merchant UI string availabilityTitle
  ///
  /// In fr, this message translates to:
  /// **'État du magasin'**
  String get availabilityTitle;

  /// Merchant UI string availabilityEstablishment
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get availabilityEstablishment;

  /// Merchant UI string availabilityOpen
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get availabilityOpen;

  /// Merchant UI string availabilityClosed
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get availabilityClosed;

  /// Merchant UI string availabilityFollowSchedule
  ///
  /// In fr, this message translates to:
  /// **'Selon les horaires'**
  String get availabilityFollowSchedule;

  /// Merchant UI string availabilityForceClosed
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get availabilityForceClosed;

  /// Merchant UI string availabilitySave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get availabilitySave;

  /// Merchant UI string availabilitySaving
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get availabilitySaving;

  /// Merchant UI string availabilitySaved
  ///
  /// In fr, this message translates to:
  /// **'État du magasin enregistré.'**
  String get availabilitySaved;

  /// Merchant UI string availabilityClosureSaved
  ///
  /// In fr, this message translates to:
  /// **'Fermeture enregistrée.'**
  String get availabilityClosureSaved;

  /// Merchant UI string availabilityLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l’état du magasin.'**
  String get availabilityLoadError;

  /// Merchant UI string availabilitySaveError
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’enregistrer l’état du magasin.'**
  String get availabilitySaveError;

  /// Merchant UI string availabilityConflict
  ///
  /// In fr, this message translates to:
  /// **'L’état a changé ailleurs. Rechargement effectué — vérifiez puis réessayez.'**
  String get availabilityConflict;

  /// Merchant UI string availabilityReopenTitle
  ///
  /// In fr, this message translates to:
  /// **'Rouvrir selon les horaires'**
  String get availabilityReopenTitle;

  /// Merchant UI string availabilityReopenOutsideHoursBody
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes hors des horaires hebdomadaires. Le magasin restera Fermé jusqu’à la prochaine ouverture prévue.'**
  String get availabilityReopenOutsideHoursBody;

  /// Merchant UI string availabilityConfirmReopen
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get availabilityConfirmReopen;

  /// Merchant UI string availabilityToday
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get availabilityToday;

  /// Merchant UI string availabilityClosedToday
  ///
  /// In fr, this message translates to:
  /// **'Fermé aujourd’hui'**
  String get availabilityClosedToday;

  /// Merchant UI string availabilityModifyHours
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get availabilityModifyHours;

  /// Merchant UI string availabilityQuickPause
  ///
  /// In fr, this message translates to:
  /// **'Pause rapide'**
  String get availabilityQuickPause;

  /// Merchant UI string availabilityQuickPauseHint
  ///
  /// In fr, this message translates to:
  /// **'Fermer temporairement pour un rush en cuisine.'**
  String get availabilityQuickPauseHint;

  /// Merchant UI string availabilityPause30
  ///
  /// In fr, this message translates to:
  /// **'30 MIN'**
  String get availabilityPause30;

  /// Merchant UI string availabilityPause60
  ///
  /// In fr, this message translates to:
  /// **'1 HEURE'**
  String get availabilityPause60;

  /// Merchant UI string availabilityActiveOrdersUnknown
  ///
  /// In fr, this message translates to:
  /// **'Commandes en cours'**
  String get availabilityActiveOrdersUnknown;

  /// Merchant UI string availabilityCloseWarningTitle
  ///
  /// In fr, this message translates to:
  /// **'Attention : fermeture immédiate'**
  String get availabilityCloseWarningTitle;

  /// Merchant UI string availabilityStaffReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Lecture seule : seuls le propriétaire et les gérants peuvent modifier l’état du magasin.'**
  String get availabilityStaffReadOnly;

  /// Merchant UI string availabilityBannerOpenTitle
  ///
  /// In fr, this message translates to:
  /// **'Magasin en ligne'**
  String get availabilityBannerOpenTitle;

  /// Merchant UI string availabilityBannerOpenBody
  ///
  /// In fr, this message translates to:
  /// **'Les clients peuvent passer commande et voir votre menu normalement.'**
  String get availabilityBannerOpenBody;

  /// Merchant UI string availabilityBannerClosedTitle
  ///
  /// In fr, this message translates to:
  /// **'Magasin hors ligne'**
  String get availabilityBannerClosedTitle;

  /// Merchant UI string availabilityBannerClosedBody
  ///
  /// In fr, this message translates to:
  /// **'Les clients ne peuvent plus passer de nouvelles commandes.'**
  String get availabilityBannerClosedBody;

  /// Merchant UI string availabilityBannerScheduleClosedTitle
  ///
  /// In fr, this message translates to:
  /// **'Selon les horaires — actuellement fermé'**
  String get availabilityBannerScheduleClosedTitle;

  /// Merchant UI string availabilityBannerScheduleClosedBody
  ///
  /// In fr, this message translates to:
  /// **'Le magasin suit le planning. Il s’ouvrira automatiquement aux prochaines heures.'**
  String get availabilityBannerScheduleClosedBody;

  /// Merchant UI string availabilityReasonPeak
  ///
  /// In fr, this message translates to:
  /// **'Forte charge (cuisine)'**
  String get availabilityReasonPeak;

  /// Merchant UI string availabilityReasonTechnical
  ///
  /// In fr, this message translates to:
  /// **'Problème technique'**
  String get availabilityReasonTechnical;

  /// Merchant UI string availabilityReasonStock
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get availabilityReasonStock;

  /// Merchant UI string availabilityReasonLunch
  ///
  /// In fr, this message translates to:
  /// **'Pause déjeuner'**
  String get availabilityReasonLunch;

  /// Merchant UI string temporaryClosureTitle
  ///
  /// In fr, this message translates to:
  /// **'Fermeture temporaire'**
  String get temporaryClosureTitle;

  /// Merchant UI string temporaryClosureActionRequired
  ///
  /// In fr, this message translates to:
  /// **'Action requise'**
  String get temporaryClosureActionRequired;

  /// Merchant UI string temporaryClosureImpactLead
  ///
  /// In fr, this message translates to:
  /// **'La fermeture suspendra l’acceptation de nouvelles commandes. '**
  String get temporaryClosureImpactLead;

  /// Merchant UI string temporaryClosureImpactNone
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande en cours.'**
  String get temporaryClosureImpactNone;

  /// Merchant UI string temporaryClosureImpactUnknown
  ///
  /// In fr, this message translates to:
  /// **'Les commandes en cours seront maintenues et doivent être préparées.'**
  String get temporaryClosureImpactUnknown;

  /// Merchant UI string temporaryClosureReason
  ///
  /// In fr, this message translates to:
  /// **'Motif de la fermeture'**
  String get temporaryClosureReason;

  /// Merchant UI string temporaryClosureReopen
  ///
  /// In fr, this message translates to:
  /// **'Réouverture prévue'**
  String get temporaryClosureReopen;

  /// Merchant UI string temporaryClosure30m
  ///
  /// In fr, this message translates to:
  /// **'Dans 30 minutes'**
  String get temporaryClosure30m;

  /// Merchant UI string temporaryClosure1h
  ///
  /// In fr, this message translates to:
  /// **'Dans 1 heure'**
  String get temporaryClosure1h;

  /// Merchant UI string temporaryClosurePickTime
  ///
  /// In fr, this message translates to:
  /// **'Choisir une heure…'**
  String get temporaryClosurePickTime;

  /// Merchant UI string temporaryClosureIndefinite
  ///
  /// In fr, this message translates to:
  /// **'Indéfinie (Manuel)'**
  String get temporaryClosureIndefinite;

  /// Merchant UI string temporaryClosureImageImpact
  ///
  /// In fr, this message translates to:
  /// **'Impact sur votre visibilité : Les clients verront votre établissement comme « Fermé temporairement ».'**
  String get temporaryClosureImageImpact;

  /// Merchant UI string temporaryClosureStaffReadOnly
  ///
  /// In fr, this message translates to:
  /// **'Seuls le propriétaire et les gérants peuvent fermer le magasin.'**
  String get temporaryClosureStaffReadOnly;

  /// Merchant UI string temporaryClosurePastTime
  ///
  /// In fr, this message translates to:
  /// **'L’heure de réouverture est déjà passée. Choisissez une nouvelle heure.'**
  String get temporaryClosurePastTime;

  /// Merchant UI string temporaryClosureMessage
  ///
  /// In fr, this message translates to:
  /// **'Message client'**
  String get temporaryClosureMessage;

  /// Merchant UI string temporaryClosureOptional
  ///
  /// In fr, this message translates to:
  /// **'Facultatif'**
  String get temporaryClosureOptional;

  /// Merchant UI string temporaryClosureMessageHint
  ///
  /// In fr, this message translates to:
  /// **'Ex: Nous sommes complets pour le moment, revenez dans 30 minutes !'**
  String get temporaryClosureMessageHint;

  /// Merchant UI string temporaryClosureManualReopenHint
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez rouvrir manuellement à tout moment.'**
  String get temporaryClosureManualReopenHint;

  /// Merchant UI string temporaryClosureConfirm
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la fermeture'**
  String get temporaryClosureConfirm;

  /// Merchant UI string storeProfileAvailability
  ///
  /// In fr, this message translates to:
  /// **'État du magasin'**
  String get storeProfileAvailability;

  /// Merchant UI string storeProfileAvailabilitySub
  ///
  /// In fr, this message translates to:
  /// **'Selon les horaires, fermeture, pause'**
  String get storeProfileAvailabilitySub;

  /// Merchant UI string notificationsTitle
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Merchant UI string notificationsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour le moment.'**
  String get notificationsEmpty;

  /// Merchant UI string notificationsLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les notifications.'**
  String get notificationsLoadError;

  /// Merchant UI string notificationsToday
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get notificationsToday;

  /// Merchant UI string notificationsYesterday
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get notificationsYesterday;

  /// Merchant UI string notificationsJustNow
  ///
  /// In fr, this message translates to:
  /// **'À l’instant'**
  String get notificationsJustNow;

  /// Merchant UI string notificationsMarkAllRead
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get notificationsMarkAllRead;

  /// Merchant UI string notificationsFilterAll
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get notificationsFilterAll;

  /// Merchant UI string notificationsFilterOrders
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get notificationsFilterOrders;

  /// Merchant UI string notificationsOpenDetails
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get notificationsOpenDetails;

  /// Merchant UI string notificationsOrderStale
  ///
  /// In fr, this message translates to:
  /// **'Cette commande n’est plus en attente d’acceptation.'**
  String get notificationsOrderStale;

  /// Merchant UI string alertNewOrder
  ///
  /// In fr, this message translates to:
  /// **'NOUVELLE COMMANDE'**
  String get alertNewOrder;

  /// Merchant UI string alertReceivedAt
  ///
  /// In fr, this message translates to:
  /// **'Reçue à'**
  String get alertReceivedAt;

  /// Merchant UI string alertPayment
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get alertPayment;

  /// Merchant UI string alertViewDetails
  ///
  /// In fr, this message translates to:
  /// **'Voir les détails'**
  String get alertViewDetails;

  /// Merchant UI string alertRefuse
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get alertRefuse;

  /// Merchant UI string alertItems
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get alertItems;

  /// Merchant UI string alertOrderTotal
  ///
  /// In fr, this message translates to:
  /// **'Sous-total marchandises'**
  String get alertOrderTotal;

  /// Merchant UI string alertOrderLabel
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get alertOrderLabel;

  /// Merchant UI string alertDismiss
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get alertDismiss;

  /// Merchant UI string alertSeeList
  ///
  /// In fr, this message translates to:
  /// **'Voir la liste'**
  String get alertSeeList;

  /// Merchant UI string notifSettingsTitle
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de notification'**
  String get notifSettingsTitle;

  /// Merchant UI string notifSettingsScreenTitle
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get notifSettingsScreenTitle;

  /// Merchant UI string notifSettingsOsEnabled
  ///
  /// In fr, this message translates to:
  /// **'Permission iOS autorisée. Le Push natif n’est pas encore actif.'**
  String get notifSettingsOsEnabled;

  /// Merchant UI string notifSettingsOsDenied
  ///
  /// In fr, this message translates to:
  /// **'Permission iOS refusée (modifiable dans Réglages). Le Push natif n’est pas encore actif.'**
  String get notifSettingsOsDenied;

  /// Merchant UI string notifSettingsOsNotAsked
  ///
  /// In fr, this message translates to:
  /// **'Permission de notification : pas encore autorisée.'**
  String get notifSettingsOsNotAsked;

  /// Merchant UI string notifSettingsOsOpen
  ///
  /// In fr, this message translates to:
  /// **'Paramètres système'**
  String get notifSettingsOsOpen;

  /// Merchant UI string notifSettingsSwitchesNote
  ///
  /// In fr, this message translates to:
  /// **'Uniquement quand l’application est ouverte.'**
  String get notifSettingsSwitchesNote;

  /// Merchant UI string notifSettingsInAppSection
  ///
  /// In fr, this message translates to:
  /// **'DANS L’APPLICATION'**
  String get notifSettingsInAppSection;

  /// Merchant UI string notifSettingsCriticalWarning
  ///
  /// In fr, this message translates to:
  /// **'Les commandes entrantes critiques ne peuvent pas être totalement réduites au silence sans risque de retard.'**
  String get notifSettingsCriticalWarning;

  /// Merchant UI string notifSettingsPushNotConfigured
  ///
  /// In fr, this message translates to:
  /// **'Non configuré'**
  String get notifSettingsPushNotConfigured;

  /// Merchant UI string notifSettingsSoundSection
  ///
  /// In fr, this message translates to:
  /// **'ALERTES SONORES'**
  String get notifSettingsSoundSection;

  /// Merchant UI string notifSettingsSound
  ///
  /// In fr, this message translates to:
  /// **'Sonnerie des nouvelles commandes'**
  String get notifSettingsSound;

  /// Merchant UI string notifSettingsVibrationSection
  ///
  /// In fr, this message translates to:
  /// **'VIBRATIONS'**
  String get notifSettingsVibrationSection;

  /// Merchant UI string notifSettingsVibration
  ///
  /// In fr, this message translates to:
  /// **'Vibration lors d’une commande'**
  String get notifSettingsVibration;

  /// Merchant UI string notifSettingsPushSection
  ///
  /// In fr, this message translates to:
  /// **'ALERTES PUSH'**
  String get notifSettingsPushSection;

  /// Merchant UI string notifSettingsOsEnabledPush
  ///
  /// In fr, this message translates to:
  /// **'Permission de notification : autorisée.'**
  String get notifSettingsOsEnabledPush;

  /// Merchant UI string notifSettingsOsDeniedPush
  ///
  /// In fr, this message translates to:
  /// **'Permission de notification refusée : activez-la dans les réglages système.'**
  String get notifSettingsOsDeniedPush;

  /// Merchant UI string notifSettingsNativePush
  ///
  /// In fr, this message translates to:
  /// **'Notifications hors application'**
  String get notifSettingsNativePush;

  /// Merchant UI string notifSettingsNativePushSub
  ///
  /// In fr, this message translates to:
  /// **'Application fermée ou en arrière-plan.'**
  String get notifSettingsNativePushSub;

  /// Merchant UI string notifSettingsLockScreenNote
  ///
  /// In fr, this message translates to:
  /// **'Aperçu sur l’écran verrouillé : selon les réglages système.'**
  String get notifSettingsLockScreenNote;

  /// Merchant UI string notifPushStatusRegistered
  ///
  /// In fr, this message translates to:
  /// **'Cet appareil est enregistré pour les notifications.'**
  String get notifPushStatusRegistered;

  /// Merchant UI string notifPushStatusPending
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement de l’appareil…'**
  String get notifPushStatusPending;

  /// Merchant UI string notifPushStatusDenied
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée : pas de notification hors application.'**
  String get notifPushStatusDenied;

  /// Merchant UI string notifPushStatusDisabled
  ///
  /// In fr, this message translates to:
  /// **'Désactivées sur cet appareil.'**
  String get notifPushStatusDisabled;

  /// Merchant UI string notifPushStatusTokenUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Jeton de notification indisponible sur cet appareil.'**
  String get notifPushStatusTokenUnavailable;

  /// Merchant UI string notifPushStatusFailed
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement impossible pour le moment. Réessayez plus tard.'**
  String get notifPushStatusFailed;

  /// Merchant UI string pushOrderInaccessible
  ///
  /// In fr, this message translates to:
  /// **'Cette commande n’est pas accessible avec ce compte.'**
  String get pushOrderInaccessible;

  /// Merchant UI string notifSettingsForeground
  ///
  /// In fr, this message translates to:
  /// **'Alertes dans l’application'**
  String get notifSettingsForeground;

  /// Merchant UI string notifSettingsPushUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Les notifications hors application ne sont pas encore disponibles.'**
  String get notifSettingsPushUnavailable;

  /// Merchant UI string notifSettingsPushBlocked
  ///
  /// In fr, this message translates to:
  /// **'Push natif (APNs/FCM) non configuré : la permission iOS ne suffit pas.'**
  String get notifSettingsPushBlocked;

  /// Merchant UI string notifSettingsSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les paramètres'**
  String get notifSettingsSave;

  /// Merchant UI string notifSettingsSaved
  ///
  /// In fr, this message translates to:
  /// **'Paramètres enregistrés.'**
  String get notifSettingsSaved;

  /// Merchant UI string profileRole
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get profileRole;

  /// Merchant UI string profileMerchant
  ///
  /// In fr, this message translates to:
  /// **'Commerce'**
  String get profileMerchant;

  /// Merchant UI string profileBranch
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get profileBranch;

  /// Merchant UI string profileRoleOwner
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get profileRoleOwner;

  /// Merchant UI string profileRoleManager
  ///
  /// In fr, this message translates to:
  /// **'Responsable'**
  String get profileRoleManager;

  /// Merchant UI string profileRoleStaff
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get profileRoleStaff;

  /// Merchant UI string profileSectionAccount
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileSectionAccount;

  /// Merchant UI string profileSectionStore
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get profileSectionStore;

  /// Merchant UI string profileSectionOps
  ///
  /// In fr, this message translates to:
  /// **'Opérations du magasin'**
  String get profileSectionOps;

  /// Merchant UI string profileSectionPrefs
  ///
  /// In fr, this message translates to:
  /// **'Préférences'**
  String get profileSectionPrefs;

  /// Merchant UI string profileSectionSupport
  ///
  /// In fr, this message translates to:
  /// **'Support & légal'**
  String get profileSectionSupport;

  /// Merchant UI string profileInfoReadonly
  ///
  /// In fr, this message translates to:
  /// **'Informations du commerce'**
  String get profileInfoReadonly;

  /// Merchant UI string profileBranchStatus
  ///
  /// In fr, this message translates to:
  /// **'Statut opérationnel'**
  String get profileBranchStatus;

  /// Merchant UI string profileUnavailableItem
  ///
  /// In fr, this message translates to:
  /// **'Non disponible dans cette version'**
  String get profileUnavailableItem;

  /// Merchant UI string switchBranch
  ///
  /// In fr, this message translates to:
  /// **'Changer d’établissement'**
  String get switchBranch;

  /// Merchant UI string logoutConfirmTitle
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logoutConfirmTitle;

  /// Merchant UI string logoutConfirmBody
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment vous déconnecter de SpeedyGo Merchant ?'**
  String get logoutConfirmBody;

  /// Merchant UI string logoutConfirmAction
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logoutConfirmAction;

  /// Merchant UI string settingsProfileRow
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get settingsProfileRow;

  /// Merchant UI string settingsNotificationsOff
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get settingsNotificationsOff;

  /// Merchant UI string settingsSupportSection
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get settingsSupportSection;

  /// Merchant UI string settingsHelpCenter
  ///
  /// In fr, this message translates to:
  /// **'Centre d’aide'**
  String get settingsHelpCenter;

  /// Merchant UI string logoutConnected
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get logoutConnected;

  /// Merchant UI string logoutWarningTitle
  ///
  /// In fr, this message translates to:
  /// **'Attention aux opérations en cours'**
  String get logoutWarningTitle;

  /// Merchant UI string logoutActiveOrders
  ///
  /// In fr, this message translates to:
  /// **'Commandes en cours'**
  String get logoutActiveOrders;

  /// Merchant UI string logoutStoreState
  ///
  /// In fr, this message translates to:
  /// **'État du magasin'**
  String get logoutStoreState;

  /// Merchant UI string logoutStoreOpen
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get logoutStoreOpen;

  /// Merchant UI string logoutStoreClosed
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get logoutStoreClosed;

  /// Merchant UI string logoutHandoverAdvice
  ///
  /// In fr, this message translates to:
  /// **'Assurez-vous qu’un autre gestionnaire est disponible pour traiter les commandes avant de vous déconnecter.'**
  String get logoutHandoverAdvice;

  /// Merchant UI string logoutDataPreserved
  ///
  /// In fr, this message translates to:
  /// **'Vos données, le catalogue et l’historique des commandes seront préservés.'**
  String get logoutDataPreserved;

  /// Merchant UI string logoutCancel
  ///
  /// In fr, this message translates to:
  /// **'Annuler et retourner'**
  String get logoutCancel;

  /// Merchant UI string cancel
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Merchant UI string attentionRequired
  ///
  /// In fr, this message translates to:
  /// **'Certaines pièces nécessitent votre attention.'**
  String get attentionRequired;

  /// Merchant UI string submitVerification
  ///
  /// In fr, this message translates to:
  /// **'Soumettre le dossier'**
  String get submitVerification;

  /// Merchant UI string submitVerificationUnavailable
  ///
  /// In fr, this message translates to:
  /// **'La soumission n’est pas encore possible : des pièces obligatoires manquent ou sont incomplètes.'**
  String get submitVerificationUnavailable;

  /// Merchant UI string permissionDenied
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée par le serveur.'**
  String get permissionDenied;

  /// Merchant UI string regTitle
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get regTitle;

  /// Merchant UI string regStepOf
  ///
  /// In fr, this message translates to:
  /// **'Étape'**
  String get regStepOf;

  /// Merchant UI string regAccountTitle
  ///
  /// In fr, this message translates to:
  /// **'Configuration du compte'**
  String get regAccountTitle;

  /// Merchant UI string regRoleLabel
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get regRoleLabel;

  /// Merchant UI string regOwner
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get regOwner;

  /// Merchant UI string regOperator
  ///
  /// In fr, this message translates to:
  /// **'Opérateur'**
  String get regOperator;

  /// Merchant UI string regOwnerHint
  ///
  /// In fr, this message translates to:
  /// **'Créez et gérez votre commerce en tant que propriétaire.'**
  String get regOwnerHint;

  /// Merchant UI string regOperatorHint
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre un commerce existant nécessite une invitation et le code remis par le propriétaire.'**
  String get regOperatorHint;

  /// Merchant UI string regOperatorUnsupported
  ///
  /// In fr, this message translates to:
  /// **'Pour rejoindre un commerce, ouvrez vos invitations reçues et saisissez le code remis par le propriétaire. SpeedyGo n’envoie pas de SMS.'**
  String get regOperatorUnsupported;

  /// Merchant UI string regOperatorOpenInvitations
  ///
  /// In fr, this message translates to:
  /// **'Voir mes invitations'**
  String get regOperatorOpenInvitations;

  /// Merchant UI string regSelectRole
  ///
  /// In fr, this message translates to:
  /// **'Choisissez un rôle pour continuer.'**
  String get regSelectRole;

  /// Merchant UI string regContactTitle
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get regContactTitle;

  /// Merchant UI string regAccountContinue
  ///
  /// In fr, this message translates to:
  /// **'Continuer l’inscription'**
  String get regAccountContinue;

  /// Merchant UI string regVerifiedPhone
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone (vérifié)'**
  String get regVerifiedPhone;

  /// Merchant UI string regVerifiedPhoneHint
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro a été vérifié lors de la connexion. Il n’est pas modifiable ici.'**
  String get regVerifiedPhoneHint;

  /// Merchant UI string regEmailUnsupported
  ///
  /// In fr, this message translates to:
  /// **'L’e-mail ne peut pas être enregistré à cette étape.'**
  String get regEmailUnsupported;

  /// Merchant UI string regConsentUnsupported
  ///
  /// In fr, this message translates to:
  /// **'Consultez les conditions générales et la politique de confidentialité SpeedyGo avant de continuer.'**
  String get regConsentUnsupported;

  /// Merchant UI string regActivityTitle
  ///
  /// In fr, this message translates to:
  /// **'Informations du commerce'**
  String get regActivityTitle;

  /// Merchant UI string regActivityBody
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le nom sous lequel votre commerce sera identifié.'**
  String get regActivityBody;

  /// Merchant UI string regLegalIdUnsupported
  ///
  /// In fr, this message translates to:
  /// **'Les pièces d’identité professionnelle se déposent à l’étape Documents.'**
  String get regLegalIdUnsupported;

  /// Merchant UI string regDocsTitle
  ///
  /// In fr, this message translates to:
  /// **'Documents d’entreprise'**
  String get regDocsTitle;

  /// Merchant UI string regDocsBody
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez les documents demandés.'**
  String get regDocsBody;

  /// Merchant UI string regDocsRequired
  ///
  /// In fr, this message translates to:
  /// **'Téléversez toutes les pièces obligatoires avant de continuer.'**
  String get regDocsRequired;

  /// Merchant UI string regDocsTipsTitle
  ///
  /// In fr, this message translates to:
  /// **'Conseils pour une capture nette'**
  String get regDocsTipsTitle;

  /// Merchant UI string regDocsTipLight
  ///
  /// In fr, this message translates to:
  /// **'Privilégiez un éclairage naturel et uniforme pour éviter les zones d’ombre.'**
  String get regDocsTipLight;

  /// Merchant UI string regDocsTipFrame
  ///
  /// In fr, this message translates to:
  /// **'Cadrez bien le document : tous les coins doivent être visibles.'**
  String get regDocsTipFrame;

  /// Merchant UI string regDocsFormats
  ///
  /// In fr, this message translates to:
  /// **'Formats acceptés : PDF, JPEG ou PNG (10 Mo max).'**
  String get regDocsFormats;

  /// Merchant UI string regDocsContinue
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get regDocsContinue;

  /// Merchant UI string regDocsContinueFinal
  ///
  /// In fr, this message translates to:
  /// **'Continuer vers l’étape finale'**
  String get regDocsContinueFinal;

  /// Merchant UI string regDocsAppBar
  ///
  /// In fr, this message translates to:
  /// **'Vérification'**
  String get regDocsAppBar;

  /// Merchant UI string regDocsTipFlash
  ///
  /// In fr, this message translates to:
  /// **'Désactivez le flash pour éviter les reflets sur les surfaces plastifiées.'**
  String get regDocsTipFlash;

  /// Merchant UI string regDocsPrivacy
  ///
  /// In fr, this message translates to:
  /// **'Vos documents sont transmis à SpeedyGo uniquement pour la vérification de votre commerce.'**
  String get regDocsPrivacy;

  /// Merchant UI string regFileTooLarge
  ///
  /// In fr, this message translates to:
  /// **'Fichier trop volumineux (max. 10 Mo).'**
  String get regFileTooLarge;

  /// Merchant UI string regFileTypeUnsupported
  ///
  /// In fr, this message translates to:
  /// **'Format non accepté. Utilisez PDF, JPEG ou PNG.'**
  String get regFileTypeUnsupported;

  /// Merchant UI string regPickerUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Impossible d’ouvrir le sélecteur de fichiers. Réessayez après avoir relancé l’application.'**
  String get regPickerUnavailable;

  /// Merchant UI string regPickDocument
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get regPickDocument;

  /// Merchant UI string regReplaceDocument
  ///
  /// In fr, this message translates to:
  /// **'Remplacer'**
  String get regReplaceDocument;

  /// Merchant UI string regEstablishmentTitle
  ///
  /// In fr, this message translates to:
  /// **'Détails de l’établissement'**
  String get regEstablishmentTitle;

  /// Merchant UI string regEstablishmentBody
  ///
  /// In fr, this message translates to:
  /// **'Renseignez les informations de votre établissement.'**
  String get regEstablishmentBody;

  /// Merchant UI string regIdentitySection
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’établissement'**
  String get regIdentitySection;

  /// Merchant UI string regBranchNameFrLabel
  ///
  /// In fr, this message translates to:
  /// **'Nom de l’établissement'**
  String get regBranchNameFrLabel;

  /// Merchant UI string regCommerceContext
  ///
  /// In fr, this message translates to:
  /// **'Commerce'**
  String get regCommerceContext;

  /// Merchant UI string regContactSection
  ///
  /// In fr, this message translates to:
  /// **'Contact de l’établissement'**
  String get regContactSection;

  /// Merchant UI string regCategorySection
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get regCategorySection;

  /// Merchant UI string regCategoryReadonly
  ///
  /// In fr, this message translates to:
  /// **'La catégorie sera attribuée après vérification.'**
  String get regCategoryReadonly;

  /// Merchant UI string regAddressSection
  ///
  /// In fr, this message translates to:
  /// **'Adresse et emplacement'**
  String get regAddressSection;

  /// Merchant UI string regAddressGuidance
  ///
  /// In fr, this message translates to:
  /// **'Saisissez l’adresse de votre établissement.'**
  String get regAddressGuidance;

  /// Merchant UI string regAddressExactLabel
  ///
  /// In fr, this message translates to:
  /// **'Adresse exacte'**
  String get regAddressExactLabel;

  /// Merchant UI string regPickupPlace
  ///
  /// In fr, this message translates to:
  /// **'Lieu de retrait'**
  String get regPickupPlace;

  /// Merchant UI string regChooseOnMap
  ///
  /// In fr, this message translates to:
  /// **'Choisir sur la carte'**
  String get regChooseOnMap;

  /// Merchant UI string regLocationConfirmed
  ///
  /// In fr, this message translates to:
  /// **'Position confirmée'**
  String get regLocationConfirmed;

  /// Merchant UI string regLocationEdit
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get regLocationEdit;

  /// Merchant UI string regLocationRequired
  ///
  /// In fr, this message translates to:
  /// **'Confirmez le lieu de retrait sur la carte avant de continuer.'**
  String get regLocationRequired;

  /// Merchant UI string regLocationPickerTitle
  ///
  /// In fr, this message translates to:
  /// **'Position du magasin'**
  String get regLocationPickerTitle;

  /// Merchant UI string regLocationConfirm
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l’emplacement'**
  String get regLocationConfirm;

  /// Merchant UI string regLocationUseGps
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position'**
  String get regLocationUseGps;

  /// Merchant UI string regLocationMoveHint
  ///
  /// In fr, this message translates to:
  /// **'Déplacez la carte pour placer le pin sur le lieu de retrait, ou utilisez votre position GPS.'**
  String get regLocationMoveHint;

  /// Merchant UI string regLocationGpsSuggestion
  ///
  /// In fr, this message translates to:
  /// **'Position GPS proposée — confirmez uniquement si c’est le lieu de retrait de l’établissement.'**
  String get regLocationGpsSuggestion;

  /// Merchant UI string regLocationDenied
  ///
  /// In fr, this message translates to:
  /// **'Autorisation de localisation refusée. Placez le pin manuellement sur la carte.'**
  String get regLocationDenied;

  /// Merchant UI string regLocationDeniedForever
  ///
  /// In fr, this message translates to:
  /// **'Localisation désactivée pour SpeedyGo. Activez-la dans Réglages, ou placez le pin manuellement.'**
  String get regLocationDeniedForever;

  /// Merchant UI string regLocationServicesDisabled
  ///
  /// In fr, this message translates to:
  /// **'Les services de localisation sont désactivés. Placez le pin manuellement sur la carte.'**
  String get regLocationServicesDisabled;

  /// Merchant UI string regLocationUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Position GPS indisponible. Placez le pin manuellement sur la carte.'**
  String get regLocationUnavailable;

  /// Merchant UI string regBranchPhoneLabel
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get regBranchPhoneLabel;

  /// Merchant UI string regBranchPhoneHint
  ///
  /// In fr, this message translates to:
  /// **'Numéro de contact de l’établissement (distinct du numéro de connexion).'**
  String get regBranchPhoneHint;

  /// Merchant UI string regPreviewLabel
  ///
  /// In fr, this message translates to:
  /// **'Aperçu (données saisies — non publié)'**
  String get regPreviewLabel;

  /// Merchant UI string regBranchIncomplete
  ///
  /// In fr, this message translates to:
  /// **'Nom, téléphone et adresse de l’établissement sont requis.'**
  String get regBranchIncomplete;

  /// Merchant UI string regCoordsInvalid
  ///
  /// In fr, this message translates to:
  /// **'Latitude (−90…90) et longitude (−180…180) invalides.'**
  String get regCoordsInvalid;

  /// Merchant UI string regCoordsConfirmHint
  ///
  /// In fr, this message translates to:
  /// **'Indiquez le lieu de retrait sur la carte, puis confirmez.'**
  String get regCoordsConfirmHint;

  /// Merchant UI string regReviewTitle
  ///
  /// In fr, this message translates to:
  /// **'Révision'**
  String get regReviewTitle;

  /// Merchant UI string regReviewDocsTitle
  ///
  /// In fr, this message translates to:
  /// **'Documents légaux'**
  String get regReviewDocsTitle;

  /// Merchant UI string regReviewBranchTitle
  ///
  /// In fr, this message translates to:
  /// **'Établissement'**
  String get regReviewBranchTitle;

  /// Merchant UI string regReviewLocation
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get regReviewLocation;

  /// Merchant UI string regReviewBody
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vérifier attentivement vos informations avant la soumission finale pour éviter tout retard de validation.'**
  String get regReviewBody;

  /// Merchant UI string regSubmit
  ///
  /// In fr, this message translates to:
  /// **'Soumettre pour vérification'**
  String get regSubmit;

  /// Merchant UI string regCorrectionTitle
  ///
  /// In fr, this message translates to:
  /// **'Correction du dossier'**
  String get regCorrectionTitle;

  /// Merchant UI string regCorrectionActionRequired
  ///
  /// In fr, this message translates to:
  /// **'Action requise'**
  String get regCorrectionActionRequired;

  /// Merchant UI string regCorrectionDetails
  ///
  /// In fr, this message translates to:
  /// **'Détails du dossier'**
  String get regCorrectionDetails;

  /// Merchant UI string regCorrectionSubmit
  ///
  /// In fr, this message translates to:
  /// **'Soumettre les corrections'**
  String get regCorrectionSubmit;

  /// Merchant UI string regContinue
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get regContinue;

  /// Merchant UI string regEdit
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get regEdit;

  /// Merchant UI string regMissingSteps
  ///
  /// In fr, this message translates to:
  /// **'Complétez votre dossier'**
  String get regMissingSteps;

  /// Merchant UI string regRejectionNoReason
  ///
  /// In fr, this message translates to:
  /// **'Des corrections sont nécessaires. Mettez à jour les pièces concernées puis soumettez à nouveau.'**
  String get regRejectionNoReason;

  /// Merchant UI string regApprovedNext
  ///
  /// In fr, this message translates to:
  /// **'Votre commerce est approuvé. Complétez ensuite horaires et catalogue lorsque disponibles.'**
  String get regApprovedNext;

  /// Merchant UI string legalSectionTitle
  ///
  /// In fr, this message translates to:
  /// **'Conditions et déclaration'**
  String get legalSectionTitle;

  /// Merchant UI string legalSectionBody
  ///
  /// In fr, this message translates to:
  /// **'Avant de soumettre, lisez et acceptez les conditions suivantes. Votre acceptation est enregistrée avec le dossier.'**
  String get legalSectionBody;

  /// Merchant UI string legalTermsLabel
  ///
  /// In fr, this message translates to:
  /// **'J’ai lu et j’accepte les conditions générales marchand SpeedyGo.'**
  String get legalTermsLabel;

  /// Merchant UI string legalDeclarationLabel
  ///
  /// In fr, this message translates to:
  /// **'Je certifie que les informations et les documents du dossier sont exacts et complets.'**
  String get legalDeclarationLabel;

  /// Merchant UI string legalVersionTag
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String legalVersionTag(String version);

  /// Merchant UI string legalLoading
  ///
  /// In fr, this message translates to:
  /// **'Chargement des conditions…'**
  String get legalLoading;

  /// Merchant UI string legalLoadFailed
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les conditions. Vérifiez votre connexion puis réessayez.'**
  String get legalLoadFailed;

  /// Merchant UI string legalIncomplete
  ///
  /// In fr, this message translates to:
  /// **'Les conditions ne sont pas disponibles pour le moment. Réessayez plus tard.'**
  String get legalIncomplete;

  /// Merchant UI string legalRetry
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get legalRetry;

  /// Merchant UI string legalConsentRequired
  ///
  /// In fr, this message translates to:
  /// **'Acceptez les conditions et la déclaration d’exactitude pour soumettre le dossier.'**
  String get legalConsentRequired;

  /// Merchant UI string legalVersionOutdated
  ///
  /// In fr, this message translates to:
  /// **'Les conditions ont été mises à jour. Relisez-les puis acceptez à nouveau avant de soumettre.'**
  String get legalVersionOutdated;

  /// Merchant UI string legalConsentHint
  ///
  /// In fr, this message translates to:
  /// **'Cochez les deux cases pour activer la soumission.'**
  String get legalConsentHint;

  /// Merchant UI string legalContentLink
  ///
  /// In fr, this message translates to:
  /// **'Référence du texte'**
  String get legalContentLink;

  /// Merchant UI string issuesTitle
  ///
  /// In fr, this message translates to:
  /// **'Points à corriger'**
  String get issuesTitle;

  /// Merchant UI string issuesApplicationTitle
  ///
  /// In fr, this message translates to:
  /// **'Informations du dossier'**
  String get issuesApplicationTitle;

  /// Merchant UI string issuesDocumentTitle
  ///
  /// In fr, this message translates to:
  /// **'Documents à remplacer'**
  String get issuesDocumentTitle;

  /// Merchant UI string issuesReplaceDocument
  ///
  /// In fr, this message translates to:
  /// **'Remplacer ce document'**
  String get issuesReplaceDocument;

  /// Merchant UI string issuesResolved
  ///
  /// In fr, this message translates to:
  /// **'Corrigé'**
  String get issuesResolved;

  /// Merchant UI string issuesFixHint
  ///
  /// In fr, this message translates to:
  /// **'Corrigez les points ci-dessus (remplacez les documents concernés si indiqué), acceptez à nouveau les conditions, puis soumettez le dossier.'**
  String get issuesFixHint;

  /// Merchant UI string issuesRemaining
  ///
  /// In fr, this message translates to:
  /// **'1 point restant à corriger{count} points restants à corriger'**
  String issuesRemaining(String count);

  /// Merchant UI string dossierAttemptLabel
  ///
  /// In fr, this message translates to:
  /// **'Tentative n°'**
  String get dossierAttemptLabel;

  /// Merchant UI string dossierSubmittedAtLabel
  ///
  /// In fr, this message translates to:
  /// **'Soumis le'**
  String get dossierSubmittedAtLabel;

  /// Merchant UI string dossierReviewedAtLabel
  ///
  /// In fr, this message translates to:
  /// **'Examiné le'**
  String get dossierReviewedAtLabel;

  /// Merchant UI string dossierConsentLabel
  ///
  /// In fr, this message translates to:
  /// **'Conditions acceptées'**
  String get dossierConsentLabel;

  /// Merchant UI string dossierConsentVersions
  ///
  /// In fr, this message translates to:
  /// **'Conditions {terms} · Déclaration {declaration}'**
  String dossierConsentVersions(String terms, String declaration);

  /// Merchant UI string settingsTeamRow
  ///
  /// In fr, this message translates to:
  /// **'Gestion de l’équipe'**
  String get settingsTeamRow;

  /// Merchant UI string settingsTeamInvitationsRow
  ///
  /// In fr, this message translates to:
  /// **'Invitations reçues'**
  String get settingsTeamInvitationsRow;

  /// Merchant UI string teamTitle
  ///
  /// In fr, this message translates to:
  /// **'Personnel et Accès'**
  String get teamTitle;

  /// Merchant UI string teamStoreContext
  ///
  /// In fr, this message translates to:
  /// **'Gestion de l’équipe'**
  String get teamStoreContext;

  /// Merchant UI string teamActiveMembers
  ///
  /// In fr, this message translates to:
  /// **'Membres actifs'**
  String get teamActiveMembers;

  /// Merchant UI string teamPendingInvitations
  ///
  /// In fr, this message translates to:
  /// **'Invitations en attente'**
  String get teamPendingInvitations;

  /// Merchant UI string teamRolesSummary
  ///
  /// In fr, this message translates to:
  /// **'Résumé des rôles'**
  String get teamRolesSummary;

  /// Merchant UI string teamRoleOwner
  ///
  /// In fr, this message translates to:
  /// **'Propriétaire'**
  String get teamRoleOwner;

  /// Merchant UI string teamRoleManager
  ///
  /// In fr, this message translates to:
  /// **'Gestionnaire'**
  String get teamRoleManager;

  /// Merchant UI string teamRoleStaff
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get teamRoleStaff;

  /// Merchant UI string teamOwnerBadge
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get teamOwnerBadge;

  /// Merchant UI string teamSelfBadge
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get teamSelfBadge;

  /// Merchant UI string teamPhoneUnavailable
  ///
  /// In fr, this message translates to:
  /// **'Numéro indisponible'**
  String get teamPhoneUnavailable;

  /// Merchant UI string teamRevoke
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get teamRevoke;

  /// Merchant UI string teamChangeRole
  ///
  /// In fr, this message translates to:
  /// **'Modifier le rôle'**
  String get teamChangeRole;

  /// Merchant UI string teamRegenerateCode
  ///
  /// In fr, this message translates to:
  /// **'Régénérer le code'**
  String get teamRegenerateCode;

  /// Merchant UI string teamCancelInvitation
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get teamCancelInvitation;

  /// Merchant UI string teamInviteMember
  ///
  /// In fr, this message translates to:
  /// **'Inviter un membre'**
  String get teamInviteMember;

  /// Merchant UI string teamInvitationExpired
  ///
  /// In fr, this message translates to:
  /// **'Expirée'**
  String get teamInvitationExpired;

  /// Merchant UI string teamRoleLine
  ///
  /// In fr, this message translates to:
  /// **'Rôle : {role}'**
  String teamRoleLine(String role);

  /// Merchant UI string teamExpiresOn
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String teamExpiresOn(String date);

  /// Merchant UI string teamEmptyMembers
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre actif pour le moment.'**
  String get teamEmptyMembers;

  /// Merchant UI string teamEmptyInvitations
  ///
  /// In fr, this message translates to:
  /// **'Aucune invitation en attente.'**
  String get teamEmptyInvitations;

  /// Merchant UI string teamLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger l’équipe. Vérifiez votre connexion puis réessayez.'**
  String get teamLoadError;

  /// Merchant UI string teamForbiddenTitle
  ///
  /// In fr, this message translates to:
  /// **'Accès réservé'**
  String get teamForbiddenTitle;

  /// Merchant UI string teamForbiddenBody
  ///
  /// In fr, this message translates to:
  /// **'La gestion de l’équipe est réservée aux propriétaires et aux gestionnaires.'**
  String get teamForbiddenBody;

  /// Merchant UI string teamSummaryOwner
  ///
  /// In fr, this message translates to:
  /// **'Invite, modifie les rôles et révoque l’accès des membres.'**
  String get teamSummaryOwner;

  /// Merchant UI string teamSummaryManager
  ///
  /// In fr, this message translates to:
  /// **'Consulte la liste de l’équipe et les invitations. Ne peut ni inviter, ni modifier les rôles, ni révoquer.'**
  String get teamSummaryManager;

  /// Merchant UI string teamSummaryStaff
  ///
  /// In fr, this message translates to:
  /// **'N’a pas accès à la gestion de l’équipe.'**
  String get teamSummaryStaff;

  /// Merchant UI string teamSummaryScope
  ///
  /// In fr, this message translates to:
  /// **'Les accès couvrent tous les établissements du commerce : il n’existe pas d’accès par établissement.'**
  String get teamSummaryScope;

  /// Merchant UI string teamInviteTitle
  ///
  /// In fr, this message translates to:
  /// **'Inviter un membre'**
  String get teamInviteTitle;

  /// Merchant UI string teamInviteHint
  ///
  /// In fr, this message translates to:
  /// **'Aucun SMS ni e-mail n’est émis par SpeedyGo. Un code d’acceptation vous sera remis : transmettez-le vous-même à la personne invitée.'**
  String get teamInviteHint;

  /// Merchant UI string teamInvitePhoneLabel
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get teamInvitePhoneLabel;

  /// Merchant UI string teamInvitePhoneHint
  ///
  /// In fr, this message translates to:
  /// **'550 12 34 56'**
  String get teamInvitePhoneHint;

  /// Merchant UI string teamInvitePhoneHelper
  ///
  /// In fr, this message translates to:
  /// **'Numéro avec lequel la personne se connecte à SpeedyGo.'**
  String get teamInvitePhoneHelper;

  /// Merchant UI string teamInvitePhoneInvalid
  ///
  /// In fr, this message translates to:
  /// **'Saisissez un numéro mobile algérien valide (9 chiffres).'**
  String get teamInvitePhoneInvalid;

  /// Merchant UI string teamInviteRoleLabel
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get teamInviteRoleLabel;

  /// Merchant UI string teamInviteCreate
  ///
  /// In fr, this message translates to:
  /// **'Créer l’invitation'**
  String get teamInviteCreate;

  /// Merchant UI string teamRoleManagerHint
  ///
  /// In fr, this message translates to:
  /// **'Peut consulter l’équipe. Aucun droit de gestion.'**
  String get teamRoleManagerHint;

  /// Merchant UI string teamRoleStaffHint
  ///
  /// In fr, this message translates to:
  /// **'Accès opérationnel, sans accès à la gestion de l’équipe.'**
  String get teamRoleStaffHint;

  /// Merchant UI string teamCodeTitle
  ///
  /// In fr, this message translates to:
  /// **'Code d’acceptation'**
  String get teamCodeTitle;

  /// Merchant UI string teamCodeRegeneratedTitle
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code d’acceptation'**
  String get teamCodeRegeneratedTitle;

  /// Merchant UI string teamCodeRegeneratedNote
  ///
  /// In fr, this message translates to:
  /// **'L’ancien code ne fonctionne plus.'**
  String get teamCodeRegeneratedNote;

  /// Merchant UI string teamCodeCopy
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get teamCodeCopy;

  /// Merchant UI string teamCodeCopied
  ///
  /// In fr, this message translates to:
  /// **'Code copié.'**
  String get teamCodeCopied;

  /// Merchant UI string teamCodeDone
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get teamCodeDone;

  /// Merchant UI string teamRevokeTitle
  ///
  /// In fr, this message translates to:
  /// **'Révoquer l’accès ?'**
  String get teamRevokeTitle;

  /// Merchant UI string teamRevoked
  ///
  /// In fr, this message translates to:
  /// **'Accès révoqué.'**
  String get teamRevoked;

  /// Merchant UI string teamCancelInviteTitle
  ///
  /// In fr, this message translates to:
  /// **'Annuler l’invitation ?'**
  String get teamCancelInviteTitle;

  /// Merchant UI string teamCancelInviteBody
  ///
  /// In fr, this message translates to:
  /// **'Le code d’acceptation de {phone} ne fonctionnera plus.'**
  String teamCancelInviteBody(String phone);

  /// Merchant UI string teamCancelInviteConfirm
  ///
  /// In fr, this message translates to:
  /// **'Annuler l’invitation'**
  String get teamCancelInviteConfirm;

  /// Merchant UI string teamKeep
  ///
  /// In fr, this message translates to:
  /// **'Conserver'**
  String get teamKeep;

  /// Merchant UI string teamInviteCancelled
  ///
  /// In fr, this message translates to:
  /// **'Invitation annulée.'**
  String get teamInviteCancelled;

  /// Merchant UI string teamRoleSheetTitle
  ///
  /// In fr, this message translates to:
  /// **'Modifier le rôle'**
  String get teamRoleSheetTitle;

  /// Merchant UI string teamRoleSheetHint
  ///
  /// In fr, this message translates to:
  /// **'Si le rôle réduit ses droits, les sessions du membre sont fermées et il devra se reconnecter.'**
  String get teamRoleSheetHint;

  /// Merchant UI string teamRoleSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get teamRoleSave;

  /// Merchant UI string teamRoleUpdated
  ///
  /// In fr, this message translates to:
  /// **'Rôle mis à jour.'**
  String get teamRoleUpdated;

  /// Merchant UI string teamErrorGeneric
  ///
  /// In fr, this message translates to:
  /// **'Action impossible pour le moment. Réessayez.'**
  String get teamErrorGeneric;

  /// Merchant UI string teamErrorConflict
  ///
  /// In fr, this message translates to:
  /// **'La liste a changé entre-temps. Elle vient d’être actualisée : vérifiez puis réessayez.'**
  String get teamErrorConflict;

  /// Merchant UI string teamErrorDuplicateMember
  ///
  /// In fr, this message translates to:
  /// **'Ce numéro fait déjà partie de l’équipe.'**
  String get teamErrorDuplicateMember;

  /// Merchant UI string teamErrorDuplicateInvite
  ///
  /// In fr, this message translates to:
  /// **'Une invitation est déjà en attente pour ce numéro.'**
  String get teamErrorDuplicateInvite;

  /// Merchant UI string teamErrorOwnerProtected
  ///
  /// In fr, this message translates to:
  /// **'Le propriétaire ne peut pas être modifié ici.'**
  String get teamErrorOwnerProtected;

  /// Merchant UI string teamErrorSelf
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas modifier votre propre accès.'**
  String get teamErrorSelf;

  /// Merchant UI string teamErrorInviteGone
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation n’existe plus.'**
  String get teamErrorInviteGone;

  /// Merchant UI string teamErrorInviteExpired
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation a expiré. Demandez un nouveau code au propriétaire.'**
  String get teamErrorInviteExpired;

  /// Merchant UI string teamErrorCodeInvalid
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect.'**
  String get teamErrorCodeInvalid;

  /// Merchant UI string teamErrorPhoneMismatch
  ///
  /// In fr, this message translates to:
  /// **'Cette invitation est destinée à un autre numéro.'**
  String get teamErrorPhoneMismatch;

  /// Merchant UI string teamErrorInvalidInput
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez le numéro et le rôle puis réessayez.'**
  String get teamErrorInvalidInput;

  /// Merchant UI string teamInvitationsTitle
  ///
  /// In fr, this message translates to:
  /// **'Invitations reçues'**
  String get teamInvitationsTitle;

  /// Merchant UI string teamInvitationsHint
  ///
  /// In fr, this message translates to:
  /// **'Invitations adressées à votre numéro. Saisissez le code remis par le propriétaire pour les accepter.'**
  String get teamInvitationsHint;

  /// Merchant UI string teamInvitationsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune invitation en attente pour votre numéro.'**
  String get teamInvitationsEmpty;

  /// Merchant UI string teamInvitationsLoadError
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos invitations. Réessayez.'**
  String get teamInvitationsLoadError;

  /// Merchant UI string teamAccept
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get teamAccept;

  /// Merchant UI string teamAcceptTitle
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code d’acceptation'**
  String get teamAcceptTitle;

  /// Merchant UI string teamAcceptCodeLabel
  ///
  /// In fr, this message translates to:
  /// **'Code remis par le propriétaire'**
  String get teamAcceptCodeLabel;

  /// Merchant UI string teamAcceptCodeInvalid
  ///
  /// In fr, this message translates to:
  /// **'Le code comporte 64 caractères (chiffres et lettres a à f).'**
  String get teamAcceptCodeInvalid;

  /// Merchant UI string teamAcceptConfirm
  ///
  /// In fr, this message translates to:
  /// **'Accepter l’invitation'**
  String get teamAcceptConfirm;

  /// Merchant UI string settingsLanguageRow
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguageRow;

  /// Merchant UI string languageSettingsTitle
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageSettingsTitle;

  /// Merchant UI string languageSettingsSubtitle
  ///
  /// In fr, this message translates to:
  /// **'Choisissez la langue de l’application. Le changement s’applique immédiatement.'**
  String get languageSettingsSubtitle;

  /// Merchant UI string languageOptionFrench
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageOptionFrench;

  /// Merchant UI string languageOptionArabic
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get languageOptionArabic;

  /// Merchant UI string languageApply
  ///
  /// In fr, this message translates to:
  /// **'Appliquer les modifications'**
  String get languageApply;

  /// Merchant UI string languageApplied
  ///
  /// In fr, this message translates to:
  /// **'Langue mise à jour.'**
  String get languageApplied;

  /// Merchant UI string languageBilingualTitle
  ///
  /// In fr, this message translates to:
  /// **'Langue / اللغة'**
  String get languageBilingualTitle;

  /// Merchant UI string languagePreviewNote
  ///
  /// In fr, this message translates to:
  /// **'Les textes de l’interface basculent entre le français et l’arabe. Les données métier restent inchangées.'**
  String get languagePreviewNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
