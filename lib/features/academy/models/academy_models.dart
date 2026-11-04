import 'package:meta/meta.dart';

/// Rappresenta una singola tecnica o trattato teorico federale.
@immutable
class TecnicaFederale {
  const TecnicaFederale({
    required this.id,
    required this.titolo,
    this.difficolta = 'Base',
    this.descrizioneScientifica = '',
    this.biomeccanica = '',
    this.fasiEsecuzione = const [],
    this.erroriComuni = const [],
    this.varianti = const {},
    this.disciplineAmmesse = const [],
    this.fonteBibliografica = '',
  });

  factory TecnicaFederale.fromJson(Map<String, dynamic> json) {
    return TecnicaFederale(
      id: json['id'] as String? ?? '',
      titolo: json['titolo'] as String? ?? '',
      difficolta: json['difficolta'] as String? ?? 'Base',
      descrizioneScientifica: json['descrizioneScientifica'] as String? ?? '',
      biomeccanica: json['biomeccanica'] as String? ?? '',
      fasiEsecuzione: json['fasiEsecuzione'] != null
          ? List<String>.from(json['fasiEsecuzione'] as Iterable)
          : const [],
      erroriComuni: json['erroriComuni'] != null
          ? List<String>.from(json['erroriComuni'] as Iterable)
          : const [],
      varianti: json['varianti'] != null
          ? (json['varianti'] as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, List<String>.from(v as Iterable)))
          : const {},
      disciplineAmmesse: json['disciplineAmmesse'] != null
          ? List<String>.from(json['disciplineAmmesse'] as Iterable)
          : const [],
      fonteBibliografica: json['fonteBibliografica'] as String? ?? '',
    );
  }

  final String id;
  final String titolo;
  final String difficolta;
  final String descrizioneScientifica;
  final String biomeccanica;
  final List<String> fasiEsecuzione;
  final List<String> erroriComuni;
  final Map<String, List<String>> varianti;
  final List<String> disciplineAmmesse;
  final String fonteBibliografica;
}

/// Raggruppa un insieme di tecniche omogenee (es. Pugni, Calci, Difese).
@immutable
class CategoriaTecnica {
  const CategoriaTecnica({
    required this.nomeCategoria,
    required this.tecniche,
  });

  factory CategoriaTecnica.fromJson(Map<String, dynamic> json) {
    return CategoriaTecnica(
      nomeCategoria: json['nomeCategoria'] as String? ?? '',
      tecniche: json['tecniche'] != null
          ? (json['tecniche'] as Iterable)
              .map((e) => TecnicaFederale.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final String nomeCategoria;
  final List<TecnicaFederale> tecniche;
}

/// Rappresenta il programma d'esame per uno specifico grado o cintura.
@immutable
class ProgrammaCintura {
  const ProgrammaCintura({
    required this.grado,
    required this.categorie,
    this.tempistica = '',
    this.criteriValutazione = const [],
  });

  factory ProgrammaCintura.fromJson(Map<String, dynamic> json) {
    return ProgrammaCintura(
      grado: json['grado'] as String? ?? '',
      tempistica: json['tempistica'] as String? ?? '',
      categorie: json['categorie'] != null
          ? (json['categorie'] as Iterable)
              .map((e) => CategoriaTecnica.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      criteriValutazione: json['criteriValutazione'] != null
          ? List<String>.from(json['criteriValutazione'] as Iterable)
          : const [],
    );
  }

  final String grado;
  final String tempistica;
  final List<CategoriaTecnica> categorie;
  final List<String> criteriValutazione;
}

/// Settore della disciplina (es. Tatami, Ring, Scienze Applicate).
@immutable
class SettoreFederale {
  const SettoreFederale({
    required this.nomeSettore,
    required this.iconaIdentificativo,
    required this.descrizione,
    required this.programmiEsame,
  });

  factory SettoreFederale.fromJson(Map<String, dynamic> json) {
    return SettoreFederale(
      nomeSettore: json['nomeSettore'] as String? ?? '',
      iconaIdentificativo: json['iconaIdentificativo'] as String? ??
          json['icona'] as String? ??
          '',
      descrizione: json['descrizione'] as String? ?? '',
      programmiEsame: json['programmiEsame'] != null
          ? (json['programmiEsame'] as Iterable)
              .map((e) => ProgrammaCintura.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final String nomeSettore;
  final String iconaIdentificativo;
  final String descrizione;
  final List<ProgrammaCintura> programmiEsame;
}
