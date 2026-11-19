import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:impetus/core/ui_constants.dart';
import 'package:impetus/features/academy/providers/academy_provider.dart';
import 'package:impetus/features/auth/providers/auth_provider.dart';

class AcademyPage extends ConsumerWidget {
  const AcademyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academyData = ref.watch(academyDataProvider);
    return Scaffold(
      backgroundColor: UIConstants.deepBlack,
      appBar: AppBar(
        backgroundColor: UIConstants.surfaceGrey,
        title: const Text(
          'ACADEMY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: UIConstants.errorRed),
            tooltip: 'Esci',
            onPressed: () => showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: academyData.when(
        data: (settori) {
          if (settori.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      color: Colors.white38,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Nessun contenuto disponibile nell'archivio.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(academyDataProvider.notifier).refresh(),
                      child: const Text(
                        'RICARICA',
                        style: TextStyle(color: UIConstants.primaryCyan),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            // Spazio extra per FAB e bottom bar traslucida
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
            itemCount: settori.length,
            itemBuilder: (context, index) => Card(
              color: UIConstants.cardGrey,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(settori[index].nomeSettore),
                subtitle: Text(settori[index].descrizione),
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: UIConstants.primaryCyan),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Errore nel caricamento: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(academyDataProvider.notifier).refresh(),
                  child: const Text('RIPROVA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
