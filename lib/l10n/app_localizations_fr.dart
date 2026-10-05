// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'SpeedyGo Merchant';

  @override
  String get brandName => 'SpeedyGo';

  @override
  String get splashTagline => 'Votre commerce. Simplement.';

  @override
  String get splashLegacyTagline => 'Espace commerçant';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingHaveAccount => 'J’ai déjà un compte';

  @override
  String get onboardingPage1Title => 'Recevez vos commandes';

  @override
  String get onboardingPage1Body =>
      'Retrouvez les nouvelles commandes et consultez leurs détails.';

  @override
  String get onboardingPage2Title => 'Maîtrisez la préparation';

  @override
  String get onboardingPage2Body =>
      'Organisez la préparation et indiquez quand une commande est prête.';

  @override
  String get onboardingPage3Title => 'Votre commerce, à portée de main';

  @override
  String get onboardingPage3Body =>
      'Retrouvez votre catalogue, vos horaires et les informations de votre établissement.';

  @override
  String get onboardingSaveFailed =>
      'Impossible d’enregistrer l’introduction. Réessayez.';

  @override
  String get onboardingPageSemantics => 'Page d’introduction';

  @override
  String get phoneTitle => 'Entrez votre numéro de téléphone';

  @override
  String get phoneSubtitle =>
      'Nous vous enverrons un code de vérification par SMS.';

  @override
  String get phoneHint => '555 12 34 56';

  @override
  String get phonePrefix => '+213';

  @override
  String get phoneSmsNote => 'Les frais de SMS standard peuvent s’appliquer.';

  @override
  String get phoneLabel => 'Numéro de téléphone';

  @override
  String get phoneInvalid => 'Saisissez un numéro algérien valide.';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get needHelp => 'Besoin d’aide ?';

  @override
  String get helpUnavailable =>
      'L’assistance sera disponible dans une prochaine version.';

  @override
  String get otpTitle => 'Vérification du code';

  @override
  String get editNumber => 'Modifier';

  @override
  String get verify => 'Vérifier';

  @override
  String get resend => 'Renvoyer le code';

  @override
  String resendIn(String clock) {
    return 'Renvoyer le code dans $clock';
  }

  @override
  String get otpCooldownHint => 'Patientez avant de renvoyer un code';

  @override
  String get resendCode => 'Renvoyer le code';

  @override
  String get otpSubtitle => 'Saisissez le code à 6 chiffres envoyé au';

  @override
  String get restoreTitle => 'Restauration de la session';

  @override
  String get restoreLoading => 'Connexion en cours…';

  @override
  String get restoreOffline =>
      'Impossible de joindre le serveur. Vérifiez votre connexion.';

  @override
  String get restoreRetry => 'Réessayer';

  @override
  String get restoreOtherAccount => 'Utiliser un autre compte';

  @override
  String get sessionExpired => 'Votre session a expiré. Connectez-vous.';

  @override
  String get networkError => 'Problème de réseau. Réessayez.';

  @override
  String get languageSaveFailed =>
      'Impossible d’enregistrer la langue. Réessayez.';

  @override
  String get retry => 'Réessayer';

  @override
  String get refreshStatus => 'Actualiser le statut';

  @override
  String get back => 'Retour';

  @override
  String get loading => 'Chargement…';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabOrders => 'Commandes';

  @override
  String get tabCatalog => 'Catalogue';

  @override
  String get tabReports => 'Rapports';

  @override
  String get tabProfile => 'Profil';

  @override
  String get navReveal => 'Afficher la navigation';

  @override
  String get homeTitle => 'Accueil';

  @override
  String get selectBranchTitle => 'Choisir un établissement';

  @override
  String get selectBranchSubtitle =>
      'Sélectionnez l’établissement avec lequel vous souhaitez travailler.';

  @override
  String get noMembershipTitle => 'Aucun commerce associé';

  @override
  String get noMembershipBody =>
      'Ce compte n’a pas encore d’adhésion commerçant. Vous pouvez créer un profil commerce pour démarrer la vérification.';

  @override
  String get noMembershipInvitationsCta => 'J’ai une invitation';

  @override
  String get createMerchant => 'Créer un commerce';

  @override
  String get merchantNameLabel => 'Nom du commerce';

  @override
  String get merchantNameHint => 'Ex. Pharmacie du Centre';

  @override
  String get verificationPendingTitle => 'Vérification en cours';

  @override
  String get verificationPendingBody =>
      'Votre commerce est enregistré et en attente de vérification.';

  @override
  String get verificationDossierProgress => 'Pièces du dossier';

  @override
  String get verificationSubmittedStep => 'Dossier soumis';

  @override
  String get verificationReviewStep => 'Examen des documents';

  @override
  String get verificationReviewStepBody => 'En cours d’examen par SpeedyGo';

  @override
  String get verificationFinalStep => 'Validation finale';

  @override
  String get verificationFinalStepBody => 'En attente de décision';

  @override
  String get verificationTimelineTitle => 'Progression du dossier';

  @override
  String get verificationReferenceLabel => 'Référence';

  @override
  String get verificationReferenceFull => 'Référence du dossier';

  @override
  String get approvedTitle => 'Félicitations !';

  @override
  String get approvedSubtitle => 'Votre établissement est approuvé';

  @override
  String get approvedBody =>
      'Pour commencer à recevoir des commandes, assurez-vous que votre magasin est ouvert, que vos horaires sont définis et que vos produits sont disponibles.';

  @override
  String get approvedReferenceLabel => 'RÉFÉRENCE MERCHANT';

  @override
  String get approvedReferenceFull => 'Référence Merchant';

  @override
  String get approvedBadge => 'Approuvé';

  @override
  String get approvedStepsTitle => 'Étapes de configuration';

  @override
  String get approvedHoursTitle => 'Horaires d’ouverture';

  @override
  String get approvedHoursBody => 'Configurez quand vous êtes ouvert';

  @override
  String get approvedCatalogTitle => 'Catalogue de produits';

  @override
  String get approvedCatalogBody => 'Ajoutez vos premiers articles';

  @override
  String get approvedAlertsTitle => 'Alertes et notifications';

  @override
  String get approvedAlertsBody => 'Restez informé des commandes';

  @override
  String get approvedNeedBranchHint =>
      'Disponible après l’ajout d’un établissement';

  @override
  String get approvedNotOpenNote =>
      'L’approbation n’ouvre pas votre magasin automatiquement : vérifiez son statut, vos horaires et votre catalogue depuis l’accueil.';

  @override
  String get approvedContinue => 'Accéder à l’accueil marchand';

  @override
  String get verificationRequestIdLabel => 'ID DE DEMANDE';

  @override
  String get verificationNeedHelp => 'Besoin d’aide pour votre dossier ?';

  @override
  String get verificationCorrectAndSubmit => 'Corriger et soumettre';

  @override
  String get verificationRejectedTitle => 'Dossier à compléter';

  @override
  String get verificationRejectedBody =>
      'Le dossier a été refusé. Corrigez le profil ou les pièces lorsque l’édition est autorisée, puis soumettez à nouveau.';

  @override
  String get verificationApprovedTitle => 'Commerce approuvé';

  @override
  String get verificationApprovedBody =>
      'Votre commerce est approuvé. Complétez un établissement actif pour l’exploitation.';

  @override
  String get suspendedTitle => 'Compte commerce suspendu';

  @override
  String get suspendedBody =>
      'Ce commerce est suspendu. Contactez le support SpeedyGo si besoin.';

  @override
  String get checklistTitle => 'Pièces du dossier';

  @override
  String get accessRestrictedTitle => 'Accès restreint';

  @override
  String get accessRestrictedBody =>
      'Vous n’avez pas les droits nécessaires pour cette action.';

  @override
  String get needBranchTitle => 'Établissement requis';

  @override
  String get needBranchBody =>
      'Ajoutez au moins un établissement actif pour utiliser l’espace opérationnel.';

  @override
  String get addBranch => 'Ajouter un établissement';

  @override
  String get branchNameLabel => 'Nom de l’établissement';

  @override
  String get branchPhoneLabel => 'Téléphone';

  @override
  String get branchAddressLabel => 'Adresse';

  @override
  String get branchLatLabel => 'Latitude';

  @override
  String get branchLngLabel => 'Longitude';

  @override
  String get save => 'Enregistrer';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get operationalActive => 'Actif';

  @override
  String get operationalInactive => 'Inactif';

  @override
  String get operationalSuspended => 'Suspendu';

  @override
  String get homeNoMetrics =>
      'Aucun indicateur agrégé n’est fourni par l’API dans cette phase.';

  @override
  String get homeOrderCountsTitle => 'Commandes en cours';

  @override
  String get homeCountIncoming => 'Nouveaux';

  @override
  String get homeCountPreparing => 'En prép.';

  @override
  String get homeCountReady => 'Prêts';

  @override
  String get homeCountCourier => 'Livreur';

  @override
  String get homeCountCourierUnavailable => '—';

  @override
  String get homeActiveOrdersTitle => 'Commandes actives';

  @override
  String get homeActiveOrdersEmpty => 'Aucune commande active pour le moment.';

  @override
  String get homeTreatOrder => 'Traiter la commande';

  @override
  String get homeOpenOrder => 'Voir la commande';

  @override
  String get homeVerificationTitle => 'Vérification à finaliser';

  @override
  String get homeVerificationBody =>
      'Complétez votre dossier pour conserver l’accès complet à votre espace marchand.';

  @override
  String get homeKpiSales => 'Ventes';

  @override
  String get homeKpiOrders => 'Commandes';

  @override
  String get homeKpiOrdersUnit => 'terminées';

  @override
  String get homeKpiCurrency => 'DZD';

  @override
  String get homeKpiUnavailable => '—';

  @override
  String get refresh => 'Actualiser';

  @override
  String get ordersEmpty => 'Aucune commande pour cet établissement.';

  @override
  String get ordersEmptyIncoming => 'Aucune nouvelle commande';

  @override
  String get ordersEmptyAccepted => 'Aucune commande acceptée';

  @override
  String get ordersEmptyPreparing => 'Aucune commande en préparation';

  @override
  String get ordersEmptyReady => 'Aucune commande prête';

  @override
  String get ordersEmptyCompleted => 'Aucune commande terminée';

  @override
  String get ordersEmptyCancelled => 'Aucune commande annulée';

  @override
  String get ordersEmptyFailed => 'Aucune commande échouée';

  @override
  String get ordersLoadError => 'Impossible de charger les commandes.';

  @override
  String get orderDetailTitle => 'Commande';

  @override
  String get orderDetailLoadError => 'Impossible de charger cette commande.';

  @override
  String get orderFulfillmentIncoming => 'Nouveau';

  @override
  String get supportReportTitle => 'Signaler un problème';

  @override
  String get supportShort => 'Support';

  @override
  String get supportContact => 'Contacter le support';

  @override
  String get supportOrderLabel => 'COMMANDE';

  @override
  String get supportCustomerLabel => 'CLIENT';

  @override
  String get supportMerchandiseLabel => 'MARCHANDISES';

  @override
  String get supportDescriptionLabel => 'Description du problème';

  @override
  String get supportDescriptionHint =>
      'Expliquez-nous ce qui s’est passé en détail...';

  @override
  String get supportSensitiveHint =>
      'Veuillez ne pas inclure de données sensibles (ex : mots de passe).';

  @override
  String get supportSend => 'Envoyer le ticket';

  @override
  String get supportSentTitle => 'Signalement envoyé';

  @override
  String get supportSentBodyNoRef =>
      'Votre ticket a été transmis à l’équipe SpeedyGo.';

  @override
  String get supportBackToOrder => 'Retour à la commande';

  @override
  String get supportForbidden =>
      'Seuls le propriétaire et les gérants peuvent contacter le support.';

  @override
  String get supportSendError => 'Le ticket n’a pas pu être envoyé. Réessayez.';

  @override
  String get supportCenterTitle => 'Support Merchant';

  @override
  String get supportNewTicket => 'Nouveau ticket';

  @override
  String get supportActiveTickets => 'Tickets actifs';

  @override
  String get supportResolvedTickets => 'Tickets résolus';

  @override
  String get supportNoTickets => 'Aucun ticket pour le moment.';

  @override
  String get supportLoadError => 'Impossible de charger vos tickets.';

  @override
  String get supportTopicsTitle => 'Sujets fréquents';

  @override
  String get supportTopicsHint =>
      'Choisissez un sujet pour ouvrir un nouveau ticket.';

  @override
  String get supportTopicsLoadError => 'Impossible de charger les sujets.';

  @override
  String get supportTopicsEmpty => 'Aucun sujet disponible pour le moment.';

  @override
  String get supportTopicLabel => 'Sujet';

  @override
  String get supportTopicRequired => 'Choisissez un sujet.';

  @override
  String get supportSubjectLabel => 'Objet';

  @override
  String get supportSubjectHint => 'Résumez votre demande en quelques mots';

  @override
  String get supportSubjectRequired => 'Indiquez l’objet de votre demande.';

  @override
  String get supportFaqTitle => 'Questions fréquentes';

  @override
  String get supportFaqEmpty => 'Aucune question fréquente pour le moment.';

  @override
  String get supportFaqLoadError => 'Impossible de charger la FAQ.';

  @override
  String get supportComposeTitle => 'Nouveau ticket';

  @override
  String get supportComposeHint =>
      'Décrivez votre demande. Pour un problème sur une commande, utilisez « Signaler un problème » depuis la commande.';

  @override
  String get supportTicketTitle => 'Ticket';

  @override
  String get supportTicketLoadError => 'Impossible de charger ce ticket.';

  @override
  String get supportLinkedOrder => 'Commande liée';

  @override
  String get supportYou => 'Vous';

  @override
  String get supportTeam => 'Support SpeedyGo';

  @override
  String get supportReplyHint => 'Votre réponse';

  @override
  String get supportReplySend => 'Envoyer';

  @override
  String get supportReplyError => 'La réponse n’a pas pu être envoyée.';

  @override
  String get supportTicketFinished =>
      'Ce ticket est clos. Créez un nouveau ticket si besoin.';

  @override
  String get supportNoMessages => 'Aucun message.';

  @override
  String get orderListAcceptNow => 'À accepter immédiatement';

  @override
  String get orderDetailsTitle => 'Détails de la commande';

  @override
  String get orderDetailCancelledTitle => 'Commande annulée';

  @override
  String get orderCancelledHeroBody => 'Cette commande n’aboutira pas.';

  @override
  String get orderCancelledByCustomer => 'Annulée par le client';

  @override
  String get orderRejectedByMerchant => 'Refusée par le commerce';

  @override
  String get orderReasonLabel => 'Raison';

  @override
  String get orderCancelledAck => 'Compris';

  @override
  String get orderViewHistory => 'Voir l’historique';

  @override
  String get orderCurrentStatus => 'Statut actuel';

  @override
  String get orderReceivedAtLabel => 'Reçue à';

  @override
  String get orderPaymentLabel => 'Paiement';

  @override
  String orderPaymentMethod(String method) {
    return 'Méthode : $method';
  }

  @override
  String get eventCreated => 'Commande reçue';

  @override
  String get eventCreatedCaption => 'Commande passée par le client';

  @override
  String get eventAccepted => 'Acceptée';

  @override
  String get eventAcceptedCaption => 'Commande confirmée';

  @override
  String get eventPrepStarted => 'En préparation';

  @override
  String get eventPrepStartedCaption => 'Préparation démarrée';

  @override
  String get eventReady => 'Préparée';

  @override
  String get eventReadyCaption => 'Prête pour la collecte';

  @override
  String get eventRejected => 'Refusée';

  @override
  String get eventCancelled => 'Annulée';

  @override
  String get eventCompleted => 'Terminée';

  @override
  String get eventCompletedCaption => 'Commande livrée au client';

  @override
  String get eventStatusUpdate => 'Mise à jour du statut';

  @override
  String get orderListLate => 'En retard';

  @override
  String get orderHistoryToday => 'Aujourd’hui';

  @override
  String get orderHistoryYesterday => 'Hier';

  @override
  String get orderHistoryEarlier => 'Plus tôt';

  @override
  String get orderFulfillmentAccepted => 'Acceptée';

  @override
  String get orderFulfillmentPreparing => 'En préparation';

  @override
  String get orderFulfillmentReady => 'Prête';

  @override
  String get orderStatusCreated => 'Créée';

  @override
  String get orderStatusConfirmed => 'Confirmée';

  @override
  String get orderStatusActive => 'Active';

  @override
  String get orderStatusCompleted => 'Terminée';

  @override
  String get orderStatusCancelled => 'Annulée';

  @override
  String get orderStatusFailed => 'Échouée';

  @override
  String get orderPaymentCod => 'Paiement à la livraison';

  @override
  String get orderPaymentElectronic => 'Paiement électronique';

  @override
  String get orderListMerchandiseLabel => 'Marchandises';

  @override
  String get orderIncomingBanner => 'Nouvelle commande';

  @override
  String get orderReadyBanner => 'Commande prête';

  @override
  String get orderSegmentActive => 'En cours';

  @override
  String get orderSegmentHistory => 'Historique';

  @override
  String get orderReferenceCopy => 'Copier la référence';

  @override
  String get orderReferenceCopied => 'Référence copiée';

  @override
  String get orderReferenceShowFull => 'Afficher la référence complète';

  @override
  String get orderItemsTitle => 'Articles';

  @override
  String get orderItemsToPrepareTitle => 'Articles à préparer';

  @override
  String get orderDeliveryAddress => 'Adresse de livraison';

  @override
  String get orderFinanceTitle => 'Répartition financière';

  @override
  String get orderFinanceGms => 'Sous-total marchandises';

  @override
  String get orderFinanceDiscount => 'Remise commerçant';

  @override
  String get orderFinanceNet => 'Net commerçant';

  @override
  String get orderFinanceCommissionUnavailable => 'Commission SpeedyGo';

  @override
  String get orderFinanceRestricted =>
      'Commission, remise et net commerçant réservés au propriétaire ou au responsable.';

  @override
  String get valueUnavailable => '—';

  @override
  String get orderFinanceNetCancelledNote =>
      'Montants historiques figés au moment de la commande — pas un paiement dû.';

  @override
  String get orderFinanceDeliveryFeeNote => 'Frais de livraison (client)';

  @override
  String get orderFinanceDeliveryFeeDisclaimer =>
      'Les frais de livraison ne sont pas un revenu commerçant.';

  @override
  String get orderAccept => 'Accepter';

  @override
  String get orderChoosePrepTime => 'Choisir le temps de préparation';

  @override
  String get orderReject => 'Refuser';

  @override
  String get orderRejectTitle => 'Refuser la commande';

  @override
  String get orderRejectHint =>
      'Le refus n’est possible qu’avant acceptation. Indiquez un motif.';

  @override
  String get orderRejectReasonLabel => 'Motif du refus';

  @override
  String get orderRejectConfirm => 'Confirmer le refus';

  @override
  String get orderQuickAlreadyHandled =>
      'Cette commande a déjà été traitée. La liste est actualisée.';

  @override
  String get orderQuickNotAllowed => 'Votre rôle ne permet pas cette action.';

  @override
  String get orderQuickCheckFailed =>
      'Impossible de vérifier la commande. Réessayez.';

  @override
  String get orderQuickAccepted => 'Commande acceptée.';

  @override
  String get orderQuickRejected => 'Commande refusée.';

  @override
  String get prepAcceptTitle => 'Accepter la commande';

  @override
  String get prepEstimatedTitle => 'Temps de préparation estimé';

  @override
  String get prepConfirmAccept => 'Confirmer et accepter';

  @override
  String get prepCustomTime => 'Temps personnalisé';

  @override
  String get prepCustomEntry => 'Saisie personnalisée';

  @override
  String prepCustomRange(String min, String max) {
    return 'Entre $min et $max minutes';
  }

  @override
  String prepItemCount(String n) {
    return '1 article$n articles';
  }

  @override
  String get prepInProgress => 'En cours';

  @override
  String get prepCurrentShort => 'Heure actuelle';

  @override
  String get prepNewShort => 'Nouvelle estimation';

  @override
  String get prepReasonHint => 'Ex : problème technique en cuisine…';

  @override
  String get prepRemainingTitle => 'Temps restant';

  @override
  String get prepMinutesCaption => 'MINUTES';

  @override
  String get prepSecondsCaption => 'SECONDES';

  @override
  String get prepLateHint =>
      'L’estimation est dépassée. Mettez à jour le temps ou marquez la commande prête quand elle l’est.';

  @override
  String get prepUpdateAction => 'Modifier temps';

  @override
  String get prepUpdateTitle => 'Mise à jour du temps';

  @override
  String get prepCurrentReady => 'Heure prévue actuelle';

  @override
  String prepOriginalReady(String time) {
    return 'Initiale : $time';
  }

  @override
  String prepOriginalReadyLabel(String time) {
    return 'Heure initiale : $time';
  }

  @override
  String get prepBranchLabel => 'Établissement';

  @override
  String get prepAddTime => 'Ajouter du temps de préparation';

  @override
  String prepNewEstimate(String from, String to, String add) {
    return 'Nouvelle estimation : $to au lieu de $from, plus $add minutes';
  }

  @override
  String prepClockOnDay(String day, String time) {
    return 'le $day à $time';
  }

  @override
  String prepOnDay(String day) {
    return 'le $day';
  }

  @override
  String prepSpokenClock(String time, String day) {
    return '$time le $day';
  }

  @override
  String get prepReasonOptional => 'Raison du retard (optionnel)';

  @override
  String get prepReasonShortcutsHint =>
      'Un raccourci remplit le motif ; vous pouvez le modifier.';

  @override
  String get prepReasonFieldLabel => 'Motif';

  @override
  String get prepReasonBusy => 'Forte affluence';

  @override
  String get prepReasonLongPrep => 'Préparation longue';

  @override
  String get prepReasonMissingIngredient => 'Ingrédient manquant';

  @override
  String get prepReasonOther => 'Autre raison';

  @override
  String get prepUpdateConfirm => 'Mettre à jour';

  @override
  String get orderStartPreparation => 'Démarrer la préparation';

  @override
  String get orderMarkReady => 'Marquer comme prête';

  @override
  String get markReadyPackingTitle => 'Liste de colisage';

  @override
  String get markReadyPackingHint =>
      'Vérifiez que tous les éléments de la commande sont bien emballés avant de la marquer prête.';

  @override
  String get markReadyConfirm => 'Confirmer et marquer prête';

  @override
  String get orderReadyWaitingDelivery =>
      'En attente de prise en charge pour la livraison.';

  @override
  String get orderDeliveryStatusTitle => 'Livraison';

  @override
  String get orderDriverAssigned => 'Un livreur est assigné.';

  @override
  String get orderDriverCardTitle => 'Livreur assigné';

  @override
  String get orderDriverStatusLabel => 'Statut';

  @override
  String get orderDriverEtaLabel => 'Arrivée estimée';

  @override
  String get orderDriverEtaUnavailable => 'Heure d’arrivée indisponible.';

  @override
  String get orderDriverContactUnavailable =>
      'Contact du livreur indisponible.';

  @override
  String get orderDriverCall => 'Appeler le livreur';

  @override
  String get pickupHandoffTitle => 'Code de retrait';

  @override
  String get pickupHandoffWaiting => 'En attente de validation par le livreur…';

  @override
  String get pickupHandoffInstruction1 =>
      'Communiquez ce code uniquement au livreur affiché ci-dessus.';

  @override
  String get pickupHandoffInstruction2 =>
      'Le livreur doit saisir ce code dans son application pour confirmer la récupération.';

  @override
  String get pickupHandoffRegenerate => 'Régénérer le code';

  @override
  String get pickupHandoffConfirmed => 'Remise confirmée';

  @override
  String get pickupHandoffLoadError =>
      'Impossible de charger le code de retrait.';

  @override
  String get pickupHandoffRetry => 'Réessayer';

  @override
  String get orderHandoffUnsupported =>
      'La confirmation de remise sécurisée n’est pas disponible pour le commerçant dans cette version.';

  @override
  String get orderHistoryTitle => 'Historique de la commande';

  @override
  String get orderReferenceLabel => 'Référence';

  @override
  String get orderCustomerLabel => 'Client';

  @override
  String get orderSummaryTitle => 'Résumé de la commande';

  @override
  String get deliverySearching => 'Recherche de livreur';

  @override
  String get deliveryAssigned => 'Livreur assigné';

  @override
  String get deliveryPickedUp => 'Récupérée';

  @override
  String get deliveryArrived => 'Arrivé chez le client';

  @override
  String get deliveryToPickup => 'Livreur en route vers le commerce';

  @override
  String get deliveryAtPickup => 'Livreur arrivé au commerce';

  @override
  String get deliveryInTransit => 'En route vers le client';

  @override
  String get deliveryFailed => 'Livraison échouée';

  @override
  String get deliveryCancelled => 'Livraison annulée';

  @override
  String get deliveryUnknown => 'Statut de livraison indisponible';

  @override
  String get deliveryDelivered => 'Livrée';

  @override
  String get catalogTitle => 'Catalogue';

  @override
  String get catalogTabProducts => 'Produits';

  @override
  String get catalogTabCategories => 'Catégories';

  @override
  String get catalogSearchHint => 'Rechercher un produit…';

  @override
  String get catalogAllCategories => 'Tous';

  @override
  String get catalogEmptyProducts => 'Aucun produit dans ce catalogue.';

  @override
  String get catalogEmptyCategories => 'Aucune catégorie pour le moment.';

  @override
  String get catalogLoadError => 'Impossible de charger le catalogue.';

  @override
  String get catalogInStock => 'En stock';

  @override
  String get catalogOutOfStock => 'Rupture';

  @override
  String get catalogUnavailableSection =>
      'La création et l’édition avancées de produits ne sont pas branchées dans cet écran.';

  @override
  String get reportsTitle => 'Rapports';

  @override
  String get reportsPeriodToday => 'Aujourd’hui';

  @override
  String get reportsPeriodYesterday => 'Hier';

  @override
  String get reportsPeriodWeek => 'Cette semaine';

  @override
  String get reportsPeriodMonth => 'Ce mois';

  @override
  String get reportsFinanceTitle => 'Détails financiers';

  @override
  String get reportsGrossSales => 'Ventes brutes';

  @override
  String get reportsCommission => 'Commission SpeedyGo';

  @override
  String get reportsMerchantNet => 'Net commerçant';

  @override
  String get reportsDataUnavailable => 'Données indisponibles';

  @override
  String get reportsDataUnavailableShort => '—';

  @override
  String get reportsOrdersMetric => 'Commandes';

  @override
  String get reportsPrepTimeMetric => 'Temps prép. moy.';

  @override
  String get reportsCancellationsMetric => 'Annulations';

  @override
  String get reportsTrendTitle => 'Tendance des ventes';

  @override
  String get reportsTopProductsTitle => 'Produits les plus vendus';

  @override
  String get reportsTopProductsScreenTitle => 'Top produits';

  @override
  String get reportsCommissionMixedRates =>
      'Commission SpeedyGo (taux variables)';

  @override
  String get reportsFinanceUnavailable => 'Données indisponibles';

  @override
  String get reportsRatingsTitle => 'Notes clients';

  @override
  String get reportsRatingsEmpty => 'Aucune note pour le moment.';

  @override
  String get reportsRatingsCount => 'avis';

  @override
  String get reportsRatingsUnavailable => 'Données indisponibles';

  @override
  String get reportsSettlementsTitle => 'Règlements';

  @override
  String get reportsSettlementsEmpty => 'Aucun règlement pour le moment.';

  @override
  String get reportsSettlementsForbidden =>
      'Les règlements sont réservés au propriétaire ou au responsable.';

  @override
  String get reportsLoadError => 'Impossible de charger les indicateurs.';

  @override
  String get reportsTrendUnavailable => 'Données indisponibles';

  @override
  String get reportsTopProductsUnavailable => 'Données indisponibles';

  @override
  String get reportsPeriodCustom => 'Personnalisé';

  @override
  String get reportsPeriodSelectorLabel => 'Période du rapport';

  @override
  String get reportsCustomRangeTooLong =>
      'La période personnalisée est limitée à 93 jours.';

  @override
  String get reportsAverageBasketMetric => 'Panier moyen';

  @override
  String get reportsPrepTimeNotTracked => 'Non suivi';

  @override
  String get reportsMerchantDiscount => 'Remise commerçant';

  @override
  String get reportsFinanceRestricted =>
      'Commission et net commerçant réservés au propriétaire ou au responsable.';

  @override
  String get reportsFinanceMissingSnapshot =>
      'Données financières indisponibles pour certaines commandes de la période.';

  @override
  String get reportsRefundsCompleted => 'Remboursements finalisés';

  @override
  String get reportsRefundAdjustments => 'Ajustements enregistrés';

  @override
  String get reportsRefundsNote =>
      'Les remboursements ne réduisent pas les ventes. Seuls les ajustements enregistrés sur vos règlements vous sont imputés.';

  @override
  String get reportsTrendEmpty => 'Aucune vente sur la période.';

  @override
  String get reportsTopProductsEmpty => 'Aucun produit vendu sur la période.';

  @override
  String get reportsSeeAll => 'Voir tout';

  @override
  String get reportsSortOrders => 'Commandes';

  @override
  String get reportsSortRevenue => 'Chiffre d’affaires';

  @override
  String get reportsTopSales => 'Top des ventes';

  @override
  String get reportsRankFirst => 'N°1';

  @override
  String get reportsDeletedProduct => 'Produit retiré du catalogue';

  @override
  String get reportsSalesLoadError => 'Impossible de charger les ventes.';

  @override
  String get reportsTopProductsLoadError =>
      'Impossible de charger les produits.';

  @override
  String reportsOrderCount(String count) {
    return '1 commande$count commandes';
  }

  @override
  String reportsTrendSemantics(String orders, String gross) {
    return 'Tendance des ventes : $orders commandes, $gross';
  }

  @override
  String get reportsDailySummaryTitle => 'Résumé quotidien';

  @override
  String get reportsDailySummaryShortcut => 'Résumé quotidien';

  @override
  String get reportsDailySummaryLoadError =>
      'Impossible de charger le résumé quotidien.';

  @override
  String get reportsDailySummaryEmpty =>
      'Aucune commande créée pour cette journée.';

  @override
  String get reportsDailySummarySalesKpi => 'Ventes';

  @override
  String get reportsDailySummaryOrdersKpi => 'Commandes';

  @override
  String get reportsDailySummaryPrepKpi => 'Temps Prép.';

  @override
  String get reportsDailySummaryCancellationsKpi => 'Annulations';

  @override
  String get reportsDailySummaryBreakdownTitle => 'Répartition des commandes';

  @override
  String get reportsDailySummaryDelivered => 'Livrées';

  @override
  String get reportsDailySummaryInProgress => 'En cours';

  @override
  String get reportsDailySummaryCancelled => 'Annulées';

  @override
  String get reportsDailySummaryPrepEfficiencyTitle =>
      'Efficacité de préparation';

  @override
  String get reportsDailySummaryPrepAverage => 'Moyenne';

  @override
  String get reportsDailySummaryOnTimeRate => 'À l’heure';

  @override
  String get reportsDailySummaryCancellationMotifs => 'Motifs d’annulation';

  @override
  String get reportsDailySummaryViewOrders =>
      'Voir toutes les commandes du jour';

  @override
  String reportsDailySummaryMinutes(String minutes) {
    return '$minutes min';
  }

  @override
  String reportsDailySummaryOnTimePercent(String percent) {
    return '$percent à l’heure';
  }

  @override
  String reportsDailySummaryTodayDate(String label) {
    return 'Aujourd’hui, $label';
  }

  @override
  String get deliveryImpactTitle => 'Impact sur la livraison';

  @override
  String get deliveryImpactMayDelayDriverAssignment =>
      'La préparation peut retarder la recherche d’un livreur.';

  @override
  String get deliveryImpactMayDelayPickup =>
      'Un livreur est assigné; le retrait peut être retardé.';

  @override
  String get deliveryImpactDriverWaiting => 'Le livreur attend la commande.';

  @override
  String get deliveryImpactTimingUnavailable =>
      'Impact exact sur la livraison indisponible.';

  @override
  String deliveryImpactLatestRevision(String reason) {
    return 'Dernier motif : $reason';
  }

  @override
  String get rejectReasonProductUnavailable => 'Indisponibilité produit';

  @override
  String get rejectReasonTooBusy => 'Trop occupé';

  @override
  String get rejectReasonClosingSoon => 'Fermeture proche';

  @override
  String get rejectReasonOther => 'Autre';

  @override
  String get rejectReasonTilesHint =>
      'Sélectionnez un motif puis précisez si nécessaire.';

  @override
  String get catalogAddProduct => 'Ajouter un produit';

  @override
  String get catalogEditProduct => 'Modifier le produit';

  @override
  String get catalogProductDetail => 'Détail du produit';

  @override
  String get catalogAddCategory => 'Ajouter une catégorie';

  @override
  String get catalogEditCategory => 'Modifier la catégorie';

  @override
  String get catalogProductName => 'Nom du produit (Français)';

  @override
  String get catalogProductDescription => 'Description (Français)';

  @override
  String get catalogProductPrice => 'Prix de base';

  @override
  String get catalogProductCategory => 'Catégorie';

  @override
  String get catalogProductAvailable => 'Visible dans le menu';

  @override
  String get catalogProductAvailableSub => 'Activer pour rendre disponible';

  @override
  String get catalogSaveProduct => 'Enregistrer';

  @override
  String get catalogSaveProductEdits => 'Enregistrer les modifications';

  @override
  String get catalogPreview => 'Aperçu';

  @override
  String get catalogPreviewTitle => 'Aperçu du produit';

  @override
  String get catalogPreviewUnavailable => 'Aperçu non disponible actuellement.';

  @override
  String get catalogFieldRequired => 'Ce champ est obligatoire.';

  @override
  String get catalogPriceInvalid => 'Indiquez un prix valide.';

  @override
  String get catalogCategoryRequired => 'Choisissez une catégorie.';

  @override
  String get catalogSaveRetryHint =>
      'Enregistrement impossible. Vérifiez la connexion et réessayez.';

  @override
  String get catalogSectionInfo => 'Informations';

  @override
  String get catalogSectionMedia => 'Médias';

  @override
  String get catalogSectionPrice => 'Prix et préparation';

  @override
  String get catalogSectionConfig => 'Configuration';

  @override
  String get catalogSectionAvailability => 'Disponibilité';

  @override
  String get catalogSectionImage => 'Image du produit';

  @override
  String get catalogSectionGeneral => 'Informations générales';

  @override
  String get catalogSectionPriceDetails => 'Prix et détails';

  @override
  String get catalogOnlineBanner =>
      'Cet article est actuellement en ligne pour les clients.';

  @override
  String get catalogOfflineBanner =>
      'Cet article n’est pas visible pour les clients.';

  @override
  String get catalogPriceWarning =>
      'Les changements de prix et de disponibilité sont appliqués immédiatement aux clients.';

  @override
  String get catalogImagePrimary => 'Image principale';

  @override
  String get catalogImageAdd => 'Ajouter une photo';

  @override
  String get catalogImageHint => 'JPG, PNG (max. 2 Mo, min. 400 px)';

  @override
  String get catalogImageChangePhoto => 'Changer la photo';

  @override
  String get catalogInStockNow => 'Actuellement en stock';

  @override
  String get catalogOutOfStockNow => 'Actuellement indisponible';

  @override
  String get catalogCurrencySuffix => 'DZD';

  @override
  String get catalogDeleteProduct => 'Supprimer';

  @override
  String get catalogNeedCategory =>
      'Créez d’abord une catégorie pour ajouter un produit.';

  @override
  String get catalogImagePick => 'Choisir une image';

  @override
  String get catalogImageFromGallery => 'Choisir dans la galerie';

  @override
  String get catalogImageFromCamera => 'Prendre une photo';

  @override
  String get catalogImagePluginRestart =>
      'Redémarrez l’application pour activer la sélection de photos.';

  @override
  String get catalogImageFormatError =>
      'Format non pris en charge. Utilisez une photo JPG ou PNG.';

  @override
  String get catalogImageTooSmall =>
      'Image trop petite. Minimum 400 × 400 pixels.';

  @override
  String get catalogImageTooLarge =>
      'Image trop lourde. Maximum 2 Mo après compression.';

  @override
  String get catalogImageChange => 'Changer l’image';

  @override
  String get catalogImageRemove => 'Retirer l’image';

  @override
  String get catalogImageUploadError => 'Impossible d’envoyer l’image.';

  @override
  String get catalogImageBindPartial =>
      'Produit enregistré, mais l’image n’a pas pu être liée. Réessayez.';

  @override
  String get catalogImageRemoteUnavailable =>
      'Aperçu de l’image non disponible actuellement.';

  @override
  String get catalogSaveError =>
      'Enregistrement impossible. Vérifiez la connexion et réessayez.';

  @override
  String get catalogDeleteConfirm =>
      'Supprimer ce produit ? Les commandes historiques sont conservées.';

  @override
  String get catalogCategoryName => 'Nom de la catégorie (Français)';

  @override
  String get catalogCategoryActive => 'Visibilité dans le menu';

  @override
  String get catalogCategoryActiveSub => 'Afficher cette catégorie aux clients';

  @override
  String get catalogCategoryDetails => 'Détails de la catégorie';

  @override
  String get catalogCategorySettings => 'Paramètres';

  @override
  String get catalogCategoryCancel => 'Annuler';

  @override
  String get catalogDeleteCategory => 'Supprimer la catégorie';

  @override
  String get catalogDeleteCategoryConfirm =>
      'Supprimer cette catégorie ? Elle doit être vide.';

  @override
  String get catalogStaffReadOnly =>
      'Consultation seule — modifications réservées au propriétaire ou responsable.';

  @override
  String get catalogCategorySearchHint => 'Rechercher une catégorie…';

  @override
  String get catalogFilterTooltip => 'Filtres';

  @override
  String get catalogReorder => 'Réorganiser';

  @override
  String get catalogVisible => 'Visible';

  @override
  String get catalogHidden => 'Masqué';

  @override
  String get catalogMenuAvailability => 'Gérer la disponibilité';

  @override
  String get catalogMenuDelete => 'Supprimer';

  @override
  String get catalogMenuDuplicate => 'Dupliquer';

  @override
  String get duplicateTitle => 'Dupliquer le produit';

  @override
  String get duplicateSource => 'Source';

  @override
  String get duplicateNewName => 'Nouveau nom du produit';

  @override
  String get duplicateNewNameHint =>
      'Veuillez modifier le nom avant de publier la copie.';

  @override
  String get duplicateNamePlaceholder => 'Entrez le nouveau nom';

  @override
  String get duplicateClearName => 'Effacer le nom';

  @override
  String duplicateDefaultName(String name) {
    return 'Copie de $name';
  }

  @override
  String get duplicateCopied => 'Éléments copiés';

  @override
  String get duplicateImage => 'Image du produit';

  @override
  String get duplicateNoImage => 'Image du produit (aucune image)';

  @override
  String duplicatePrice(String price) {
    return 'Prix ($price)';
  }

  @override
  String get duplicateOptions => 'Options et variantes';

  @override
  String get duplicateSaleUnits => 'Unités de vente (non gérées)';

  @override
  String get duplicateNotCopiedLead =>
      'Le statut de disponibilité et l’historique des ventes ';

  @override
  String get duplicateNotCopiedStrong => 'ne seront pas';

  @override
  String get duplicateNotCopiedTail => ' copiés vers le nouveau produit.';

  @override
  String get duplicateUnavailableInfo =>
      'La copie sera créée indisponible afin que vous puissiez la vérifier avant de l’activer.';

  @override
  String get duplicateCancel => 'Annuler';

  @override
  String get duplicateCreate => 'Créer la copie';

  @override
  String get duplicateCreating => 'Création…';

  @override
  String get duplicateNameRequired => 'Le nom ne peut pas être vide.';

  @override
  String get duplicateNameTooLong => 'Maximum 255 caractères.';

  @override
  String get duplicateNetworkError =>
      'Connexion interrompue. Réessayez : la copie ne sera pas créée deux fois.';

  @override
  String get duplicateError =>
      'La copie n’a pas pu être créée et aucun produit n’a été ajouté. Réessayez.';

  @override
  String get duplicateConflict =>
      'Cette demande de copie a déjà servi ailleurs. Rouvrez l’écran puis réessayez.';

  @override
  String get duplicateNotFound =>
      'Produit introuvable. Actualisez le catalogue.';

  @override
  String get duplicateCreated =>
      'Copie créée — indisponible jusqu’à votre vérification.';

  @override
  String get duplicateReplayed => 'Copie déjà créée — ouverture du produit.';

  @override
  String get duplicateForbiddenTitle =>
      'Duplication réservée au propriétaire ou au responsable';

  @override
  String get duplicateBackToCatalog => 'Retour au catalogue';

  @override
  String get catalogMenuViewCategory => 'Voir la catégorie';

  @override
  String get catalogBulkTooltip => 'Disponibilité groupée';

  @override
  String get catalogCategoryInUse =>
      'Cette catégorie contient encore des produits. Déplacez-les ou supprimez-les d’abord.';

  @override
  String get catalogProductInUse =>
      'Ce produit figure dans des commandes passées : il ne peut pas être supprimé. Mettez-le en rupture à la place.';

  @override
  String get catalogVisibilityError =>
      'Impossible de modifier la visibilité. Réessayez.';

  @override
  String get catalogAvailabilityError =>
      'Impossible de modifier la disponibilité. Réessayez.';

  @override
  String get catalogNoResults => 'Aucun produit ne correspond à ces filtres.';

  @override
  String get catalogNoCategoryResults =>
      'Aucune catégorie ne correspond à cette recherche.';

  @override
  String get catalogFiltersTitle => 'Recherche et Filtres';

  @override
  String get catalogFiltersReset => 'Réinitialiser';

  @override
  String get catalogFiltersCategories => 'Catégories';

  @override
  String get catalogFiltersStatus => 'Statut';

  @override
  String get catalogFiltersOutOfStock => 'Rupture de stock';

  @override
  String get catalogFiltersQuality => 'Contrôle qualité';

  @override
  String get catalogFiltersMissingImage => 'Image manquante';

  @override
  String get catalogFiltersPreview => 'Aperçu des résultats';

  @override
  String catalogProductsCount(String n) {
    return '$n produit$n produits';
  }

  @override
  String get catalogFiltersApply => 'Appliquer les filtres';

  @override
  String get catalogCategoryDetailTitle => 'Détails de la catégorie';

  @override
  String catalogDisplayOrder(String n) {
    return 'Ordre d’affichage : $n';
  }

  @override
  String get catalogCategoryProducts => 'Produits';

  @override
  String get catalogCategoryEmpty => 'Aucun produit dans cette catégorie.';

  @override
  String get catalogReorderTitle => 'Réorganiser les catégories';

  @override
  String get catalogReorderHint =>
      'Faites glisser pour modifier l’ordre d’affichage.';

  @override
  String get catalogReorderSave => 'Enregistrer l’ordre';

  @override
  String get catalogReorderSaved => 'Ordre enregistré.';

  @override
  String get catalogReorderPartial =>
      'Certaines catégories n’ont pas pu être déplacées. Réessayez.';

  @override
  String get catalogAvailabilityTitle => 'Disponibilité du produit';

  @override
  String get catalogAvailabilityNote =>
      'Les modifications n’affectent pas les commandes déjà acceptées.';

  @override
  String get catalogAvailabilityState => 'État de disponibilité';

  @override
  String get catalogAvailableOption => 'Disponible';

  @override
  String get catalogAvailableOptionSub =>
      'Visible et commandable immédiatement.';

  @override
  String get catalogOutOfStockOptionSub =>
      'Affiché comme indisponible jusqu’à réactivation manuelle.';

  @override
  String get catalogAvailabilitySave => 'Enregistrer la disponibilité';

  @override
  String get catalogAvailabilitySaved => 'Disponibilité enregistrée.';

  @override
  String get catalogBulkTitle => 'Disponibilité groupée';

  @override
  String get catalogBulkNote =>
      'Les modifications s’appliquent immédiatement sur l’application client. Elles n’affectent pas les commandes en cours.';

  @override
  String get catalogBulkSelection => 'Sélection multiple';

  @override
  String get catalogBulkNewStatus => 'Nouveau statut';

  @override
  String get catalogBulkSelectAll => 'Tout sélectionner';

  @override
  String get catalogBulkClear => 'Effacer la sélection';

  @override
  String get catalogBulkApply => 'Appliquer';

  @override
  String catalogBulkDone(String n) {
    return '$n produit mis à jour.$n produits mis à jour.';
  }

  @override
  String catalogBulkFailed(String n) {
    return '$n produit n’a pas pu être mis à jour.$n produits n’ont pas pu être mis à jour.';
  }

  @override
  String get catalogUncategorized => 'Sans catégorie';

  @override
  String get catalogDeleteTitle => 'Supprimer le produit';

  @override
  String get catalogDeleteWarningTitle =>
      'Un produit déjà commandé ne peut pas être supprimé.';

  @override
  String get catalogDeleteWarningBody =>
      'Les commandes passées gardent leur copie du produit. Si la suppression est refusée, mettez le produit en rupture.';

  @override
  String get catalogDeleteHideOption => 'Mettre en rupture';

  @override
  String get catalogDeleteHideOptionSub =>
      'Le produit reste enregistré et modifiable, mais n’est plus commandable.';

  @override
  String get catalogDeleteRecommended => 'Recommandé';

  @override
  String get catalogDeleteHardOption => 'Supprimer définitivement';

  @override
  String get catalogDeleteHardOptionSub =>
      'Retire le produit, ses variantes et suppléments. Impossible s’il figure dans une commande.';

  @override
  String get catalogDeleteHardConfirm => 'Supprimer définitivement';

  @override
  String get catalogDeleted => 'Produit supprimé.';

  @override
  String get catalogMarkedOutOfStock => 'Produit mis en rupture.';

  @override
  String get catalogVariantsTitle => 'Variantes obligatoires';

  @override
  String get catalogVariantsInfo =>
      'Les variantes obligatoires demandent au client de choisir une option avant d’ajouter le produit au panier.';

  @override
  String get catalogVariantsSubtitle =>
      'Configurez les options requises avant l’ajout au panier.';

  @override
  String get catalogExtrasTitle => 'Suppléments optionnels';

  @override
  String get catalogExtrasSubtitle =>
      'Options facultatives que le client peut ajouter.';

  @override
  String get catalogRequiredTag => 'Obligatoire';

  @override
  String get catalogSingleChoice => 'Sélection unique';

  @override
  String get catalogAddChoice => 'Ajouter un choix';

  @override
  String get catalogAddOption => 'Ajouter une option';

  @override
  String get catalogAddVariantGroup => 'Ajouter un groupe de variantes';

  @override
  String get catalogAddExtrasGroup => 'Nouveau groupe de suppléments';

  @override
  String get catalogNewGroup => 'Nouveau groupe';

  @override
  String get catalogGroupName => 'Nom du groupe (Français)';

  @override
  String get catalogGroupNameHint => 'ex : Sauce';

  @override
  String get catalogOptionName => 'Nom du choix';

  @override
  String get catalogOptionPrice => 'Prix (+)';

  @override
  String get catalogMaxSelectionsLabel => 'Sélections maximum';

  @override
  String get catalogGroupRequiredSwitch => 'Choix obligatoire';

  @override
  String get catalogGroupRequiredSub => 'Le client doit choisir une option.';

  @override
  String get catalogGroupSave => 'Enregistrer le groupe';

  @override
  String get catalogGroupDelete => 'Supprimer le groupe';

  @override
  String get catalogGroupDeleteConfirm =>
      'Supprimer ce groupe et toutes ses options ? Les commandes passées ne sont pas modifiées.';

  @override
  String get catalogOptionDelete => 'Supprimer l’option';

  @override
  String get catalogOptionAvailable => 'Option disponible';

  @override
  String get catalogOptionsEmpty => 'Aucun choix pour le moment.';

  @override
  String get catalogGroupsLoadError =>
      'Impossible de charger les options du produit.';

  @override
  String get catalogGroupInvalid =>
      'Vérifiez le nombre de sélections (minimum ≤ maximum).';

  @override
  String get catalogSaveFirstForOptions =>
      'Enregistrez le produit pour configurer ses variantes et suppléments.';

  @override
  String catalogGroupsCount(String n) {
    return 'Aucun groupe1 groupe$n groupes';
  }

  @override
  String get catalogLastUpdated => 'Dernière mise à jour';

  @override
  String get catalogCustomerPreview => 'Aperçu client';

  @override
  String get catalogEditGroup => 'Modifier le groupe';

  @override
  String get catalogProductDetailTitle => 'Détails du Produit';

  @override
  String get catalogDetailInfo => 'Informations';

  @override
  String get catalogDetailName => 'Nom (Français)';

  @override
  String get catalogDetailPricing => 'Tarification';

  @override
  String get catalogDetailPrice => 'Prix de base';

  @override
  String get catalogDetailAppearance => 'Apparence sur l’application';

  @override
  String get catalogDetailAvailable => 'Produit disponible';

  @override
  String get catalogDetailNoDescription => 'Aucune description.';

  @override
  String get catalogDetailNoOptions =>
      'Aucune variante ni supplément configuré.';

  @override
  String catalogRequiredSummary(String rule) {
    return 'Obligatoire · $rule';
  }

  @override
  String catalogOptionalSummary(String max) {
    return 'Facultatif · Maximum $max';
  }

  @override
  String get catalogCropTitle => 'Image du produit';

  @override
  String get catalogCropTipsTitle => 'Conseils pour une belle photo';

  @override
  String get catalogCropTip1 =>
      'Utilisez un fond neutre et propre (blanc ou bois clair).';

  @override
  String get catalogCropTip2 =>
      'Assurez-vous d’avoir un bon éclairage, de préférence naturel.';

  @override
  String catalogCropTip3(String name) {
    return 'Centrez le produit dans le cadre.Centrez le produit (« $name ») dans le cadre.';
  }

  @override
  String get catalogCropFormat => 'Format : JPG, PNG (max. 2 Mo, min. 400 px)';

  @override
  String get catalogCropUse => 'Utiliser cette image';

  @override
  String get catalogCropRotate => 'Pivoter';

  @override
  String get catalogCropZoom => 'Zoomer';

  @override
  String get catalogCropRemove => 'Supprimer l’image';

  @override
  String get contractFieldUnavailable => 'Non disponible actuellement';

  @override
  String get catalogFieldNameAr => 'Nom du produit (Arabe)';

  @override
  String get catalogFieldDescAr => 'Description (Arabe)';

  @override
  String get catalogFieldPrepTime => 'Temps de prép.';

  @override
  String get catalogFieldSaleUnit => 'Unité de vente';

  @override
  String get sellingUnitTitle => 'Unités de vente';

  @override
  String get sellingUnitCalloutTitle => 'Précision de l’unité';

  @override
  String get sellingUnitCalloutBody =>
      'Choisissez l’unité exacte pour éviter toute confusion lors de la préparation. Cette unité sera affichée aux clients (ex : 1 500 DZD / Plat). Les quantités sont entières : pas de vente au poids.';

  @override
  String get sellingUnitPreviewLabel => 'Aperçu client';

  @override
  String get sellingUnitPreviewNoPrice => '— DZD';

  @override
  String get sellingUnitCommon => 'Unités courantes';

  @override
  String get sellingUnitPackaging => 'Conditionnement';

  @override
  String get sellingUnitNone => 'Aucune unité';

  @override
  String get sellingUnitNoneSub => 'Le prix est affiché sans unité.';

  @override
  String get sellingUnitNotSet => 'Non définie';

  @override
  String get sellingUnitCustomName => 'Nom de l’unité (Français)';

  @override
  String get sellingUnitCustomHint => 'ex : Cornet';

  @override
  String get sellingUnitApply => 'Appliquer l’unité';

  @override
  String get sellingUnitReadOnly =>
      'Seuls le propriétaire et les gérants peuvent modifier l’unité de vente.';

  @override
  String get catalogFieldVariants => 'Variantes obligatoires';

  @override
  String get catalogFieldExtras => 'Suppléments optionnels';

  @override
  String get catalogFieldCategoryNameAr => 'Nom de la catégorie (Arabe)';

  @override
  String get catalogFieldCategoryDesc =>
      'Description de la catégorie (Optionnel)';

  @override
  String get storeCoverTitle => 'Logo et Couverture';

  @override
  String get storeCoverPick => 'Choisir une couverture';

  @override
  String get storeCoverReplace => 'Remplacer';

  @override
  String get storeCoverSave => 'Enregistrer les modifications';

  @override
  String get storeCoverRemove => 'Supprimer';

  @override
  String get storeCoverSection => 'Photo de couverture';

  @override
  String get storeCoverSectionHint =>
      'La photo de couverture doit représenter votre établissement.';

  @override
  String get storeLogoSection => 'Logo du magasin';

  @override
  String get storeLogoSectionHint =>
      'Le logo doit être lisible même en petit format.';

  @override
  String get storeLogoEdit => 'Modifier';

  @override
  String get storeLogoAdd => 'Ajouter';

  @override
  String get storeLogoRemove => 'Supprimer';

  @override
  String get storeLogoEmpty => 'Aucun logo';

  @override
  String get storeLogoPending =>
      'Nouveau logo sélectionné — enregistrez pour l’appliquer.';

  @override
  String get storeLogoTooSmall => 'Logo trop petit. Minimum 128 × 128 pixels.';

  @override
  String get storeLogoTooLarge =>
      'Logo trop lourd. Maximum 1 Mo après compression.';

  @override
  String get storeLogoUploadError => 'Impossible d’envoyer le logo.';

  @override
  String get storeLogoBindPartial =>
      'Envoi réussi, mais le logo n’a pas pu être lié. Réessayez.';

  @override
  String get storeLogoRemoved => 'Logo supprimé.';

  @override
  String get storeLogoRemoveError =>
      'Impossible de supprimer le logo. Réessayez.';

  @override
  String get storeLogoRemoteUnavailable =>
      'Aperçu du logo non disponible actuellement.';

  @override
  String get storeMediaPartialSaved =>
      'Le logo est enregistré, mais la couverture a échoué. Réessayez.';

  @override
  String get storeCoverHint => 'JPEG ou PNG, max. 2 Mo.';

  @override
  String get storeCoverUploadError => 'Impossible d’envoyer la couverture.';

  @override
  String get storeCoverBindPartial =>
      'Envoi réussi, mais la couverture n’a pas pu être liée. Réessayez.';

  @override
  String get storeCoverRemoteUnavailable =>
      'Aperçu de la couverture non disponible actuellement.';

  @override
  String get storeCustomerPreviewTitle => 'Aperçu client';

  @override
  String get storeCustomerPreviewHint =>
      'Notes et délai estimé non disponibles actuellement.';

  @override
  String get storeAddressTitle => 'Contact et Adresse du magasin';

  @override
  String get storeAddressSave => 'Enregistrer les modifications';

  @override
  String get storeAddressConfirmMap => 'Modifier sur la carte';

  @override
  String get storeAddressSaveError =>
      'Enregistrement impossible. Vérifiez la connexion et réessayez.';

  @override
  String get storeAddressBanner =>
      'La modification de l’adresse peut affecter vos zones de livraison et les opérations en cours.';

  @override
  String get storeAddressCoordsSection => 'Coordonnées';

  @override
  String get storeAddressSection => 'Adresse';

  @override
  String get storeAddressPhone => 'Numéro de téléphone';

  @override
  String get storeAddressPhoneHint =>
      'Numéro communiqué aux livreurs pour le retrait.';

  @override
  String get storeAddressDetailed => 'Adresse détaillée';

  @override
  String get storeAddressLocationSummary => 'Emplacement confirmé';

  @override
  String get storeAddressPublicContact => 'Contact public (Optionnel)';

  @override
  String get storeAddressWilaya => 'Wilaya';

  @override
  String get storeAddressCommune => 'Commune';

  @override
  String get adminLocationChoose => 'Sélectionner';

  @override
  String get adminLocationSearchHint => 'Rechercher…';

  @override
  String get adminLocationEmpty => 'Aucun résultat';

  @override
  String get adminLocationLoadError =>
      'Impossible de charger la liste. Réessayez.';

  @override
  String get adminLocationRetry => 'Réessayer';

  @override
  String get adminLocationWilayaRequired => 'Sélectionnez d’abord une wilaya.';

  @override
  String get adminLocationPairRequired =>
      'Wilaya et commune sont obligatoires.';

  @override
  String get storeAddressPickupHints => 'Instructions de retrait';

  @override
  String get storeProfileMediaSub => 'Logo et photo de couverture';

  @override
  String get storeProfileMediaUnavailable => 'Indisponible';

  @override
  String get storeProfilePrepUnavailable => 'Indisponible';

  @override
  String get storeProfilePreviewUnavailable => 'Aperçu client indisponible.';

  @override
  String get profileSettingsTitle => 'Paramètres';

  @override
  String get storeProfileTitle => 'Profil magasin';

  @override
  String get storeProfileCustomerPreview => 'Aperçu client';

  @override
  String get storeProfileGeneral => 'Informations générales';

  @override
  String get storeProfileGeneralSub => 'Nom et statut du commerce';

  @override
  String get storeGeneralTitle => 'Informations générales';

  @override
  String get storeGeneralBranchName => 'Nom de l’établissement';

  @override
  String get storeGeneralBranchNameHint =>
      'Affiché aux clients pour cet établissement.';

  @override
  String get storeGeneralMerchantName => 'Nom du commerce';

  @override
  String get storeGeneralMerchantLocked =>
      'Nom vérifié par SpeedyGo : non modifiable ici.';

  @override
  String get storeGeneralReadOnly =>
      'Seuls le propriétaire et le gérant peuvent modifier ces informations.';

  @override
  String get storeGeneralPhoneElsewhere =>
      'Le téléphone se modifie dans « Adresse et Emplacement ».';

  @override
  String get storeGeneralSave => 'Enregistrer';

  @override
  String get storeGeneralSaved =>
      'Informations de l’établissement enregistrées.';

  @override
  String get storeGeneralNameAr => 'Nom en arabe';

  @override
  String get storeGeneralNameArHint =>
      'Optionnel. Affiché aux clients arabophones.';

  @override
  String get storeGeneralDescription => 'Description courte';

  @override
  String get storeGeneralDescriptionHint =>
      'Optionnel. Présentez votre établissement en quelques phrases.';

  @override
  String get storeGeneralPublicEmail => 'E-mail public';

  @override
  String get storeGeneralPublicEmailHint =>
      'Optionnel. Adresse de contact visible par les clients.';

  @override
  String get storeGeneralEmailInvalid => 'Adresse e-mail invalide.';

  @override
  String get storeGeneralPreviewTitle => 'Aperçu client';

  @override
  String get storeGeneralPreviewOpen => 'Ouvert';

  @override
  String get storeGeneralPreviewClosed => 'Fermé';

  @override
  String get storeProfileCategory => 'Catégorie de l’établissement';

  @override
  String get storeProfileCategorySub => 'Type de commerce affiché aux clients';

  @override
  String get storeCategoryTitle => 'Catégorie de l’établissement';

  @override
  String get storeCategorySubtitle =>
      'Choisissez la catégorie qui décrit le mieux votre activité.';

  @override
  String get storeCategorySearch => 'Rechercher une catégorie...';

  @override
  String get storeCategoryInfo =>
      'Une seule catégorie par établissement. Elle détermine où il apparaît dans l’application client.';

  @override
  String get storeCategoryReadOnly =>
      'Seuls le propriétaire et les gérants peuvent modifier la catégorie.';

  @override
  String get storeCategorySave => 'Enregistrer';

  @override
  String get storeCategoryClear => 'Retirer la catégorie';

  @override
  String get storeCategorySaved => 'Catégorie enregistrée.';

  @override
  String get storeCategoryCleared => 'Catégorie retirée.';

  @override
  String get storeCategoryNotSet => 'Non définie';

  @override
  String get storeCategoryEmpty =>
      'Aucune catégorie disponible pour le moment.';

  @override
  String get storeCategoryNoMatch => 'Aucune catégorie ne correspond.';

  @override
  String get storeCategoryLoadError => 'Impossible de charger les catégories.';

  @override
  String get storeCategorySaveError => 'Enregistrement impossible. Réessayez.';

  @override
  String get storeCategoryForbidden =>
      'Votre rôle ne permet pas de modifier cet établissement.';

  @override
  String get storeCategoryRestricted =>
      'Le statut du commerce ne permet pas cette modification.';

  @override
  String get storeGeneralNameRequired => 'Le nom ne peut pas être vide.';

  @override
  String get storeGeneralSaveError => 'Enregistrement impossible. Réessayez.';

  @override
  String get storeGeneralForbidden =>
      'Votre rôle ne permet pas de modifier cet établissement.';

  @override
  String get storeGeneralRestricted =>
      'Le statut du commerce ne permet pas cette modification.';

  @override
  String get storeProfileMedia => 'Médias et Logos';

  @override
  String get storeProfileAddress => 'Adresse et Emplacement';

  @override
  String get storeProfileAddressSub => 'Téléphone, adresse et position GPS';

  @override
  String get storeProfileHours => 'Horaires d’ouverture';

  @override
  String get storeProfileHoursSub => 'Jours d’ouverture, pauses';

  @override
  String get storeProfilePrep => 'Paramètres de préparation';

  @override
  String get storeProfileSettings => 'Paramètres du compte';

  @override
  String get storeProfileSettingsSub => 'Compte, préférences, déconnexion';

  @override
  String get storeProfileNotifications => 'Notifications';

  @override
  String get storeProfileNotificationsSub => 'Centre d’alertes';

  @override
  String get openingHoursTitle => 'Horaires d’ouverture';

  @override
  String get openingHoursEmpty =>
      'Aucun horaire configuré pour cet établissement.';

  @override
  String get openingHoursSave => 'Enregistrer les horaires';

  @override
  String get openingHoursSaved => 'Horaires enregistrés.';

  @override
  String get openingHoursLoadError => 'Impossible de charger les horaires.';

  @override
  String get openingHoursSaveError => 'Impossible d’enregistrer les horaires.';

  @override
  String get openingHoursInvalid =>
      'Horaires refusés : vérifiez les chevauchements, y compris après minuit.';

  @override
  String get openingHoursConflict =>
      'Les horaires ont changé ailleurs. Rechargement effectué — vérifiez puis réessayez.';

  @override
  String get openingHoursClosed => 'Fermé';

  @override
  String get openingHoursUsual => 'Horaires habituels';

  @override
  String get openingHoursNotConfigured => 'Aucun horaire configuré';

  @override
  String get openingHoursOpenNow => 'Ouvert actuellement';

  @override
  String get openingHoursClosedNow => 'Fermé actuellement';

  @override
  String get openingHoursInfo =>
      'Les clients peuvent commander uniquement pendant vos heures d’ouverture. Les modifications sont appliquées dès l’enregistrement.';

  @override
  String get openingHoursStaffReadOnly =>
      'Lecture seule : seuls le propriétaire et les gérants peuvent modifier les horaires.';

  @override
  String get openingHoursOpens => 'Ouverture';

  @override
  String get openingHoursCloses => 'Fermeture';

  @override
  String get openingHoursEditorHint =>
      'Jusqu’à 3 plages par jour. Une fermeture avant l’ouverture se termine le lendemain.';

  @override
  String get openingHoursAddRange => 'Ajouter une plage';

  @override
  String get openingHoursRemoveRange => 'Supprimer la plage';

  @override
  String get openingHoursApply => 'Appliquer';

  @override
  String get openingHoursNextDay => 'Se termine le lendemain';

  @override
  String get openingHoursAllDay => 'Ouvert 24 h/24';

  @override
  String get openingHoursDayClosedHint => 'Aucune plage : le jour sera fermé.';

  @override
  String get openingHoursIssueOverlap => 'Les plages se chevauchent.';

  @override
  String get openingHoursIssueZero =>
      'L’ouverture et la fermeture doivent être différentes (00:00–00:00 pour 24 h).';

  @override
  String get openingHoursIssueTooMany => 'Maximum 3 plages par jour.';

  @override
  String get hoursExceptionsTitle => 'Horaires exceptionnels';

  @override
  String get hoursExceptionsNavSub => 'Jours fériés, fermetures ponctuelles';

  @override
  String get hoursExceptionsBanner =>
      'Ces horaires remplacent vos horaires habituels uniquement pour les dates sélectionnées.';

  @override
  String get hoursExceptionsUpcoming => 'Exceptions à venir';

  @override
  String get hoursExceptionsEmpty => 'Aucune exception à venir.';

  @override
  String get hoursExceptionsAdd => 'Ajouter une exception';

  @override
  String get hoursExceptionsEdit => 'Modifier l’exception';

  @override
  String get hoursExceptionsDate => 'Date';

  @override
  String get hoursExceptionsDateHint => 'Sélectionner une date';

  @override
  String get hoursExceptionsDateTaken =>
      'Cette date a déjà une exception : l’enregistrement la remplacera.';

  @override
  String get hoursExceptionsStatus => 'Statut';

  @override
  String get hoursExceptionsOpen => 'Ouvert';

  @override
  String get hoursExceptionsClosed => 'Fermé';

  @override
  String get hoursExceptionsHours => 'Horaires modifiés';

  @override
  String get hoursExceptionsTo => 'à';

  @override
  String get hoursExceptionsLabel => 'Motif';

  @override
  String get hoursExceptionsLabelHint => 'ex : Jour férié, Travaux…';

  @override
  String get hoursExceptionsMessage => 'Message pour les clients (Optionnel)';

  @override
  String get hoursExceptionsMessageHint =>
      'Enregistré avec l’exception. Pas encore affiché dans l’application client.';

  @override
  String get hoursExceptionsCancel => 'Annuler';

  @override
  String get hoursExceptionsSave => 'Enregistrer les horaires';

  @override
  String get hoursExceptionsSaved => 'Exception enregistrée.';

  @override
  String get hoursExceptionsDeleted => 'Exception supprimée.';

  @override
  String get hoursExceptionsDeleteTitle => 'Supprimer l’exception ?';

  @override
  String hoursExceptionsDeleteBody(String date) {
    return 'Le $date reprendra vos horaires habituels.';
  }

  @override
  String get hoursExceptionsDeleteConfirm => 'Supprimer';

  @override
  String get hoursExceptionsLoadError =>
      'Impossible de charger les horaires exceptionnels.';

  @override
  String get hoursExceptionsSaveError =>
      'Impossible d’enregistrer l’exception. Vos saisies sont conservées.';

  @override
  String get hoursExceptionsDeleteError =>
      'Impossible de supprimer l’exception. Réessayez.';

  @override
  String get hoursExceptionsConflict =>
      'Cette date a été modifiée ailleurs. La liste a été rechargée : vérifiez puis enregistrez à nouveau.';

  @override
  String get hoursExceptionsInvalid =>
      'Exception refusée : vérifiez la date (aujourd’hui à +365 jours) et les plages.';

  @override
  String get hoursExceptionsWeeklyRequired =>
      'Configurez d’abord les horaires habituels.';

  @override
  String get hoursExceptionsTooMany =>
      'Trop d’exceptions à venir (100 maximum).';

  @override
  String get hoursExceptionsStaffReadOnly =>
      'Lecture seule : seuls le propriétaire et les gérants peuvent modifier les horaires exceptionnels.';

  @override
  String get hoursExceptionsDateRequired => 'Sélectionnez une date.';

  @override
  String get hoursExceptionsLabelRequired => 'Indiquez un motif.';

  @override
  String get hoursExceptionsIntervalsRequired =>
      'Ajoutez au moins une plage horaire.';

  @override
  String get hoursExceptionsSameDay =>
      'Chaque plage doit finir le même jour (00:00 = minuit).';

  @override
  String get hoursExceptionsHelpTitle => 'Ordre d’application';

  @override
  String get hoursExceptionsHelpBody =>
      'Une fermeture forcée ou temporaire de l’établissement s’applique toujours en premier. Sinon, une exception remplace les horaires habituels pour sa date (heure d’Alger). Les autres jours suivent les horaires habituels.';

  @override
  String get hoursExceptionsHelpOk => 'Compris';

  @override
  String hoursExceptionsToday(String label) {
    return 'Exception aujourd’hui : $label';
  }

  @override
  String get availabilityTitle => 'État du magasin';

  @override
  String get availabilityEstablishment => 'Établissement';

  @override
  String get availabilityOpen => 'Ouvert';

  @override
  String get availabilityClosed => 'Fermé';

  @override
  String get availabilityFollowSchedule => 'Selon les horaires';

  @override
  String get availabilityForceClosed => 'Fermé';

  @override
  String get availabilitySave => 'Enregistrer les modifications';

  @override
  String get availabilitySaving => 'Enregistrement…';

  @override
  String get availabilitySaved => 'État du magasin enregistré.';

  @override
  String get availabilityClosureSaved => 'Fermeture enregistrée.';

  @override
  String get availabilityLoadError =>
      'Impossible de charger l’état du magasin.';

  @override
  String get availabilitySaveError =>
      'Impossible d’enregistrer l’état du magasin.';

  @override
  String get availabilityConflict =>
      'L’état a changé ailleurs. Rechargement effectué — vérifiez puis réessayez.';

  @override
  String get availabilityReopenTitle => 'Rouvrir selon les horaires';

  @override
  String get availabilityReopenOutsideHoursBody =>
      'Vous êtes hors des horaires hebdomadaires. Le magasin restera Fermé jusqu’à la prochaine ouverture prévue.';

  @override
  String get availabilityConfirmReopen => 'Confirmer';

  @override
  String get availabilityToday => 'Aujourd’hui';

  @override
  String get availabilityClosedToday => 'Fermé aujourd’hui';

  @override
  String get availabilityModifyHours => 'Modifier';

  @override
  String get availabilityQuickPause => 'Pause rapide';

  @override
  String get availabilityQuickPauseHint =>
      'Fermer temporairement pour un rush en cuisine.';

  @override
  String get availabilityPause30 => '30 MIN';

  @override
  String get availabilityPause60 => '1 HEURE';

  @override
  String get availabilityActiveOrdersUnknown => 'Commandes en cours';

  @override
  String get availabilityCloseWarningTitle => 'Attention : fermeture immédiate';

  @override
  String get availabilityStaffReadOnly =>
      'Lecture seule : seuls le propriétaire et les gérants peuvent modifier l’état du magasin.';

  @override
  String get availabilityBannerOpenTitle => 'Magasin en ligne';

  @override
  String get availabilityBannerOpenBody =>
      'Les clients peuvent passer commande et voir votre menu normalement.';

  @override
  String get availabilityBannerClosedTitle => 'Magasin hors ligne';

  @override
  String get availabilityBannerClosedBody =>
      'Les clients ne peuvent plus passer de nouvelles commandes.';

  @override
  String get availabilityBannerScheduleClosedTitle =>
      'Selon les horaires — actuellement fermé';

  @override
  String get availabilityBannerScheduleClosedBody =>
      'Le magasin suit le planning. Il s’ouvrira automatiquement aux prochaines heures.';

  @override
  String get availabilityReasonPeak => 'Forte charge (cuisine)';

  @override
  String get availabilityReasonTechnical => 'Problème technique';

  @override
  String get availabilityReasonStock => 'Rupture de stock';

  @override
  String get availabilityReasonLunch => 'Pause déjeuner';

  @override
  String get temporaryClosureTitle => 'Fermeture temporaire';

  @override
  String get temporaryClosureActionRequired => 'Action requise';

  @override
  String get temporaryClosureImpactLead =>
      'La fermeture suspendra l’acceptation de nouvelles commandes. ';

  @override
  String get temporaryClosureImpactNone => 'Aucune commande en cours.';

  @override
  String get temporaryClosureImpactUnknown =>
      'Les commandes en cours seront maintenues et doivent être préparées.';

  @override
  String get temporaryClosureReason => 'Motif de la fermeture';

  @override
  String get temporaryClosureReopen => 'Réouverture prévue';

  @override
  String get temporaryClosure30m => 'Dans 30 minutes';

  @override
  String get temporaryClosure1h => 'Dans 1 heure';

  @override
  String get temporaryClosurePickTime => 'Choisir une heure…';

  @override
  String get temporaryClosureIndefinite => 'Indéfinie (Manuel)';

  @override
  String get temporaryClosureImageImpact =>
      'Impact sur votre visibilité : Les clients verront votre établissement comme « Fermé temporairement ».';

  @override
  String get temporaryClosureStaffReadOnly =>
      'Seuls le propriétaire et les gérants peuvent fermer le magasin.';

  @override
  String get temporaryClosurePastTime =>
      'L’heure de réouverture est déjà passée. Choisissez une nouvelle heure.';

  @override
  String get temporaryClosureMessage => 'Message client';

  @override
  String get temporaryClosureOptional => 'Facultatif';

  @override
  String get temporaryClosureMessageHint =>
      'Ex: Nous sommes complets pour le moment, revenez dans 30 minutes !';

  @override
  String get temporaryClosureManualReopenHint =>
      'Vous pourrez rouvrir manuellement à tout moment.';

  @override
  String get temporaryClosureConfirm => 'Confirmer la fermeture';

  @override
  String get storeProfileAvailability => 'État du magasin';

  @override
  String get storeProfileAvailabilitySub =>
      'Selon les horaires, fermeture, pause';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Aucune notification pour le moment.';

  @override
  String get notificationsLoadError =>
      'Impossible de charger les notifications.';

  @override
  String get notificationsToday => 'Aujourd’hui';

  @override
  String get notificationsYesterday => 'Hier';

  @override
  String get notificationsJustNow => 'À l’instant';

  @override
  String get notificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notificationsFilterAll => 'Tout';

  @override
  String get notificationsFilterOrders => 'Commandes';

  @override
  String get notificationsOpenDetails => 'Détails';

  @override
  String get notificationsOrderStale =>
      'Cette commande n’est plus en attente d’acceptation.';

  @override
  String get alertNewOrder => 'NOUVELLE COMMANDE';

  @override
  String get alertReceivedAt => 'Reçue à';

  @override
  String get alertPayment => 'Paiement';

  @override
  String get alertViewDetails => 'Voir les détails';

  @override
  String get alertRefuse => 'Refuser';

  @override
  String get alertItems => 'Articles';

  @override
  String get alertOrderTotal => 'Sous-total marchandises';

  @override
  String get alertOrderLabel => 'Commande';

  @override
  String get alertDismiss => 'Fermer';

  @override
  String get alertSeeList => 'Voir la liste';

  @override
  String get notifSettingsTitle => 'Paramètres de notification';

  @override
  String get notifSettingsScreenTitle => 'Alertes';

  @override
  String get notifSettingsOsEnabled =>
      'Permission iOS autorisée. Le Push natif n’est pas encore actif.';

  @override
  String get notifSettingsOsDenied =>
      'Permission iOS refusée (modifiable dans Réglages). Le Push natif n’est pas encore actif.';

  @override
  String get notifSettingsOsNotAsked =>
      'Permission de notification : pas encore autorisée.';

  @override
  String get notifSettingsOsOpen => 'Paramètres système';

  @override
  String get notifSettingsSwitchesNote =>
      'Uniquement quand l’application est ouverte.';

  @override
  String get notifSettingsInAppSection => 'DANS L’APPLICATION';

  @override
  String get notifSettingsCriticalWarning =>
      'Les commandes entrantes critiques ne peuvent pas être totalement réduites au silence sans risque de retard.';

  @override
  String get notifSettingsPushNotConfigured => 'Non configuré';

  @override
  String get notifSettingsSoundSection => 'ALERTES SONORES';

  @override
  String get notifSettingsSound => 'Sonnerie des nouvelles commandes';

  @override
  String get notifSettingsVibrationSection => 'VIBRATIONS';

  @override
  String get notifSettingsVibration => 'Vibration lors d’une commande';

  @override
  String get notifSettingsPushSection => 'ALERTES PUSH';

  @override
  String get notifSettingsOsEnabledPush =>
      'Permission de notification : autorisée.';

  @override
  String get notifSettingsOsDeniedPush =>
      'Permission de notification refusée : activez-la dans les réglages système.';

  @override
  String get notifSettingsNativePush => 'Notifications hors application';

  @override
  String get notifSettingsNativePushSub =>
      'Application fermée ou en arrière-plan.';

  @override
  String get notifSettingsLockScreenNote =>
      'Aperçu sur l’écran verrouillé : selon les réglages système.';

  @override
  String get notifPushStatusRegistered =>
      'Cet appareil est enregistré pour les notifications.';

  @override
  String get notifPushStatusPending => 'Enregistrement de l’appareil…';

  @override
  String get notifPushStatusDenied =>
      'Permission refusée : pas de notification hors application.';

  @override
  String get notifPushStatusDisabled => 'Désactivées sur cet appareil.';

  @override
  String get notifPushStatusTokenUnavailable =>
      'Jeton de notification indisponible sur cet appareil.';

  @override
  String get notifPushStatusFailed =>
      'Enregistrement impossible pour le moment. Réessayez plus tard.';

  @override
  String get pushOrderInaccessible =>
      'Cette commande n’est pas accessible avec ce compte.';

  @override
  String get notifSettingsForeground => 'Alertes dans l’application';

  @override
  String get notifSettingsPushUnavailable =>
      'Les notifications hors application ne sont pas encore disponibles.';

  @override
  String get notifSettingsPushBlocked =>
      'Push natif (APNs/FCM) non configuré : la permission iOS ne suffit pas.';

  @override
  String get notifSettingsSave => 'Enregistrer les paramètres';

  @override
  String get notifSettingsSaved => 'Paramètres enregistrés.';

  @override
  String get profileRole => 'Rôle';

  @override
  String get profileMerchant => 'Commerce';

  @override
  String get profileBranch => 'Établissement';

  @override
  String get profileRoleOwner => 'Propriétaire';

  @override
  String get profileRoleManager => 'Responsable';

  @override
  String get profileRoleStaff => 'Équipe';

  @override
  String get profileSectionAccount => 'Compte';

  @override
  String get profileSectionStore => 'Établissement';

  @override
  String get profileSectionOps => 'Opérations du magasin';

  @override
  String get profileSectionPrefs => 'Préférences';

  @override
  String get profileSectionSupport => 'Support & légal';

  @override
  String get profileInfoReadonly => 'Informations du commerce';

  @override
  String get profileBranchStatus => 'Statut opérationnel';

  @override
  String get profileUnavailableItem => 'Non disponible dans cette version';

  @override
  String get switchBranch => 'Changer d’établissement';

  @override
  String get logoutConfirmTitle => 'Déconnexion';

  @override
  String get logoutConfirmBody =>
      'Voulez-vous vraiment vous déconnecter de SpeedyGo Merchant ?';

  @override
  String get logoutConfirmAction => 'Déconnexion';

  @override
  String get settingsProfileRow => 'Profil';

  @override
  String get settingsNotificationsOff => 'Désactivé';

  @override
  String get settingsSupportSection => 'Support';

  @override
  String get settingsHelpCenter => 'Centre d’aide';

  @override
  String get logoutConnected => 'Connecté';

  @override
  String get logoutWarningTitle => 'Attention aux opérations en cours';

  @override
  String get logoutActiveOrders => 'Commandes en cours';

  @override
  String get logoutStoreState => 'État du magasin';

  @override
  String get logoutStoreOpen => 'Ouvert';

  @override
  String get logoutStoreClosed => 'Fermé';

  @override
  String get logoutHandoverAdvice =>
      'Assurez-vous qu’un autre gestionnaire est disponible pour traiter les commandes avant de vous déconnecter.';

  @override
  String get logoutDataPreserved =>
      'Vos données, le catalogue et l’historique des commandes seront préservés.';

  @override
  String get logoutCancel => 'Annuler et retourner';

  @override
  String get cancel => 'Annuler';

  @override
  String get attentionRequired =>
      'Certaines pièces nécessitent votre attention.';

  @override
  String get submitVerification => 'Soumettre le dossier';

  @override
  String get submitVerificationUnavailable =>
      'La soumission n’est pas encore possible : des pièces obligatoires manquent ou sont incomplètes.';

  @override
  String get permissionDenied => 'Permission refusée par le serveur.';

  @override
  String get regTitle => 'Inscription';

  @override
  String get regStepOf => 'Étape';

  @override
  String get regAccountTitle => 'Configuration du compte';

  @override
  String get regRoleLabel => 'Rôle';

  @override
  String get regOwner => 'Propriétaire';

  @override
  String get regOperator => 'Opérateur';

  @override
  String get regOwnerHint =>
      'Créez et gérez votre commerce en tant que propriétaire.';

  @override
  String get regOperatorHint =>
      'Rejoindre un commerce existant nécessite une invitation et le code remis par le propriétaire.';

  @override
  String get regOperatorUnsupported =>
      'Pour rejoindre un commerce, ouvrez vos invitations reçues et saisissez le code remis par le propriétaire. SpeedyGo n’envoie pas de SMS.';

  @override
  String get regOperatorOpenInvitations => 'Voir mes invitations';

  @override
  String get regSelectRole => 'Choisissez un rôle pour continuer.';

  @override
  String get regContactTitle => 'Contact';

  @override
  String get regAccountContinue => 'Continuer l’inscription';

  @override
  String get regVerifiedPhone => 'Numéro de téléphone (vérifié)';

  @override
  String get regVerifiedPhoneHint =>
      'Ce numéro a été vérifié lors de la connexion. Il n’est pas modifiable ici.';

  @override
  String get regEmailUnsupported =>
      'L’e-mail ne peut pas être enregistré à cette étape.';

  @override
  String get regConsentUnsupported =>
      'Consultez les conditions générales et la politique de confidentialité SpeedyGo avant de continuer.';

  @override
  String get regActivityTitle => 'Informations du commerce';

  @override
  String get regActivityBody =>
      'Indiquez le nom sous lequel votre commerce sera identifié.';

  @override
  String get regLegalIdUnsupported =>
      'Les pièces d’identité professionnelle se déposent à l’étape Documents.';

  @override
  String get regDocsTitle => 'Documents d’entreprise';

  @override
  String get regDocsBody => 'Ajoutez les documents demandés.';

  @override
  String get regDocsRequired =>
      'Téléversez toutes les pièces obligatoires avant de continuer.';

  @override
  String get regDocsTipsTitle => 'Conseils pour une capture nette';

  @override
  String get regDocsTipLight =>
      'Privilégiez un éclairage naturel et uniforme pour éviter les zones d’ombre.';

  @override
  String get regDocsTipFrame =>
      'Cadrez bien le document : tous les coins doivent être visibles.';

  @override
  String get regDocsFormats =>
      'Formats acceptés : PDF, JPEG ou PNG (10 Mo max).';

  @override
  String get regDocsContinue => 'Continuer';

  @override
  String get regDocsContinueFinal => 'Continuer vers l’étape finale';

  @override
  String get regDocsAppBar => 'Vérification';

  @override
  String get regDocsTipFlash =>
      'Désactivez le flash pour éviter les reflets sur les surfaces plastifiées.';

  @override
  String get regDocsPrivacy =>
      'Vos documents sont transmis à SpeedyGo uniquement pour la vérification de votre commerce.';

  @override
  String get regFileTooLarge => 'Fichier trop volumineux (max. 10 Mo).';

  @override
  String get regFileTypeUnsupported =>
      'Format non accepté. Utilisez PDF, JPEG ou PNG.';

  @override
  String get regPickerUnavailable =>
      'Impossible d’ouvrir le sélecteur de fichiers. Réessayez après avoir relancé l’application.';

  @override
  String get regPickDocument => 'Ajouter';

  @override
  String get regReplaceDocument => 'Remplacer';

  @override
  String get regEstablishmentTitle => 'Détails de l’établissement';

  @override
  String get regEstablishmentBody =>
      'Renseignez les informations de votre établissement.';

  @override
  String get regIdentitySection => 'Nom de l’établissement';

  @override
  String get regBranchNameFrLabel => 'Nom de l’établissement';

  @override
  String get regCommerceContext => 'Commerce';

  @override
  String get regContactSection => 'Contact de l’établissement';

  @override
  String get regCategorySection => 'Catégorie';

  @override
  String get regCategoryReadonly =>
      'La catégorie sera attribuée après vérification.';

  @override
  String get regAddressSection => 'Adresse et emplacement';

  @override
  String get regAddressGuidance =>
      'Saisissez l’adresse de votre établissement.';

  @override
  String get regAddressExactLabel => 'Adresse exacte';

  @override
  String get regPickupPlace => 'Lieu de retrait';

  @override
  String get regChooseOnMap => 'Choisir sur la carte';

  @override
  String get regLocationConfirmed => 'Position confirmée';

  @override
  String get regLocationEdit => 'Modifier';

  @override
  String get regLocationRequired =>
      'Confirmez le lieu de retrait sur la carte avant de continuer.';

  @override
  String get regLocationPickerTitle => 'Position du magasin';

  @override
  String get regLocationConfirm => 'Confirmer l’emplacement';

  @override
  String get regLocationUseGps => 'Utiliser ma position';

  @override
  String get regLocationMoveHint =>
      'Déplacez la carte pour placer le pin sur le lieu de retrait, ou utilisez votre position GPS.';

  @override
  String get regLocationGpsSuggestion =>
      'Position GPS proposée — confirmez uniquement si c’est le lieu de retrait de l’établissement.';

  @override
  String get regLocationDenied =>
      'Autorisation de localisation refusée. Placez le pin manuellement sur la carte.';

  @override
  String get regLocationDeniedForever =>
      'Localisation désactivée pour SpeedyGo. Activez-la dans Réglages, ou placez le pin manuellement.';

  @override
  String get regLocationServicesDisabled =>
      'Les services de localisation sont désactivés. Placez le pin manuellement sur la carte.';

  @override
  String get regLocationUnavailable =>
      'Position GPS indisponible. Placez le pin manuellement sur la carte.';

  @override
  String get regBranchPhoneLabel => 'Numéro de téléphone';

  @override
  String get regBranchPhoneHint =>
      'Numéro de contact de l’établissement (distinct du numéro de connexion).';

  @override
  String get regPreviewLabel => 'Aperçu (données saisies — non publié)';

  @override
  String get regBranchIncomplete =>
      'Nom, téléphone et adresse de l’établissement sont requis.';

  @override
  String get regCoordsInvalid =>
      'Latitude (−90…90) et longitude (−180…180) invalides.';

  @override
  String get regCoordsConfirmHint =>
      'Indiquez le lieu de retrait sur la carte, puis confirmez.';

  @override
  String get regReviewTitle => 'Révision';

  @override
  String get regReviewDocsTitle => 'Documents légaux';

  @override
  String get regReviewBranchTitle => 'Établissement';

  @override
  String get regReviewLocation => 'Localisation';

  @override
  String get regReviewBody =>
      'Veuillez vérifier attentivement vos informations avant la soumission finale pour éviter tout retard de validation.';

  @override
  String get regSubmit => 'Soumettre pour vérification';

  @override
  String get regCorrectionTitle => 'Correction du dossier';

  @override
  String get regCorrectionActionRequired => 'Action requise';

  @override
  String get regCorrectionDetails => 'Détails du dossier';

  @override
  String get regCorrectionSubmit => 'Soumettre les corrections';

  @override
  String get regContinue => 'Continuer';

  @override
  String get regEdit => 'Modifier';

  @override
  String get regMissingSteps => 'Complétez votre dossier';

  @override
  String get regRejectionNoReason =>
      'Des corrections sont nécessaires. Mettez à jour les pièces concernées puis soumettez à nouveau.';

  @override
  String get regApprovedNext =>
      'Votre commerce est approuvé. Complétez ensuite horaires et catalogue lorsque disponibles.';

  @override
  String get legalSectionTitle => 'Conditions et déclaration';

  @override
  String get legalSectionBody =>
      'Avant de soumettre, lisez et acceptez les conditions suivantes. Votre acceptation est enregistrée avec le dossier.';

  @override
  String get legalTermsLabel =>
      'J’ai lu et j’accepte les conditions générales marchand SpeedyGo.';

  @override
  String get legalDeclarationLabel =>
      'Je certifie que les informations et les documents du dossier sont exacts et complets.';

  @override
  String legalVersionTag(String version) {
    return 'Version $version';
  }

  @override
  String get legalLoading => 'Chargement des conditions…';

  @override
  String get legalLoadFailed =>
      'Impossible de charger les conditions. Vérifiez votre connexion puis réessayez.';

  @override
  String get legalIncomplete =>
      'Les conditions ne sont pas disponibles pour le moment. Réessayez plus tard.';

  @override
  String get legalRetry => 'Réessayer';

  @override
  String get legalConsentRequired =>
      'Acceptez les conditions et la déclaration d’exactitude pour soumettre le dossier.';

  @override
  String get legalVersionOutdated =>
      'Les conditions ont été mises à jour. Relisez-les puis acceptez à nouveau avant de soumettre.';

  @override
  String get legalConsentHint =>
      'Cochez les deux cases pour activer la soumission.';

  @override
  String get legalContentLink => 'Référence du texte';

  @override
  String get issuesTitle => 'Points à corriger';

  @override
  String get issuesApplicationTitle => 'Informations du dossier';

  @override
  String get issuesDocumentTitle => 'Documents à remplacer';

  @override
  String get issuesReplaceDocument => 'Remplacer ce document';

  @override
  String get issuesResolved => 'Corrigé';

  @override
  String get issuesFixHint =>
      'Corrigez les points ci-dessus (remplacez les documents concernés si indiqué), acceptez à nouveau les conditions, puis soumettez le dossier.';

  @override
  String issuesRemaining(String count) {
    return '1 point restant à corriger$count points restants à corriger';
  }

  @override
  String get dossierAttemptLabel => 'Tentative n°';

  @override
  String get dossierSubmittedAtLabel => 'Soumis le';

  @override
  String get dossierReviewedAtLabel => 'Examiné le';

  @override
  String get dossierConsentLabel => 'Conditions acceptées';

  @override
  String dossierConsentVersions(String terms, String declaration) {
    return 'Conditions $terms · Déclaration $declaration';
  }

  @override
  String get settingsTeamRow => 'Gestion de l’équipe';

  @override
  String get settingsTeamInvitationsRow => 'Invitations reçues';

  @override
  String get teamTitle => 'Personnel et Accès';

  @override
  String get teamStoreContext => 'Gestion de l’équipe';

  @override
  String get teamActiveMembers => 'Membres actifs';

  @override
  String get teamPendingInvitations => 'Invitations en attente';

  @override
  String get teamRolesSummary => 'Résumé des rôles';

  @override
  String get teamRoleOwner => 'Propriétaire';

  @override
  String get teamRoleManager => 'Gestionnaire';

  @override
  String get teamRoleStaff => 'Équipe';

  @override
  String get teamOwnerBadge => 'Admin';

  @override
  String get teamSelfBadge => 'Vous';

  @override
  String get teamPhoneUnavailable => 'Numéro indisponible';

  @override
  String get teamRevoke => 'Révoquer';

  @override
  String get teamChangeRole => 'Modifier le rôle';

  @override
  String get teamRegenerateCode => 'Régénérer le code';

  @override
  String get teamCancelInvitation => 'Annuler';

  @override
  String get teamInviteMember => 'Inviter un membre';

  @override
  String get teamInvitationExpired => 'Expirée';

  @override
  String teamRoleLine(String role) {
    return 'Rôle : $role';
  }

  @override
  String teamExpiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String get teamEmptyMembers => 'Aucun membre actif pour le moment.';

  @override
  String get teamEmptyInvitations => 'Aucune invitation en attente.';

  @override
  String get teamLoadError =>
      'Impossible de charger l’équipe. Vérifiez votre connexion puis réessayez.';

  @override
  String get teamForbiddenTitle => 'Accès réservé';

  @override
  String get teamForbiddenBody =>
      'La gestion de l’équipe est réservée aux propriétaires et aux gestionnaires.';

  @override
  String get teamSummaryOwner =>
      'Invite, modifie les rôles et révoque l’accès des membres.';

  @override
  String get teamSummaryManager =>
      'Consulte la liste de l’équipe et les invitations. Ne peut ni inviter, ni modifier les rôles, ni révoquer.';

  @override
  String get teamSummaryStaff => 'N’a pas accès à la gestion de l’équipe.';

  @override
  String get teamSummaryScope =>
      'Les accès couvrent tous les établissements du commerce : il n’existe pas d’accès par établissement.';

  @override
  String get teamInviteTitle => 'Inviter un membre';

  @override
  String get teamInviteHint =>
      'Aucun SMS ni e-mail n’est émis par SpeedyGo. Un code d’acceptation vous sera remis : transmettez-le vous-même à la personne invitée.';

  @override
  String get teamInvitePhoneLabel => 'Numéro de téléphone';

  @override
  String get teamInvitePhoneHint => '550 12 34 56';

  @override
  String get teamInvitePhoneHelper =>
      'Numéro avec lequel la personne se connecte à SpeedyGo.';

  @override
  String get teamInvitePhoneInvalid =>
      'Saisissez un numéro mobile algérien valide (9 chiffres).';

  @override
  String get teamInviteRoleLabel => 'Rôle';

  @override
  String get teamInviteCreate => 'Créer l’invitation';

  @override
  String get teamRoleManagerHint =>
      'Peut consulter l’équipe. Aucun droit de gestion.';

  @override
  String get teamRoleStaffHint =>
      'Accès opérationnel, sans accès à la gestion de l’équipe.';

  @override
  String get teamCodeTitle => 'Code d’acceptation';

  @override
  String get teamCodeRegeneratedTitle => 'Nouveau code d’acceptation';

  @override
  String get teamCodeRegeneratedNote => 'L’ancien code ne fonctionne plus.';

  @override
  String get teamCodeCopy => 'Copier le code';

  @override
  String get teamCodeCopied => 'Code copié.';

  @override
  String get teamCodeDone => 'Terminer';

  @override
  String get teamRevokeTitle => 'Révoquer l’accès ?';

  @override
  String get teamRevoked => 'Accès révoqué.';

  @override
  String get teamCancelInviteTitle => 'Annuler l’invitation ?';

  @override
  String teamCancelInviteBody(String phone) {
    return 'Le code d’acceptation de $phone ne fonctionnera plus.';
  }

  @override
  String get teamCancelInviteConfirm => 'Annuler l’invitation';

  @override
  String get teamKeep => 'Conserver';

  @override
  String get teamInviteCancelled => 'Invitation annulée.';

  @override
  String get teamRoleSheetTitle => 'Modifier le rôle';

  @override
  String get teamRoleSheetHint =>
      'Si le rôle réduit ses droits, les sessions du membre sont fermées et il devra se reconnecter.';

  @override
  String get teamRoleSave => 'Enregistrer';

  @override
  String get teamRoleUpdated => 'Rôle mis à jour.';

  @override
  String get teamErrorGeneric => 'Action impossible pour le moment. Réessayez.';

  @override
  String get teamErrorConflict =>
      'La liste a changé entre-temps. Elle vient d’être actualisée : vérifiez puis réessayez.';

  @override
  String get teamErrorDuplicateMember =>
      'Ce numéro fait déjà partie de l’équipe.';

  @override
  String get teamErrorDuplicateInvite =>
      'Une invitation est déjà en attente pour ce numéro.';

  @override
  String get teamErrorOwnerProtected =>
      'Le propriétaire ne peut pas être modifié ici.';

  @override
  String get teamErrorSelf => 'Vous ne pouvez pas modifier votre propre accès.';

  @override
  String get teamErrorInviteGone => 'Cette invitation n’existe plus.';

  @override
  String get teamErrorInviteExpired =>
      'Cette invitation a expiré. Demandez un nouveau code au propriétaire.';

  @override
  String get teamErrorCodeInvalid => 'Code incorrect.';

  @override
  String get teamErrorPhoneMismatch =>
      'Cette invitation est destinée à un autre numéro.';

  @override
  String get teamErrorInvalidInput =>
      'Vérifiez le numéro et le rôle puis réessayez.';

  @override
  String get teamInvitationsTitle => 'Invitations reçues';

  @override
  String get teamInvitationsHint =>
      'Invitations adressées à votre numéro. Saisissez le code remis par le propriétaire pour les accepter.';

  @override
  String get teamInvitationsEmpty =>
      'Aucune invitation en attente pour votre numéro.';

  @override
  String get teamInvitationsLoadError =>
      'Impossible de charger vos invitations. Réessayez.';

  @override
  String get teamAccept => 'Accepter';

  @override
  String get teamAcceptTitle => 'Saisir le code d’acceptation';

  @override
  String get teamAcceptCodeLabel => 'Code remis par le propriétaire';

  @override
  String get teamAcceptCodeInvalid =>
      'Le code comporte 64 caractères (chiffres et lettres a à f).';

  @override
  String get teamAcceptConfirm => 'Accepter l’invitation';

  @override
  String get settingsLanguageRow => 'Langue';

  @override
  String get languageSettingsTitle => 'Langue';

  @override
  String get languageSettingsSubtitle =>
      'Choisissez la langue de l’application. Le changement s’applique immédiatement.';

  @override
  String get languageOptionFrench => 'Français';

  @override
  String get languageOptionArabic => 'العربية';

  @override
  String get languageApply => 'Appliquer les modifications';

  @override
  String get languageApplied => 'Langue mise à jour.';

  @override
  String get languageBilingualTitle => 'Langue / اللغة';

  @override
  String get languagePreviewNote =>
      'Les textes de l’interface basculent entre le français et l’arabe. Les données métier restent inchangées.';
}
