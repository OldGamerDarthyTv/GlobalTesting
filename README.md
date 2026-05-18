# ☕ OGD WinCaffe NEXT 8.0.10

> **Creato da un Nerd Gamer, per altri Nerd Gamers** ❤️

![Stato](https://img.shields.io/badge/Stato-Attivo-00bcd4?style=for-the-badge)
![Versione](https://img.shields.io/badge/Versione-8.0.10-8e44ad?style=for-the-badge)
![Target](https://img.shields.io/badge/Target-Windows%2010%20%26%2011-2ecc71?style=for-the-badge)
![Licenza](https://img.shields.io/badge/Uso-No%20profit-orange?style=for-the-badge)

---

## 🌌 Cos'è OGD WinCaffe NEXT

**OGD WinCaffe NEXT** è uno script PowerShell di ottimizzazione, manutenzione, diagnostica e riparazione pensato soprattutto per il gaming su Windows.

L'obiettivo del progetto non è “spingere tutto al massimo a caso”, ma **migliorare il sistema in modo ragionato**, offrendo:

- preset rapidi per diversi tipi di PC e di uso,
- menu dedicati a moduli specifici,
- fix mirati per problemi reali,
- strumenti di bonifica per tornare a uno stato più pulito quando tweak vecchi o troppo aggressivi peggiorano il comportamento del sistema.

Il progetto è presentato nello script come **NO-PROFIT** e orientato ad aiutare la community gaming.

---

## 🧭 Nota importante sulla versione 8.0.10

La numerazione **8.0.10** non è un errore.

Questa release viene usata come **versione provvisoria di fix e transizione** al posto di una numerazione tipo **8.1.0**, per separare con più chiarezza:

- i **fix urgenti**,
- le **bonifiche dei rami precedenti**,
- le **revisioni maggiori** che arriveranno più avanti.

In pratica, questa build rappresenta un ponte più prudente verso le versioni future del progetto.

---

## 🖥️ Compatibilità e filosofia d'uso

### Sistemi target
- **Windows 11**
- **Windows 10**
- rilevamento e scelta del target **Windows 10 / 11 / 24H2+ / 25H2+**

### Modalità d'esecuzione
- richiede privilegi **amministrativi**,
- può rilanciarsi automaticamente elevato,
- usa PowerShell con logica compatibile con ambienti moderni,
- include controlli iniziali sul target Windows e sul tipo di PC.

### Filosofia del progetto
- **migliorare senza esagerare**,
- evitare tweak troppo “magici” o poco chiari,
- fornire menu separati per profili, fix, diagnostica e moduli speciali,
- lasciare all’utente il controllo finale.

---

## 🎛️ Menu e moduli principali

Lo script espone nel menu principale i seguenti rami operativi.

### Profili core
- **[1] LIGHT** → profilo leggero e prudente
- **[2] NORMALE** → preset consigliato
- **[3] AGGRESSIVO** → profilo più spinto
- **[A] AGGRESSIVO GAMING** → ramo dedicato al gaming
- **[4] LAPTOP** → profilo pensato per notebook
- **[5] LAPTOP GAMING** → ramo gaming per notebook

### Strumenti e moduli speciali
- **[6] FIX RETE** → fix di rete e ripristino DNS automatici/default
- **[7] EXPLORER** → tweak e interventi legati a Esplora file
- **[8] INFO** → informazioni e riepiloghi
- **[9] RESET** → funzioni di reset e ripristino
- **[F] FILE I/O** → tweak orientati a I/O, disco e file system
- **[U] WINGET** → controlli e operazioni legate a Winget / pacchetti
- **[W] WINREVIVE** → sezione dedicata a WinRevive
- **[N] NETWORK** → tweak di rete e diagnostica collegata
- **[G] NVIDIA** → modulo NVIDIA
- **[L] DPC FIX** → fix per latenze/DPC
- **[P] NPU** → rilevamento e diagnostica NPU
- **[E] UNREAL** → modulo dedicato a Unreal Engine
- **[Y] WIN11 24H2+** → tweak dedicati ai sistemi Windows 11 più recenti
- **[C] CALL OF DUTY** → ramo dedicato a Call of Duty
- **[M] MOUSE** → modulo mouse / input
- **[D] DISCORD** → tweak o fix dedicati a Discord
- **[B] BETA** → area test / sperimentale
- **[Q] BENCHMARK** → benchmark e adattamento tweak
- **[T] MICRO TWEAKS** → micro ottimizzazioni
- **[K] SSD/NVME** → tweak archiviazione / SSD / NVMe
- **[H] HOTFIX 8.0.10** → fix mirati, accessibilità e compatibilità
- **[J] FIX PRE 8.0.10** → bonifica di tweak legacy e rami precedenti

---

## 🛠️ Hotfix e bonifica

### [H] HOTFIX 8.0.10
Questo menu è pensato per problemi specifici, non per ottimizzazione generica. Include funzioni dedicate a:

- controllo stato **DX9 legacy**,
- apertura della riparazione ufficiale **DirectX legacy**,
- modalità compatibilità per software o giochi DX9 più delicati,
- gestione **OpenDyslexic**,
- diagnostica **NPU avanzata**,
- ripristino **Opzioni di accesso / cambio password**,
- ripristino compatibilità app / runtime / launcher,
- riabilitazione completa di **Copilot**.

### [J] FIX PRE 8.0.10
Questa sezione serve a **bonificare tweak vecchi o troppo aggressivi**. In particolare riporta verso valori più prudenti:

- clock/timer low-level,
- power throttling,
- alcune impostazioni di memory management,
- SysMain / Prefetch,
- Windows Search,
- manutenzione automatica,
- Windows Error Reporting,
- residui legacy poco adatti al ramo 8.0.10.

---

## 🧠 NPU e hardware moderno

Uno dei punti forti dichiarati della release 8.0.10 è il **rilevamento NPU più robusto**, con più metodi in cascata e fallback CPU-based.

Lo script è pensato per riconoscere in modo più moderno piattaforme come:
- **Intel Core Ultra**,
- **AMD Ryzen AI**,
- **Snapdragon X**.

Questo non significa “forzare magia IA”, ma offrire:
- rilevamento migliore,
- menu dedicati,
- diagnostica più chiara,
- separazione tra hardware rilevato e hardware davvero pronto all’uso.

---

## ⚠️ Stato attuale tweak AMD

I rami **AMD GPU** e **AMD CPU** sono presenti nel progetto, ma al momento non sono ancora supportati in modo pieno.

La ragione è semplice:
- attualmente non c'è ancora hardware AMD reale disponibile per test diretti e validazione seria sul campo,
- quindi questi tweak vengono forniti **così come sono**,
- senza supporto ufficiale,
- e con utilizzo **a rischio dell'utente** fino a futura validazione pratica.

In breve:
- possono essere utili come base lato Windows,
- ma non vanno considerati al livello di affidabilità dei rami testati su hardware realmente disponibile.

Quando sarà disponibile hardware AMD da testare, questa parte del progetto verrà rivista e supportata in modo più completo.

---

## ♿ Accessibilità: OpenDyslexic

Lo script include un gestore dedicato per **OpenDyslexic**, trattato come funzione di **accessibilità opzionale**.

Il manager permette di:
- verificare / installare / riparare il font,
- forzare reinstallazione o riparazione,
- applicarlo in modalità compatibile,
- ripristinare i font standard,
- disinstallarlo.

⚠️ **Nota importante:** OpenDyslexic è consigliato solo a chi ne ha davvero bisogno per dislessia o difficoltà di lettura. Non va considerato un tweak universale da applicare a tutti i PC.

---

## 🌐 Nota DNS: nuova filosofia del progetto

A partire da questo ramo, **WinCaffe NEXT non imposta più DNS personalizzati** come parte normale dei preset o dei menu di rete.

La scelta è voluta:
- i **DNS** da oggi vengono lasciati **all’utente**,
- lo script non deve più mischiare DNS custom con i tweak rete,
- la funzione prevista è solo quella di **ripristinare i DNS ai valori di default / automatici** quando serve.

In breve:
- **nessun DNS pubblico forzato**,
- **nessun Cloudflare / Google / Quad9 applicato automaticamente**,
- solo **reset DNS → automatico/default** quando richiesto.

---

## 📦 Funzioni di supporto presenti nello script

In base alla struttura visibile del file, il progetto include anche:

- animazioni e feedback visivi durante varie operazioni,
- riepiloghi a schermo di ciò che è stato applicato,
- creazione di **punti di ripristino** in diverse aree sensibili,
- funzioni di repair e rollback parziale,
- integrazione con **Winget**,
- controlli su runtime e componenti Windows,
- sezioni dedicate a GPU, storage, rete, app, gaming e accessibilità.

---

## ⚠️ Avvertenze

Questo progetto nasce con intento **community-driven** e **no-profit**, ma resta comunque uno script di tweaking avanzato.

### Prima di usarlo è bene ricordare che:
- non tutti i preset sono universali,
- un tweak utile su un PC può essere inutile o dannoso su un altro,
- i rami più aggressivi vanno usati con più attenzione,
- i fix pre-8.0.10 servono proprio perché i rami precedenti possono aver lasciato impostazioni da ripulire,
- è sempre consigliato capire **cosa si sta applicando**, invece di cliccare tutto in automatico.

---

## 👑 Crediti, ringraziamenti e gloria dovuta

Questo progetto non nasce nel vuoto. È giusto dare **gloria, merito e riconoscenza** a chi ha costruito strumenti, documentazione, test e conoscenze che hanno reso possibile WinCaffè.

### 👨‍💻 Autore principale
**OldGamerDarthy** — **#DarkPlayer84Tv Productions**  
Sviluppo, integrazione, testing, manutenzione e visione del progetto.

### 🙏 Ringraziamenti personali già presenti nello script
- **AlexsTrexx (Alex)** — per aver creduto nelle fasi embrionali del progetto e averlo provato sul campo
- **Diego** — per supporto, consigli e amicizia durante lo sviluppo
- **gli amici del server Discord OGD** — per idee, suggerimenti e ispirazione continua
- **Claude AI** — citata nello script come supporto durante lo sviluppo

### 🤖 IA e supporti creativi citati per questo progetto
Su tua indicazione, in questo README vengono riconosciute con gratitudine anche diverse IA di supporto usate come aiuto creativo, tecnico o collaborativo nel tempo:

- **Antigravity**
- **Claude**
- **Codex**
- **ChatGPT**
- **Copilot**
- **e molte altre**

Non tutte hanno avuto lo stesso ruolo in ogni singola release, ma il ringraziamento resta sincero verso tutti gli strumenti che hanno aiutato il progetto a crescere.

### 📚 Fonti e crediti tecnici presenti nello script
- **SpeedGuide.net / TCP Optimizer** — per il lavoro storico e tecnico sulle impostazioni TCP/IP
- **Resplendence Software / LatencyMon** — per il riferimento sull’analisi della latenza DPC
- **WinScript (flick9000 / Francesco)** — per la parte di ispirazione collegata a debloat, privacy e telemetria
- **Microsoft Docs / Microsoft Learn** — per documentazione ufficiale su registry, PowerCfg, servizi, DISM, rete, compatibilità e componenti Windows
- **GitHub e community open-source** — per confronti, fix, validazione pratica e condivisione di conoscenze
- **community gaming e forum tecnici** — per test empirici, osservazioni pratiche e confronto sul campo
- **autori di driver, pannelli di controllo e tool hardware** di **NVIDIA, AMD e Intel** — per best practice, documentazione e strumenti ufficiali

### 🌟 Nota di rispetto
Questo README non vuole appropriarsi del lavoro altrui. Al contrario:

- riconosce che molte conoscenze arrivano da documentazione pubblica e da chi ha condiviso esperienze reali,
- ringrazia chi ha pubblicato tool, guide, fix, benchmark, post tecnici e documentazione,
- mantiene il principio che **i crediti restano ai rispettivi autori**.

A tutti loro va un grazie sincero. Davvero. 🙏

---

## ❤️ Conclusione

**OGD WinCaffe NEXT 8.0.10** non vuole essere solo uno “script che cambia valori”, ma un banco di lavoro per chi vuole:

- ottimizzare,
- capire,
- ripulire,
- testare,
- e usare Windows in modo più adatto al proprio stile di gioco e di utilizzo.

Con prudenza, rispetto per chi ha condiviso conoscenza, e passione da nerd gamer. ☕🎮✨

---

## 📌 File consigliati da tenere insieme
Per una release ordinata, è consigliato distribuire insieme:

- `OGD_WinCaffe_8.0.10.ps1`
- `readme-gpt.txt`
- `README.md`
