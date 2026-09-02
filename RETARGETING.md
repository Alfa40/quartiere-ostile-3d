# Retargeting animazioni — conoscenze di riferimento

Raccolta delle informazioni utili a risolvere i problemi di retargeting/animazione
incontrati in questo progetto (personaggio Ready Player Me + clip Mixamo, Godot 4.7).
Per le regole operative del progetto vedi `CLAUDE.md` → sezione "Pipeline attuale".

---

## 1. Perché serve il retargeting

Godot non può condividere un'animazione tra scheletri diversi usando solo i nomi
delle ossa: ogni scheletro ha **Bone Rest** (posa di riposo) diversi. Il
retargeting allinea le rest pose così l'animazione si trasferisce.
In Godot 4 il *Bone Pose* **include** il Bone Rest (diverso da Godot 3).

## 2. Dove si configura

Import dock → seleziona il file 3D → tab **Import** → **Advanced Import Settings**
→ seleziona il nodo **Skeleton3D** → pannello destro, sezione **Retarget**.

Headless / da terminale: si scrive a mano il blocco `_subresources` nel file
`<asset>.import`, sotto `[params]`. **La chiave del nodo deve avere il prefisso
`PATH:`** (es. `"PATH:Armature/Skeleton3D"`); senza, l'importer ignora tutto in
silenzio. Il `BoneMap` si referenzia come `Resource("res://...tres")`.

## 3. I tre passi

### 3a. Bone Map
- **SkeletonProfile**: il template della struttura scheletro. Per i personaggi:
  `SkeletonProfileHumanoid`.
- **BoneMap**: mappa "osso del profilo → osso reale dello scheletro".
- Con un profilo assegnato si attiva l'**auto-map** (pattern matching sui nomi):
  funziona bene solo con nomi ossa in inglese standard. I pulsanti magenta/rossi
  segnalano ossa mancanti/duplicate/gerarchia errata — sono **warning**, non
  bloccano.

### 3b. Rimozione tracce (opzionale)
| Opzione | Effetto |
|---|---|
| **Except Bone Transform** | toglie tutte le tracce non-osso |
| **Unimportant Positions** | toglie le tracce di *posizione* tranne `root_bone` e `scale_base_bone` (in humanoid: "Root" e "Hips"). **Se la disattivi, l'animazione può deformare le proporzioni del corpo in modo imprevedibile.** |
| **Unmapped Bones** | cancella le tracce delle ossa senza voce nella mappa |

Regola: **disattiva** queste opzioni se la scena ha accessori animati;
**attiva** per una `AnimationLibrary` condivisa.

### 3c. Rest Fixer — che cosa cambia ogni opzione
Riportano le rest pose verso la posa di riferimento del profilo (T-pose, faccia
verso +Z, Y-up).

| Opzione | Cosa fa |
|---|---|
| **Apply Node Transform** (`apply_node_transforms`) | corregge scheletri con transform a livello di nodo sbagliati (tipico export Blender senza "Apply Transform"). |
| **Overwrite Axis** (`overwrite_axis`) | "l'opzione più importante per condividere animazioni in Godot 4": sostituisce le rest delle ossa con quelle del profilo. **Dà risultati sbagliati se le rest originali contano** (es. clip già montata sul rig giusto). |
| **Normalize Position Tracks** (`normalize_position_tracks`) | scala il movimento in base all'altezza di `scale_base_bone` (Hips) per evitare che i piedi slittino tra modelli di taglia diversa. |
| **Fix Silhouette** (`fix_silhouette/enable`, `.../threshold`, `.../filter`, `.../base_height_adjustment`) | forza la posa del modello verso la T/A-pose di riferimento. Serve per modelli in **A-pose**, non per quelli già in **T-pose** (su questi rovina). Ginocchia/piedi piegati vengono male senza tarare `base_height_adjustment`; `filter` esclude ossa problematiche. |
| **Reset All Bone Poses After Import** (`reset_all_bone_poses_after_import`) | riazzera le pose ossa dopo l'import. |
| **Keep Global Rest On Leftovers** (`keep_global_rest_on_leftovers`) | mantiene la rest globale per le ossa non mappate. |

