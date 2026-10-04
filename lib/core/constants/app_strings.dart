/// French UI copy for Phase 1. Arabic uses the same keys via locale direction;
/// content stays French until ARB extraction (RTL layout is supported).
class AppStrings {
  const AppStrings._();

  static const appName = 'SpeedyGo Merchant';
  static const brandName = 'SpeedyGo';
  static const splashTagline = 'Votre commerce. Simplement.';
  static const splashLegacyTagline = 'Espace commerçant';
  static const onboardingSkip = 'Passer';
  static const onboardingNext = 'Suivant';
  static const onboardingStart = 'Commencer';
  static const onboardingHaveAccount = 'J’ai déjà un compte';
  static const onboardingPage1Title = 'Recevez vos commandes';
  static const onboardingPage1Body =
      'Retrouvez les nouvelles commandes et consultez leurs détails.';
  static const onboardingPage2Title = 'Maîtrisez la préparation';
  static const onboardingPage2Body =
      'Organisez la préparation et indiquez quand une commande est prête.';
  static const onboardingPage3Title = 'Votre commerce, à portée de main';
  static const onboardingPage3Body =
      'Retrouvez votre catalogue, vos horaires et les informations de votre établissement.';
  static const onboardingSaveFailed =
      'Impossible d’enregistrer l’introduction. Réessayez.';
  static const onboardingPageSemantics = 'Page d’introduction';
  static const phoneTitle = 'Entrez votre numéro de téléphone';
  static const phoneSubtitle =
      'Nous vous enverrons un code de vérification par SMS.';
  static const phoneHint = '555 12 34 56';
  static const phonePrefix = '+213';
  static const phoneSmsNote = 'Les frais de SMS standard peuvent s’appliquer.';
  static const phoneLabel = 'Numéro de téléphone';
  static const phoneInvalid = 'Saisissez un numéro algérien valide.';
  static const continueLabel = 'Continuer';
  static const needHelp = 'Besoin d’aide ?';
  static const helpUnavailable =
      'L’assistance sera disponible dans une prochaine version.';
  static const otpTitle = 'Vérification du code';
  static String otpSentTo(String masked) => 'Code envoyé au $masked';
  static const editNumber = 'Modifier';
  static const verify = 'Vérifier';
  static const resend = 'Renvoyer le code';
  static String resendIn(String clock) => 'Renvoyer le code dans $clock';
  static const otpCooldownHint = 'Patientez avant de renvoyer un code';
  static const resendCode = 'Renvoyer le code';
  static const otpSubtitle = 'Saisissez le code à 6 chiffres envoyé au';
  static const restoreTitle = 'Restauration de la session';
  static const restoreLoading = 'Connexion en cours…';
  static const restoreOffline =
      'Impossible de joindre le serveur. Vérifiez votre connexion.';
  static const restoreRetry = 'Réessayer';
  static const restoreOtherAccount = 'Utiliser un autre compte';
  static const sessionExpired = 'Votre session a expiré. Connectez-vous.';
  static const networkError = 'Problème de réseau. Réessayez.';
  static const languageSaveFailed =
      'Impossible d’enregistrer la langue. Réessayez.';
  static const retry = 'Réessayer';
  static const refreshStatus = 'Actualiser le statut';
  static const back = 'Retour';
  static const loading = 'Chargement…';
  static const tabHome = 'Accueil';
  static const tabOrders = 'Commandes';
  static const tabCatalog = 'Catalogue';
  static const tabReports = 'Rapports';
  static const tabProfile = 'Profil';
  static const navReveal = 'Afficher la navigation';
  static const homeTitle = 'Accueil';
  static const selectBranchTitle = 'Choisir un établissement';
  static const selectBranchSubtitle =
      'Sélectionnez l’établissement avec lequel vous souhaitez travailler.';
  static const noMembershipTitle = 'Aucun commerce associé';
  static const noMembershipBody =
      'Ce compte n’a pas encore d’adhésion commerçant. Vous pouvez créer un profil commerce pour démarrer la vérification.';
  static const noMembershipInvitationsCta = 'J’ai une invitation';
  static const createMerchant = 'Créer un commerce';
  static const merchantNameLabel = 'Nom du commerce';
  static const merchantNameHint = 'Ex. Pharmacie du Centre';
  static const verificationPendingTitle = 'Vérification en cours';
  static const verificationPendingBody =
      'Votre commerce est enregistré et en attente de vérification.';
  static const verificationDossierProgress = 'Pièces du dossier';
  static const verificationSubmittedStep = 'Dossier soumis';
  static const verificationReviewStep = 'Examen des documents';
  static const verificationReviewStepBody = 'En cours d’examen par SpeedyGo';
  static const verificationFinalStep = 'Validation finale';
  static const verificationFinalStepBody = 'En attente de décision';
  static const verificationTimelineTitle = 'Progression du dossier';
  static const verificationReferenceLabel = 'Référence';
  static const verificationReferenceFull = 'Référence du dossier';
  static const approvedTitle = 'Félicitations !';
  static const approvedSubtitle = 'Votre établissement est approuvé';
  static const approvedBody =
      'Pour commencer à recevoir des commandes, assurez-vous que votre '
      'magasin est ouvert, que vos horaires sont définis et que vos produits '
      'sont disponibles.';
  static const approvedReferenceLabel = 'RÉFÉRENCE MERCHANT';
  static const approvedReferenceFull = 'Référence Merchant';
  static const approvedBadge = 'Approuvé';
  static const approvedStepsTitle = 'Étapes de configuration';
  static const approvedHoursTitle = 'Horaires d’ouverture';
  static const approvedHoursBody = 'Configurez quand vous êtes ouvert';
  static const approvedCatalogTitle = 'Catalogue de produits';
  static const approvedCatalogBody = 'Ajoutez vos premiers articles';
  static const approvedAlertsTitle = 'Alertes et notifications';
  static const approvedAlertsBody = 'Restez informé des commandes';
  static const approvedNeedBranchHint =
      'Disponible après l’ajout d’un établissement';
  static const approvedNotOpenNote =
      'L’approbation n’ouvre pas votre magasin automatiquement : vérifiez '
      'son statut, vos horaires et votre catalogue depuis l’accueil.';
  static const approvedContinue = 'Accéder à l’accueil marchand';
  static const verificationRequestIdLabel = 'ID DE DEMANDE';
  static const verificationNeedHelp = 'Besoin d’aide pour votre dossier ?';
  static const verificationCorrectAndSubmit = 'Corriger et soumettre';
  static String verificationRejectedGreeting(String merchantName) =>
      'Bonjour, le dossier de $merchantName nécessite des corrections.';
  static const verificationRejectedTitle = 'Dossier à compléter';
  static const verificationRejectedBody =
      'Le dossier a été refusé. Corrigez le profil ou les pièces lorsque l’édition est autorisée, puis soumettez à nouveau.';
  static const verificationApprovedTitle = 'Commerce approuvé';
  static const verificationApprovedBody =
      'Votre commerce est approuvé. Complétez un établissement actif pour l’exploitation.';
  static const suspendedTitle = 'Compte commerce suspendu';
  static const suspendedBody =
      'Ce commerce est suspendu. Contactez le support SpeedyGo si besoin.';
  static const checklistTitle = 'Pièces du dossier';
  static const accessRestrictedTitle = 'Accès restreint';
  static const accessRestrictedBody =
      'Vous n’avez pas les droits nécessaires pour cette action.';
  static const needBranchTitle = 'Établissement requis';
  static const needBranchBody =
      'Ajoutez au moins un établissement actif pour utiliser l’espace opérationnel.';
  static const addBranch = 'Ajouter un établissement';
  static const branchNameLabel = 'Nom de l’établissement';
  static const branchPhoneLabel = 'Téléphone';
  static const branchAddressLabel = 'Adresse';
  static const branchLatLabel = 'Latitude';
  static const branchLngLabel = 'Longitude';
  static const save = 'Enregistrer';
  static const logout = 'Se déconnecter';
  static const operationalActive = 'Actif';
  static const operationalInactive = 'Inactif';
  static const operationalSuspended = 'Suspendu';
  static const homeNoMetrics =
      'Aucun indicateur agrégé n’est fourni par l’API dans cette phase.';
  static const homeOrderCountsTitle = 'Commandes en cours';
  static const homeCountIncoming = 'Nouveaux';
  static const homeCountPreparing = 'En prép.';
  static const homeCountReady = 'Prêts';
  static const homeCountCourier = 'Livreur';
  static const homeCountCourierUnavailable = '—';
  static const homeActiveOrdersTitle = 'Commandes actives';
  static const homeActiveOrdersEmpty = 'Aucune commande active pour le moment.';
  static const homeTreatOrder = 'Traiter la commande';
  static const homeOpenOrder = 'Voir la commande';
  static const homeVerificationTitle = 'Vérification à finaliser';
  static const homeVerificationBody =
      'Complétez votre dossier pour conserver l’accès complet à votre espace marchand.';
  static const homeKpiSales = 'Ventes';
  static const homeKpiOrders = 'Commandes';
  static const homeKpiOrdersUnit = 'terminées';
  static const homeKpiCurrency = 'DZD';
  static const homeKpiUnavailable = '—';
  static String homeLastSync(String hhmm) => 'Dernière synchro : $hhmm';
  static const refresh = 'Actualiser';
  static const ordersEmpty = 'Aucune commande pour cet établissement.';
  static const ordersEmptyIncoming = 'Aucune nouvelle commande';
  static const ordersEmptyAccepted = 'Aucune commande acceptée';
  static const ordersEmptyPreparing = 'Aucune commande en préparation';
  static const ordersEmptyReady = 'Aucune commande prête';
  static const ordersEmptyCompleted = 'Aucune commande terminée';
  static const ordersEmptyCancelled = 'Aucune commande annulée';
  static const ordersEmptyFailed = 'Aucune commande échouée';
  static const ordersLoadError = 'Impossible de charger les commandes.';
  static const orderDetailTitle = 'Commande';
  static const orderDetailLoadError = 'Impossible de charger cette commande.';
  static const orderFulfillmentIncoming = 'Nouveau';
  static const supportReportTitle = 'Signaler un problème';
  static const supportShort = 'Support';
  static const supportContact = 'Contacter le support';
  static const supportOrderLabel = 'COMMANDE';
  static const supportCustomerLabel = 'CLIENT';
  static const supportMerchandiseLabel = 'MARCHANDISES';
  static const supportDescriptionLabel = 'Description du problème';
  static const supportDescriptionHint =
      'Expliquez-nous ce qui s’est passé en détail...';
  static const supportSensitiveHint =
      'Veuillez ne pas inclure de données sensibles (ex : mots de passe).';
  static const supportSend = 'Envoyer le ticket';
  static const supportSentTitle = 'Signalement envoyé';
  static String supportSentBody(String ref) =>
      'Votre ticket $ref a été transmis à l’équipe SpeedyGo.';
  static const supportSentBodyNoRef =
      'Votre ticket a été transmis à l’équipe SpeedyGo.';
  static const supportBackToOrder = 'Retour à la commande';
  static const supportForbidden =
      'Seuls le propriétaire et les gérants peuvent contacter le support.';
  static const supportSendError =
      'Le ticket n’a pas pu être envoyé. Réessayez.';
  static const supportCenterTitle = 'Support Merchant';
  static const supportNewTicket = 'Nouveau ticket';
  static const supportActiveTickets = 'Tickets actifs';
  static const supportResolvedTickets = 'Tickets résolus';
  static const supportNoTickets = 'Aucun ticket pour le moment.';
  static const supportLoadError = 'Impossible de charger vos tickets.';
  static String supportUpdated(DateTime updatedAt, DateTime now) {
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return 'Mis à jour à l’instant';
    if (diff.inMinutes < 60) return 'Mis à jour il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Mis à jour il y a ${diff.inHours} h';
    return 'Mis à jour le ${_ddMmYyyy(updatedAt)}';
  }

  static String supportDate(DateTime at) => _ddMmYyyy(at);
  static String _ddMmYyyy(DateTime at) {
    final l = at.toUtc().add(const Duration(hours: 1));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }

