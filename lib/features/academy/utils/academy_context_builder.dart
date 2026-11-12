import 'package:impetus/features/academy/models/academy_models.dart';

// Serializza il database federale in Markdown per il contesto di sistema di Gemini.
String generaContestoAccademia(List<SettoreFederale> database) {
  final buffer = StringBuffer();

  buffer.writeln('# ISTRUZIONI DI SISTEMA & LINEE GUIDA');
  buffer.writeln(
      'Ruolo: Assistente Tecnico Ufficiale di IMPETUS per la Kickboxing (FEDERKOMBAT / WAKO).\n');
  buffer.writeln('Vincoli di risposta:');
  buffer.writeln(
      '1. Aderenza al testo: Rispondi basandoti esclusivamente sulle tecniche e sui regolamenti contenuti in questo prontuario.');
  buffer.writeln(
      '2. Ambito specialistico: Se la domanda riguarda temi non inerenti alla Kickboxing, rispondi cortesemente che puoi trattare solo argomenti marziali e tecnici del syllabus federale.');
  buffer.writeln(
      '3. Formattazione: Utilizza elenchi puntati e struttura Markdown chiara per facilitare la consultazione.');
  buffer.writeln(
      '4. Nomenclatura federale: Adotta sempre la terminologia ufficiale italiana (Diretto Avanzato, Diretto Posteriore, Gancio, Montante, Calcio Circolare Basso/Medio/Alto, Calcio Frontale, Calcio ad Ascia, Ginocchiata).\n');
  buffer.writeln('--- (Inizio Knowledge Base Federale) ---\n');

  for (final settore in database) {
    buffer.writeln('## SETTORE: ${settore.nomeSettore.toUpperCase()}');
    buffer.writeln('Descrizione: ${settore.descrizione}\n');

    for (final programma in settore.programmiEsame) {
      buffer.writeln('### Programma: ${programma.grado}');
      if (programma.tempistica.isNotEmpty) {
        buffer.writeln('Tempistica: ${programma.tempistica}');
      }
      if (programma.criteriValutazione.isNotEmpty) {
        buffer.writeln('Criteri di Valutazione:');
        for (final criterio in programma.criteriValutazione) {
          buffer.writeln('- $criterio');
        }
      }
      buffer.writeln();

      for (final categoria in programma.categorie) {
        buffer.writeln('#### Categoria: ${categoria.nomeCategoria}');
        for (final tecnica in categoria.tecniche) {
          buffer.writeln(
              '##### Tecnica: ${tecnica.titolo} (Difficoltà: ${tecnica.difficolta})');
          if (tecnica.descrizioneScientifica.isNotEmpty) {
            buffer.writeln(
                'Descrizione/Teoria: ${tecnica.descrizioneScientifica}');
          }
          if (tecnica.biomeccanica.isNotEmpty) {
            buffer.writeln('Biomeccanica: ${tecnica.biomeccanica}');
          }
          if (tecnica.fasiEsecuzione.isNotEmpty) {
            buffer.writeln('Fasi Esecuzione:');
            for (final fase in tecnica.fasiEsecuzione) {
              buffer.writeln('  * $fase');
            }
          }
          if (tecnica.erroriComuni.isNotEmpty) {
            buffer.writeln('Errori Comuni:');
            for (final errore in tecnica.erroriComuni) {
              buffer.writeln('  * $errore');
            }
          }
          if (tecnica.varianti.isNotEmpty) {
            buffer.writeln('Varianti:');
            tecnica.varianti.forEach((chiave, lista) {
              buffer.writeln('  - $chiave:');
              for (final v in lista) {
                buffer.writeln('    * $v');
              }
            });
          }
          if (tecnica.disciplineAmmesse.isNotEmpty) {
            buffer.writeln(
                "Discipline Ammesse: ${tecnica.disciplineAmmesse.join(', ')}");
          }
          buffer.writeln();
        }
      }
      buffer.writeln('---\n');
    }
  }

  return buffer.toString();
}
