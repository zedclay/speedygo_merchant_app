/// Merchant Team Management contract
/// (`docs/architecture/MERCHANT_TEAM_MANAGEMENT.md`). Members are identified by
/// phone only: the backend exposes no display name, presence or last activity.
library;

const teamRoleOwner = 'OWNER';
const teamRoleManager = 'MANAGER';
const teamRoleStaff = 'STAFF';

/// Roles an OWNER can assign (OWNER itself is never assignable).
const teamAssignableRoles = [teamRoleManager, teamRoleStaff];

/// Hex length of the one-time accept code (32 random bytes).
const teamAcceptCodeLength = 64;

/// `TEAM_READ`: OWNER and MANAGER. STAFF gets `MERCHANT_ROLE_FORBIDDEN`.
bool merchantRoleCanReadTeam(String? role) =>
    role == teamRoleOwner || role == teamRoleManager;

class TeamMember {
  const TeamMember({
    required this.id,
    required this.phone,
    required this.role,
    required this.isSelf,
    required this.version,
    this.createdAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    id: json['id']?.toString() ?? '',
    phone: _trimmedOrNull(json['phone']),
    role: json['role']?.toString() ?? '',
    isSelf: json['isSelf'] == true,
    version: (json['version'] as num?)?.toInt() ?? 1,
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );

  final String id;
  final String? phone;
  final String role;
  final bool isSelf;
  final int version;
  final DateTime? createdAt;

  bool get isOwner => role == teamRoleOwner;

  /// Only MANAGER/STAFF memberships can be re-roled or revoked.
  bool get isMutable => role == teamRoleManager || role == teamRoleStaff;
}

class TeamInvitation {
  const TeamInvitation({
    required this.id,
    required this.phone,
    required this.role,
    required this.status,
    required this.version,
    this.expiresAt,
    this.createdAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) => TeamInvitation(
    id: json['id']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
    status: json['status']?.toString() ?? 'PENDING',
    version: (json['version'] as num?)?.toInt() ?? 1,
    expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
  );

  final String id;
  final String phone;
  final String role;
  final String status;
  final int version;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isExpired => status == 'EXPIRED';

  /// ACCEPTED and CANCELLED invitations are history, not "pending".
  bool get isOutstanding => status == 'PENDING' || status == 'EXPIRED';
}

/// An invitation plus its one-time plaintext code. The code is returned once
/// by the server (only its hash is stored) and must never be persisted.
class TeamInvitationIssued {
  const TeamInvitationIssued({
    required this.invitation,
    required this.acceptCode,
  });

  factory TeamInvitationIssued.fromJson(Map<String, dynamic> json) =>
      TeamInvitationIssued(
        invitation: TeamInvitation.fromJson(json),
        acceptCode: json['acceptCode']?.toString() ?? '',
      );

  final TeamInvitation invitation;
  final String acceptCode;
}

class MerchantTeam {
  const MerchantTeam({
    required this.merchantId,
    required this.members,
    required this.invitations,
    required this.canManage,
  });

  factory MerchantTeam.fromJson(Map<String, dynamic> json) => MerchantTeam(
    merchantId: json['merchantId']?.toString() ?? '',
    members: _maps(json['members'])
        .map(TeamMember.fromJson)
        .where((m) => m.id.isNotEmpty)
        .toList(),
    invitations: _maps(json['invitations'])
        .map(TeamInvitation.fromJson)
        .where((i) => i.id.isNotEmpty)
        .toList(),
    canManage: (json['capabilities'] as Map?)?['canManage'] == true,
  );

  final String merchantId;
  final List<TeamMember> members;
  final List<TeamInvitation> invitations;
  final bool canManage;

  List<TeamInvitation> get outstandingInvitations => [
    for (final i in invitations)
      if (i.isOutstanding) i,
  ];
}

/// Invitation addressed to the authenticated phone
/// (`GET /merchant/me/team-invitations`).
class MyTeamInvitation {
  const MyTeamInvitation({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.role,
    this.expiresAt,
    this.createdAt,
  });

  factory MyTeamInvitation.fromJson(Map<String, dynamic> json) =>
      MyTeamInvitation(
        id: json['id']?.toString() ?? '',
        merchantId: json['merchantId']?.toString() ?? '',
        merchantName: json['merchantName']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );

  final String id;
  final String merchantId;
  final String merchantName;
  final String role;
  final DateTime? expiresAt;
  final DateTime? createdAt;
}

class TeamInvitationAccepted {
  const TeamInvitationAccepted({
    required this.merchantId,
    required this.memberId,
    required this.role,
  });

  factory TeamInvitationAccepted.fromJson(Map<String, dynamic> json) =>
      TeamInvitationAccepted(
        merchantId: json['merchantId']?.toString() ?? '',
        memberId: json['memberId']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
      );

  final String merchantId;
  final String memberId;
  final String role;
}

/// E.164 form (`+213XXXXXXXXX`) of an Algerian mobile number typed as
/// `0550 12 34 56`, `550123456` or `+213 550 12 34 56`; null when invalid.
String? normalizeTeamPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00213')) {
    digits = digits.substring(2);
  }
  String local;
  if (digits.startsWith('213') && digits.length == 12) {
    local = digits.substring(3);
  } else if (digits.startsWith('0') && digits.length == 10) {
    local = digits.substring(1);
  } else if (digits.length == 9) {
    local = digits;
  } else {
    return null;
  }
  if (!RegExp(r'^[567]\d{8}$').hasMatch(local)) return null;
  return '+213$local';
}

/// `+213550123456` → `+213 550 12 34 56`; other values are shown as received.
String formatTeamPhone(String? raw) {
  final value = raw?.trim() ?? '';
  final match = RegExp(r'^\+213(\d{3})(\d{2})(\d{2})(\d{2})$')
      .firstMatch(value);
  if (match == null) return value;
  return '+213 ${match[1]} ${match[2]} ${match[3]} ${match[4]}';
}

/// `dd/MM/yyyy` in local time.
String formatTeamDate(DateTime date) {
  final d = date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

String? _trimmedOrNull(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}

List<Map<String, dynamic>> _maps(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map) Map<String, dynamic>.from(e),
  ];
}
