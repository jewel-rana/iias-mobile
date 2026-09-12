import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const defaultLocale = Locale('en');
  static const supportedLocales = [Locale('en'), Locale('bn')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(defaultLocale);
  }

  bool get isBangla => locale.languageCode == 'bn';

  String _t(String en, String bn) => isBangla ? bn : en;

  String get language => _t('Language', 'ভাষা');
  String get english => 'English';
  String get bangla => 'বাংলা';

  String get getStarted => _t('Get Started', 'শুরু করুন');
  String get login => _t('Login', 'লগইন');
  String get welcomeBack => _t('Welcome Back', 'আবার স্বাগতম');
  String get loginSubtitle => _t('Login to your account', 'আপনার অ্যাকাউন্টে লগইন করুন');
  String get password => _t('Password', 'পাসওয়ার্ড');
  String get rememberMe => _t('Remember me', 'মনে রাখুন');
  String get forgotPassword => _t('Forgot password?', 'পাসওয়ার্ড ভুলে গেছেন?');
  String get alreadyHaveAccount => _t('Already have an account? ', 'ইতিমধ্যে অ্যাকাউন্ট আছে? ');
  String get dontHaveAccount => _t("Don't have an account? ", 'অ্যাকাউন্ট নেই? ');
  String get joinNow => _t('Join Now', 'এখনই যোগ দিন');
  String get logout => _t('Logout', 'লগআউট');

  String get dashboard => _t('Dashboard', 'ড্যাশবোর্ড');
  String get members => _t('Members', 'সদস্য');
  String get collection => _t('Collection', 'কালেকশন');
  String get funds => _t('Funds', 'তহবিল');
  String get more => _t('More', 'আরও');
  String get home => _t('Home', 'হোম');
  String get payments => _t('Payments', 'পেমেন্ট');
  String get donations => _t('Donations', 'দান');
  String get profile => _t('Profile', 'প্রোফাইল');

  String get reports => _t('Reports', 'রিপোর্ট');
  String get reportsSubtitle =>
      _t('Monthly collection summary', 'মাসিক কালেকশনের সারসংক্ষেপ');
  String get expenses => _t('Expenses', 'ব্যয়');
  String get expensesSubtitle =>
      _t('Salary, festival bonus & spending', 'বেতন, উৎসব বোনাস ও খরচ');
  String get expenseHeads => _t('Expense Heads', 'ব্যয়ের খাত');
  String get expenseHeadsSubtitle =>
      _t('Manage salary, bonus & other types', 'বেতন, বোনাস ও অন্যান্য খাত');
  String get committee => _t('Organizing Committee', 'সংগঠক কমিটি');
  String get committeeSubtitle =>
      _t('Chairman, Secretary & other roles', 'সভাপতি, সম্পাদক ও অন্যান্য পদ');
  String get meetings => _t('Meetings', 'সভা');
  String get meetingsSubtitle => _t(
        'Open a meeting, notify members & share WhatsApp',
        'সভা খুলুন, সদস্যদের জানান ও হোয়াটসঅ্যাপে শেয়ার করুন',
      );
  String get joinRequests => _t('Join Requests', 'যোগদানের আবেদন');
  String get joinRequestsSubtitle =>
      _t('Approve or reject applicants', 'আবেদন অনুমোদন বা বাতিল করুন');
  String get paymentApprovals => _t('Payment Approvals', 'পেমেন্ট অনুমোদন');
  String get paymentApprovalsSubtitle =>
      _t('Accept member-submitted payments', 'সদস্যের জমা পেমেন্ট গ্রহণ করুন');
  String get organizationSettings => _t('Organization Settings', 'সংগঠনের সেটিংস');
  String get organizationSettingsSubtitle =>
      _t('Name, dues default & referrals', 'নাম, চাঁদা ও রেফারেল');

  String get notifications => _t('Notifications', 'বিজ্ঞপ্তি');
  String get noNotifications =>
      _t('No notifications right now', 'এখন কোনো বিজ্ঞপ্তি নেই');
  String get openMeeting => _t('Open Meeting', 'সভা খুলুন');
  String get callAMeeting => _t('Call a meeting', 'সভা আহ্বান করুন');
  String get openMeetingHint => _t(
        'Members receive a push notification. A WhatsApp announcement is generated in English and Bangla.',
        'সদস্যরা পুশ বিজ্ঞপ্তি পাবেন। ইংরেজি ও বাংলায় হোয়াটসঅ্যাপ ঘোষণা তৈরি হবে।',
      );
  String get title => _t('Title', 'শিরোনাম');
  String get purpose => _t('Purpose *', 'উদ্দেশ্য *');
  String get dateTime => _t('Date & time', 'তারিখ ও সময়');
  String get venue => _t('Venue', 'স্থান');
  String get openMeetingNotify =>
      _t('Open Meeting & Notify Members', 'সভা খুলুন ও সদস্যদের জানান');
  String get meetingOpened =>
      _t('Meeting opened. Members have been notified.', 'সভা খোলা হয়েছে। সদস্যদের জানানো হয়েছে।');
  String get all => _t('All', 'সব');
  String get scheduled => _t('Scheduled', 'নির্ধারিত');
  String get completed => _t('Completed', 'সম্পন্ন');
  String get cancelled => _t('Cancelled', 'বাতিল');
  String get noMeetings => _t('No meetings yet', 'এখনো কোনো সভা নেই');
  String get meeting => _t('Meeting', 'সভা');
  String get englishAnnouncement => _t('English announcement', 'ইংরেজি ঘোষণা');
  String get banglaAnnouncement => 'বাংলা ঘোষণা';
  String get copy => _t('Copy', 'কপি');
  String get share => _t('Share', 'শেয়ার');
  String get copyBoth => _t('Copy English + Bangla', 'ইংরেজি ও বাংলা কপি করুন');
  String get meetingSummary => _t('Meeting summary', 'সভার সারসংক্ষেপ');
  String get cancellationNote => _t('Cancellation note', 'বাতিলের কারণ');
  String get membersPresent => _t('Members present', 'উপস্থিত সদস্য');
  String get afterTheMeeting => _t('After the meeting', 'সভার পরে');
  String get afterMeetingHint => _t(
        'Add a summary and mark who was present, then complete or cancel.',
        'সারসংক্ষেপ লিখুন, উপস্থিত সদস্য চিহ্নিত করুন, তারপর সম্পন্ন বা বাতিল করুন।',
      );
  String get summary => _t('Summary', 'সারসংক্ষেপ');
  String get markComplete => _t('Mark Complete', 'সম্পন্ন করুন');
  String get cancelMeeting => _t('Cancel Meeting', 'সভা বাতিল করুন');
  String get copied => _t('copied', 'কপি হয়েছে');

  String get assalamuAlaikum => _t('Assalamu Alaikum', 'আসসালামু আলাইকুম');
  String get quickActions => _t('Quick Actions', 'দ্রুত কাজ');
  String get addMember => _t('Add Member', 'সদস্য যোগ');
  String get collectPayment => _t('Collect Payment', 'পেমেন্ট গ্রহণ');
  String get addExpense => _t('Add Expense', 'ব্যয় যোগ');
  String get viewUnpaid => _t('View Unpaid', 'বকেয়া দেখুন');
  String get activeCampaigns => _t('Active Campaigns', 'চলমান ক্যাম্পেইন');
  String get seeAll => _t('See all', 'সব দেখুন');
  String get paid => _t('Paid', 'পরিশোধিত');
  String get partial => _t('Partial', 'আংশিক');
  String get unpaid => _t('Unpaid', 'বকেয়া');

  String get user => _t('User', 'ব্যবহারকারী');

  String get quote => _t(
        '"The best of people are those who are most beneficial to others."',
        '"মানুষের মধ্যে সর্বোত্তম তারাই যারা অন্যের জন্য সবচেয়ে উপকারী।"',
      );
  String get quoteAuthor => _t('— Prophet Muhammad ﷺ', '— রাসূলুল্লাহ ﷺ');
  String get loginUnable =>
      _t('Unable to login. Try again.', 'লগইন করা যায়নি। আবার চেষ্টা করুন।');

  String get thisMonthCollection =>
      _t('This Month Collection', 'এই মাসের কালেকশন');
  String get totalFundsAvailable =>
      _t('Total Funds Available', 'মোট উপলব্ধ তহবিল');
  String ofExpected(String expected, int percent) => _t(
        'of ৳ $expected  ·  $percent%',
        '৳ $expected-এর মধ্যে  ·  $percent%',
      );
  String spentOf(String spent, String total) => _t(
        'Spent ৳ $spent of ৳ $total',
        '৳ $total-এর মধ্যে ব্যয় ৳ $spent',
      );

  String get memberDetails => _t('Member Details', 'সদস্যের বিবরণ');
  String get donationReceived => _t('Donation Received', 'দান গ্রহণ হয়েছে');
  String get receipt => _t('Receipt', 'রসিদ');
  String get newDonation => _t('New Donation', 'নতুন দান');
  String get joinOrganization => _t('Join Organization', 'সংগঠনে যোগ দিন');
  String get addCampaign => _t('Add Campaign', 'ক্যাম্পেইন যোগ');
  String get recordDonation => _t('Record donation', 'দান রেকর্ড করুন');
  String get searchMembers =>
      _t('Search by name, ID or phone', 'নাম, আইডি বা ফোন দিয়ে খুঁজুন');
  String get memberProfileNotFound =>
      _t('Member profile not found', 'সদস্য প্রোফাইল পাওয়া যায়নি');
  String get paymentPendingApproval =>
      _t('Payment pending approval', 'পেমেন্ট অনুমোদনের অপেক্ষায়');
  String get newJoinRequest => _t('New join request', 'নতুন যোগদানের আবেদন');
  String meetingPrefix(String title) => _t('Meeting: $title', 'সভা: $title');
  String membersUnpaid(int n) => _t('$n members unpaid', '$n জন সদস্য বকেয়া');
  String duesOutstanding(String month) =>
      _t('$month dues are still outstanding.', '$month-এর চাঁদা এখনো বকেয়া।');
  String get unableToLoadNotifications =>
      _t('Unable to load notifications.', 'বিজ্ঞপ্তি লোড করা যায়নি।');
  String get unableToLoadMeetings =>
      _t('Unable to load meetings.', 'সভা লোড করা যায়নি।');
  String get unableToLoadMeeting =>
      _t('Unable to load meeting.', 'সভা লোড করা যায়নি।');
  String get enterPurpose =>
      _t('Enter the meeting purpose', 'সভার উদ্দেশ্য লিখুন');
  String get purposeHint => _t(
        'Monthly review, Ramadan planning, …',
        'মাসিক পর্যালোচনা, রমজান পরিকল্পনা, …',
      );
  String get venueHint => _t('Mosque / office address', 'মসজিদ / অফিসের ঠিকানা');
  String get summaryHint =>
      _t('Decisions, follow-ups, notes…', 'সিদ্ধান্ত, পরবর্তী কাজ, নোট…');
  String get noMembersToMark =>
      _t('No members to mark', 'চিহ্নিত করার মতো সদস্য নেই');
  String get addSummaryBeforeComplete => _t(
        'Add a meeting summary before completing.',
        'সম্পন্ন করার আগে সভার সারসংক্ষেপ লিখুন।',
      );
  String get meetingMarkedComplete =>
      _t('Meeting marked complete', 'সভা সম্পন্ন হিসেবে চিহ্নিত');
  String get meetingCancelled => _t('Meeting cancelled', 'সভা বাতিল হয়েছে');
  String couldNotUpdateMeeting(Object e) =>
      _t('Could not update meeting: $e', 'সভা আপডেট করা যায়নি: $e');
  String couldNotOpenMeeting(Object e) =>
      _t('Could not open meeting: $e', 'সভা খোলা যায়নি: $e');
  String get announcement => _t('Announcement', 'ঘোষণা');
  String copiedLabel(String label) => _t('$label copied', '$label কপি হয়েছে');
  String get organizationMeeting =>
      _t('Organization Meeting', 'সংগঠনের সভা');
  String get active => _t('Active', 'চলমান');
  String get past => _t('Past', 'পূর্ববর্তী');
  String get noFundraisingEvents =>
      _t('No fundraising events', 'কোনো ক্যাম্পেইন নেই');
  String get submitPayment => _t('Submit Payment', 'পেমেন্ট জমা দিন');
  String get paymentSubmitted => _t('Payment Submitted', 'পেমেন্ট জমা হয়েছে');
  String get paymentRecorded => _t('Payment Recorded', 'পেমেন্ট রেকর্ড হয়েছে');
  String get roles => _t('Roles', 'পদ');
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
