
# [OMOP_SEPSIS]-CohortDiagnostics

Questo repository contiene il codice per eseguire la fase preliminare dello studio, ovvero CohortDiagnostics.

Si prega di seguire le istruzioni sotto riportate per eseguire correttamente le analisi necessarie.

## Istruzioni
Una volta scaricato il contenuto del repository, aprire il file **[OMOP_SEPSIS]-CohortDiagnostics.Rproj** utilizzando RStudio e procedere con le operazioni elencate sotto.

### Creazione della libreria per il progetto e sincronizzazione dei pacchetti R necessari

Prima di avviare le analisi, è fondamentale verificare che tutti i pacchetti R necessari siano installati. Inoltre, è essenziale che ogni centro utilizzi la stessa versione dei pacchetti R per garantire la comparabilità dei risultati.

Per garantire l'installazione corretta dei pacchetti nella versione richiesta è necessario eseguire il codice contenuto nel file **CreateProjectLibrary.R**. 

Questo script deve essere eseguito una sola volta, prima dell'avvio della prima esecuzione di CohortDiagnostics.

### Esecuzione delle analisi

L'unico file che richiede modifiche è il file **RunAnalysis.R**. Si prega di compilarlo con tutte le informazioni necessarie, adattandole alla propria situazione prima di eseguire le analisi. Le informazioni inserite saranno poi necessarie per la connessione al database e l'esecuzione delle analisi.

Per garantire la corretta esecuzione, si prega di non apportare modifiche agli altri file contenuti nella cartella.

Una volta inserite le informazioni richieste, eseguire lo script **RunAnalysis.R** per ottenere i risultati del tool CohortDiagnostics.

### Diagnostics Explorer (Opzionale)
Questo passaggio è facoltativo se vuoi esaminare i risultati ottenuti prima di inviarli al centro coordinatore.

Lo script **DiagnosticsExplorer.R** contiene una Shiny app per visualizzare i risultati del CohortDiagnostics. Per avviare l'applicazione, seguire i seguenti passaggi:
1 - creare una cartella dal nome **data** all'interno della cartella di lavoro ([OMOP_SEPSIS]-CohortDiagnostics);
2 - copiare all'interno della cartella appena creata il file zip **abc.zip**, contenente i risultati del CohortDiagnostics;
3 - eseguire lo script **DiagnosticsExplorer.R**.

## Condivisione dei risultati
Al termine delle analisi, se tutto avrà funzionato correttamente, ogni centro avrà a disposizione il file **abc.zip**.

Il file elencato, dovrà essere condiviso con il centro coordinatore secondo le modalità comunicate.

Grazie!
