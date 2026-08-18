import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/router/app_router.dart';
import '../providers/notes_provider.dart';
import 'page_notes_sheet.dart';

const _stickyNoteColor = Color(0xFFF59E0B);

/// Header "Sticky Notes" button — badge shows the current page's note
/// count. Flutter port of web's `NoteTrigger.tsx`, reshaped for mobile:
/// tapping opens [showPageNotesSheet] directly (a bottom sheet combining
/// web's separate color-picker popover + freeform notes panel into one
/// scrollable list), rather than a hover popover.
class NoteTriggerButton extends ConsumerWidget {
  const NoteTriggerButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notesForCurrentRouteProvider).maybeWhen(data: (notes) => notes.length, orElse: () => 0);

    return InkWell(
      onTap: () {
        final navContext = ref.read(appRouterProvider).routerDelegate.navigatorKey.currentContext;
        if (navContext == null) return;
        showPageNotesSheet(navContext);
      },
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 16, color: _stickyNoteColor),
            if (count > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 14),
                  decoration: const BoxDecoration(color: Color(0xFF6D4AFF), shape: BoxShape.circle),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
