import 'package:flutter/material.dart';

import '../data/models/models.dart';

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
  String get chooseLanguage => _t('Choose your language', 'ভাষা বেছে নিন');
  String get chooseLanguageHint => _t(
        'English is selected by default. You can change this later from More.',
        'ইংরেজি ডিফল্ট হিসেবে নির্বাচিত। পরে আরও মেনু থেকে পরিবর্তন করতে পারবেন।',
      );
  String get continueLabel => _t('Continue', 'চালিয়ে যান');
  String get defaultLanguage => _t('Default', 'ডিফল্ট');

  String get getStarted => _t('Get Started', 'শুরু করুন');
  String get login => _t('Login', 'লগইন');
  String get welcomeBack => _t('Welcome Back', 'আবার স্বাগতম');
  String get loginSubtitle => _t('Login to your account', 'আপনার অ্যাকাউন্টে লগইন করুন');
  String get password => _t('Password', 'পাসওয়ার্ড');
  String get rememberMe => _t('Remember me', 'মনে রাখুন');
  String get forgotPassword => _t('Forgot password?', 'পাসওয়ার্ড ভুলে গেছেন?');
  String get forgotPasswordTitle => _t('Reset password', 'পাসওয়ার্ড রিসেট');
  String get forgotPasswordHint => _t(
        'Enter the phone number on your account. We will email a 6-digit code to the address on file. If you never set a password, this will create one.',
        'আপনার অ্যাকাউন্টের ফোন নম্বর দিন। ফাইলে থাকা ইমেইলে ৬ সংখ্যার কোড পাঠানো হবে। পাসওয়ার্ড না থাকলে এখান থেকে তৈরি হবে।',
      );
  String get sendResetCode => _t('Send code', 'কোড পাঠান');
  String get codeSentHint => _t(
        'Enter the 6-digit code from your email, then choose a new password.',
        'ইমেইলের ৬ সংখ্যার কোড দিন, তারপর নতুন পাসওয়ার্ড বেছে নিন।',
      );
  String get resetCode => _t('6-digit code', '৬ সংখ্যার কোড');
  String get newPassword => _t('New password', 'নতুন পাসওয়ার্ড');
  String get currentPassword => _t('Current password', 'বর্তমান পাসওয়ার্ড');
  String get editProfile => _t('Edit profile', 'প্রোফাইল সম্পাদনা');
  String get profileSaved => _t('Profile saved', 'প্রোফাইল সংরক্ষিত');
  String get changePasswordOptional =>
      _t('Change password (optional)', 'পাসওয়ার্ড পরিবর্তন (ঐচ্ছিক)');
  String get leavePasswordBlank => _t(
        'Leave blank to keep your current password.',
        'বর্তমান পাসওয়ার্ড রাখতে খালি রাখুন।',
      );
  String couldNotSaveProfile(Object e) =>
      _t('Could not save profile: $e', 'প্রোফাইল সংরক্ষণ যায়নি: $e');
  String get confirmPassword => _t('Confirm password', 'পাসওয়ার্ড নিশ্চিত করুন');
  String get resetPasswordAction => _t('Update password', 'পাসওয়ার্ড আপডেট');
  String get resendCode => _t('Resend code', 'আবার কোড পাঠান');
  String get passwordsDoNotMatch =>
      _t('Passwords do not match', 'পাসওয়ার্ড মিলছে না');
  String get passwordTooShort =>
      _t('Use at least 6 characters', 'কমপক্ষে ৬ অক্ষর দিন');
  String get enterResetCode => _t('Enter the 6-digit code', '৬ সংখ্যার কোড দিন');
  String get passwordResetSuccess => _t(
        'Password updated. You can log in now.',
        'পাসওয়ার্ড আপডেট হয়েছে। এখন লগইন করতে পারেন।',
      );
  String get codeSent => _t(
        'If this number is registered, a reset code was emailed.',
        'এই নম্বর নিবন্ধিত থাকলে ইমেইলে রিসেট কোড পাঠানো হয়েছে।',
      );
  String codeSentTo(String hint) => _t(
        'We emailed a code to $hint',
        '$hint-এ কোড ইমেইল করা হয়েছে',
      );
  String debugResetCode(String code) => _t(
        'Development code: $code',
        'ডেভেলপমেন্ট কোড: $code',
      );
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
  String get selectMonth => _t('Select month', 'মাস বেছে নিন');
  String get expenses => _t('Expenses', 'ব্যয়');
  String get expensesSubtitle =>
      _t('Salary, festival bonus & spending', 'বেতন, উৎসব বোনাস ও খরচ');
  String get expenseHeads => _t('Expense Heads', 'ব্যয়ের খাত');
  String get expenseHeadsSubtitle =>
      _t('Manage salary, bonus & other types', 'বেতন, বোনাস ও অন্যান্য খাত');
  String get committee => _t('Organizing Committee', 'সংগঠক কমিটি');
  String get committeeSubtitle =>
      _t('Chairman, Secretary & other roles', 'সভাপতি, সম্পাদক ও অন্যান্য পদ');
  String get accessRoles => _t('Login roles', 'লগইন রোল');
  String get accessRolesSubtitle =>
      _t('Member, collector, admin & custom permissions', 'সদস্য, কালেক্টর, অ্যাডমিন ও অনুমতি');
  String get newAccessRole => _t('New role', 'নতুন রোল');
  String get editAccessRole => _t('Edit role', 'রোল সম্পাদনা');
  String get noAccessRolesYet => _t('No roles yet', 'এখনো কোনো রোল নেই');
  String get systemRole => _t('System', 'সিস্টেম');
  String get loginRole => _t('Login role', 'লগইন রোল');
  String get loginRoleSaved => _t('Login role saved', 'লগইন রোল সংরক্ষিত');
  String get editMember => _t('Edit member', 'সদস্য সম্পাদনা');
  String get memberUpdated => _t('Member updated', 'সদস্য আপডেট হয়েছে');
  String get monthlyDonationSaved =>
      _t('Monthly donation updated', 'মাসিক দান আপডেট হয়েছে');
  String get deletePayment => _t('Delete payment', 'পেমেন্ট মুছুন');
  String deletePaymentHint(String receipt, String amount) => _t(
        'Delete $receipt ($amount)? This reverses it from the member\'s dues.',
        '$receipt ($amount) মুছবেন? সদস্যের বকেয়া থেকে এটি ফিরিয়ে নেওয়া হবে।',
      );
  String paymentDeleted(String receipt) =>
      _t('$receipt deleted', '$receipt মুছে ফেলা হয়েছে');
  String deletePaymentFailed(Object e) =>
      _t('Could not delete payment: $e', 'পেমেন্ট মুছা যায়নি: $e');
  String get approvePaymentTitle =>
      _t('Approve payment?', 'পেমেন্ট অনুমোদন করবেন?');
  String approvePaymentHint(String name, String amount, String receipt) => _t(
        'Approve $amount from $name ($receipt)? It will count toward dues.',
        '$name-এর $amount ($receipt) অনুমোদন করবেন? এটি চাঁদায় গণনা হবে।',
      );
  String get submitPaymentConfirmTitle =>
      _t('Submit payment request?', 'পেমেন্ট অনুরোধ জমা দেবেন?');
  String submitPaymentConfirmHint(String amount) => _t(
        'Submit $amount for admin approval? It will stay pending until accepted.',
        'অ্যাডমিন অনুমোদনের জন্য $amount জমা দেবেন? গ্রহণ না হওয়া পর্যন্ত এটি অপেক্ষমাণ থাকবে।',
      );
  String get permissions => _t('Permissions', 'অনুমতি');
  String get adminHasAllPermissions =>
      _t('Admin always has every permission.', 'অ্যাডমিন সব অনুমতি পায়।');
  String permissionCount(int n) => _t('$n permissions', '$n-টি অনুমতি');
  String deleteRoleHint(String name) =>
      _t('Delete the $name role?', '$name রোল মুছবেন?');
  String permissionGroup(String group) => switch (group) {
        'Members' => _t('Members', 'সদস্য'),
        'Collection' => _t('Collection', 'কালেকশন'),
        'Funds' => _t('Funds', 'তহবিল'),
        'Expenses' => _t('Expenses', 'ব্যয়'),
        'Reports' => _t('Reports', 'রিপোর্ট'),
        'Join requests' => _t('Join requests', 'যোগদানের আবেদন'),
        'Committee' => _t('Committee', 'কমিটি'),
        'Meetings' => _t('Meetings', 'সভা'),
        'Settings' => _t('Settings', 'সেটিংস'),
        _ => group,
      };
  String permissionLabel(String key) => switch (key) {
        'members.view' => _t('View members', 'সদস্য দেখা'),
        'members.create' => _t('Add members', 'সদস্য যোগ'),
        'collection.view' => _t('View collection', 'কালেকশন দেখা'),
        'collection.collect' => _t('Collect payments', 'পেমেন্ট গ্রহণ'),
        'payments.approve' => _t('Approve payments', 'পেমেন্ট অনুমোদন'),
        'funds.view' => _t('View funds', 'তহবিল দেখা'),
        'funds.manage' => _t('Manage campaigns', 'ক্যাম্পেইন পরিচালনা'),
        'expenses.view' => _t('View expenses', 'ব্যয় দেখা'),
        'expenses.create' => _t('Add expenses', 'ব্যয় যোগ'),
        'expense_heads.manage' => _t('Manage expense heads', 'ব্যয়ের খাত'),
        'reports.view' => _t('View reports', 'রিপোর্ট দেখা'),
        'join_requests.manage' => _t('Manage join requests', 'যোগদানের আবেদন'),
        'committee.manage' => _t('Manage committee', 'কমিটি পরিচালনা'),
        'meetings.view' => _t('View meetings', 'সভা দেখা'),
        'meetings.manage' => _t('Open meetings', 'সভা খোলা'),
        'organization.manage' => _t('Organization settings', 'সংগঠনের সেটিংস'),
        'roles.manage' => _t('Manage login roles', 'লগইন রোল'),
        _ => key,
      };
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
  String get memberPasswordNotSet => _t(
        'No password yet. Use Forgot password to create one.',
        'এখনো পাসওয়ার্ড নেই। ‘পাসওয়ার্ড ভুলে গেছেন?’ থেকে একটি তৈরি করুন।',
      );

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

  String get clear => _t('Clear', 'মুছুন');
  String get retry => _t('Retry', 'আবার চেষ্টা');
  String get cancel => _t('Cancel', 'বাতিল');
  String get save => _t('Save', 'সংরক্ষণ');
  String get donate => _t('Donate', 'দান করুন');
  String get confirmDonation => _t('Confirm Donation', 'দান নিশ্চিত করুন');
  String get paymentMethod => _t('Payment Method', 'পেমেন্ট পদ্ধতি');
  String get mobileWallet => _t('Mobile Wallet', 'মোবাইল ওয়ালেট');
  String get cashToCollector => _t('Cash to collector', 'কালেক্টরকে নগদ');
  String get handCash => _t('Hand Cash', 'হাতে নগদ');
  String get cash => _t('Cash', 'নগদ');
  String perMonth(String amount) => _t('৳ $amount / month', '৳ $amount / মাস');
  String outstandingAmount(String amount) =>
      _t('Outstanding: ৳ $amount', 'বকেয়া: ৳ $amount');
  String get unableToLoadMembers =>
      _t('Unable to load members.', 'সদস্য লোড করা যায়নি।');
  String get noMembersFound => _t('No members found', 'কোনো সদস্য পাওয়া যায়নি');
  String noMembersMatch(String query) =>
      _t('No members match "$query"', '"$query" এর সাথে কোনো সদস্য মিলেনি');
  String raisedOf(String raised, String goal, int donors) => _t(
        '৳ $raised of ৳ $goal · $donors donors',
        '৳ $goal-এর মধ্যে ৳ $raised · $donors জন দাতা',
      );

  String get fundsAvailable => _t('Funds Available', 'উপলব্ধ তহবিল');
  String get totalSpent => _t('Total Spent', 'মোট ব্যয়');
  String get salary => _t('Salary', 'বেতন');
  String get festivalBonus => _t('Festival Bonus', 'উৎসব বোনাস');
  String get operational => _t('Operational', 'পরিচালনা');
  String get charity => _t('Charity', 'দান/ত্রাণ');
  String get other => _t('Other', 'অন্যান্য');
  String get anyType => _t('Any type', 'যেকোনো ধরন');
  String get monthly => _t('Monthly', 'মাসিক');
  String get occasional => _t('Occasional', 'মাঝে মাঝে');
  String get recurring => _t('Recurring', 'নিয়মিত');
  String get oneTime => _t('One-time', 'একবার');
  String get paySalary => _t('Pay Salary', 'বেতন দিন');
  String get manageHeads => _t('Manage Heads', 'খাত পরিচালনা');
  String get manageHeadsTooltip => _t('Manage heads', 'খাত পরিচালনা');
  String get heads => _t('Heads', 'খাত');
  String get addHead => _t('Add Head', 'খাত যোগ');
  String get noExpenseHeadsYet =>
      _t('No expense heads yet', 'এখনো কোনো ব্যয়ের খাত নেই');
  String get noExpensesRecorded =>
      _t('No expenses recorded yet', 'এখনো কোনো ব্যয় নেই');
  String get selectExpenseHead =>
      _t('Select an expense head', 'একটি ব্যয়ের খাত বেছে নিন');
  String get expenseRecorded => _t('Expense recorded', 'ব্যয় রেকর্ড হয়েছে');
  String couldNotSave(Object e) =>
      _t('Could not save: $e', 'সংরক্ষণ করা যায়নি: $e');
  String salaryAlreadyPaid(String month) => _t(
        'Salary for $month is already paid',
        '$month-এর বেতন ইতিমধ্যে দেওয়া হয়েছে',
      );
  String get noExpenseHeadsHint => _t(
        'No expense heads yet. Create Salary or Festival Bonus heads first.',
        'এখনো কোনো ব্যয়ের খাত নেই। আগে বেতন বা উৎসব বোনাস খাত তৈরি করুন।',
      );
  String get expenseDetails => _t('Expense details', 'ব্যয়ের বিবরণ');
  String get expenseDetailsHint => _t(
        'Pick a head (Salary, Festival Bonus, etc.), then enter amount.',
        'খাত বেছে নিন (বেতন, উৎসব বোনাস ইত্যাদি), তারপর পরিমাণ লিখুন।',
      );
  String get expenseHead => _t('Expense head', 'ব্যয়ের খাত');
  String get salaryMonth => _t('Salary month', 'বেতনের মাস');
  String get month => _t('Month', 'মাস');
  String get year => _t('Year', 'বছর');
  String unpaidSalaryMonths(int n) => _t(
        '$n unpaid salary month${n == 1 ? '' : 's'} marked due',
        '$n মাসের বেতন বকেয়া চিহ্নিত',
      );
  String monthsDue(String head, int n) => _t(
        '$head: $n month${n == 1 ? '' : 's'} due',
        '$head: $n মাস বকেয়া',
      );
  String get thisMonthAlreadyPaid => _t(
        'This month is already paid. Pick a due month.',
        'এই মাস ইতিমধ্যে পরিশোধিত। একটি বকেয়া মাস বেছে নিন।',
      );
  String get expenseTitleHint =>
      _t("e.g. Imam's Salary — September", 'যেমন: ইমামের বেতন — সেপ্টেম্বর');
  String get requiredField => _t('Required', 'আবশ্যক');
  String get amountTaka => _t('Amount (৳)', 'পরিমাণ (৳)');
  String get amount => _t('Amount', 'পরিমাণ');
  String get enterValidAmount =>
      _t('Enter a valid amount', 'সঠিক পরিমাণ লিখুন');
  String get type => _t('Type', 'ধরন');
  String get paidOn => _t('Paid on', 'পরিশোধের তারিখ');
  String get expenseDate => _t('Expense date', 'ব্যয়ের তারিখ');
  String get paidVia => _t('Paid via', 'যেভাবে দেওয়া হয়েছে');
  String get notesOptional => _t('Notes (optional)', 'নোট (ঐচ্ছিক)');
  String get saveExpense => _t('Save Expense', 'ব্যয় সংরক্ষণ');
  String salaryMonthPaid(String month, String paid) =>
      _t('Salary month $month · Paid $paid', 'বেতনের মাস $month · পরিশোধ $paid');

  String get shareWhatsApp => _t('Share WhatsApp', 'হোয়াটসঅ্যাপে শেয়ার');
  String get viewReceipt => _t('View Receipt', 'রসিদ দেখুন');
  String get backToFunds => _t('Back to Funds', 'তহবিলে ফিরুন');
  String get whatsappUnavailable => _t(
        'WhatsApp is not available. Receipt copied.',
        'হোয়াটসঅ্যাপ নেই। রসিদ কপি হয়েছে।',
      );
  String get donorName => _t('Donor Name', 'দাতার নাম');
  String get phone => _t('Phone', 'ফোন');
  String get fundraisingEvent => _t('Fundraising Event', 'তহবিল সংগ্রহ');
  String get referringMember =>
      _t('Referring Member (Optional)', 'রেফারকারী সদস্য (ঐচ্ছিক)');
  String get none => _t('None', 'নেই');
  String get member => _t('Member', 'সদস্য');
  String get nonMember => _t('Non-member', 'অসদস্য');
  String get fillDonationFields => _t(
        'Please fill donor name, event and amount',
        'দাতার নাম, ক্যাম্পেইন ও পরিমাণ পূরণ করুন',
      );

  String get pending => _t('Pending', 'অপেক্ষমাণ');
  String get approved => _t('Approved', 'অনুমোদিত');
  String get rejected => _t('Rejected', 'বাতিল');
  String get confirmed => _t('Confirmed', 'নিশ্চিত');
  String get accept => _t('Accept', 'গ্রহণ');
  String get reject => _t('Reject', 'বাতিল');
  String get approve => _t('Approve', 'অনুমোদন');
  String get due => _t('Due', 'বকেয়া');
  String get advance => _t('Advance', 'অগ্রিম');
  String get edit => _t('Edit', 'সম্পাদনা');
  String get saveSettings => _t('Save Settings', 'সেটিংস সংরক্ষণ');
  String get enableReferrals => _t('Enable referrals', 'রেফারেল চালু করুন');
  String get publicJoin =>
      _t('Public join applications', 'পাবলিক যোগদানের আবেদন');
  String get paymentHistory => _t('Payment History', 'পেমেন্ট ইতিহাস');
  String get paymentDetails => _t('Payment details', 'পেমেন্ট বিবরণ');
  String get noMembersThisFilter =>
      _t('No members in this list', 'এই তালিকায় কোনো সদস্য নেই');
  String get noDonationsYet => _t('No donations yet', 'এখনো কোনো দান নেই');
  String get myContribution => _t('My Contribution', 'আমার অবদান');
  String get totalPaid => _t('Total Paid', 'মোট পরিশোধ');
  String get outstanding => _t('Outstanding', 'বকেয়া');
  String get noPaymentsYet => _t('No payments yet', 'এখনো কোনো পেমেন্ট নেই');
  String get viewFundraisingEvents =>
      _t('View Fundraising Events', 'তহবিল সংগ্রহ দেখুন');
  String get backToLogin => _t('Back to Login', 'লগইনে ফিরুন');
  String get submitApplication => _t('Submit Application', 'আবেদন জমা দিন');
  String get createCampaign => _t('Create Campaign', 'ক্যাম্পেইন তৈরি');
  String get campaignCreated => _t('Campaign created', 'ক্যাম্পেইন তৈরি হয়েছে');
  String get campaignTitle => _t('Campaign title', 'ক্যাম্পেইনের শিরোনাম');
  String get goalAmount => _t('Goal amount', 'লক্ষ্য পরিমাণ');
  String get startDate => _t('Start date', 'শুরুর তারিখ');
  String get endDateOptional =>
      _t('End date (optional)', 'শেষ তারিখ (ঐচ্ছিক)');
  String get fundraisingCampaign =>
      _t('Fundraising campaign', 'তহবিল সংগ্রহের ক্যাম্পেইন');
  String get fundraisingCampaignHint => _t(
        'Create a new campaign to collect donations from members and non-members.',
        'সদস্য ও অসদস্যদের কাছ থেকে দান সংগ্রহের নতুন ক্যাম্পেইন তৈরি করুন।',
      );
  String get campaignTitleHint =>
      _t('e.g. Winter Relief Drive', 'যেমন: শীতকালীন ত্রাণ');
  String get joiningDate => _t('Joining date', 'যোগদানের তারিখ');
  String get fullName => _t('Full Name', 'পূর্ণ নাম');
  String get phoneNumber => _t('Phone Number', 'ফোন নম্বর');
  String get email => _t('Email', 'ইমেইল');
  String get addEmail => _t('Add email', 'ইমেইল যোগ করুন');
  String get emailSaved => _t('Email saved', 'ইমেইল সংরক্ষিত');
  String get newMemberDetails => _t('New member details', 'নতুন সদস্যের বিবরণ');
  String get memberAdded => _t(
        'Member added. Record payment for due months.',
        'সদস্য যোগ হয়েছে। বকেয়া মাসের পেমেন্ট রেকর্ড করুন।',
      );
  String get selectedMonths => _t('Selected months', 'নির্বাচিত মাস');
  String get paymentAmount => _t('Payment amount', 'পেমেন্টের পরিমাণ');
  String get selectAtLeastOneMonth =>
      _t('Select at least one month to pay', 'অন্তত একটি মাস বেছে নিন');
  String get mobileWalletDetails =>
      _t('Mobile Wallet Details', 'মোবাইল ওয়ালেটের তথ্য');
  String get walletAccountNumber =>
      _t('Wallet Account Number', 'ওয়ালেট অ্যাকাউন্ট নম্বর');
  String get transactionId => _t('Transaction ID', 'ট্রানজেকশন আইডি');
  String get collectionRate => _t('Collection Rate', 'কালেকশনের হার');
  String get noJoinRequests =>
      _t('No join requests', 'কোনো যোগদানের আবেদন নেই');
  String get noPaymentsFilter =>
      _t('No payments in this filter', 'এই ফিল্টারে কোনো পেমেন্ট নেই');
  String get noCommitteeMembers =>
      _t('No committee members yet', 'এখনো কোনো কমিটি সদস্য নেই');
  String get noRolesYet => _t('No roles yet', 'এখনো কোনো পদ নেই');
  String get noExpenseHeadsCreate => _t(
        'No expense heads yet',
        'এখনো কোনো ব্যয়ের খাত নেই',
      );

  String collectorOf(String name) =>
      _t('Collector: $name', 'কালেক্টর: $name');
  String get collector => _t('Collector', 'কালেক্টর');
  String get collectorMember => _t('Collector Member', 'কালেক্টর সদস্য');
  String get selectCollector => _t('Select Collector', 'কালেক্টর বেছে নিন');
  String get searchMembersShort => _t('Search members', 'সদস্য খুঁজুন');
  String get tapToSelectCollector =>
      _t('Tap to select collector', 'কালেক্টর বেছে নিতে ট্যাপ করুন');
  String get selectCollectorHint => _t(
        'Select who received the cash from the members list.',
        'সদস্য তালিকা থেকে যিনি নগদ গ্রহণ করেছেন তাকে বেছে নিন।',
      );
  String get enterWalletAndTxn => _t(
        'Enter wallet account number and transaction ID',
        'ওয়ালেট অ্যাকাউন্ট নম্বর ও ট্রানজেকশন আইডি লিখুন',
      );
  String get selectCollectorFromList => _t(
        'Select a collector from the members list',
        'সদস্য তালিকা থেকে একজন কালেক্টর বেছে নিন',
      );
  String get noPayableAmount => _t(
        'Selected months have no payable amount',
        'নির্বাচিত মাসগুলোর পরিশোধযোগ্য পরিমাণ নেই',
      );
  String paymentFailed(Object e) =>
      _t('Payment failed: $e', 'পেমেন্ট ব্যর্থ: $e');
  String get paymentPendingSelfHint => _t(
        'Your payment will stay pending until an admin accepts it. Only accepted payments count toward dues and collections.',
        'অ্যাডমিন গ্রহণ না করা পর্যন্ত পেমেন্ট অপেক্ষমাণ থাকবে। শুধু গৃহীত পেমেন্ট চাঁদা ও কালেকশনে গণনা হবে।',
      );
  String monthlySlash(String amount) =>
      _t('৳ $amount/month', '৳ $amount/মাস');
  String get selectMonths => _t('Select Months', 'মাস বেছে নিন');
  String get selectMonthsHint => _t(
        'Choose which months to pay. Nothing is selected by default.',
        'যে মাসগুলোর পেমেন্ট দেবেন সেগুলো বেছে নিন। ডিফল্টে কিছুই নির্বাচিত নয়।',
      );
  String get noPayableMonths =>
      _t('No payable months available', 'পরিশোধযোগ্য মাস নেই');
  String get submitForApproval =>
      _t('Submit for Approval', 'অনুমোদনের জন্য জমা দিন');
  String get confirmPayment => _t('Confirm Payment', 'পেমেন্ট নিশ্চিত করুন');
  String get waitingAdminApproval => _t(
        'Waiting for admin approval. This payment is not counted yet.',
        'অ্যাডমিন অনুমোদনের অপেক্ষায়। এই পেমেন্ট এখনো গণনা হয়নি।',
      );
  String monthsForMember(int n, String name) =>
      _t('$n months · $name', '$n মাস · $name');
  String get statusLabel => _t('Status', 'অবস্থা');
  String get date => _t('Date', 'তারিখ');
  String get method => _t('Method', 'পদ্ধতি');
  String get walletAccount => _t('Wallet Account', 'ওয়ালেট অ্যাকাউন্ট');
  String get wallet => _t('Wallet', 'ওয়ালেট');
  String get txnId => _t('Txn ID', 'ট্রানজেকশন আইডি');
  String get receivedBy => _t('Received By', 'গ্রহণকারী');
  String get donor => _t('Donor', 'দাতা');
  String get referredBy => _t('Referred by', 'রেফার করেছেন');
  String get pendingApproval =>
      _t('Pending approval', 'অনুমোদনের অপেক্ষায়');
  String get backToHome => _t('Back to Home', 'হোমে ফিরুন');
  String get backToDashboard =>
      _t('Back to Dashboard', 'ড্যাশবোর্ডে ফিরুন');
  String get enterValidGoal =>
      _t('Enter a valid goal', 'সঠিক লক্ষ্য লিখুন');
  String get descriptionOptional =>
      _t('Description (optional)', 'বিবরণ (ঐচ্ছিক)');
  String get notSet => _t('Not set', 'সেট করা হয়নি');
  String couldNotCreateCampaign(Object e) =>
      _t('Could not create campaign: $e', 'ক্যাম্পেইন তৈরি যায়নি: $e');
  String couldNotAddMember(Object e) =>
      _t('Could not add member: $e', 'সদস্য যোগ করা যায়নি: $e');
  String couldNotSubmit(Object e) =>
      _t('Could not submit: $e', 'জমা দেওয়া যায়নি: $e');
  String get approveMember => _t('Approve member?', 'সদস্য অনুমোদন করবেন?');
  String get rejectRequestTitle => _t('Reject request', 'আবেদন বাতিল');
  String get rejectPayment => _t('Reject payment', 'পেমেন্ট বাতিল');
  String get requestRejected => _t('Request rejected', 'আবেদন বাতিল হয়েছে');
  String approveFailed(Object e) =>
      _t('Approve failed: $e', 'অনুমোদন ব্যর্থ: $e');
  String rejectFailed(Object e) =>
      _t('Reject failed: $e', 'বাতিল ব্যর্থ: $e');
  String get inactive => _t('Inactive', 'নিষ্ক্রিয়');
  String get deactivate => _t('Deactivate', 'নিষ্ক্রিয় করুন');
  String get delete => _t('Delete', 'মুছুন');
  String get deactivateHead => _t('Deactivate head?', 'খাত নিষ্ক্রিয় করবেন?');
  String get deleteHead => _t('Delete head?', 'খাত মুছবেন?');
  String get deactivateHeadHint => _t(
        'Heads already used by expenses are deactivated instead of deleted.',
        'ব্যয়ে ব্যবহৃত খাত মুছে না দিয়ে নিষ্ক্রিয় করা হয়।',
      );
  String deleteHeadHint(String name) =>
      _t('Remove "$name" if unused.', 'অব্যবহৃত হলে "$name" সরান।');
  String get newExpenseHead => _t('New expense head', 'নতুন ব্যয়ের খাত');
  String get editExpenseHead => _t('Edit expense head', 'ব্যয়ের খাত সম্পাদনা');
  String get name => _t('Name', 'নাম');
  String get expenseHeadNameHint =>
      _t("e.g. Imam's Salary", 'যেমন: ইমামের বেতন');
  String get kind => _t('Kind', 'ধরন');
  String get defaultType => _t('Default type', 'ডিফল্ট ধরন');
  String get createHead => _t('Create Head', 'খাত তৈরি');
  String get saveChanges => _t('Save Changes', 'পরিবর্তন সংরক্ষণ');
  String couldNotUpdate(Object e) =>
      _t('Could not update: $e', 'আপডেট করা যায়নি: $e');
  String get addRole => _t('Add Role', 'পদ যোগ');
  String get createRoleFirst =>
      _t('Create a committee role first', 'আগে কমিটির পদ তৈরি করুন');
  String get newRole => _t('New role', 'নতুন পদ');
  String get editRole => _t('Edit role', 'পদ সম্পাদনা');
  String get roleName => _t('Role name', 'পদের নাম');
  String get createRole => _t('Create Role', 'পদ তৈরি');
  String get addCommitteeMember =>
      _t('Add committee member', 'কমিটি সদস্য যোগ');
  String get editCommitteeMember => _t('Edit member', 'সদস্য সম্পাদনা');
  String get role => _t('Role', 'পদ');
  String get addToCommittee => _t('Add to Committee', 'কমিটিতে যোগ');
  String get recentPayments => _t('Recent Payments', 'সাম্প্রতিক পেমেন্ট');
  String get currentDues => _t('Current Dues', 'চলতি বকেয়া');
  String get paidMembers => _t('Paid Members', 'পরিশোধিত সদস্য');
  String get partialMembers => _t('Partial Members', 'আংশিক সদস্য');
  String get unpaidMembers => _t('Unpaid Members', 'বকেয়া সদস্য');
  String get advancePaid => _t('Advance Paid', 'অগ্রিম পরিশোধ');
  String get expected => _t('Expected', 'প্রত্যাশিত');
  String get collected => _t('Collected', 'সংগৃহীত');
  String get paymentReceiptTitle => _t('PAYMENT RECEIPT', 'পেমেন্ট রসিদ');
  String get donationReceiptTitle => _t('DONATION RECEIPT', 'দানের রসিদ');
  String get covers => _t('Covers', 'কভার করে');
  String get campaign => _t('Campaign', 'ক্যাম্পেইন');
  String get thankYou => _t('Thank you', 'ধন্যবাদ');
  String get reasonOptional => _t('Reason (optional)', 'কারণ (ঐচ্ছিক)');
  String receiptApproved(String n) => _t('$n approved', '$n অনুমোদিত');
  String receiptRejected(String n) => _t('$n rejected', '$n বাতিল');
  String get memberNotFound => _t('Member not found', 'সদস্য পাওয়া যায়নি');
  String unableToLoadMember(Object e) =>
      _t('Unable to load member.\n$e', 'সদস্য লোড করা যায়নি।\n$e');
  String joinedOn(String date) => _t('Joined $date', 'যোগদান $date');
  String referralCodeLabel(String code) =>
      _t('Referral: $code', 'রেফারেল: $code');
  String referralReady(String code) =>
      _t('Referral $code ready to share', 'রেফারেল $code শেয়ারের জন্য প্রস্তুত');
  String get emailOptional => _t('Email (optional)', 'ইমেইল (ঐচ্ছিক)');
  String get referralCodeOptional =>
      _t('Referral code (optional)', 'রেফারেল কোড (ঐচ্ছিক)');
  String get applicationSubmitted =>
      _t('Application submitted', 'আবেদন জমা হয়েছে');
  String get applicationSubmittedHint => _t(
        'An admin will review your join request in the app. You will be notified after approval.',
        'অ্যাডমিন অ্যাপে আপনার আবেদন পর্যালোচনা করবেন। অনুমোদনের পর জানানো হবে।',
      );
  String get joinFormHint => _t(
        'Submit a membership application. Admin approval happens in the mobile app — no web panel.',
        'সদস্যপদের আবেদন জমা দিন। অনুমোদন মোবাইল অ্যাপেই হয় — ওয়েব প্যানেল নেই।',
      );
  String get nameRequired => _t('Name is required', 'নাম আবশ্যক');
  String get enterValidPhone =>
      _t('Enter a valid phone', 'সঠিক ফোন নম্বর লিখুন');
  String get enterValidEmail =>
      _t('Enter a valid email', 'সঠিক ইমেইল লিখুন');
  String get monthlyDonation => _t('Monthly Donation', 'মাসিক দান');
  String get assignedCollectorOptional =>
      _t('Assigned Collector (optional)', 'নির্ধারিত কালেক্টর (ঐচ্ছিক)');
  String get recordPreviousMonths => _t(
        'Record payment for previous months',
        'পূর্ববর্তী মাসের পেমেন্ট রেকর্ড করুন',
      );
  String outstandingForMonths(String amount, int n) => _t(
        'Outstanding $amount for $n month${n == 1 ? '' : 's'}',
        '$n মাসের বকেয়া $amount',
      );
  String get enterMonthlyAmountFirst =>
      _t('Enter monthly amount first', 'আগে মাসিক পরিমাণ লিখুন');
  String get saveAndRecordPayment =>
      _t('Save & Record Payment', 'সংরক্ষণ ও পেমেন্ট রেকর্ড');
  String get saveMember => _t('Save Member', 'সদস্য সংরক্ষণ');
  String joiningDateRange(int n, String start, String end) => _t(
        '$n month${n == 1 ? '' : 's'} due ($start – $end)',
        '$n মাস বকেয়া ($start – $end)',
      );
  String get joiningDateCreatesDues => _t(
        'Joining date creates unpaid dues from that month through today.',
        'যোগদানের তারিখ থেকে আজ পর্যন্ত বকেয়া চাঁদা তৈরি হয়।',
      );
  String get defaultMonthlyAmount =>
      _t('Default monthly amount', 'ডিফল্ট মাসিক পরিমাণ');
  String get currencySymbol => _t('Currency symbol', 'মুদ্রার চিহ্ন');
  String get enableReferralsHint => _t(
        'Allow referral codes on join and donations',
        'যোগদান ও দানে রেফারেল কোড চালু রাখুন',
      );
  String get publicJoinHint => _t(
        'Let people apply from the login screen',
        'লগইন স্ক্রিন থেকে আবেদন করতে দিন',
      );
  String settingsSaved(String name) =>
      _t('$name settings saved', '$name-এর সেটিংস সংরক্ষিত');
  String get organizationName => _t('Organization name', 'সংগঠনের নাম');
  String get tagline => _t('Tagline', 'ট্যাগলাইন');
  String get address => _t('Address', 'ঠিকানা');
  String get contactPhone => _t('Contact phone', 'যোগাযোগের ফোন');
  String get organizationProfile =>
      _t('Organization profile', 'সংগঠনের প্রোফাইল');
  String get organizationProfileHint => _t(
        'These settings apply to member joins, dues defaults, and referrals.',
        'এই সেটিংস সদস্য যোগদান, চাঁদা ও রেফারেলে প্রযোজ্য।',
      );
  String get collectionDefaults =>
      _t('Collection defaults', 'কালেকশনের ডিফল্ট');
  String get addExpenseTooltip => _t('Add expense', 'ব্যয় যোগ');
  String reasonLabel(String r) => _t('Reason: $r', 'কারণ: $r');
  String approveMemberHint(String name, String phone) => _t(
        'Create a member record for $name ($phone)? They can log in after setting a password with Forgot password.',
        '$name ($phone)-এর জন্য সদস্য রেকর্ড তৈরি করবেন? পাসওয়ার্ড ভুলে গেছেন থেকে পাসওয়ার্ড সেট করে তারা লগইন করতে পারবেন।',
      );
  String walletLine(String v) => _t('Wallet: $v', 'ওয়ালেট: $v');
  String txnLine(String v) => _t('Txn: $v', 'ট্রানজেকশন: $v');
  String collectorLine(String v) => _t('Collector: $v', 'কালেক্টর: $v');
  String preferredMonthly(String amount) =>
      _t('Preferred monthly: ৳ $amount', 'পছন্দের মাসিক: ৳ $amount');

  String expenseKindLabel(ExpenseHeadKind kind) => switch (kind) {
        ExpenseHeadKind.salary => salary,
        ExpenseHeadKind.festivalBonus => festivalBonus,
        ExpenseHeadKind.operational => operational,
        ExpenseHeadKind.charity => charity,
        ExpenseHeadKind.other => other,
      };

  String expenseRecurrenceLabel(ExpenseRecurrence r) => switch (r) {
        ExpenseRecurrence.monthly => monthly,
        ExpenseRecurrence.occasional => occasional,
      };

  String paymentMethodName(PaymentMethod m) => switch (m) {
        PaymentMethod.mobileWallet => mobileWallet,
        PaymentMethod.cashToCollector => cashToCollector,
        PaymentMethod.handCash => handCash,
      };
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