  static String supportShowingLatest(int shown, int total) =>
      '$shown tickets les plus récents affichés sur $total.';
  static String supportStatus(String code) => switch (code) {
    'open' => 'Ouvert',
    'inProgress' => 'En cours',
    'waitingCustomer' => 'Réponse attendue',
    'resolved' => 'Résolu',
    'closed' => 'Fermé',
    _ => 'Statut inconnu',
  };
  static const supportTopicsTitle = 'Sujets fréquents';
  static const supportTopicsHint =
      'Choisissez un sujet pour ouvrir un nouveau ticket.';
  static const supportTopicsLoadError = 'Impossible de charger les sujets.';
  static const supportTopicsEmpty = 'Aucun sujet disponible pour le moment.';
  static const supportTopicLabel = 'Sujet';
  static const supportTopicRequired = 'Choisissez un sujet.';
  static const supportSubjectLabel = 'Objet';
  static const supportSubjectHint = 'Résumez votre demande en quelques mots';
  static const supportSubjectRequired = 'Indiquez l’objet de votre demande.';
  static const supportFaqTitle = 'Questions fréquentes';
  static const supportFaqEmpty = 'Aucune question fréquente pour le moment.';
  static const supportFaqLoadError = 'Impossible de charger la FAQ.';
  static const supportComposeTitle = 'Nouveau ticket';
  static const supportComposeHint =
      'Décrivez votre demande. Pour un problème sur une commande, utilisez « Signaler un problème » depuis la commande.';
  static String supportCreated(String reference) =>
      reference.isEmpty ? 'Ticket envoyé.' : 'Ticket envoyé : $reference';
  static const supportTicketTitle = 'Ticket';
  static const supportTicketLoadError = 'Impossible de charger ce ticket.';
  static const supportLinkedOrder = 'Commande liée';
  static const supportYou = 'Vous';
  static const supportTeam = 'Support SpeedyGo';
  static const supportReplyHint = 'Votre réponse';
  static const supportReplySend = 'Envoyer';
  static const supportReplyError = 'La réponse n’a pas pu être envoyée.';
  static const supportTicketFinished =
      'Ce ticket est clos. Créez un nouveau ticket si besoin.';
  static const supportNoMessages = 'Aucun message.';
  static const orderListAcceptNow = 'À accepter immédiatement';
  static const orderDetailsTitle = 'Détails de la commande';
  static const orderDetailCancelledTitle = 'Commande annulée';
  static const orderCancelledHeroBody = 'Cette commande n’aboutira pas.';
  static const orderCancelledByCustomer = 'Annulée par le client';
  static const orderRejectedByMerchant = 'Refusée par le commerce';
  static const orderReasonLabel = 'Raison';
  static const orderCancelledAck = 'Compris';
  static const orderViewHistory = 'Voir l’historique';
  static const orderCurrentStatus = 'Statut actuel';
  static String orderDeliveredOn(String when) => 'Livrée le $when';
  static String orderCompletedOn(String when) => 'Terminée le $when';
  static const orderReceivedAtLabel = 'Reçue à';
  static const orderPaymentLabel = 'Paiement';
  static String orderPaymentMethod(String method) => 'Méthode : $method';
  static String orderReadySince(String hhmm) => 'Prête depuis $hhmm';
  static const eventCreated = 'Commande reçue';
  static const eventCreatedCaption = 'Commande passée par le client';
  static const eventAccepted = 'Acceptée';
  static const eventAcceptedCaption = 'Commande confirmée';
  static const eventPrepStarted = 'En préparation';
  static const eventPrepStartedCaption = 'Préparation démarrée';
  static const eventReady = 'Préparée';
  static const eventReadyCaption = 'Prête pour la collecte';
  static const eventRejected = 'Refusée';
  static const eventCancelled = 'Annulée';
  static const eventCompleted = 'Terminée';
  static const eventCompletedCaption = 'Commande livrée au client';
  static const eventStatusUpdate = 'Mise à jour du statut';
  static const orderListLate = 'En retard';
  static String orderListReadyAt(String hhmm) => 'Prête vers $hhmm';
  static const orderHistoryToday = 'Aujourd’hui';
  static const orderHistoryYesterday = 'Hier';
  static const orderHistoryEarlier = 'Plus tôt';
  static const orderFulfillmentAccepted = 'Acceptée';
  static const orderFulfillmentPreparing = 'En préparation';
  static const orderFulfillmentReady = 'Prête';
  static const orderStatusCreated = 'Créée';
  static const orderStatusConfirmed = 'Confirmée';
  static const orderStatusActive = 'Active';
  static const orderStatusCompleted = 'Terminée';
  static const orderStatusCancelled = 'Annulée';
  static const orderStatusFailed = 'Échouée';
  static const orderPaymentCod = 'Paiement à la livraison';
  static const orderPaymentElectronic = 'Paiement électronique';
  static String orderCreatedAt(String when) => 'Créée le $when';
  static String orderConfirmedAt(String when) => 'Confirmée le $when';
  static String orderCancelledAt(String when) => 'Annulée le $when';
  static String orderCreatedShort(String when) => 'Créée · $when';
  static const orderListMerchandiseLabel = 'Marchandises';
  static const orderIncomingBanner = 'Nouvelle commande';
  static const orderReadyBanner = 'Commande prête';
  static const orderSegmentActive = 'En cours';
  static const orderSegmentHistory = 'Historique';
  static const orderReferenceCopy = 'Copier la référence';
  static const orderReferenceCopied = 'Référence copiée';
  static const orderReferenceShowFull = 'Afficher la référence complète';
  static const orderItemsTitle = 'Articles';
  static const orderItemsToPrepareTitle = 'Articles à préparer';
  static const orderDeliveryAddress = 'Adresse de livraison';
  static const orderFinanceTitle = 'Répartition financière';
  static const orderFinanceGms = 'Sous-total marchandises';
  static const orderFinanceDiscount = 'Remise commerçant';
  static String orderFinanceCommission(String percent) =>
      'Commission SpeedyGo ($percent %)';
  static const orderFinanceNet = 'Net commerçant';
  static const orderFinanceCommissionUnavailable = 'Commission SpeedyGo';
  static const orderFinanceRestricted =
      'Commission, remise et net commerçant réservés au propriétaire ou au responsable.';
  static const valueUnavailable = '—';
  static const orderFinanceNetCancelledNote =
      'Montants historiques figés au moment de la commande — pas un paiement dû.';
  static const orderFinanceDeliveryFeeNote = 'Frais de livraison (client)';
  static const orderFinanceDeliveryFeeDisclaimer =
      'Les frais de livraison ne sont pas un revenu commerçant.';
  static const orderAccept = 'Accepter';
  static const orderChoosePrepTime = 'Choisir le temps de préparation';
  static const orderReject = 'Refuser';
  static const orderRejectTitle = 'Refuser la commande';
  static const orderRejectHint =
      'Le refus n’est possible qu’avant acceptation. Indiquez un motif.';
  static const orderRejectReasonLabel = 'Motif du refus';
  static const orderRejectConfirm = 'Confirmer le refus';
  static const orderQuickAlreadyHandled =
      'Cette commande a déjà été traitée. La liste est actualisée.';
  static const orderQuickNotAllowed = 'Votre rôle ne permet pas cette action.';
  static const orderQuickCheckFailed =
      'Impossible de vérifier la commande. Réessayez.';
  static const orderQuickAccepted = 'Commande acceptée.';
  static const orderQuickRejected = 'Commande refusée.';
  static const prepAcceptTitle = 'Accepter la commande';
  static const prepEstimatedTitle = 'Temps de préparation estimé';
  static String prepSelectHint(int itemCount) {
    if (itemCount <= 1) {
      return 'Sélectionnez le temps nécessaire pour préparer l’article.';
    }
    return 'Sélectionnez le temps nécessaire pour préparer les $itemCount articles.';
  }

  static String prepMinutesLabel(int minutes) => '$minutes min';
  static const prepConfirmAccept = 'Confirmer et accepter';
  static const prepCustomTime = 'Temps personnalisé';
  static const prepCustomEntry = 'Saisie personnalisée';
  static String prepCustomRange(int min, int max) =>
      'Entre $min et $max minutes';
  static String prepItemCount(int n) => n <= 1 ? '1 article' : '$n articles';
  static const prepInProgress = 'En cours';
  static const prepCurrentShort = 'Heure actuelle';
  static const prepNewShort = 'Nouvelle estimation';
  static const prepReasonHint = 'Ex : problème technique en cuisine…';
  static const prepRemainingTitle = 'Temps restant';
  static const prepMinutesCaption = 'MINUTES';
  static const prepSecondsCaption = 'SECONDES';
  static String prepScheduledAtLocal(String time) =>
      'Heure prévue : $time (heure locale)';
  static String prepScheduledOnLocal(String day, String time) =>
      'Heure prévue : le $day à $time (heure locale)';
  static String prepLateBy(int minutes) =>
      minutes <= 0 ? 'En retard' : '${durationFr(minutes)} de retard';

  /// "45 min", "2 h 5 min", "1 j 23 h" (zero parts omitted; minutes are
  /// dropped once the duration reaches a day).
  static String durationFr(int minutes) {
    if (minutes < 60) return '$minutes min';
    final days = minutes ~/ (24 * 60);
    final hours = (minutes % (24 * 60)) ~/ 60;
    final rest = minutes % 60;
    if (days > 0) return hours > 0 ? '$days j $hours h' : '$days j';
    return rest > 0 ? '$hours h $rest min' : '$hours h';
  }

