import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/school_entity.dart';
import '../../domain/entities/billing_entity.dart';
import '../../domain/entities/audit_entity.dart';
import '../../domain/entities/policy_entity.dart';

/// Local sample data for School Tenancy UI preview
/// This is temporary data for UI-only testing
/// Will be replaced with real API integration after auth is merged

class SchoolTenancyLocalData {
  SchoolTenancyLocalData._();

  /// Sample Dashboard Data
  static DashboardEntity getDashboard() {
    return const DashboardEntity(
      totalSchools: 48,
      activeSchools: 45,
      totalStudents: 12453,
      activeStudents: 11890,
      inactiveStudents: 563,
      totalStaff: 856,
      mrr: MrrEntity(
        current: 589000,
        previous: 556000,
        trend: 5.9,
      ),
      alertCount: 3,
      overdueCount: 2,
      blockedCount: 1,
      boardBreakdown: [
        BoardBreakdownEntity(board: 'CBSE', count: 28, percent: 58.3),
        BoardBreakdownEntity(board: 'ICSE', count: 12, percent: 25.0),
        BoardBreakdownEntity(board: 'State Board', count: 8, percent: 16.7),
      ],
      trends: TrendsEntity(
        students: 8.2,
        mrr: 5.9,
      ),
      recentEvents: [
        RecentEventEntity(
          id: 'EVT001',
          timestamp: '2026-07-17T10:30:00Z',
          actor: 'Super Admin',
          action: 'School Created',
          detail: 'New school "St. Mary\'s High School" provisioned',
          severity: 'info',
          tenantId: 'SCH048',
          schoolName: 'St. Mary\'s High School',
        ),
        RecentEventEntity(
          id: 'EVT002',
          timestamp: '2026-07-17T09:15:00Z',
          actor: 'Super Admin',
          action: 'Plan Upgraded',
          detail: 'Delhi Public School upgraded to Premium',
          severity: 'success',
          tenantId: 'SCH003',
          schoolName: 'Delhi Public School',
        ),
        RecentEventEntity(
          id: 'EVT003',
          timestamp: '2026-07-17T08:45:00Z',
          actor: 'System',
          action: 'Payment Failed',
          detail: 'Auto-payment failed for Modern Academy',
          severity: 'error',
          tenantId: 'SCH012',
          schoolName: 'Modern Academy',
        ),
      ],
      stateBreakdown: [
        StateBreakdownEntity(state: 'Karnataka', code: 'KA', count: 12, students: 3245),
        StateBreakdownEntity(state: 'Maharashtra', code: 'MH', count: 10, students: 2890),
        StateBreakdownEntity(state: 'Tamil Nadu', code: 'TN', count: 8, students: 2156),
        StateBreakdownEntity(state: 'Delhi', code: 'DL', count: 7, students: 1998),
        StateBreakdownEntity(state: 'Gujarat', code: 'GJ', count: 6, students: 1534),
        StateBreakdownEntity(state: 'Others', code: 'XX', count: 5, students: 630),
      ],
      planBreakdown: [
        PlanBreakdownEntity(plan: 'Premium', count: 18, mrr: 324000, students: 5678),
        PlanBreakdownEntity(plan: 'Standard', count: 22, mrr: 198000, students: 4890),
        PlanBreakdownEntity(plan: 'Basic', count: 8, mrr: 67000, students: 1885),
      ],
    );
  }

