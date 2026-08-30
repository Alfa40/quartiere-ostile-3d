extends RefCounted

# Convenzione FISSA per "fronte/retro/destra/sinistra" di QUALSIASI
# personaggio del gioco (player, nemici, NPC): sono le direzioni LOCALI del
# nodo FacingPivot di ciascun personaggio, non gli assi grezzi del modello
# 3D importato al suo interno (che possono differire da modello a modello a
# seconda di come è stato creato/orientato in Blender).
#
# FacingPivot viene ruotato ogni frame con look_at() per guardare verso la
# direzione di movimento/mira (vedi player.gd/face_direction): il suo spazio
# locale rappresenta quindi sempre "il personaggio", a prescindere da come è
# girato nel mondo in un dato istante. look_at() punta il -Z locale verso il
# bersaglio, quindi -Z è per definizione il fronte (già confermato dalla
# posizione di AttackArea/FirearmFlash, entrambi a z=-1 su FacingPivot).
#
# Usare questi nomi al posto di Vector3(x, y, z) scritti a mano per
# posizionare accessori/dettagli specifici di un lato (zaino sulla schiena,
# fondina sul fianco, spallina solo a destra, ecc.) evita il tipo di
# confusione avuta con lo zaino (dover ricordare a memoria quale segno
# corrispondeva a quale lato).
const FRONT := Vector3(0, 0, -1)
const BACK := Vector3(0, 0, 1)
const RIGHT := Vector3(1, 0, 0)
const LEFT := Vector3(-1, 0, 0)
const UP := Vector3(0, 1, 0)

# Posizione locale (relativa a FacingPivot) costruita per nome invece che a
# coordinate grezze: local_offset(forward=0.2, side=-0.3, height=1.0) mette
# un punto leggermente avanti, a sinistra, all'altezza del petto.
static func local_offset(forward: float, side: float, height: float) -> Vector3:
	return FRONT * forward + RIGHT * side + UP * height