  static const prepLateHint =
      'L’estimation est dépassée. Mettez à jour le temps ou marquez la commande prête quand elle l’est.';
  static const prepUpdateAction = 'Modifier temps';
  static const prepUpdateTitle = 'Mise à jour du temps';
  static const prepCurrentReady = 'Heure prévue actuelle';
  static String prepOriginalReady(String time) => 'Initiale : $time';
  static String prepOriginalReadyLabel(String time) => 'Heure initiale : $time';
  static const prepBranchLabel = 'Établissement';
  static const prepAddTime = 'Ajouter du temps de préparation';
  static String prepNewEstimate(String from, String to, int add) =>
      'Nouvelle estimation : $to au lieu de $from, plus $add minutes';
  static String prepClockOnDay(String day, String time) => 'le $day à $time';
  static String prepOnDay(String day) => 'le $day';
  static String prepSpokenClock(String time, String? day) =>
      day == null ? time : '$time le $day';
  static const prepReasonOptional = 'Raison du retard (optionnel)';
  static const prepReasonShortcutsHint =
      'Un raccourci remplit le motif ; vous pouvez le modifier.';
  static const prepReasonFieldLabel = 'Motif';
  static const prepReasonBusy = 'Forte affluence';
  static const prepReasonLongPrep = 'Préparation longue';
  static const prepReasonMissingIngredient = 'Ingrédient manquant';
  static const prepReasonOther = 'Autre raison';
  static const prepUpdateConfirm = 'Mettre à jour';
  static const orderStartPreparation = 'Démarrer la préparation';
  static const orderMarkReady = 'Marquer comme prête';
  static const markReadyPackingTitle = 'Liste de colisage';
  static const markReadyPackingHint =
      'Vérifiez que tous les éléments de la commande sont bien emballés avant de la marquer prête.';
  static const markReadyConfirm = 'Confirmer et marquer prête';
  static const orderReadyWaitingDelivery =
      'En attente de prise en charge pour la livraison.';
  static const orderDeliveryStatusTitle = 'Livraison';
  static const orderDriverAssigned = 'Un livreur est assigné.';
  static String orderDriverSearchStarted(String when) =>
      'Recherche démarrée le $when';
  static String orderDriverSearchStartedAt(String hhmm) =>
      'Recherche démarrée à $hhmm';
  static String orderDriverEtaEstimate(String when) =>
      'Arrivée estimée : $when';
  static const orderDriverCardTitle = 'Livreur assigné';
  static const orderDriverStatusLabel = 'Statut';
  static const orderDriverEtaLabel = 'Arrivée estimée';
  static const orderDriverEtaUnavailable = 'Heure d’arrivée indisponible.';
  static const orderDriverContactUnavailable =
      'Contact du livreur indisponible.';
  static const orderDriverCall = 'Appeler le livreur';
  static const pickupHandoffTitle = 'Code de retrait';
  static const pickupHandoffWaiting =
      'En attente de validation par le livreur…';
  static const pickupHandoffInstruction1 =
      'Communiquez ce code uniquement au livreur affiché ci-dessus.';
  static const pickupHandoffInstruction2 =
      'Le livreur doit saisir ce code dans son application pour confirmer la récupération.';
  static const pickupHandoffRegenerate = 'Régénérer le code';
  static const pickupHandoffConfirmed = 'Remise confirmée';
  static const pickupHandoffLoadError =
      'Impossible de charger le code de retrait.';
  static const pickupHandoffRetry = 'Réessayer';
  static const orderHandoffUnsupported =
      'La confirmation de remise sécurisée n’est pas disponible pour le commerçant dans cette version.';
  static const orderHistoryTitle = 'Historique de la commande';
  static const orderReferenceLabel = 'Référence';
  static const orderCustomerLabel = 'Client';
  static const orderSummaryTitle = 'Résumé de la commande';
  static const deliverySearching = 'Recherche de livreur';
  static const deliveryAssigned = 'Livreur assigné';
  static const deliveryPickedUp = 'Récupérée';
  static const deliveryArrived = 'Arrivé chez le client';
  static const deliveryToPickup = 'Livreur en route vers le commerce';
  static const deliveryAtPickup = 'Livreur arrivé au commerce';
  static const deliveryInTransit = 'En route vers le client';
  static const deliveryFailed = 'Livraison échouée';
  static const deliveryCancelled = 'Livraison annulée';
  static const deliveryUnknown = 'Statut de livraison indisponible';
  static const deliveryDelivered = 'Livrée';
  static const catalogTitle = 'Catalogue';
  static const catalogTabProducts = 'Produits';
  static const catalogTabCategories = 'Catégories';
  static const catalogSearchHint = 'Rechercher un produit…';
  static const catalogAllCategories = 'Tous';
  static const catalogEmptyProducts = 'Aucun produit dans ce catalogue.';
  static const catalogEmptyCategories = 'Aucune catégorie pour le moment.';
  static const catalogLoadError = 'Impossible de charger le catalogue.';
  static const catalogInStock = 'En stock';
  static const catalogOutOfStock = 'Rupture';
  static const catalogUnavailableSection =
      'La création et l’édition avancées de produits ne sont pas branchées dans cet écran.';
  static const reportsTitle = 'Rapports';
  static const reportsPeriodToday = 'Aujourd’hui';
  static const reportsPeriodYesterday = 'Hier';
  static const reportsPeriodWeek = 'Cette semaine';
  static const reportsPeriodMonth = 'Ce mois';
  static const reportsFinanceTitle = 'Détails financiers';
  static const reportsGrossSales = 'Ventes brutes';
  static const reportsCommission = 'Commission SpeedyGo';
  static const reportsMerchantNet = 'Net commerçant';
  static const reportsDataUnavailable = 'Données indisponibles';
  static const reportsDataUnavailableShort = '—';
  static const reportsOrdersMetric = 'Commandes';
  static const reportsPrepTimeMetric = 'Temps prép. moy.';
  static const reportsCancellationsMetric = 'Annulations';
  static const reportsTrendTitle = 'Tendance des ventes';
  static const reportsTopProductsTitle = 'Produits les plus vendus';
  static const reportsTopProductsScreenTitle = 'Top produits';
  static const reportsCommissionMixedRates =
      'Commission SpeedyGo (taux variables)';
  static const reportsFinanceUnavailable = 'Données indisponibles';
  static const reportsRatingsTitle = 'Notes clients';
  static const reportsRatingsEmpty = 'Aucune note pour le moment.';
  static const reportsRatingsCount = 'avis';
  static const reportsRatingsUnavailable = 'Données indisponibles';
  static const reportsSettlementsTitle = 'Règlements';
  static String reportsSettlementStatus(String status) =>
      switch (status.toUpperCase()) {
        'DRAFT' => 'Brouillon',
        'FINALIZED' => 'Finalisé',
        _ => 'Statut inconnu',
      };
  static const reportsSettlementsEmpty = 'Aucun règlement pour le moment.';
  static const reportsSettlementsForbidden =
      'Les règlements sont réservés au propriétaire ou au responsable.';
  static const reportsLoadError = 'Impossible de charger les indicateurs.';
  static const reportsTrendUnavailable = 'Données indisponibles';
  static const reportsTopProductsUnavailable = 'Données indisponibles';
  static const reportsPeriodCustom = 'Personnalisé';
  static const reportsPeriodSelectorLabel = 'Période du rapport';
  static const reportsCustomRangeTooLong =
      'La période personnalisée est limitée à 93 jours.';
  static const reportsAverageBasketMetric = 'Panier moyen';
  static const reportsPrepTimeNotTracked = 'Non suivi';
  static const reportsMerchantDiscount = 'Remise commerçant';
  static const reportsFinanceRestricted =
      'Commission et net commerçant réservés au propriétaire ou au responsable.';
  static const reportsFinanceMissingSnapshot =
      'Données financières indisponibles pour certaines commandes de la période.';
  static const reportsRefundsCompleted = 'Remboursements finalisés';
  static const reportsRefundAdjustments = 'Ajustements enregistrés';
  static const reportsRefundsNote =
      'Les remboursements ne réduisent pas les ventes. Seuls les ajustements enregistrés sur vos règlements vous sont imputés.';
  static const reportsTrendEmpty = 'Aucune vente sur la période.';
  static const reportsTopProductsEmpty = 'Aucun produit vendu sur la période.';
  static const reportsSeeAll = 'Voir tout';
  static const reportsSortOrders = 'Commandes';
  static const reportsSortRevenue = 'Chiffre d’affaires';
  static const reportsTopSales = 'Top des ventes';
  static const reportsRankFirst = 'N°1';
  static const reportsDeletedProduct = 'Produit retiré du catalogue';
  static const reportsSalesLoadError = 'Impossible de charger les ventes.';
  static const reportsTopProductsLoadError =
      'Impossible de charger les produits.';
  static String reportsLastUpdated(String time) =>
      'Dernière mise à jour : $time';
  static String reportsSyncedAt(String time) => 'Synchronisé à $time';
  static String reportsCommissionWithRate(String rate) =>
      'Commission SpeedyGo ($rate)';
  static String reportsOrderCount(int count) =>
      count == 1 ? '1 commande' : '$count commandes';
  static String reportsUnitCount(int count) =>
      count == 1 ? '1 unité' : '$count unités';
  static String reportsTotalArticles(int count) =>
      count == 1 ? 'Total : 1 article' : 'Total : $count articles';
  static String reportsTrendSemantics(int orders, String gross) =>
      'Tendance des ventes : $orders commandes, $gross';
  static const reportsDailySummaryTitle = 'Résumé quotidien';
  static const reportsDailySummaryShortcut = 'Résumé quotidien';
  static const reportsDailySummaryLoadError =
      'Impossible de charger le résumé quotidien.';
  static const reportsDailySummaryEmpty =
      'Aucune commande créée pour cette journée.';
  static const reportsDailySummarySalesKpi = 'Ventes';
  static const reportsDailySummaryOrdersKpi = 'Commandes';
  static const reportsDailySummaryPrepKpi = 'Temps Prép.';
  static const reportsDailySummaryCancellationsKpi = 'Annulations';
  static const reportsDailySummaryBreakdownTitle = 'Répartition des commandes';
  static const reportsDailySummaryDelivered = 'Livrées';
  static const reportsDailySummaryInProgress = 'En cours';
  static const reportsDailySummaryCancelled = 'Annulées';
  static const reportsDailySummaryPrepEfficiencyTitle =
      'Efficacité de préparation';
  static const reportsDailySummaryPrepAverage = 'Moyenne';
  static const reportsDailySummaryOnTimeRate = 'À l’heure';
  static const reportsDailySummaryCancellationMotifs = 'Motifs d’annulation';
  static const reportsDailySummaryViewOrders =
      'Voir toutes les commandes du jour';
  static String reportsDailySummaryMinutes(int minutes) => '$minutes min';
  static String reportsDailySummaryOnTimePercent(String percent) =>
      '$percent à l’heure';
  static String reportsDailySummaryTodayDate(String label) =>
      'Aujourd’hui, $label';
  static const deliveryImpactTitle = 'Impact sur la livraison';
  static const deliveryImpactMayDelayDriverAssignment =
      'La préparation peut retarder la recherche d’un livreur.';
  static const deliveryImpactMayDelayPickup =
      'Un livreur est assigné; le retrait peut être retardé.';
  static const deliveryImpactDriverWaiting = 'Le livreur attend la commande.';
  static const deliveryImpactTimingUnavailable =
      'Impact exact sur la livraison indisponible.';
  static String deliveryImpactLatestRevision(String reason) =>
      'Dernier motif : $reason';
  static const rejectReasonProductUnavailable = 'Indisponibilité produit';
  static const rejectReasonTooBusy = 'Trop occupé';
  static const rejectReasonClosingSoon = 'Fermeture proche';
  static const rejectReasonOther = 'Autre';
  static const rejectReasonTilesHint =
      'Sélectionnez un motif puis précisez si nécessaire.';
  static const catalogAddProduct = 'Ajouter un produit';
  static const catalogEditProduct = 'Modifier le produit';
  static const catalogProductDetail = 'Détail du produit';
  static const catalogAddCategory = 'Ajouter une catégorie';
  static const catalogEditCategory = 'Modifier la catégorie';
  static const catalogProductName = 'Nom du produit (Français)';
  static const catalogProductDescription = 'Description (Français)';
  static const catalogProductPrice = 'Prix de base';
  static const catalogProductCategory = 'Catégorie';
  static const catalogProductAvailable = 'Visible dans le menu';
  static const catalogProductAvailableSub = 'Activer pour rendre disponible';
  static const catalogSaveProduct = 'Enregistrer';
  static const catalogSaveProductEdits = 'Enregistrer les modifications';
  static const catalogPreview = 'Aperçu';
  static const catalogPreviewTitle = 'Aperçu du produit';
  static const catalogPreviewUnavailable =
      'Aperçu non disponible actuellement.';
  static const catalogFieldRequired = 'Ce champ est obligatoire.';
  static const catalogPriceInvalid = 'Indiquez un prix valide.';
  static const catalogCategoryRequired = 'Choisissez une catégorie.';
  static const catalogSaveRetryHint =
      'Enregistrement impossible. Vérifiez la connexion et réessayez.';
  static const catalogSectionInfo = 'Informations';
  static const catalogSectionMedia = 'Médias';
  static const catalogSectionPrice = 'Prix et préparation';
  static const catalogSectionConfig = 'Configuration';
  static const catalogSectionAvailability = 'Disponibilité';
  static const catalogSectionImage = 'Image du produit';
  static const catalogSectionGeneral = 'Informations générales';
  static const catalogSectionPriceDetails = 'Prix et détails';
  static const catalogOnlineBanner =
      'Cet article est actuellement en ligne pour les clients.';
  static const catalogOfflineBanner =
      'Cet article n’est pas visible pour les clients.';
  static const catalogPriceWarning =
      'Les changements de prix et de disponibilité sont appliqués immédiatement aux clients.';
  static const catalogImagePrimary = 'Image principale';
  static const catalogImageAdd = 'Ajouter une photo';
  static const catalogImageHint = 'JPG, PNG (max. 2 Mo, min. 400 px)';
  static const catalogImageChangePhoto = 'Changer la photo';
  static const catalogInStockNow = 'Actuellement en stock';
  static const catalogOutOfStockNow = 'Actuellement indisponible';
  static const catalogCurrencySuffix = 'DZD';
  static const catalogDeleteProduct = 'Supprimer';
  static const catalogNeedCategory =
      'Créez d’abord une catégorie pour ajouter un produit.';
  static const catalogImagePick = 'Choisir une image';
  static const catalogImageFromGallery = 'Choisir dans la galerie';
  static const catalogImageFromCamera = 'Prendre une photo';
  static const catalogImagePluginRestart =
      'Redémarrez l’application pour activer la sélection de photos.';
  static const catalogImageFormatError =
      'Format non pris en charge. Utilisez une photo JPG ou PNG.';
  static const catalogImageTooSmall =
      'Image trop petite. Minimum 400 × 400 pixels.';
  static const catalogImageTooLarge =
      'Image trop lourde. Maximum 2 Mo après compression.';
  static const catalogImageChange = 'Changer l’image';
  static const catalogImageRemove = 'Retirer l’image';
  static const catalogImageUploadError = 'Impossible d’envoyer l’image.';
  static const catalogImageBindPartial =
      'Produit enregistré, mais l’image n’a pas pu être liée. Réessayez.';
  static const catalogImageRemoteUnavailable =
      'Aperçu de l’image non disponible actuellement.';
  static const catalogSaveError = catalogSaveRetryHint;
  static const catalogDeleteConfirm =
      'Supprimer ce produit ? Les commandes historiques sont conservées.';
  static const catalogCategoryName = 'Nom de la catégorie (Français)';
  static const catalogCategoryActive = 'Visibilité dans le menu';
  static const catalogCategoryActiveSub =
      'Afficher cette catégorie aux clients';
  static const catalogCategoryDetails = 'Détails de la catégorie';
  static const catalogCategorySettings = 'Paramètres';
  static const catalogCategoryCancel = 'Annuler';
  static const catalogDeleteCategory = 'Supprimer la catégorie';
  static const catalogDeleteCategoryConfirm =
      'Supprimer cette catégorie ? Elle doit être vide.';
  static const catalogStaffReadOnly =
      'Consultation seule — modifications réservées au propriétaire ou responsable.';
  static const catalogCategorySearchHint = 'Rechercher une catégorie…';
  static const catalogFilterTooltip = 'Filtres';
  static const catalogReorder = 'Réorganiser';
  static const catalogVisible = 'Visible';
  static const catalogHidden = 'Masqué';
  static String catalogArticles(int n) => n <= 1 ? '$n article' : '$n articles';
  static const catalogMenuAvailability = 'Gérer la disponibilité';
  static const catalogMenuDelete = 'Supprimer';
  static const catalogMenuDuplicate = 'Dupliquer';
  static const duplicateTitle = 'Dupliquer le produit';
  static const duplicateSource = 'Source';
  static const duplicateNewName = 'Nouveau nom du produit';
  static const duplicateNewNameHint =
      'Veuillez modifier le nom avant de publier la copie.';
  static const duplicateNamePlaceholder = 'Entrez le nouveau nom';
  static const duplicateClearName = 'Effacer le nom';
  static String duplicateDefaultName(String name) => 'Copie de $name';
  static const duplicateCopied = 'Éléments copiés';
  static const duplicateImage = 'Image du produit';
  static const duplicateNoImage = 'Image du produit (aucune image)';
  static String duplicatePrice(String price) => 'Prix ($price)';
  static const duplicateOptions = 'Options et variantes';
  static const duplicateSaleUnits = 'Unités de vente (non gérées)';
  static const duplicateNotCopiedLead =
      'Le statut de disponibilité et l’historique des ventes ';
  static const duplicateNotCopiedStrong = 'ne seront pas';
  static const duplicateNotCopiedTail = ' copiés vers le nouveau produit.';
  static const duplicateUnavailableInfo =
      'La copie sera créée indisponible afin que vous puissiez la vérifier avant de l’activer.';
  static const duplicateCancel = 'Annuler';
  static const duplicateCreate = 'Créer la copie';
  static const duplicateCreating = 'Création…';
  static const duplicateNameRequired = 'Le nom ne peut pas être vide.';
  static const duplicateNameTooLong = 'Maximum 255 caractères.';
  static const duplicateNetworkError =
      'Connexion interrompue. Réessayez : la copie ne sera pas créée deux fois.';
  static const duplicateError =
      'La copie n’a pas pu être créée et aucun produit n’a été ajouté. Réessayez.';
  static const duplicateConflict =
      'Cette demande de copie a déjà servi ailleurs. Rouvrez l’écran puis réessayez.';
  static const duplicateNotFound =
      'Produit introuvable. Actualisez le catalogue.';
  static const duplicateCreated =
      'Copie créée — indisponible jusqu’à votre vérification.';
  static const duplicateReplayed = 'Copie déjà créée — ouverture du produit.';
  static const duplicateForbiddenTitle =
      'Duplication réservée au propriétaire ou au responsable';
  static const duplicateBackToCatalog = 'Retour au catalogue';
  static const catalogMenuViewCategory = 'Voir la catégorie';
  static const catalogBulkTooltip = 'Disponibilité groupée';
  static const catalogCategoryInUse =
      'Cette catégorie contient encore des produits. Déplacez-les ou supprimez-les d’abord.';
  static const catalogProductInUse =
      'Ce produit figure dans des commandes passées : il ne peut pas être supprimé. Mettez-le en rupture à la place.';
  static const catalogVisibilityError =
      'Impossible de modifier la visibilité. Réessayez.';
  static const catalogAvailabilityError =
      'Impossible de modifier la disponibilité. Réessayez.';
  static const catalogNoResults = 'Aucun produit ne correspond à ces filtres.';
  static const catalogNoCategoryResults =
      'Aucune catégorie ne correspond à cette recherche.';
  // Filters screen
  static const catalogFiltersTitle = 'Recherche et Filtres';
  static const catalogFiltersReset = 'Réinitialiser';
  static const catalogFiltersCategories = 'Catégories';
  static const catalogFiltersStatus = 'Statut';
  static const catalogFiltersOutOfStock = 'Rupture de stock';
  static const catalogFiltersQuality = 'Contrôle qualité';
  static const catalogFiltersMissingImage = 'Image manquante';
  static const catalogFiltersPreview = 'Aperçu des résultats';
  static String catalogProductsCount(int n) =>
      n <= 1 ? '$n produit' : '$n produits';
  static const catalogFiltersApply = 'Appliquer les filtres';
  // Category detail
  static const catalogCategoryDetailTitle = 'Détails de la catégorie';
  static String catalogDisplayOrder(int n) => 'Ordre d’affichage : $n';
  static const catalogCategoryProducts = 'Produits';
  static const catalogCategoryEmpty = 'Aucun produit dans cette catégorie.';
  // Reorder
  static const catalogReorderTitle = 'Réorganiser les catégories';
  static String catalogCategoriesCount(int n) =>
      n <= 1 ? '$n catégorie' : '$n catégories';
  static const catalogReorderHint =
      'Faites glisser pour modifier l’ordre d’affichage.';
  static const catalogReorderSave = 'Enregistrer l’ordre';
  static const catalogReorderSaved = 'Ordre enregistré.';
  static const catalogReorderPartial =
      'Certaines catégories n’ont pas pu être déplacées. Réessayez.';
  // Product availability
  static const catalogAvailabilityTitle = 'Disponibilité du produit';
  static const catalogAvailabilityNote =
      'Les modifications n’affectent pas les commandes déjà acceptées.';
  static const catalogAvailabilityState = 'État de disponibilité';
  static const catalogAvailableOption = 'Disponible';
  static const catalogAvailableOptionSub =
      'Visible et commandable immédiatement.';
  static const catalogOutOfStockOptionSub =
      'Affiché comme indisponible jusqu’à réactivation manuelle.';
  static const catalogAvailabilitySave = 'Enregistrer la disponibilité';
  static const catalogAvailabilitySaved = 'Disponibilité enregistrée.';
  // Bulk availability
  static const catalogBulkTitle = 'Disponibilité groupée';
  static const catalogBulkNote =
      'Les modifications s’appliquent immédiatement sur l’application client. Elles n’affectent pas les commandes en cours.';
  static const catalogBulkSelection = 'Sélection multiple';
  static String catalogBulkSelected(int n) =>
      n <= 1 ? '$n produit sélectionné' : '$n produits sélectionnés';
  static const catalogBulkNewStatus = 'Nouveau statut';
  static const catalogBulkSelectAll = 'Tout sélectionner';
  static const catalogBulkClear = 'Effacer la sélection';
  static const catalogBulkApply = 'Appliquer';
  static String catalogBulkDone(int n) =>
      n <= 1 ? '$n produit mis à jour.' : '$n produits mis à jour.';
  static String catalogBulkFailed(int n) => n <= 1
      ? '$n produit n’a pas pu être mis à jour.'
      : '$n produits n’ont pas pu être mis à jour.';
  static const catalogUncategorized = 'Sans catégorie';
  // Delete product
  static const catalogDeleteTitle = 'Supprimer le produit';
  static const catalogDeleteWarningTitle =
      'Un produit déjà commandé ne peut pas être supprimé.';
  static const catalogDeleteWarningBody =
      'Les commandes passées gardent leur copie du produit. Si la suppression est refusée, mettez le produit en rupture.';
  static const catalogDeleteHideOption = 'Mettre en rupture';
  static const catalogDeleteHideOptionSub =
      'Le produit reste enregistré et modifiable, mais n’est plus commandable.';
  static const catalogDeleteRecommended = 'Recommandé';
  static const catalogDeleteHardOption = 'Supprimer définitivement';
  static const catalogDeleteHardOptionSub =
      'Retire le produit, ses variantes et suppléments. Impossible s’il figure dans une commande.';
  static const catalogDeleteHardConfirm = 'Supprimer définitivement';
  static const catalogDeleted = 'Produit supprimé.';
  static const catalogMarkedOutOfStock = 'Produit mis en rupture.';
  // Option groups
  static const catalogVariantsTitle = 'Variantes obligatoires';
  static const catalogVariantsInfo =
      'Les variantes obligatoires demandent au client de choisir une option avant d’ajouter le produit au panier.';
  static const catalogVariantsSubtitle =
      'Configurez les options requises avant l’ajout au panier.';
  static const catalogExtrasTitle = 'Suppléments optionnels';
  static const catalogExtrasSubtitle =
      'Options facultatives que le client peut ajouter.';
  static const catalogRequiredTag = 'Obligatoire';
  static const catalogSingleChoice = 'Sélection unique';
  static String catalogChoiceRange(int min, int max) =>
      min == max ? '$min choix' : 'Entre $min et $max choix';
  static String catalogMaxSelections(int n) =>
      n <= 1 ? 'Maximum 1 sélection' : 'Maximum $n sélections';
  static const catalogAddChoice = 'Ajouter un choix';
  static const catalogAddOption = 'Ajouter une option';
  static const catalogAddVariantGroup = 'Ajouter un groupe de variantes';
  static const catalogAddExtrasGroup = 'Nouveau groupe de suppléments';
  static const catalogNewGroup = 'Nouveau groupe';
  static const catalogGroupName = 'Nom du groupe (Français)';
  static const catalogGroupNameHint = 'ex : Sauce';
  static const catalogOptionName = 'Nom du choix';
  static const catalogOptionPrice = 'Prix (+)';
  static const catalogMaxSelectionsLabel = 'Sélections maximum';
  static const catalogGroupRequiredSwitch = 'Choix obligatoire';
  static const catalogGroupRequiredSub = 'Le client doit choisir une option.';
  static const catalogGroupSave = 'Enregistrer le groupe';
  static const catalogGroupDelete = 'Supprimer le groupe';
  static const catalogGroupDeleteConfirm =
      'Supprimer ce groupe et toutes ses options ? Les commandes passées ne sont pas modifiées.';
  static const catalogOptionDelete = 'Supprimer l’option';
  static const catalogOptionAvailable = 'Option disponible';
  static const catalogOptionsEmpty = 'Aucun choix pour le moment.';
  static const catalogGroupsLoadError =
      'Impossible de charger les options du produit.';
  static const catalogGroupInvalid =
      'Vérifiez le nombre de sélections (minimum ≤ maximum).';
  static const catalogSaveFirstForOptions =
      'Enregistrez le produit pour configurer ses variantes et suppléments.';
  static String catalogGroupsCount(int n) =>
      n == 0 ? 'Aucun groupe' : (n == 1 ? '1 groupe' : '$n groupes');
  static const catalogLastUpdated = 'Dernière mise à jour';
  static const catalogCustomerPreview = 'Aperçu client';
  static const catalogEditGroup = 'Modifier le groupe';
  // Product detail (read-only)
  static const catalogProductDetailTitle = 'Détails du Produit';
  static const catalogDetailInfo = 'Informations';
  static const catalogDetailName = 'Nom (Français)';
  static const catalogDetailPricing = 'Tarification';
  static const catalogDetailPrice = 'Prix de base';
  static const catalogDetailAppearance = 'Apparence sur l’application';
  static const catalogDetailAvailable = 'Produit disponible';
  static const catalogDetailNoDescription = 'Aucune description.';
  static const catalogDetailNoOptions =
      'Aucune variante ni supplément configuré.';
  static String catalogRequiredSummary(String rule) => 'Obligatoire · $rule';
  static String catalogOptionalSummary(int max) => 'Facultatif · Maximum $max';
  // Image crop
  static const catalogCropTitle = 'Image du produit';
  static const catalogCropTipsTitle = 'Conseils pour une belle photo';
  static const catalogCropTip1 =
      'Utilisez un fond neutre et propre (blanc ou bois clair).';
  static const catalogCropTip2 =
      'Assurez-vous d’avoir un bon éclairage, de préférence naturel.';
  static String catalogCropTip3(String? name) => name == null || name.isEmpty
      ? 'Centrez le produit dans le cadre.'
      : 'Centrez le produit (« $name ») dans le cadre.';
  static const catalogCropFormat = 'Format : JPG, PNG (max. 2 Mo, min. 400 px)';
  static const catalogCropUse = 'Utiliser cette image';
  static const catalogCropRotate = 'Pivoter';
  static const catalogCropZoom = 'Zoomer';
  static const catalogCropRemove = 'Supprimer l’image';
  static const contractFieldUnavailable = 'Non disponible actuellement';
  static const catalogFieldNameAr = 'Nom du produit (Arabe)';
  static const catalogFieldDescAr = 'Description (Arabe)';
  static const catalogFieldPrepTime = 'Temps de prép.';
  static const catalogFieldSaleUnit = 'Unité de vente';
  static const sellingUnitTitle = 'Unités de vente';
  static const sellingUnitCalloutTitle = 'Précision de l’unité';
  static const sellingUnitCalloutBody =
      'Choisissez l’unité exacte pour éviter toute confusion lors de la préparation. Cette unité sera affichée aux clients (ex : 1 500 DZD / Plat). Les quantités sont entières : pas de vente au poids.';
  static const sellingUnitPreviewLabel = 'Aperçu client';
  static const sellingUnitPreviewNoPrice = '— DZD';
  static const sellingUnitCommon = 'Unités courantes';
  static const sellingUnitPackaging = 'Conditionnement';
  static const sellingUnitNone = 'Aucune unité';
  static const sellingUnitNoneSub = 'Le prix est affiché sans unité.';
  static const sellingUnitNotSet = 'Non définie';
  static const sellingUnitCustomName = 'Nom de l’unité (Français)';
  static const sellingUnitCustomHint = 'ex : Cornet';
  static const sellingUnitCustomMaxLength = 40;
  static const sellingUnitApply = 'Appliquer l’unité';
  static const sellingUnitReadOnly =
      'Seuls le propriétaire et les gérants peuvent modifier l’unité de vente.';
  static const catalogFieldVariants = 'Variantes obligatoires';
  static const catalogFieldExtras = 'Suppléments optionnels';
  static const catalogFieldCategoryNameAr = 'Nom de la catégorie (Arabe)';
  static const catalogFieldCategoryDesc =
      'Description de la catégorie (Optionnel)';
  static const storeCoverTitle = 'Logo et Couverture';
  static const storeCoverPick = 'Choisir une couverture';
  static const storeCoverReplace = 'Remplacer';
  static const storeCoverSave = 'Enregistrer les modifications';
  static const storeCoverRemove = 'Supprimer';
  static const storeCoverSection = 'Photo de couverture';
  static const storeCoverSectionHint =
      'La photo de couverture doit représenter votre établissement.';
  static const storeLogoSection = 'Logo du magasin';
  static const storeLogoSectionHint =
      'Le logo doit être lisible même en petit format.';
  static const storeLogoEdit = 'Modifier';
  static const storeLogoAdd = 'Ajouter';
  static const storeLogoRemove = 'Supprimer';
  static const storeLogoEmpty = 'Aucun logo';
  static const storeLogoPending =
      'Nouveau logo sélectionné — enregistrez pour l’appliquer.';
  static const storeLogoTooSmall = 'Logo trop petit. Minimum 128 × 128 pixels.';
  static const storeLogoTooLarge =
      'Logo trop lourd. Maximum 1 Mo après compression.';
  static const storeLogoUploadError = 'Impossible d’envoyer le logo.';
  static const storeLogoBindPartial =
      'Envoi réussi, mais le logo n’a pas pu être lié. Réessayez.';
  static const storeLogoRemoved = 'Logo supprimé.';
  static const storeLogoRemoveError =
      'Impossible de supprimer le logo. Réessayez.';
  static const storeLogoRemoteUnavailable =
      'Aperçu du logo non disponible actuellement.';
  static const storeMediaPartialSaved =
      'Le logo est enregistré, mais la couverture a échoué. Réessayez.';
  static const storeCoverHint = 'JPEG ou PNG, max. 2 Mo.';
  static const storeCoverUploadError = 'Impossible d’envoyer la couverture.';
  static const storeCoverBindPartial =
      'Envoi réussi, mais la couverture n’a pas pu être liée. Réessayez.';
  static const storeCoverRemoteUnavailable =
      'Aperçu de la couverture non disponible actuellement.';
  static const storeCustomerPreviewTitle = 'Aperçu client';
  static const storeCustomerPreviewHint =
      'Notes et délai estimé non disponibles actuellement.';
  static const storeAddressTitle = 'Contact et Adresse du magasin';
  static const storeAddressSave = 'Enregistrer les modifications';
  static const storeAddressConfirmMap = 'Modifier sur la carte';
  static const storeAddressSaveError =
      'Enregistrement impossible. Vérifiez la connexion et réessayez.';
  static const storeAddressBanner =
      'La modification de l’adresse peut affecter vos zones de livraison et les opérations en cours.';
  static const storeAddressCoordsSection = 'Coordonnées';
  static const storeAddressSection = 'Adresse';
  static const storeAddressPhone = 'Numéro de téléphone';
  static const storeAddressPhoneHint =
      'Numéro communiqué aux livreurs pour le retrait.';
  static const storeAddressDetailed = 'Adresse détaillée';
  static const storeAddressLocationSummary = 'Emplacement confirmé';
  static const storeAddressPublicContact = 'Contact public (Optionnel)';
  static const storeAddressWilaya = 'Wilaya';
  static const storeAddressCommune = 'Commune';
  static const adminLocationChoose = 'Sélectionner';
  static const adminLocationSearchHint = 'Rechercher…';
  static const adminLocationEmpty = 'Aucun résultat';
  static const adminLocationLoadError =
      'Impossible de charger la liste. Réessayez.';
  static const adminLocationRetry = 'Réessayer';
  static const adminLocationWilayaRequired = 'Sélectionnez d’abord une wilaya.';
  static const adminLocationPairRequired =
      'Wilaya et commune sont obligatoires.';
  static const storeAddressPickupHints = 'Instructions de retrait';
  static const storeProfileMediaSub = 'Logo et photo de couverture';
  static const storeProfileMediaUnavailable = 'Indisponible';
  static const storeProfilePrepUnavailable = 'Indisponible';
  static const storeProfilePreviewUnavailable = 'Aperçu client indisponible.';
  static const profileSettingsTitle = 'Paramètres';
  static const storeProfileTitle = 'Profil magasin';
  static const storeProfileCustomerPreview = 'Aperçu client';
  static const storeProfileGeneral = 'Informations générales';
  static const storeProfileGeneralSub = 'Nom et statut du commerce';
  static const storeGeneralTitle = 'Informations générales';
  static const storeGeneralBranchName = 'Nom de l’établissement';
  static const storeGeneralBranchNameHint =
      'Affiché aux clients pour cet établissement.';
  static const storeGeneralMerchantName = 'Nom du commerce';
  static const storeGeneralMerchantLocked =
      'Nom vérifié par SpeedyGo : non modifiable ici.';
  static const storeGeneralReadOnly =
      'Seuls le propriétaire et le gérant peuvent modifier ces informations.';
  static const storeGeneralPhoneElsewhere =
      'Le téléphone se modifie dans « Adresse et Emplacement ».';
  static const storeGeneralSave = 'Enregistrer';
  static const storeGeneralSaved =
      'Informations de l’établissement enregistrées.';
  static const storeGeneralNameAr = 'Nom en arabe';
  static const storeGeneralNameArHint =
      'Optionnel. Affiché aux clients arabophones.';
  static const storeGeneralDescription = 'Description courte';
  static const storeGeneralDescriptionHint =
      'Optionnel. Présentez votre établissement en quelques phrases.';
  static const storeGeneralPublicEmail = 'E-mail public';
  static const storeGeneralPublicEmailHint =
      'Optionnel. Adresse de contact visible par les clients.';
  static const storeGeneralEmailInvalid = 'Adresse e-mail invalide.';
  static const storeGeneralPreviewTitle = 'Aperçu client';
  static const storeGeneralPreviewOpen = 'Ouvert';
  static const storeGeneralPreviewClosed = 'Fermé';
  static const storeProfileCategory = 'Catégorie de l’établissement';
  static const storeProfileCategorySub = 'Type de commerce affiché aux clients';
  static const storeCategoryTitle = 'Catégorie de l’établissement';
  static const storeCategorySubtitle =
      'Choisissez la catégorie qui décrit le mieux votre activité.';
  static const storeCategorySearch = 'Rechercher une catégorie...';
  static const storeCategoryInfo =
      'Une seule catégorie par établissement. Elle détermine où il apparaît dans l’application client.';
  static const storeCategoryReadOnly =
      'Seuls le propriétaire et les gérants peuvent modifier la catégorie.';
  static const storeCategorySave = 'Enregistrer';
  static const storeCategoryClear = 'Retirer la catégorie';
  static const storeCategorySaved = 'Catégorie enregistrée.';
  static const storeCategoryCleared = 'Catégorie retirée.';
  static const storeCategoryNotSet = 'Non définie';
  static const storeCategoryEmpty =
      'Aucune catégorie disponible pour le moment.';
  static const storeCategoryNoMatch = 'Aucune catégorie ne correspond.';
  static const storeCategoryLoadError = 'Impossible de charger les catégories.';
  static const storeCategorySaveError = 'Enregistrement impossible. Réessayez.';
  static const storeCategoryForbidden =
      'Votre rôle ne permet pas de modifier cet établissement.';
  static const storeCategoryRestricted =
      'Le statut du commerce ne permet pas cette modification.';
  static const storeGeneralNameRequired = 'Le nom ne peut pas être vide.';
  static const storeGeneralSaveError = 'Enregistrement impossible. Réessayez.';
  static const storeGeneralForbidden =
      'Votre rôle ne permet pas de modifier cet établissement.';
  static const storeGeneralRestricted =
      'Le statut du commerce ne permet pas cette modification.';
  static const storeProfileMedia = 'Médias et Logos';
  static const storeProfileAddress = 'Adresse et Emplacement';
  static const storeProfileAddressSub = 'Téléphone, adresse et position GPS';
  static const storeProfileHours = 'Horaires d’ouverture';
  static const storeProfileHoursSub = 'Jours d’ouverture, pauses';
  static const storeProfilePrep = 'Paramètres de préparation';
  static const storeProfileSettings = 'Paramètres du compte';
  static const storeProfileSettingsSub = 'Compte, préférences, déconnexion';
  static const storeProfileNotifications = 'Notifications';
  static const storeProfileNotificationsSub = 'Centre d’alertes';
  static const openingHoursTitle = 'Horaires d’ouverture';
  static const openingHoursEmpty =
      'Aucun horaire configuré pour cet établissement.';
  static const openingHoursSave = 'Enregistrer les horaires';
  static const openingHoursSaved = 'Horaires enregistrés.';
  static const openingHoursLoadError = 'Impossible de charger les horaires.';
  static const openingHoursSaveError = 'Impossible d’enregistrer les horaires.';
  static const openingHoursInvalid =
      'Horaires refusés : vérifiez les chevauchements, y compris après minuit.';
  static const openingHoursConflict =
      'Les horaires ont changé ailleurs. Rechargement effectué — vérifiez puis réessayez.';
  static const openingHoursClosed = 'Fermé';
  static const openingHoursUsual = 'Horaires habituels';
  static const openingHoursNotConfigured = 'Aucun horaire configuré';
  static const openingHoursOpenNow = 'Ouvert actuellement';
  static const openingHoursClosedNow = 'Fermé actuellement';
  static const openingHoursInfo =
      'Les clients peuvent commander uniquement pendant vos heures d’ouverture. Les modifications sont appliquées dès l’enregistrement.';
  static const openingHoursStaffReadOnly =
      'Lecture seule : seuls le propriétaire et les gérants peuvent modifier les horaires.';
  static const openingHoursOpens = 'Ouverture';
  static const openingHoursCloses = 'Fermeture';
  static const openingHoursEditorHint =
      'Jusqu’à 3 plages par jour. Une fermeture avant l’ouverture se termine le lendemain.';
  static const openingHoursAddRange = 'Ajouter une plage';
  static const openingHoursRemoveRange = 'Supprimer la plage';
  static const openingHoursApply = 'Appliquer';
  static const openingHoursNextDay = 'Se termine le lendemain';
  static const openingHoursAllDay = 'Ouvert 24 h/24';
  static const openingHoursDayClosedHint = 'Aucune plage : le jour sera fermé.';
  static const openingHoursIssueOverlap = 'Les plages se chevauchent.';
  static const openingHoursIssueZero =
      'L’ouverture et la fermeture doivent être différentes (00:00–00:00 pour 24 h).';
  static const openingHoursIssueTooMany = 'Maximum 3 plages par jour.';
  static const hoursExceptionsTitle = 'Horaires exceptionnels';
  static const hoursExceptionsNavSub = 'Jours fériés, fermetures ponctuelles';
  static const hoursExceptionsBanner =
      'Ces horaires remplacent vos horaires habituels uniquement pour les dates sélectionnées.';
  static const hoursExceptionsUpcoming = 'Exceptions à venir';
  static const hoursExceptionsEmpty = 'Aucune exception à venir.';
  static const hoursExceptionsAdd = 'Ajouter une exception';
  static const hoursExceptionsEdit = 'Modifier l’exception';
  static const hoursExceptionsDate = 'Date';
  static const hoursExceptionsDateHint = 'Sélectionner une date';
  static const hoursExceptionsDateTaken =
      'Cette date a déjà une exception : l’enregistrement la remplacera.';
  static const hoursExceptionsStatus = 'Statut';
  static const hoursExceptionsOpen = 'Ouvert';
  static const hoursExceptionsClosed = 'Fermé';
  static const hoursExceptionsHours = 'Horaires modifiés';
  static const hoursExceptionsTo = 'à';
  static const hoursExceptionsLabel = 'Motif';
  static const hoursExceptionsLabelHint = 'ex : Jour férié, Travaux…';
  static const hoursExceptionsMessage = 'Message pour les clients (Optionnel)';
  static const hoursExceptionsMessageHint =
      'Enregistré avec l’exception. Pas encore affiché dans l’application client.';
  static const hoursExceptionsCancel = 'Annuler';
  static const hoursExceptionsSave = 'Enregistrer les horaires';
  static const hoursExceptionsSaved = 'Exception enregistrée.';
  static const hoursExceptionsDeleted = 'Exception supprimée.';
  static const hoursExceptionsDeleteTitle = 'Supprimer l’exception ?';
  static String hoursExceptionsDeleteBody(String date) =>
      'Le $date reprendra vos horaires habituels.';
  static const hoursExceptionsDeleteConfirm = 'Supprimer';
  static const hoursExceptionsLoadError =
      'Impossible de charger les horaires exceptionnels.';
  static const hoursExceptionsSaveError =
      'Impossible d’enregistrer l’exception. Vos saisies sont conservées.';
  static const hoursExceptionsDeleteError =
      'Impossible de supprimer l’exception. Réessayez.';
  static const hoursExceptionsConflict =
      'Cette date a été modifiée ailleurs. La liste a été rechargée : vérifiez puis enregistrez à nouveau.';
  static const hoursExceptionsInvalid =
      'Exception refusée : vérifiez la date (aujourd’hui à +365 jours) et les plages.';
  static const hoursExceptionsWeeklyRequired =
      'Configurez d’abord les horaires habituels.';
  static const hoursExceptionsTooMany =
      'Trop d’exceptions à venir (100 maximum).';
  static const hoursExceptionsStaffReadOnly =
      'Lecture seule : seuls le propriétaire et les gérants peuvent modifier les horaires exceptionnels.';
  static const hoursExceptionsDateRequired = 'Sélectionnez une date.';
  static const hoursExceptionsLabelRequired = 'Indiquez un motif.';
  static const hoursExceptionsIntervalsRequired =
      'Ajoutez au moins une plage horaire.';
  static const hoursExceptionsSameDay =
      'Chaque plage doit finir le même jour (00:00 = minuit).';
  static const hoursExceptionsHelpTitle = 'Ordre d’application';
  static const hoursExceptionsHelpBody =
      'Une fermeture forcée ou temporaire de l’établissement s’applique toujours en premier. '
      'Sinon, une exception remplace les horaires habituels pour sa date (heure d’Alger). '
      'Les autres jours suivent les horaires habituels.';
  static const hoursExceptionsHelpOk = 'Compris';
  static String hoursExceptionsToday(String label) =>
      'Exception aujourd’hui : $label';
  static const availabilityTitle = 'État du magasin';
  static const availabilityEstablishment = 'Établissement';
  static const availabilityOpen = 'Ouvert';
  static const availabilityClosed = 'Fermé';
  static const availabilityFollowSchedule = 'Selon les horaires';
  static const availabilityForceClosed = 'Fermé';
  static const availabilitySave = 'Enregistrer les modifications';
  static const availabilitySaving = 'Enregistrement…';
  static const availabilitySaved = 'État du magasin enregistré.';
  static const availabilityClosureSaved = 'Fermeture enregistrée.';
  static const availabilityLoadError =
      'Impossible de charger l’état du magasin.';
  static const availabilitySaveError =
      'Impossible d’enregistrer l’état du magasin.';
  static const availabilityConflict =
      'L’état a changé ailleurs. Rechargement effectué — vérifiez puis réessayez.';
  static const availabilityReopenTitle = 'Rouvrir selon les horaires';
  static const availabilityReopenOutsideHoursBody =
      'Vous êtes hors des horaires hebdomadaires. Le magasin restera Fermé jusqu’à la prochaine ouverture prévue.';
  static const availabilityConfirmReopen = 'Confirmer';
  static String availabilityLastUpdate(DateTime updatedAt, DateTime now) {
    final minutes = now.difference(updatedAt).inMinutes;
    final String when;
    if (minutes < 1) {
      when = 'à l’instant';
    } else if (minutes < 60) {
      when = 'il y a $minutes min';
    } else if (minutes < 24 * 60) {
      when = 'il y a ${minutes ~/ 60} h';
    } else {
      final local = updatedAt.toUtc().add(const Duration(hours: 1));
      String two(int v) => v.toString().padLeft(2, '0');
      when =
          'le ${two(local.day)}/${two(local.month)} à '
          '${two(local.hour)}:${two(local.minute)}';
    }
    return 'Dernière mise à jour : $when';
  }

