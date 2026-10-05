# IMPETUS – Bozza Prototipale di Tesi Triennale

**Candidato:** Rocco Desario  
**Corso di Laurea:** Ingegneria Informatica e dell'Automazione (L-8) – Politecnico di Bari  
**Progetto:** Sistema Mobile per l'Analisi del Movimento e la Didattica nella Kickboxing  

---

### Descrizione dell'Infrastruttura
Questa repository rappresenta la bozza architetturale iniziale predisposta per verificare la fattibilità tecnica del progetto di tesi:
* **Framework:** Flutter / Dart (architettura modulare a feature con gestione dello stato tramite Riverpod).
* **Pipeline Video & Tracking:** Integrazione del flusso fotocamera on-device e predisposizione per il tracciamento dei 33 landmark corporei (Google ML Kit / BlazePose).
* **Didattica Federale:** Syllabus didattico e tecnico FEDERKOMBAT/WAKO strutturato in locale (`assets/data/academy_data.json`).
* **Modulo Oracolo:** Assistente di consultazione tecnica con contesto vincolato alla didattica federale.
* **Storage Locale & Privacy:** Persistenza protetta per il profilo dell'atleta e la reportistica di allenamento.

---

### Istruzioni per l'avvio

1. Scaricare le dipendenze:
   ```bash
   flutter pub get
   ```

2. Verificare l'integrità del codice:
   ```bash
   flutter analyze
   ```

3. Eseguire l'applicazione su smartphone o emulatore:
   ```bash
   flutter run
   ```
