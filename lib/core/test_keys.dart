import 'package:flutter/widgets.dart';

/// Satu file Key untuk test (docs/05 §2). Layar fitur memakai ini; jangan finder berbasis teks UI.
abstract final class K {
  // auth
  static const loginPhone = Key('login_phone');
  static const loginPassword = Key('login_password');
  static const loginSubmit = Key('login_submit');
  static const welcomeRegister = Key('welcome_register');
  static const welcomeLogin = Key('welcome_login');
  static const registerName = Key('register_name');
  static const registerPhone = Key('register_phone');
  static const registerEmail = Key('register_email');
  static const registerPassword = Key('register_password');
  static const registerConsent = Key('register_consent');
  static const registerSubmit = Key('register_submit');
  static const otpInput = Key('otp_input');
  static const otpSubmit = Key('otp_submit');
  static const otpResend = Key('otp_resend');
  static const roleSeeker = Key('role_seeker');
  static const roleAssistant = Key('role_assistant');
  static const roleContinue = Key('role_continue');
  static const roleSwitchChip = Key('role_switch_chip');
  static const logout = Key('logout');

  // shell
  static Key tab(String id) => Key('tab_$id');
  static const notificationBell = Key('notification_bell');

  // verification
  static const verificationStart = Key('verification_start');
  static const verificationLater = Key('verification_later');
  static const ktpCapture = Key('ktp_capture');
  static const selfieCapture = Key('selfie_capture');
  static const nikInput = Key('nik_input');
  static const verificationSubmit = Key('verification_submit');
  static const verificationStatus = Key('verification_status');

  // listing / application
  static Key listingCard(String ulid) => Key('listing_$ulid');
  static const listingTitle = Key('listing_title');
  static const listingCreate = Key('listing_create');
  static const listingPay = Key('listing_pay');
  static const listingClose = Key('listing_close');
  static const applyMessage = Key('apply_message');
  static const applyRate = Key('apply_rate');
  static const applySubmit = Key('apply_submit');
  static const applyWithdraw = Key('apply_withdraw');
  static Key applicantCard(String ulid) => Key('applicant_$ulid');
  static const applicationShortlist = Key('application_shortlist');
  static const applicationReject = Key('application_reject');
  static const applicationAccept = Key('application_accept');

  // interview
  static const interviewPropose = Key('interview_propose');
  static const interviewConfirm = Key('interview_confirm');
  static const interviewJoin = Key('interview_join');
  static const interviewEvaluate = Key('interview_evaluate');

  // chat
  static Key conversationTile(String ulid) => Key('conversation_$ulid');
  static const chatInput = Key('chat_input');
  static const chatSend = Key('chat_send');
  static const chatMenu = Key('chat_menu');
  static Key messageBubble(String id) => Key('message_$id');

  // booking / payment
  static const agreementRate = Key('agreement_rate');
  static const agreementSubmit = Key('agreement_submit');
  static const agreementApprove = Key('agreement_approve');
  static const agreementCounter = Key('agreement_counter');
  static Key periodTile(String ulid) => Key('period_$ulid');
  static const payButton = Key('pay_button');
  static const paymentChecking = Key('payment_checking');
  static const periodStatus = Key('period_status');
  static const confirmComplete = Key('confirm_complete');
  static const bookingCancel = Key('booking_cancel');
  static const bookingPay = Key('booking_pay');
  static const bookingConfirmOpen = Key('booking_confirm_open');
  static const bookingReport = Key('booking_report');
  static const bookingChat = Key('booking_chat');
  static const bookingRate = Key('booking_rate');
  static const agreementPeriodPlus = Key('agreement_period_plus');
  static const agreementPeriodMinus = Key('agreement_period_minus');
  static const agreementStart = Key('agreement_start');
  static Key contractCard(String ulid) => Key('contract_$ulid');
  static const paymentPending = Key('payment_pending');
  static const confirmReport = Key('confirm_report');
  static const cancelSubmit = Key('cancel_submit');
  static Key cancelReason(int i) => Key('cancel_reason_$i');

  // wallet
  static const walletBalance = Key('wallet_balance');
  static const payoutAmount = Key('payout_amount');
  static const payoutSubmit = Key('payout_submit');
  static const bankNumber = Key('bank_number');
  static const bankSave = Key('bank_save');
  static const bankName = Key('bank_name');
  static const bankHolder = Key('bank_holder');
  static const bankEdit = Key('bank_edit');
  static const walletPayoutOpen = Key('wallet_payout_open');
  static const walletBankOpen = Key('wallet_bank_open');
  static const payoutAll = Key('payout_all');
  static const payoutResult = Key('payout_result');