  static const availabilityToday = 'Aujourd’hui';
  static const availabilityClosedToday = 'Fermé aujourd’hui';
  static const availabilityModifyHours = 'Modifier';
  static const availabilityQuickPause = 'Pause rapide';
  static const availabilityQuickPauseHint =
      'Fermer temporairement pour un rush en cuisine.';
  static const availabilityPause30 = '30 MIN';
  static const availabilityPause60 = '1 HEURE';
  static const availabilityActiveOrdersUnknown = 'Commandes en cours';
  static const availabilityCloseWarningTitle =
      'Attention : fermeture immédiate';
  static String availabilityCloseWarningBody(int? count) => count == null
      ? 'Toutes les nouvelles commandes seront rejetées. Les commandes actives doivent toujours être traitées.'
      : count == 0
      ? 'Toutes les nouvelles commandes seront rejetées. Aucune commande active en cours.'
      : 'Toutes les nouvelles commandes seront rejetées. Vous devez toujours traiter ${count == 1 ? 'la commande active' : 'les $count commandes actives'}.';
  static const availabilityStaffReadOnly =
      'Lecture seule : seuls le propriétaire et les gérants peuvent modifier l’état du magasin.';
  static const availabilityBannerOpenTitle = 'Magasin en ligne';
  static const availabilityBannerOpenBody =
      'Les clients peuvent passer commande et voir votre menu normalement.';
  static const availabilityBannerClosedTitle = 'Magasin hors ligne';
  static const availabilityBannerClosedBody =
      'Les clients ne peuvent plus passer de nouvelles commandes.';
  static const availabilityBannerScheduleClosedTitle =
      'Selon les horaires — actuellement fermé';
  static const availabilityBannerScheduleClosedBody =
      'Le magasin suit le planning. Il s’ouvrira automatiquement aux prochaines heures.';
  static String availabilityActiveOrders(int count) =>
      '$count commande${count == 1 ? '' : 's'} en cours';
  static const availabilityReasonPeak = 'Forte charge (cuisine)';
  static const availabilityReasonTechnical = 'Problème technique';
  static const availabilityReasonStock = 'Rupture de stock';
  static const availabilityReasonLunch = 'Pause déjeuner';
  static const temporaryClosureTitle = 'Fermeture temporaire';
  static const temporaryClosureActionRequired = 'Action requise';
  static const temporaryClosureImpactLead =
      'La fermeture suspendra l’acceptation de nouvelles commandes. ';
  static String temporaryClosureImpactCount(int count) =>
      count == 1 ? 'La commande en cours' : 'Les $count commandes en cours';
  static String temporaryClosureImpactTail(int count) => count == 1
      ? ' sera maintenue et doit être préparée.'
      : ' seront maintenues et doivent être préparées.';
  static const temporaryClosureImpactNone = 'Aucune commande en cours.';
  static const temporaryClosureImpactUnknown =
      'Les commandes en cours seront maintenues et doivent être préparées.';
  static const temporaryClosureReason = 'Motif de la fermeture';
  static const temporaryClosureReopen = 'Réouverture prévue';
  static const temporaryClosure30m = 'Dans 30 minutes';
  static const temporaryClosure1h = 'Dans 1 heure';
  static const temporaryClosurePickTime = 'Choisir une heure…';
  static String temporaryClosureAt({
    required bool today,
    required String hhmm,
  }) => '${today ? 'Aujourd’hui' : 'Demain'} à $hhmm';
  static const temporaryClosureIndefinite = 'Indéfinie (Manuel)';
  static const temporaryClosureImageImpact =
      'Impact sur votre visibilité : Les clients verront votre établissement comme « Fermé temporairement ».';
  static const temporaryClosureStaffReadOnly =
      'Seuls le propriétaire et les gérants peuvent fermer le magasin.';
  static const temporaryClosurePastTime =
      'L’heure de réouverture est déjà passée. Choisissez une nouvelle heure.';
  static const temporaryClosureMessage = 'Message client';
  static const temporaryClosureOptional = 'Facultatif';
  static const temporaryClosureMessageHint =
      'Ex: Nous sommes complets pour le moment, revenez dans 30 minutes !';
  static const temporaryClosureManualReopenHint =
      'Vous pourrez rouvrir manuellement à tout moment.';
  static const temporaryClosureConfirm = 'Confirmer la fermeture';
  static const storeProfileAvailability = 'État du magasin';
  static const storeProfileAvailabilitySub =
      'Selon les horaires, fermeture, pause';
  static const notificationsTitle = 'Notifications';
  static const notificationsEmpty = 'Aucune notification pour le moment.';
  static const notificationsLoadError =
      'Impossible de charger les notifications.';
  static const notificationsToday = 'Aujourd’hui';
  static const notificationsYesterday = 'Hier';
  static const notificationsJustNow = 'À l’instant';
  static const notificationsMarkAllRead = 'Tout marquer comme lu';
  static const notificationsFilterAll = 'Tout';
  static const notificationsFilterOrders = 'Commandes';
  static const notificationsOpenDetails = 'Détails';
  static const notificationsOrderStale =
      'Cette commande n’est plus en attente d’acceptation.';
  static const alertNewOrder = 'NOUVELLE COMMANDE';
  static const alertReceivedAt = 'Reçue à';
  static const alertPayment = 'Paiement';
  static const alertViewDetails = 'Voir les détails';
  static const alertRefuse = 'Refuser';
  static const alertItems = 'Articles';
  static const alertOrderTotal = 'Sous-total marchandises';
  static const alertOrderLabel = 'Commande';
  static const alertDismiss = 'Fermer';
  static const alertSeeList = 'Voir la liste';
  static const notifSettingsTitle = 'Paramètres de notification';
  static const notifSettingsScreenTitle = 'Alertes';
  static const notifSettingsOsEnabled =
      'Permission iOS autorisée. Le Push natif n’est pas encore actif.';
  static const notifSettingsOsDenied =
      'Permission iOS refusée (modifiable dans Réglages). Le Push natif n’est pas encore actif.';
  static const notifSettingsOsNotAsked =
      'Permission de notification : pas encore autorisée.';
  static const notifSettingsOsOpen = 'Paramètres système';
  static const notifSettingsSwitchesNote =
      'Uniquement quand l’application est ouverte.';
  static const notifSettingsInAppSection = 'DANS L’APPLICATION';
  static const notifSettingsCriticalWarning =
      'Les commandes entrantes critiques ne peuvent pas être totalement réduites au silence sans risque de retard.';
  static const notifSettingsPushNotConfigured = 'Non configuré';
  static const notifSettingsSoundSection = 'ALERTES SONORES';
  static const notifSettingsSound = 'Sonnerie des nouvelles commandes';
  static const notifSettingsVibrationSection = 'VIBRATIONS';
  static const notifSettingsVibration = 'Vibration lors d’une commande';
  static const notifSettingsPushSection = 'ALERTES PUSH';
  static const notifSettingsOsEnabledPush =
      'Permission de notification : autorisée.';
  static const notifSettingsOsDeniedPush =
      'Permission de notification refusée : activez-la dans les réglages système.';
  static const notifSettingsNativePush = 'Notifications hors application';
  static const notifSettingsNativePushSub =
      'Application fermée ou en arrière-plan.';
  static const notifSettingsLockScreenNote =
      'Aperçu sur l’écran verrouillé : selon les réglages système.';
  static const notifPushStatusRegistered =
      'Cet appareil est enregistré pour les notifications.';
  static const notifPushStatusPending = 'Enregistrement de l’appareil…';
  static const notifPushStatusDenied =
      'Permission refusée : pas de notification hors application.';
  static const notifPushStatusDisabled = 'Désactivées sur cet appareil.';
  static const notifPushStatusTokenUnavailable =
      'Jeton de notification indisponible sur cet appareil.';
  static const notifPushStatusFailed =
      'Enregistrement impossible pour le moment. Réessayez plus tard.';
  static const pushOrderInaccessible =
      'Cette commande n’est pas accessible avec ce compte.';
  static const notifSettingsForeground = 'Alertes dans l’application';
  static const notifSettingsPushUnavailable =
      'Les notifications hors application ne sont pas encore disponibles.';
  static const notifSettingsPushBlocked =
      'Push natif (APNs/FCM) non configuré : la permission iOS ne suffit pas.';
  static const notifSettingsSave = 'Enregistrer les paramètres';
  static const notifSettingsSaved = 'Paramètres enregistrés.';
  static const profileRole = 'Rôle';
  static const profileMerchant = 'Commerce';
  static const profileBranch = 'Établissement';
  static const profileRoleOwner = 'Propriétaire';
  static const profileRoleManager = 'Responsable';
  static const profileRoleStaff = 'Équipe';
  static const profileSectionAccount = 'Compte';
  static const profileSectionStore = 'Établissement';
  static const profileSectionOps = 'Opérations du magasin';
  static const profileSectionPrefs = 'Préférences';
  static const profileSectionSupport = 'Support & légal';
  static const profileInfoReadonly = 'Informations du commerce';
  static const profileBranchStatus = 'Statut opérationnel';
  static const profileUnavailableItem = 'Non disponible dans cette version';
  static const switchBranch = 'Changer d’établissement';
  static const logoutConfirmTitle = 'Déconnexion';
  static const logoutConfirmBody =
      'Voulez-vous vraiment vous déconnecter de SpeedyGo Merchant ?';
  static const logoutConfirmAction = 'Déconnexion';
  static const settingsProfileRow = 'Profil';
  static const settingsNotificationsOff = 'Désactivé';
  static const settingsSupportSection = 'Support';
  static const settingsHelpCenter = 'Centre d’aide';
  static const logoutConnected = 'Connecté';
  static const logoutWarningTitle = 'Attention aux opérations en cours';
  static String logoutWarningBody({
    required bool hasActiveOrders,
    required bool storeOpen,
  }) => switch ((hasActiveOrders, storeOpen)) {
    (true, true) =>
      'Vous avez des commandes actives et le magasin est actuellement ouvert.',
    (true, false) => 'Vous avez des commandes actives.',
    _ => 'Le magasin est actuellement ouvert.',
  };
  static const logoutActiveOrders = 'Commandes en cours';
  static const logoutStoreState = 'État du magasin';
  static const logoutStoreOpen = 'Ouvert';
  static const logoutStoreClosed = 'Fermé';
  static const logoutHandoverAdvice =
      'Assurez-vous qu’un autre gestionnaire est disponible pour traiter les commandes avant de vous déconnecter.';
  static const logoutDataPreserved =
      'Vos données, le catalogue et l’historique des commandes seront préservés.';
  static const logoutCancel = 'Annuler et retourner';
  static const cancel = 'Annuler';
  static const attentionRequired =
      'Certaines pièces nécessitent votre attention.';
  static const submitVerification = 'Soumettre le dossier';
  static const submitVerificationUnavailable =
      'La soumission n’est pas encore possible : des pièces obligatoires manquent ou sont incomplètes.';
  static const permissionDenied = 'Permission refusée par le serveur.';