  /// Sample Schools Data
  static PaginatedSchoolsEntity getSchools({
    String? search,
    String? status,
    String? board,
    String? plan,
  }) {
    // Sample school data
    final allSchools = [
      const SchoolEntity(
        tenantId: 'SCH001',
        name: 'Delhi Public School',
        shortCode: 'DPS',
        subdomainUrl: 'dps.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 30,
        ssoMethod: 'SAML',
        apiAccess: true,
        plan: 'premium',
        status: 'active',
        provisionedAt: '2025-09-15T10:00:00Z',
        createdAt: '2025-09-15T10:00:00Z',
        updatedAt: '2026-07-15T14:30:00Z',
        students: 1250,
        activeStudents: 1198,
        seats: 1500,
        staff: 78,
        lastActivity: '2026-07-17T09:45:00Z',
        board: 'CBSE',
        state: 'Delhi',
        region: 'North',
        gstin: '07AABCU9603R1ZM',
        udiseCode: '09010100101',
        pan: 'AABCU9603R',
        brandColor: '#1E40AF',
        logoUrl: 'https://storage.eskoolia.com/logos/dps.png',
      ),
      const SchoolEntity(
        tenantId: 'SCH002',
        name: 'St. Mary\'s Convent',
        shortCode: 'SMC',
        subdomainUrl: 'stmarys.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 30,
        ssoMethod: 'OAuth',
        apiAccess: true,
        plan: 'standard',
        status: 'active',
        provisionedAt: '2025-10-20T11:30:00Z',
        students: 856,
        activeStudents: 823,
        seats: 1000,
        staff: 52,
        lastActivity: '2026-07-17T08:20:00Z',
        board: 'ICSE',
        state: 'Karnataka',
        region: 'South',
        gstin: '29AABCU9603R1ZN',
        udiseCode: '29010200202',
      ),
      const SchoolEntity(
        tenantId: 'SCH003',
        name: 'Modern Academy',
        shortCode: 'MAC',
        subdomainUrl: 'modern.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 15,
        ssoMethod: 'None',
        apiAccess: false,
        plan: 'basic',
        status: 'active',
        provisionedAt: '2026-01-10T09:00:00Z',
        students: 425,
        activeStudents: 412,
        seats: 500,
        staff: 28,
        lastActivity: '2026-07-16T16:45:00Z',
        board: 'State Board',
        state: 'Maharashtra',
        region: 'West',
        gstin: '27AABCU9603R1ZO',
      ),
      const SchoolEntity(
        tenantId: 'SCH004',
        name: 'Greenfield International',
        shortCode: 'GFI',
        subdomainUrl: 'greenfield.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 30,
        ssoMethod: 'SAML',
        apiAccess: true,
        plan: 'premium',
        status: 'trial',
        provisionedAt: '2026-07-10T14:00:00Z',
        students: 320,
        activeStudents: 318,
        seats: 800,
        staff: 24,
        lastActivity: '2026-07-17T10:15:00Z',
        board: 'CBSE',
        state: 'Tamil Nadu',
        region: 'South',
      ),
      const SchoolEntity(
        tenantId: 'SCH005',
        name: 'Bright Future School',
        shortCode: 'BFS',
        subdomainUrl: 'brightfuture.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 30,
        ssoMethod: 'OAuth',
        apiAccess: true,
        plan: 'standard',
        status: 'active',
        provisionedAt: '2025-11-05T10:30:00Z',
        students: 678,
        activeStudents: 654,
        seats: 750,
        staff: 41,
        lastActivity: '2026-07-17T07:30:00Z',
        board: 'CBSE',
        state: 'Gujarat',
        region: 'West',
        gstin: '24AABCU9603R1ZP',
      ),
      const SchoolEntity(
        tenantId: 'SCH006',
        name: 'Sunrise Academy',
        shortCode: 'SRA',
        subdomainUrl: 'sunrise.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 15,
        ssoMethod: 'None',
        apiAccess: false,
        plan: 'basic',
        status: 'suspended',
        provisionedAt: '2026-02-15T11:00:00Z',
        students: 234,
        activeStudents: 0,
        seats: 300,
        staff: 18,
        lastActivity: '2026-06-30T12:00:00Z',
        board: 'ICSE',
        state: 'Karnataka',
        region: 'South',
      ),
      const SchoolEntity(
        tenantId: 'SCH007',
        name: 'Royal Public School',
        shortCode: 'RPS',
        subdomainUrl: 'royal.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 30,
        ssoMethod: 'SAML',
        apiAccess: true,
        plan: 'premium',
        status: 'active',
        provisionedAt: '2025-08-20T09:30:00Z',
        students: 1450,
        activeStudents: 1423,
        seats: 1600,
        staff: 89,
        lastActivity: '2026-07-17T09:00:00Z',
        board: 'CBSE',
        state: 'Delhi',
        region: 'North',
        gstin: '07AABCU9603R1ZQ',
      ),
      const SchoolEntity(
        tenantId: 'SCH008',
        name: 'Wisdom International',
        shortCode: 'WIS',
        subdomainUrl: 'wisdom.eskoolia.com',
        shardRegion: 'ap-south-1',
        storageRegion: 'ap-south-1',
        backupRetention: 30,
        ssoMethod: 'OAuth',
        apiAccess: true,
        plan: 'standard',
        status: 'onboarding',
        provisionedAt: '2026-07-15T15:30:00Z',
        students: 0,
        activeStudents: 0,
        seats: 500,
        staff: 0,
        lastActivity: '2026-07-15T15:30:00Z',
        board: 'ICSE',
        state: 'Maharashtra',
        region: 'West',
      ),
    ];

    // Apply filters
    var filteredSchools = allSchools;

    if (search != null && search.isNotEmpty) {
      filteredSchools = filteredSchools.where((school) {
        return school.name.toLowerCase().contains(search.toLowerCase()) ||
            school.shortCode.toLowerCase().contains(search.toLowerCase()) ||
            school.tenantId.toLowerCase().contains(search.toLowerCase());
      }).toList();
    }

    if (status != null && status.isNotEmpty) {
      filteredSchools = filteredSchools.where((school) {
        return school.status.toLowerCase() == status.toLowerCase();
      }).toList();
    }

    if (board != null && board.isNotEmpty) {
      filteredSchools = filteredSchools.where((school) {
        return school.board?.toLowerCase() == board.toLowerCase();
      }).toList();
    }

    if (plan != null && plan.isNotEmpty) {
      filteredSchools = filteredSchools.where((school) {
        return school.plan.toLowerCase() == plan.toLowerCase();
      }).toList();
    }

    return PaginatedSchoolsEntity(
      count: filteredSchools.length,
      next: null,
      previous: null,
      results: filteredSchools,
    );
  }