  // rating / report
  static const ratingStars = Key('rating_stars');
  static const ratingSubmit = Key('rating_submit');
  static const reportDescription = Key('report_description');
  static const reportSubmit = Key('report_submit');
  static const shareConsent = Key('share_consent');
  static const shareDecline = Key('share_decline');
  static const reportRevokeShare = Key('report_revoke_share');
  static const reportAddEvidence = Key('report_add_evidence');
  static Key reportType(String name) => Key('report_type_$name');

  // notification
  static const notificationMarkAll = Key('notification_mark_all');
  static Key notificationTile(String ulid) => Key('notification_$ulid');

  // listing / application / interview (tambahan)
  static Key applicationCard(String ulid) => Key('application_$ulid');
  static Key invitationCard(String ulid) => Key('invitation_$ulid');
  static const searchField = Key('search_field');
  static const filterRate = Key('filter_rate');
  static Key otpBox(int i) => ValueKey('otp-box-$i');
  static const filterButton = Key('filter_button');
  static const filterApply = Key('filter_apply');
  static const filterReset = Key('filter_reset');
  static Key assistantCard(String ulid) => Key('assistant_$ulid');
  static Key option(String value) => Key('option_$value');
  static const inviteSubmit = Key('invite_submit');
  static const inviteMessage = Key('invite_message');
  static Key inviteListing(String ulid) => Key('invite_listing_$ulid');
  static const wizardNext = Key('wizard_next');
  static const wizardBack = Key('wizard_back');
  static const wizardSaveDraft = Key('wizard_save_draft');
  static const listingDescription = Key('listing_description');
  static const listingPeriodCount = Key('listing_period_count');
  static const listingBudgetMin = Key('listing_budget_min');
  static const listingBudgetMax = Key('listing_budget_max');
  static const listingStartDate = Key('listing_start_date');
  static const listingRequireSkck = Key('listing_require_skck');
  static const listingSkipInterview = Key('listing_skip_interview');
  static const listingQuestionAdd = Key('listing_question_add');
  static const listingPayCheck = Key('listing_pay_check');
  static const listingApply = Key('listing_apply');
  static const listingUploadSkck = Key('listing_upload_skck');
  static const listingViewApplication = Key('listing_view_application');
  static const applicationChat = Key('application_chat');
  static const applicationAgreement = Key('application_agreement');
  static const interviewSlotAdd = Key('interview_slot_add');
  static const interviewSubmit = Key('interview_submit');
  static const interviewNote = Key('interview_note');
  static Key interviewSlot(int i) => Key('interview_slot_$i');
  static const interviewReschedule = Key('interview_reschedule');
  static const interviewCancel = Key('interview_cancel');
  static const evalSubmit = Key('eval_submit');
  static const evalNote = Key('eval_note');
  static Key evalScore(String aspect) => Key('eval_score_$aspect');

  // auth / akun / home / profil (fitur auth, verification, home, profile)
  static const roleBoth = Key('role_both');
  static const loginForgot = Key('login_forgot');
  static const loginRegister = Key('login_register');
  static const otpChangePhone = Key('otp_change_phone');
  static const forgotIdentifier = Key('forgot_identifier');
  static const forgotSend = Key('forgot_send');
  static const forgotCode = Key('forgot_code');
  static const forgotNewPassword = Key('forgot_new_password');
  static const forgotSave = Key('forgot_save');
  static const accountRoleRow = Key('account_role_row');
  static const themeSystem = Key('theme_system');
  static const themeLight = Key('theme_light');
  static const themeDark = Key('theme_dark');
  static Key deviceRevoke(String id) => Key('device_revoke_$id');
  static const verificationConsent = Key('verification_consent');
  static const verificationRetake = Key('verification_retake');
  static const verificationNext = Key('verification_next');
  static const verificationGallery = Key('verification_gallery');
  static const skckUpload = Key('skck_upload');
  static const homeNextStep = Key('home_next_step');
  static const homeVerifyBanner = Key('home_verify_banner');
  static const homeCreateListing = Key('home_create_listing');
  static const homeFindAssistant = Key('home_find_assistant');
  static const homeProfileMeter = Key('home_profile_meter');
  static const profileInvite = Key('profile_invite');
  static const profileEdit = Key('profile_edit');
  static const profileSave = Key('profile_save');
  static const profileCity = Key('profile_city');
  static const profileRate = Key('profile_rate');
  static const profileBio = Key('profile_bio');
  static const profileExperience = Key('profile_experience');
  static const profileSkillInput = Key('profile_skill_input');
  static const profileMeter = Key('profile_meter');
  static Key profileCategory(String c) => Key('profile_category_$c');

  // umum
  static const retry = Key('retry');
}