  static const regTitle = 'Inscription';
  static const regStepOf = 'Étape';
  static const regAccountTitle = 'Configuration du compte';
  static const regRoleLabel = 'Rôle';
  static const regOwner = 'Propriétaire';
  static const regOperator = 'Opérateur';
  static const regOwnerHint =
      'Créez et gérez votre commerce en tant que propriétaire.';
  static const regOperatorHint =
      'Rejoindre un commerce existant nécessite une invitation et le code remis par le propriétaire.';
  static const regOperatorUnsupported =
      'Pour rejoindre un commerce, ouvrez vos invitations reçues et saisissez le code remis par le propriétaire. SpeedyGo n’envoie pas de SMS.';
  static const regOperatorOpenInvitations = 'Voir mes invitations';
  static const regSelectRole = 'Choisissez un rôle pour continuer.';
  static const regContactTitle = 'Contact';
  static const regAccountContinue = 'Continuer l’inscription';
  static const regVerifiedPhone = 'Numéro de téléphone (vérifié)';
  static const regVerifiedPhoneHint =
      'Ce numéro a été vérifié lors de la connexion. Il n’est pas modifiable ici.';
  static const regEmailUnsupported =
      'L’e-mail ne peut pas être enregistré à cette étape.';
  static const regConsentUnsupported =
      'Consultez les conditions générales et la politique de confidentialité SpeedyGo avant de continuer.';
  static const regActivityTitle = 'Informations du commerce';
  static const regActivityBody =
      'Indiquez le nom sous lequel votre commerce sera identifié.';
  static const regLegalIdUnsupported =
      'Les pièces d’identité professionnelle se déposent à l’étape Documents.';
  static const regDocsTitle = 'Documents d’entreprise';
  static const regDocsBody = 'Ajoutez les documents demandés.';
  static const regDocsRequired =
      'Téléversez toutes les pièces obligatoires avant de continuer.';
  static const regDocsTipsTitle = 'Conseils pour une capture nette';
  static const regDocsTipLight =
      'Privilégiez un éclairage naturel et uniforme pour éviter les zones d’ombre.';
  static const regDocsTipFrame =
      'Cadrez bien le document : tous les coins doivent être visibles.';
  static const regDocsFormats =
      'Formats acceptés : PDF, JPEG ou PNG (10 Mo max).';
  static const regDocsContinue = 'Continuer';
  static const regDocsContinueFinal = 'Continuer vers l’étape finale';
  static const regDocsAppBar = 'Vérification';
  static const regDocsTipFlash =
      'Désactivez le flash pour éviter les reflets sur les surfaces plastifiées.';
  static const regDocsPrivacy =
      'Vos documents sont transmis à SpeedyGo uniquement pour la vérification de votre commerce.';
  static const regFileTooLarge = 'Fichier trop volumineux (max. 10 Mo).';
  static const regFileTypeUnsupported =
      'Format non accepté. Utilisez PDF, JPEG ou PNG.';
  static const regPickerUnavailable =
      'Impossible d’ouvrir le sélecteur de fichiers. Réessayez après avoir relancé l’application.';
  static const regPickDocument = 'Ajouter';
  static const regReplaceDocument = 'Remplacer';
  static const regEstablishmentTitle = 'Détails de l’établissement';
  static const regEstablishmentBody =
      'Renseignez les informations de votre établissement.';
  static const regIdentitySection = 'Nom de l’établissement';
  static const regBranchNameFrLabel = 'Nom de l’établissement';
  static const regCommerceContext = 'Commerce';
  static const regContactSection = 'Contact de l’établissement';
  static const regCategorySection = 'Catégorie';
  static const regCategoryReadonly =
      'La catégorie sera attribuée après vérification.';
  static const regAddressSection = 'Adresse et emplacement';
  static const regAddressGuidance =
      'Saisissez l’adresse de votre établissement.';
  static const regAddressExactLabel = 'Adresse exacte';
  static const regPickupPlace = 'Lieu de retrait';
  static const regChooseOnMap = 'Choisir sur la carte';
  static const regLocationConfirmed = 'Position confirmée';
  static const regLocationEdit = 'Modifier';
  static const regLocationRequired =
      'Confirmez le lieu de retrait sur la carte avant de continuer.';
  static const regLocationPickerTitle = 'Position du magasin';
  static const regLocationConfirm = 'Confirmer l’emplacement';
  static const regLocationUseGps = 'Utiliser ma position';
  static const regLocationMoveHint =
      'Déplacez la carte pour placer le pin sur le lieu de retrait, ou utilisez votre position GPS.';
  static const regLocationGpsSuggestion =
      'Position GPS proposée — confirmez uniquement si c’est le lieu de retrait de l’établissement.';
  static const regLocationDenied =
      'Autorisation de localisation refusée. Placez le pin manuellement sur la carte.';
  static const regLocationDeniedForever =
      'Localisation désactivée pour SpeedyGo. Activez-la dans Réglages, ou placez le pin manuellement.';
  static const regLocationServicesDisabled =
      'Les services de localisation sont désactivés. Placez le pin manuellement sur la carte.';
  static const regLocationUnavailable =
      'Position GPS indisponible. Placez le pin manuellement sur la carte.';
  static const regBranchPhoneLabel = 'Numéro de téléphone';
  static const regBranchPhoneHint =
      'Numéro de contact de l’établissement (distinct du numéro de connexion).';
  static const regPreviewLabel = 'Aperçu (données saisies — non publié)';
  static const regBranchIncomplete =
      'Nom, téléphone et adresse de l’établissement sont requis.';
  static const regCoordsInvalid =
      'Latitude (−90…90) et longitude (−180…180) invalides.';
  static const regCoordsConfirmHint =
      'Indiquez le lieu de retrait sur la carte, puis confirmez.';
  static const regReviewTitle = 'Révision';
  static const regReviewDocsTitle = 'Documents légaux';
  static const regReviewBranchTitle = 'Établissement';
  static const regReviewLocation = 'Localisation';
  static const regReviewBody =
      'Veuillez vérifier attentivement vos informations avant la soumission finale pour éviter tout retard de validation.';
  static const regSubmit = 'Soumettre pour vérification';
  static const regCorrectionTitle = 'Correction du dossier';
  static const regCorrectionActionRequired = 'Action requise';
  static String regCorrectionIntro(String merchantName) =>
      'Corrigez les éléments nécessaires puis soumettez à nouveau. '
      'Votre établissement $merchantName sera activé après validation.';
  static const regCorrectionDetails = 'Détails du dossier';
  static const regCorrectionSubmit = 'Soumettre les corrections';
  static const regContinue = 'Continuer';
  static const regEdit = 'Modifier';
  static const regMissingSteps = 'Complétez votre dossier';
  static const regRejectionNoReason =
      'Des corrections sont nécessaires. Mettez à jour les pièces concernées puis soumettez à nouveau.';
  static const regApprovedNext =
      'Votre commerce est approuvé. Complétez ensuite horaires et catalogue lorsque disponibles.';