  /// Sample Billing Data
  static BillingStateEntity getBillingState() {
    return BillingStateEntity(
      invoices: [
        InvoiceEntity(
          invoiceNumber: 'INV-2026-0045',
          schoolName: 'Delhi Public School',
          amount: 67800,
          status: 'paid',
          dueDate: DateTime(2026, 7, 15),
        ),
        InvoiceEntity(
          invoiceNumber: 'INV-2026-0044',
          schoolName: 'St. Mary\'s Convent',
          amount: 45200,
          status: 'paid',
          dueDate: DateTime(2026, 7, 14),
        ),
        InvoiceEntity(
          invoiceNumber: 'INV-2026-0043',
          schoolName: 'Modern Academy',
          amount: 23600,
          status: 'pending',
          dueDate: DateTime(2026, 7, 12),
        ),
        InvoiceEntity(
          invoiceNumber: 'INV-2026-0042',
          schoolName: 'Greenfield International',
          amount: 56400,
          status: 'overdue',
          dueDate: DateTime(2026, 7, 10),
        ),
      ],
    );
  }

  /// Sample Audit Data
  static AuditStateEntity getAuditState() {
    final now = DateTime.now();
    return AuditStateEntity(
      events: [
        AuditEventEntity(
          id: 'ev-001',
          timestamp: now.subtract(const Duration(minutes: 4)).toIso8601String(),
          actor: 'superadmin@eskoolia.com',
          actorIp: '103.27.8.14',
          action: 'school.provision',
          detail: 'Provisioned Delhi Public School (schema: dps_noida)',
          severity: 'info',
          schoolName: 'Delhi Public School',
        ),
        AuditEventEntity(
          id: 'ev-002',
          timestamp: now.subtract(const Duration(minutes: 18)).toIso8601String(),
          actor: 'superadmin@eskoolia.com',
          actorIp: '103.27.8.14',
          action: 'invoice.generated',
          detail: 'Invoice INV-2026-0045 generated for Ryan International (\u20b99,999)',
          severity: 'info',
          schoolName: 'Ryan International',
        ),
        AuditEventEntity(
          id: 'ev-003',
          timestamp: now.subtract(const Duration(minutes: 45)).toIso8601String(),
          actor: 'admin@ryan.edu',
          actorIp: '49.207.193.22',
          action: 'auth.impersonate',
          detail: 'Super admin impersonated school admin at Ryan International',
          severity: 'warning',
          schoolName: 'Ryan International',
        ),
        AuditEventEntity(
          id: 'ev-004',
          timestamp: now.subtract(const Duration(hours: 2)).toIso8601String(),
          actor: 'superadmin@eskoolia.com',
          actorIp: '103.27.8.14',
          action: 'policy.updated',
          detail: 'GST rate changed from 9% to 18% (key: gst.default_rate)',
          severity: 'warning',
        ),
        AuditEventEntity(
          id: 'ev-005',
          timestamp: now.subtract(const Duration(hours: 3)).toIso8601String(),
          actor: 'system',
          actorIp: '127.0.0.1',
          action: 'invoice.overdue',
          detail: 'Invoice INV-2026-0031 (Sunrise Academy) marked overdue \u2014 \u20b92,999',
          severity: 'critical',
          schoolName: 'Sunrise Academy',
        ),
      ],
    );
  }

