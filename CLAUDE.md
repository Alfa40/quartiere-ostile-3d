# The Magic Trip — regole per Claude

Godot 4.7.2, gioco pensato per telefono (vedi sotto), export web in `docs/` per GitHub Pages.

## Animazioni del personaggio (protagonist_saeedd.glb)

Queste regole esistono perché violarle ha causato più round di modifiche sbagliate/insoddisfacenti nella stessa sessione.

1. **Non inventare/derivare animazioni a mano.** Prima di costruire una curva di rotazione a occhio (o dedurla da angoli biomeccanici stimati), controlla `~/Desktop/animazioni/` — è una libreria di clip Mixamo reali (Locomotion Pack: idle/walk/run/strafe/turn/jump; più Punching-2..5, Hook Punch, Elbow Punch, Mutant Punch, Hit On Side/Back of Body). Se esiste una clip adatta o vicina, usala via retargeting (vedi sotto) invece di costruire keyframe a mano.

2. **Retargeting Mixamo → protagonist_saeedd**: i due rig hanno la stessa gerarchia/nomi di ossa (Mixamo usa il prefisso `mixamorig:`, che Godot sanitizza in `mixamorig_` — protagonist_saeedd non ha prefisso) ma pose di riposo diverse, quindi NON copiare le rotazioni locali grezze. Usa rotazioni globali normalizzate sulla posa di riposo, in ordine padre-prima-del-figlio (gli indici osso di `Skeleton3D` sono già ordinati così):
   ```
   G_target(i) = Grest_target(i) * Grest_source(i).inverse() * Gpose_source(i)
   ```
   (`Skeleton3D.get_bone_global_rest()` / `get_bone_global_pose()`, solo la `Basis`), poi converti in locale con `G_target(parent(i)).inverse() * G_target(i)` usando il **padre già ritargettato** (non quello della sorgente).
   Per specchiare una clip a un braccio solo (es. un pugno destro → sinistro): **non** scambiare a quale osso target scrivi i dati della sorgente (mischia pose di riposo di lati diversi, sembra plausibile sul braccio attivo ma produce un braccio "storto" su quello passivo/fermo). Calcola prima il retarget normale stesso-lato per ogni osso, poi rifletti quella posa già corretta per coniugazione: `G_mirrored = M * G_normal * M` con `M = Basis(Vector3(-1,0,0), Vector3(0,1,0), Vector3(0,0,1))`.

3. **Verifica SEMPRE dalla telecamera reale di gioco, non da una laterale/ravvicinata.** La `Camera3D` di `Player.tscn` è quasi verticale dall'alto: `position=(0, 12.6, 9.8)`, `rotation_degrees=(-52, 0, 0)`. Un movimento perfetto da una telecamera laterale può leggersi malissimo da quest'angolo (un'oscillazione ampia delle braccia può proiettarsi come "mani vicino al viso" invece che una falcata normale — già successo). Prima di considerare un'animazione finita, renderizza almeno un frame con la stessa posizione/rotazione esatta della camera reale (avvicinata per poterla ispezionare, ma senza cambiare pitch/heading, es. `position=(0, 2.2, 1.72)`, stessa `rotation_degrees`). Un check solo laterale non è sufficiente.

4. **Se il feedback dell'utente è vago dopo un paio di tentativi** ("le animazioni non vanno", "sembra strano"), chiedi uno screenshot o un video invece di continuare a indovinare. Per un video: `ffmpeg -i <path> -vf "fps=1/1.5,scale=480:-1" -y frame_%02d.png` (installa con `brew install ffmpeg` se manca) dà frame sufficienti; ritaglia/ingrandisci con PIL attorno al personaggio se è troppo piccolo per essere letto nel frame intero.

## Pipeline tecnica di modifica delle animazioni (.glb)

- Modifica via script GDScript disposable: istanzia il `.glb`, prendi `AnimationPlayer.get_animation_library(...).get_animation(nome)`, modifica le track (`find_track`/`add_track` con `NodePath("Armature/Skeleton3D:NomeOsso")`, tipo `Animation.TYPE_ROTATION_3D`), poi riesporta sovrascrivendo il file sorgente con `GLTFDocument.append_from_scene(...)` + `write_to_filesystem(...)`.
- **Prima di ogni `write_to_filesystem`**, ripristina le texture dei materiali sui file sorgente originali tracciati in git (non su quelli attualmente caricati) — altrimenti ad ogni ciclo di export/reimport il prefisso `protagonist_saeedd_` nei nomi dei file di texture-dipendenza si raddoppia. Percorsi originali puliti: `git ls-files assets/models/protagonist/ | grep -v '\.glb$\|\.import$'` (14 file, mix jpg/png; nota `Wolf3D_Teeth.jpg` sorgente vs `Wolf3D_Teeth2` nome incorporato — abbina togliendo prefissi ripetuti/cifra finale).
- Dopo aver riscritto il `.glb`: `rm` degli eventuali file `protagonist_saeedd_protagonist_saeedd_*.png(.import)` residui, pulisci `.godot/imported/protagonist_saeedd.glb-*.scn*`/`.md5`, `touch` il `.glb`, poi `godot --headless --editor --quit` per rigenerare l'import pulito.
- Un FBX Mixamo scaricato può contenere sia una clip `"Take 001"` statica (T-pose vuota) sia quella vera `"mixamo_com"` nella stessa `AnimationLibrary` — non prendere `get_animation_list()[0]` alla cieca, cerca il nome che contiene `"mixamo"`.
- `AnimationPlayer.play()` seguito da `seek()` lascia il player che continua ad avanzare ad ogni frame successivo — chiama `stop(true)` subito dopo ogni `seek(t, true)` prima di leggere/campionare, altrimenti letture ripetute derivano silenziosamente.
- Backup del `.glb` in `/private/tmp/.../scratchpad/` prima di ogni modifica: un `write_to_filesystem` andato male produce un file che sembra funzionare ma non lo è, e lo scopri solo con la regressione completa, non con un controllo visivo veloce.

## Workflow generale

- Modifica `.tscn`/`.gd` a mano, niente editor GUI, tranne un `godot --headless --editor --quit` quando aggiungi un nuovo `class_name` o un nuovo asset (.glb/.png) da importare.
- Verifica ogni modifica con `scripts/_test_*.gd` + `scenes/_Test*.tscn` disposable via `godot --headless --path . scenes/_TestX.tscn --quit-after N`, poi cancella entrambi appena la verifica passa. Mai lasciare scaffolding di test committato.
- Prima dell'export: sweep veloce di tutte le scene (`--quit-after 30`), più `Home.tscn --quit-after 500` e `Main.tscn --quit-after 8000`.
- Export web: `godot --headless --path . --export-release "Web" docs/index.html`.
- Commit in italiano con `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. **Mai pushare senza una conferma esplicita ogni volta** ("Procedi"/"Pusha") — un'approvazione non vale per il commit successivo.

## Target: telefono

Il gioco è pensato per essere giocato su telefono. Uno screenshot/render da desktop (specialmente ravvicinato o ritagliato) può far sembrare un dettaglio visibile o distinguibile quando sul dispositivo reale non lo è (o viceversa, vedi regola 3 sopra sulle animazioni). Quando non è possibile un test reale sul dispositivo, dichiaralo esplicitamente invece di affermare una conclusione visiva come certa.
