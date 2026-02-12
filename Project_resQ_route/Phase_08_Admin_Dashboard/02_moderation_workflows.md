# 02 — Moderation Workflows

## Objective
Build workflows for moderating user-flagged unsafe zones, SOS event review, and user report handling.

---

## Flag Moderation Queue

```
┌───────────────────────────────────────┐
│  📋 Flag Moderation Queue (12 pending)│
│  ─────────────────────────────────────│
│                                       │
│  ┌───────────────────────────────┐    │
│  │ 🔴 Flag #128                  │    │
│  │ Reason: Suspicious activity   │    │
│  │ Location: Koramangala, BLR    │    │
│  │ Reported by: User #456        │    │
│  │ Existing flags nearby: 2      │    │
│  │ Photo: [View]                 │    │
│  │                               │    │
│  │ [✅ Approve] [❌ Reject]      │    │
│  │ [🔗 Merge with nearby]       │    │
│  └───────────────────────────────┘    │
│                                       │
│  ┌───────...                          │
└───────────────────────────────────────┘
```

## Moderation Actions

| Action | Effect |
|--------|--------|
| **Approve** | Set `verified = true`, increase `confidence_score` |
| **Reject** | Remove flag, decrease reporter credibility |
| **Merge** | Combine with nearby zone, increase `flag_count` |
| **Escalate** | Flag for admin review (if moderator unsure) |

## Implementation

```dart
class FlagModerationService {
  Future<void> approveFlag(String flagId) async {
    await supabase.from('unsafe_zones')
        .update({ 'verified': true, 'confidence_score': 0.8 })
        .eq('id', flagId);
    
    await logAdminAction(action: 'approve_flag', targetType: 'unsafe_zone', targetId: flagId);
  }

  Future<void> rejectFlag(String flagId) async {
    await supabase.from('unsafe_zones').delete().eq('id', flagId);
    await logAdminAction(action: 'reject_flag', targetType: 'unsafe_zone', targetId: flagId);
  }

  Future<void> mergeFlags(String primaryId, List<String> mergeIds) async {
    // Increase flag_count on primary, delete merged
    final totalFlags = mergeIds.length + 1;
    await supabase.from('unsafe_zones')
        .update({ 'flag_count': totalFlags, 'verified': true })
        .eq('id', primaryId);
    
    for (final id in mergeIds) {
      await supabase.from('unsafe_zones').delete().eq('id', id);
    }
    
    await logAdminAction(action: 'merge_flags', targetType: 'unsafe_zone', 
        targetId: primaryId, details: { 'merged': mergeIds });
  }
}
```

---

## Verification
- [ ] Moderation queue shows pending flags
- [ ] Approve/reject/merge actions work
- [ ] All moderation actions are audited
- [ ] Flag count and confidence update correctly