  static const legalSectionTitle = 'Conditions et déclaration';
  static const legalSectionBody =
      'Avant de soumettre, lisez et acceptez les conditions suivantes. '
      'Votre acceptation est enregistrée avec le dossier.';
  static const legalTermsLabel =
      'J’ai lu et j’accepte les conditions générales marchand SpeedyGo.';
  static const legalDeclarationLabel =
      'Je certifie que les informations et les documents du dossier sont exacts et complets.';
  static String legalVersionTag(String version) => 'Version $version';
  static const legalLoading = 'Chargement des conditions…';
  static const legalLoadFailed =
      'Impossible de charger les conditions. Vérifiez votre connexion puis réessayez.';
  static const legalIncomplete =
      'Les conditions ne sont pas disponibles pour le moment. Réessayez plus tard.';
  static const legalRetry = 'Réessayer';
  static const legalConsentRequired =
      'Acceptez les conditions et la déclaration d’exactitude pour soumettre le dossier.';
  static const legalVersionOutdated =
      'Les conditions ont été mises à jour. Relisez-les puis acceptez à nouveau avant de soumettre.';
  static const legalConsentHint =
      'Cochez les deux cases pour activer la soumission.';
  static const legalContentLink = 'Référence du texte';

  static const issuesTitle = 'Points à corriger';
  static const issuesApplicationTitle = 'Informations du dossier';
  static const issuesDocumentTitle = 'Documents à remplacer';
  static String issuesDocumentConcerned(String documentTitle) =>
      'Pièce concernée : $documentTitle';
  static const issuesReplaceDocument = 'Remplacer ce document';
  static const issuesResolved = 'Corrigé';
  static const issuesFixHint =
      'Corrigez les points ci-dessus (remplacez les documents concernés si indiqué), acceptez à nouveau les conditions, puis soumettez le dossier.';
  static String issuesRemaining(int count) => count == 1
      ? '1 point restant à corriger'
      : '$count points restants à corriger';

