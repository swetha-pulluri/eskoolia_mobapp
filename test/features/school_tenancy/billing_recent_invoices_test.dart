import 'package:eskoolia_mobapp/features/school_tenancy/domain/entities/invoice_entity.dart';
import 'package:eskoolia_mobapp/features/school_tenancy/presentation/pages/billing_tab.dart';
import 'package:eskoolia_mobapp/features/school_tenancy/presentation/pages/invoice_detail_page.dart';
import 'package:eskoolia_mobapp/features/school_tenancy/presentation/providers/school_tenancy_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

InvoiceEntity _fixtureInvoice({
  required String id,
  required String number,
  required String school,
  required String status,
}) {
  return InvoiceEntity(
    id: id,
    invoiceNumber: number,
    schoolName: school,
    tenantId: 'TNT001',
    invoiceDate: '2026-08-01',
    dueDate: '2026-08-15',
    status: status,
    sellerName: 'Eskoolia Technologies Pvt Ltd',
    sellerGstin: '29AABCE1234F1ZS',
    sellerState: 'Karnataka',
    buyerName: school,
    buyerGstin: '29AACCG1234H1Z8',
    buyerState: 'Karnataka',
    lineItems: const [
      InvoiceLineItemEntity(
        description: 'Eskoolia ERP — Premium plan',
        quantity: 1,
        unitPrice: 34500,
        sacCode: '998313',
        amount: 34500,
      ),
    ],
    taxBreakdown: const TaxBreakdownEntity(
      subtotal: 34500,
      cgst: 3105,
      sgst: 3105,
      totalTax: 6210,
      grandTotal: 40710,
      amountInWords: 'Indian Rupees Forty Thousand Seven Hundred Ten Only',
    ),
    dueAmount: status == 'paid' ? 0 : 40710,
  );
}

void main() {
  testWidgets(
    'Recent invoices render as compact mobile cards and open a dedicated detail screen',
    (tester) async {
      // A small mobile viewport (iPhone SE-ish) — this is the scenario the
      // Billing tab redesign targets: no desktop-style horizontal scrolling.
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final invoices = PaginatedInvoicesEntity(
        count: 2,
        results: [
          _fixtureInvoice(
            id: '1',
            number: 'INV-202608-AAA11111',
            school: 'Greenwood High School',
            status: 'sent',
          ),
          _fixtureInvoice(
            id: '2',
            number: 'INV-202608-BBB22222',
            school: 'Blue Ridge Academy',
            status: 'paid',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoicesProvider.overrideWith((ref) async => invoices),
            billingMrrProvider.overrideWith(
              (ref) async => const BillingMrrEntity(
                currentMrr: 100000,
                previousMrr: 90000,
                gstCollected: 18000,
                outstandingAmount: 40710,
                atRiskAmount: 0,
                trendPercent: 5,
              ),
            ),
            plansProvider.overrideWith(
              (ref) async => const PlansCatalogEntity(
                plans: [],
                gstPercent: 18,
                sacCode: '998313',
                sacDescription: 'Education software',
                currency: 'INR',
              ),
            ),
          ],
          child: const MaterialApp(home: SuperAdminBillingPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Compact card shows only the required fields — no dense desktop-table
      // row (no full GSTIN/SAC/action-icon-row baked into the list card).
      expect(find.text('INV-202608-AAA11111'), findsOneWidget);
      expect(find.text('Greenwood High School'), findsOneWidget);
      expect(find.byType(InvoiceDetailPage), findsNothing);

      // The card sits below the fold on a small screen (header/KPIs/plans
      // render above it) — scroll it into view before tapping.
      await tester.scrollUntilVisible(
        find.text('INV-202608-AAA11111'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tapping a card opens the dedicated invoice-details screen.
      await tester.tap(find.text('INV-202608-AAA11111'));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceDetailPage), findsOneWidget);
      expect(find.text('Tax Invoice'), findsOneWidget);
      expect(find.text('INVOICE ACTIONS'), findsOneWidget);

      // Back navigation returns cleanly to the invoice list.
      await tester.tap(find.text('Back to invoices'));
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceDetailPage), findsNothing);
      expect(find.text('INV-202608-AAA11111'), findsOneWidget);
    },
  );
}