  /// Sample Policies Data
  static PoliciesStateEntity getPoliciesState() {
    return const PoliciesStateEntity(
      security: [
        PolicyEntity(
          key: 'password.min_length',
          label: 'Password Min Length',
          description: 'Minimum password length for super-admin and platform accounts.',
          type: 'number',
          value: 10,
          isToggle: false,
          isOverridable: false,
        ),
        PolicyEntity(
          key: 'session.timeout_minutes',
          label: 'Session Timeout',
          description: 'Session timeout before re-authentication is required.',
          type: 'number',
          value: 30,
          isToggle: false,
          isOverridable: false,
        ),
        PolicyEntity(
          key: 'mfa.required',
          label: 'MFA Required',
          description: 'Require MFA for super-admin accounts.',
          type: 'boolean',
          value: true,
          isToggle: true,
          isOverridable: false,
        ),
      ],
      dataIsolation: [
        PolicyEntity(
          key: 'tenant.public_schema_only',
          label: 'Public Schema Only',
          description: 'Super-admin APIs are restricted to the public schema.',
          type: 'boolean',
          value: true,
          isToggle: true,
          isOverridable: false,
        ),
        PolicyEntity(
          key: 'audit.retention_days',
          label: 'Audit Retention',
          description: 'Audit log retention window in days.',
          type: 'number',
          value: 365,
          isToggle: false,
          isOverridable: false,
        ),
      ],
      billing: [
        PolicyEntity(
          key: 'gst.rate_percent',
          label: 'GST Rate',
          description: 'Default GST rate used for billing calculations.',
          type: 'number',
          value: 18,
          isToggle: false,
          isOverridable: true,
        ),
        PolicyEntity(
          key: 'invoice.payment_terms_days',
          label: 'Payment Terms',
          description: 'Payment due window for issued invoices.',
          type: 'number',
          value: 15,
          isToggle: false,
          isOverridable: true,
        ),
      ],
      system: [
        PolicyEntity(
          key: 'backup.retention_days',
          label: 'Backup Retention',
          description: 'Daily backup retention window.',
          type: 'number',
          value: 30,
          isToggle: false,
          isOverridable: true,
        ),
        PolicyEntity(
          key: 'multi_tenancy.enabled',
          label: 'Multi-tenancy',
          description: 'Controls whether schema-based multi-tenancy is enabled.',
          type: 'boolean',
          value: false,
          isToggle: true,
          isOverridable: false,
        ),
      ],
    );
  }
}