### Bone Renamer
- **Rename Bones** (`bone_renamer/rename_bones`): rinomina le ossa mappate **sia
  nello Skeleton3D sia nei path delle tracce di animazione**, ai nomi del profilo
  (`SkeletonProfileHumanoid`: `LeftUpperArm`, `LeftLowerArm`, `Chest`,
  `UpperChest`, `LeftUpperLeg`, `LeftLowerLeg`, `LeftToes`, …).
- **Unique Node** (`bone_renamer/unique_node/skeleton_name`): marca lo Skeleton
  come unico, così i path delle tracce sono indipendenti dalla gerarchia scena.

## 4. Trappole note

- **T-pose vs A-pose**: un modello già in T-pose **non** vuole Fix Silhouette;
  in A-pose sì, ma i piedi possono venire male.
- **Nomi non inglesi**: l'auto-map fallisce.
- **Asset Mixamo generici**: di solito servono *Overwrite Axis* + *Normalize
  Position Tracks*.
- **Se le rest originali devono restare intatte** (clip già montata sul rig
  giusto): non usare Overwrite Axis / Fix Silhouette; serve solo il rename, più
  eventuale correzione manuale (vedi sotto). Per casi complessi esiste il modulo
  **Realtime Retarget** (esterno).
- **Import FBX in Godot**: l'importer ripiega una conversione Y-up→Z-up nelle
  rest pose della sorgente. Copiare le rotazioni grezze fa "cadere"/accartocciare
  il personaggio. Correzione per-osso, chiave per chiave:
  `q' = Rrest_target(osso) · Rrest_source(osso)⁻¹ · q` (solo `Basis`).
- **`AnimationNodeAnimation` (dentro un `AnimationTree`) non eredita il
  `loop_mode` della clip**: va impostato `node.loop_mode = Animation.LOOP_LINEAR`
  sul nodo, altrimenti la clip parte una volta e si ferma sull'ultimo frame.
- **`Animation.loop_mode` non sopravvive a un re-export `.glb`** (è roba Godot,
  non glTF): usare il suffisso `_loop`/`-loop`/`-cycle` nel nome della clip, che
  l'importer riconosce e converte in `LOOP_LINEAR` togliendo il suffisso.

## 5. Cosa è configurato in questo progetto (e perché)

`assets/models/protagonist/protagonist_saeedd.glb.import`, nodo
`"PATH:Armature/Skeleton3D"`:
- `bone_map` → `protagonist_bonemap.tres`, `bone_renamer/rename_bones: true` →
  ossa in gioco ai nomi del profilo umanoide.
- `rest_fixer/apply_node_transforms: true`.
- `fix_silhouette/enable: false`, `overwrite_axis: false`,
  `reset_all_bone_poses_after_import: false` → la rest pose naturale dell'avatar
  va tenuta com'è: le clip Mixamo ora si scaricano già montate su quello
  scheletro (Upload Character su mixamo.com), e le clip già nel `.glb`
  (`attack-melee-*`, `idle`, `interact-workbench`, emote) la assumono. Il fix
  silhouette la trasformava in T-pose e rompeva tutto.

## 6. Altre risorse

- **Godot Docs → "Retargeting 3D skeletons"** (fonte di questo file):
  <https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/retargeting_3d_skeletons.html>
- **Godot Docs → "Importing 3D scenes"** — glTF vs FBX, conversione assi.
- **Godot Docs → "Using AnimationTree"** + class ref `AnimationNodeAnimation`.
- **helpx.adobe.com/mixamo** — Upload Character, marker auto-rigger, slider
  *Arm Space* / *In Place*, parametri di download (FBX, Without Skin, 30 fps).
- **GDC Vault** — "locomotion", "animation blending", "motion matching".
- Libro **"Game Anim" (Jonathan Cooper)** — fondamenti di animazione di movimento.
- Retarget in Blender: plugin **Rokoko** (gratuito), **Auto-Rig Pro**.