  static const dossierAttemptLabel = 'Tentative n°';
  static const dossierSubmittedAtLabel = 'Soumis le';
  static const dossierReviewedAtLabel = 'Examiné le';
  static const dossierConsentLabel = 'Conditions acceptées';
  static String dossierConsentVersions(String terms, String declaration) =>
      'Conditions $terms · Déclaration $declaration';

  // Personnel et Accès (`staff_and_account_access_french`). Members are known
  // by phone only; no SMS or e-mail is ever sent, the owner shares a code.
  static const settingsTeamRow = 'Gestion de l’équipe';
  static const settingsTeamInvitationsRow = 'Invitations reçues';
  static const teamTitle = 'Personnel et Accès';
  static const teamStoreContext = 'Gestion de l’équipe';
  static const teamActiveMembers = 'Membres actifs';
  static const teamPendingInvitations = 'Invitations en attente';
  static const teamRolesSummary = 'Résumé des rôles';
  static const teamRoleOwner = 'Propriétaire';
  static const teamRoleManager = 'Gestionnaire';
  static const teamRoleStaff = 'Équipe';
  static const teamOwnerBadge = 'Admin';
  static const teamSelfBadge = 'Vous';
  static const teamPhoneUnavailable = 'Numéro indisponible';
  static const teamRevoke = 'Révoquer';
  static const teamChangeRole = 'Modifier le rôle';
  static const teamRegenerateCode = 'Régénérer le code';
  static const teamCancelInvitation = 'Annuler';
  static const teamInviteMember = 'Inviter un membre';
  static const teamInvitationExpired = 'Expirée';
  static String teamRoleLine(String role) => 'Rôle : $role';
  static String teamExpiresOn(String date) => 'Expire le $date';
  static const teamEmptyMembers = 'Aucun membre actif pour le moment.';
  static const teamEmptyInvitations = 'Aucune invitation en attente.';
  static const teamLoadError =
      'Impossible de charger l’équipe. Vérifiez votre connexion puis réessayez.';
  static const teamForbiddenTitle = 'Accès réservé';
  static const teamForbiddenBody =
      'La gestion de l’équipe est réservée aux propriétaires et aux gestionnaires.';
  static const teamSummaryOwner =
      'Invite, modifie les rôles et révoque l’accès des membres.';
  static const teamSummaryManager =
      'Consulte la liste de l’équipe et les invitations. Ne peut ni inviter, ni modifier les rôles, ni révoquer.';
  static const teamSummaryStaff = 'N’a pas accès à la gestion de l’équipe.';
  static const teamSummaryScope =
      'Les accès couvrent tous les établissements du commerce : il n’existe pas d’accès par établissement.';

