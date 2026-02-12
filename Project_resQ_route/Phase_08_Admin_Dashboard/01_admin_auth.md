# 01 — Admin Authentication & Access Control

## Objective
Implement secure admin login with MFA, role-based access control (RBAC), and audit logging.

---

## Admin Roles

| Role | Permissions |
|------|------------|
| `moderator` | View users, moderate flags, view analytics |
| `admin` | All moderator + ban users, tune safety scores, manage zones |
| `super_admin` | All admin + manage admin users, system configuration |

## MFA Setup

Supabase supports TOTP-based MFA:

```dart
// Enroll MFA for admin
final response = await supabase.auth.mfa.enroll(
  factorType: FactorType.totp,
  friendlyName: 'Admin TOTP',
);
// Show QR code from response.data.totp.qrCode

// Verify MFA challenge on login
final challengeResponse = await supabase.auth.mfa.challenge(
  factorId: factorId,
);
await supabase.auth.mfa.verify(
  factorId: factorId,
  challengeId: challengeResponse.id,
  code: totpCode,
);
```

## RLS-Based Authorization

```sql
-- Helper function: check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper: check specific permission
CREATE OR REPLACE FUNCTION has_admin_permission(required_permission TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admin_users 
        WHERE user_id = auth.uid()
        AND permissions ? required_permission
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Audit Trail

Every admin action is logged:

```dart
Future<void> logAdminAction({
  required String action,
  required String targetType,
  String? targetId,
  Map<String, dynamic>? details,
}) async {
  await supabase.from('admin_audit_log').insert({
    'admin_id': supabase.auth.currentUser!.id,
    'action': action,
    'target_type': targetType,
    'target_id': targetId,
    'details': details,
  });
}
```

---

## Verification
- [ ] Admin login requires MFA
- [ ] Role-based access controls work
- [ ] Unauthorized access blocked by RLS
- [ ] All admin actions appear in audit log
