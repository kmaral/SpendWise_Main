/// Group Feature Permissions
/// Controls which features are visible/accessible to group members
/// Admin can control these settings
class GroupFeaturePermissions {
  final bool canViewTransactions;
  final bool canAddTransactions;
  final bool canEditTransactions;
  final bool canDeleteTransactions;
  final bool canViewAccounts;
  final bool canManageAccounts;
  final bool canViewReports;
  final bool canExportData;
  final bool canViewPaymentMethods;
  final bool canManagePaymentMethods;
  final bool canViewLoans;
  final bool canManageLoans;
  final bool canViewCreditCards;
  final bool canManageCreditCards;
  final bool canImportSMS;

  GroupFeaturePermissions({
    this.canViewTransactions = true,
    this.canAddTransactions = true,
    this.canEditTransactions = true,
    this.canDeleteTransactions = false,
    this.canViewAccounts = true,
    this.canManageAccounts = false,
    this.canViewReports = true,
    this.canExportData = false,
    this.canViewPaymentMethods = true,
    this.canManagePaymentMethods = false,
    this.canViewLoans = true,
    this.canManageLoans = false,
    this.canViewCreditCards = true,
    this.canManageCreditCards = false,
    this.canImportSMS = false,
  });

  /// Default permissions for admin (all enabled)
  factory GroupFeaturePermissions.admin() {
    return GroupFeaturePermissions(
      canViewTransactions: true,
      canAddTransactions: true,
      canEditTransactions: true,
      canDeleteTransactions: true,
      canViewAccounts: true,
      canManageAccounts: true,
      canViewReports: true,
      canExportData: true,
      canViewPaymentMethods: true,
      canManagePaymentMethods: true,
      canViewLoans: true,
      canManageLoans: true,
      canViewCreditCards: true,
      canManageCreditCards: true,
      canImportSMS: true,
    );
  }

  /// Default permissions for regular members (limited access)
  factory GroupFeaturePermissions.member() {
    return GroupFeaturePermissions(
      canViewTransactions: true,
      canAddTransactions: true,
      canEditTransactions: true,
      canDeleteTransactions: false,
      canViewAccounts: true,
      canManageAccounts: false,
      canViewReports: true,
      canExportData: false,
      canViewPaymentMethods: true,
      canManagePaymentMethods: false,
      canViewLoans: true,
      canManageLoans: false,
      canViewCreditCards: true,
      canManageCreditCards: false,
      canImportSMS: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canViewTransactions': canViewTransactions,
      'canAddTransactions': canAddTransactions,
      'canEditTransactions': canEditTransactions,
      'canDeleteTransactions': canDeleteTransactions,
      'canViewAccounts': canViewAccounts,
      'canManageAccounts': canManageAccounts,
      'canViewReports': canViewReports,
      'canExportData': canExportData,
      'canViewPaymentMethods': canViewPaymentMethods,
      'canManagePaymentMethods': canManagePaymentMethods,
      'canViewLoans': canViewLoans,
      'canManageLoans': canManageLoans,
      'canViewCreditCards': canViewCreditCards,
      'canManageCreditCards': canManageCreditCards,
      'canImportSMS': canImportSMS,
    };
  }

  factory GroupFeaturePermissions.fromMap(Map<String, dynamic> map) {
    return GroupFeaturePermissions(
      canViewTransactions: map['canViewTransactions'] as bool? ?? true,
      canAddTransactions: map['canAddTransactions'] as bool? ?? true,
      canEditTransactions: map['canEditTransactions'] as bool? ?? true,
      canDeleteTransactions: map['canDeleteTransactions'] as bool? ?? false,
      canViewAccounts: map['canViewAccounts'] as bool? ?? true,
      canManageAccounts: map['canManageAccounts'] as bool? ?? false,
      canViewReports: map['canViewReports'] as bool? ?? true,
      canExportData: map['canExportData'] as bool? ?? false,
      canViewPaymentMethods: map['canViewPaymentMethods'] as bool? ?? true,
      canManagePaymentMethods: map['canManagePaymentMethods'] as bool? ?? false,
      canViewLoans: map['canViewLoans'] as bool? ?? true,
      canManageLoans: map['canManageLoans'] as bool? ?? false,
      canViewCreditCards: map['canViewCreditCards'] as bool? ?? true,
      canManageCreditCards: map['canManageCreditCards'] as bool? ?? false,
      canImportSMS: map['canImportSMS'] as bool? ?? false,
    );
  }

  GroupFeaturePermissions copyWith({
    bool? canViewTransactions,
    bool? canAddTransactions,
    bool? canEditTransactions,
    bool? canDeleteTransactions,
    bool? canViewAccounts,
    bool? canManageAccounts,
    bool? canViewReports,
    bool? canExportData,
    bool? canViewPaymentMethods,
    bool? canManagePaymentMethods,
    bool? canViewLoans,
    bool? canManageLoans,
    bool? canViewCreditCards,
    bool? canManageCreditCards,
    bool? canImportSMS,
  }) {
    return GroupFeaturePermissions(
      canViewTransactions: canViewTransactions ?? this.canViewTransactions,
      canAddTransactions: canAddTransactions ?? this.canAddTransactions,
      canEditTransactions: canEditTransactions ?? this.canEditTransactions,
      canDeleteTransactions:
          canDeleteTransactions ?? this.canDeleteTransactions,
      canViewAccounts: canViewAccounts ?? this.canViewAccounts,
      canManageAccounts: canManageAccounts ?? this.canManageAccounts,
      canViewReports: canViewReports ?? this.canViewReports,
      canExportData: canExportData ?? this.canExportData,
      canViewPaymentMethods:
          canViewPaymentMethods ?? this.canViewPaymentMethods,
      canManagePaymentMethods:
          canManagePaymentMethods ?? this.canManagePaymentMethods,
      canViewLoans: canViewLoans ?? this.canViewLoans,
      canManageLoans: canManageLoans ?? this.canManageLoans,
      canViewCreditCards: canViewCreditCards ?? this.canViewCreditCards,
      canManageCreditCards: canManageCreditCards ?? this.canManageCreditCards,
      canImportSMS: canImportSMS ?? this.canImportSMS,
    );
  }
}