  static const teamInviteTitle = 'Inviter un membre';
  static const teamInviteHint =
      'Aucun SMS ni e-mail n’est émis par SpeedyGo. Un code d’acceptation vous sera remis : transmettez-le vous-même à la personne invitée.';
  static const teamInvitePhoneLabel = 'Numéro de téléphone';
  static const teamInvitePhoneHint = '550 12 34 56';
  static const teamInvitePhoneHelper =
      'Numéro avec lequel la personne se connecte à SpeedyGo.';
  static const teamInvitePhoneInvalid =
      'Saisissez un numéro mobile algérien valide (9 chiffres).';
  static const teamInviteRoleLabel = 'Rôle';
  static const teamInviteCreate = 'Créer l’invitation';
  static const teamRoleManagerHint =
      'Peut consulter l’équipe. Aucun droit de gestion.';
  static const teamRoleStaffHint =
      'Accès opérationnel, sans accès à la gestion de l’équipe.';

  static const teamCodeTitle = 'Code d’acceptation';
  static const teamCodeRegeneratedTitle = 'Nouveau code d’acceptation';
  static String teamCodeInstruction(String phone) =>
      'Aucun SMS ni e-mail n’est émis par SpeedyGo. Copiez ce code et transmettez-le vous-même à $phone. Il ne sera plus affiché après la fermeture de cette fenêtre.';
  static const teamCodeRegeneratedNote = 'L’ancien code ne fonctionne plus.';
  static const teamCodeCopy = 'Copier le code';
  static const teamCodeCopied = 'Code copié.';
  static const teamCodeDone = 'Terminer';

  static const teamRevokeTitle = 'Révoquer l’accès ?';
  static String teamRevokeBody(String phone) =>
      '$phone perdra l’accès à ce commerce et ses sessions seront fermées. Son compte SpeedyGo n’est pas supprimé.';
  static const teamRevoked = 'Accès révoqué.';
  static const teamCancelInviteTitle = 'Annuler l’invitation ?';
  static String teamCancelInviteBody(String phone) =>
      'Le code d’acceptation de $phone ne fonctionnera plus.';
  static const teamCancelInviteConfirm = 'Annuler l’invitation';
  static const teamKeep = 'Conserver';
  static const teamInviteCancelled = 'Invitation annulée.';
  static const teamRoleSheetTitle = 'Modifier le rôle';
  static const teamRoleSheetHint =
      'Si le rôle réduit ses droits, les sessions du membre sont fermées et il devra se reconnecter.';
  static const teamRoleSave = 'Enregistrer';
  static const teamRoleUpdated = 'Rôle mis à jour.';

  static const teamErrorGeneric =
      'Action impossible pour le moment. Réessayez.';
  static const teamErrorConflict =
      'La liste a changé entre-temps. Elle vient d’être actualisée : vérifiez puis réessayez.';
  static const teamErrorDuplicateMember =
      'Ce numéro fait déjà partie de l’équipe.';
  static const teamErrorDuplicateInvite =
      'Une invitation est déjà en attente pour ce numéro.';
  static const teamErrorOwnerProtected =
      'Le propriétaire ne peut pas être modifié ici.';
  static const teamErrorSelf =
      'Vous ne pouvez pas modifier votre propre accès.';
  static const teamErrorInviteGone = 'Cette invitation n’existe plus.';
  static const teamErrorInviteExpired =
      'Cette invitation a expiré. Demandez un nouveau code au propriétaire.';
  static const teamErrorCodeInvalid = 'Code incorrect.';
  static const teamErrorPhoneMismatch =
      'Cette invitation est destinée à un autre numéro.';
  static const teamErrorInvalidInput =
      'Vérifiez le numéro et le rôle puis réessayez.';

  static const teamInvitationsTitle = 'Invitations reçues';
  static const teamInvitationsHint =
      'Invitations adressées à votre numéro. Saisissez le code remis par le propriétaire pour les accepter.';
  static const teamInvitationsEmpty =
      'Aucune invitation en attente pour votre numéro.';
  static const teamInvitationsLoadError =
      'Impossible de charger vos invitations. Réessayez.';
  static const teamAccept = 'Accepter';
  static const teamAcceptTitle = 'Saisir le code d’acceptation';
  static const teamAcceptCodeLabel = 'Code remis par le propriétaire';
  static const teamAcceptCodeInvalid =
      'Le code comporte 64 caractères (chiffres et lettres a à f).';
  static const teamAcceptConfirm = 'Accepter l’invitation';
  static String teamAccepted(String merchantName) =>
      'Invitation acceptée. Vous avez maintenant accès à $merchantName.';

  static String errorForCode(String? code) {
    switch (code) {
      case 'AUTH_INVALID_OTP':
        return 'Code incorrect.';
      case 'AUTH_OTP_EXPIRED':
        return 'Code expiré. Demandez-en un nouveau.';
      case 'AUTH_OTP_ATTEMPTS_EXCEEDED':
        return 'Trop de tentatives. Demandez un nouveau code.';
      case 'AUTH_RATE_LIMITED':
        return 'Trop de demandes. Réessayez plus tard.';
      case 'AUTH_ACCOUNT_SUSPENDED':
      case 'AUTH_ACCOUNT_DISABLED':
        return 'Compte indisponible.';
      case 'AUTH_INVALID_TOKEN':
      case 'AUTH_SESSION_REVOKED':
      case 'AUTH_SESSION_EXPIRED':
        return sessionExpired;
      case 'MERCHANT_ROLE_FORBIDDEN':
        return permissionDenied;
      case 'MERCHANT_STATUS_RESTRICTED':
        return accessRestrictedBody;
      case 'MERCHANT_NOT_FOUND':
        return 'Commerce introuvable.';
      case 'MERCHANT_ORDER_NOT_FOUND':
        return 'Commande introuvable.';
      case 'MERCHANT_ORDER_ALREADY_ACCEPTED':
        return 'Cette commande a déjà été acceptée.';
      case 'MERCHANT_ORDER_NOT_REJECTABLE':
        return 'Cette commande ne peut plus être refusée.';
      case 'MERCHANT_ORDER_INVALID_TRANSITION':
        return 'Cette action n’est plus possible pour l’état actuel.';
      case 'MERCHANT_ORDER_PAYMENT_NOT_READY':
        return 'Le paiement n’est pas encore prêt pour démarrer la préparation.';
      case 'MERCHANT_ORDER_PREP_ESTIMATE_INVALID':
        return 'Temps de préparation invalide.';
      case 'MERCHANT_ORDER_PREP_ESTIMATE_CONFLICT':
        return 'L’estimation a changé. Actualisez puis réessayez.';
      case 'MERCHANT_ORDER_PREP_ESTIMATE_NOT_ALLOWED':
        return 'La mise à jour du temps n’est plus possible pour cet état.';
      case 'MERCHANT_VERIFICATION_NOT_READY':
        return submitVerificationUnavailable;
      case 'LEGAL_ACCEPTANCE_REQUIRED':
        return legalConsentRequired;
      case 'LEGAL_VERSION_OUTDATED':
        return legalVersionOutdated;
      default:
        return networkError;
    }
  }
}
