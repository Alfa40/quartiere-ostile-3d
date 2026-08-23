class_name Firearms
extends RefCounted

const CATEGORY_ORDER := ["pistole", "mitragliette", "mitra", "fucile_a_pompa", "cecchino", "lanciagranate", "lanciarazzi", "armi_speciali"]

const CATEGORIES := {
	"pistole": {"label": "Pistole", "unlocked": true},
	"mitragliette": {"label": "Mitragliette", "unlocked": true},
	"mitra": {"label": "Fucili da assalto", "unlocked": true},
	"fucile_a_pompa": {"label": "Fucile a pompa", "unlocked": true},
	"cecchino": {"label": "Fucili da tiratore", "unlocked": true},
	"lanciagranate": {"label": "Lanciagranate", "unlocked": true},
	"lanciarazzi": {"label": "Lanciarazzi", "unlocked": true},
	"armi_speciali": {"label": "Armi speciali", "unlocked": true},
}

const CATEGORY_WEAPONS := {
	"pistole": ["pistola_aria_compressa", "revolver_arrugginito", "semiautomatica_9mm", "pistola_tattica", "magnum_44"],
	"mitragliette": ["mitraglietta_aria_compressa", "mitraglietta_compatta", "mitraglietta_tattica", "mitraglietta_militare", "mitraglietta_incursione"],
	"mitra": ["mitra_artigianale", "mitra_pattuglia", "mitra_pesante", "fucile_tricolpo", "mitra_assalto", "mitra_guerra"],
	"fucile_a_pompa": ["pompa_arrugginito", "pompa_corto", "pompa_tattico", "pompa_militare", "pompa_demolizione"],
	"cecchino": ["fucile_caccia", "carabina_precisione", "tiratore_scelto", "anti_materiale", "cecchino_leggendario"],
	"lanciagranate": ["lanciagranate_improvvisato", "lanciagranate_a_pompa", "lanciagranate_semiautomatico", "lanciagranate_militare", "lanciagranate_pesante"],
	"lanciarazzi": ["lanciarazzi_tubo", "lanciarazzi_improvvisato", "lanciarazzi_militare", "lanciarazzi_pesante", "lanciarazzi_avanzato"],
	"armi_speciali": ["balestra_potenziata", "lanciagranate_puzzolente", "lanciarazzi_incendiario", "lanciagranate_a_grappolo_speciale", "lanciarazzi_tossico"],
}

# fire_mode "auto": spara in automatico quando un nemico è nel cono di mira.
# fire_mode "single": spara un solo colpo al rilascio del joystick di mira.
# fire_mode "burst": spara una raffica di "burst_count" colpi al rilascio del joystick di mira.
# fire_style è solo estetico/informativo (mostrato nel menu): "manuale" (a pompa/otturatore),
# "semiautomatica", "automatica" o "raffica a N colpi".
const WEAPONS := {
	"pistola_aria_compressa": {
		"label": "Pistola ad aria compressa", "category": "pistole", "tier": 1, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 150, "price_material": "metallo", "price_amount": 8,
		"damage": 10.0, "fire_cooldown": 0.5, "magazine_size": 6, "range": 12.0, "reload_time": 1.4, "draw_time": 0.20,
		"ammo_pack_amount": 12, "ammo_pack_price_money": 20,
	},
	"revolver_arrugginito": {
		"label": "Revolver arrugginito", "category": "pistole", "tier": 2, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 260, "price_material": "metallo", "price_amount": 12,
		"damage": 22.0, "fire_cooldown": 0.65, "magazine_size": 6, "range": 14.0, "reload_time": 1.8, "draw_time": 0.18,
		"ammo_pack_amount": 10, "ammo_pack_price_money": 35,
	},
	"semiautomatica_9mm": {
		"label": "Semiautomatica 9mm", "category": "pistole", "tier": 3, "fire_mode": "auto", "fire_style": "semiautomatica",
		"price_money": 420, "price_material": "metallo", "price_amount": 18,
		"damage": 16.0, "fire_cooldown": 0.22, "magazine_size": 12, "range": 16.0, "reload_time": 1.3, "draw_time": 0.14,
		"ammo_pack_amount": 20, "ammo_pack_price_money": 40,
	},
	"pistola_tattica": {
		"label": "Pistola tattica", "category": "pistole", "tier": 4, "fire_mode": "auto", "fire_style": "semiautomatica",
		"price_money": 650, "price_material": "metallo", "price_amount": 24,
		"damage": 20.0, "fire_cooldown": 0.18, "magazine_size": 15, "range": 18.0, "reload_time": 1.1, "draw_time": 0.10,
		"ammo_pack_amount": 24, "ammo_pack_price_money": 55,
	},
	"magnum_44": {
		"label": "Magnum calibro .44", "category": "pistole", "tier": 5, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 1050, "price_material": "metallo", "price_amount": 32,
		"damage": 55.0, "fire_cooldown": 0.9, "magazine_size": 6, "range": 20.0, "reload_time": 2.0, "draw_time": 0.08,
		"ammo_pack_amount": 8, "ammo_pack_price_money": 70,
	},

	"mitraglietta_aria_compressa": {
		"label": "Mitraglietta ad aria compressa", "category": "mitragliette", "tier": 1, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 700, "price_material": "metallo", "price_amount": 30,
		"damage": 8.0, "fire_cooldown": 0.10, "magazine_size": 30, "range": 12.0, "reload_time": 1.6, "draw_time": 0.15,
		"ammo_pack_amount": 40, "ammo_pack_price_money": 45,
	},
	"mitraglietta_compatta": {
		"label": "Mitraglietta compatta", "category": "mitragliette", "tier": 2, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 950, "price_material": "metallo", "price_amount": 40,
		"damage": 10.0, "fire_cooldown": 0.09, "magazine_size": 35, "range": 13.0, "reload_time": 1.5, "draw_time": 0.13,
		"ammo_pack_amount": 45, "ammo_pack_price_money": 55,
	},
	"mitraglietta_tattica": {
		"label": "Mitraglietta tattica", "category": "mitragliette", "tier": 3, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 1300, "price_material": "metallo", "price_amount": 55,
		"damage": 12.0, "fire_cooldown": 0.08, "magazine_size": 40, "range": 14.0, "reload_time": 1.4, "draw_time": 0.11,
		"ammo_pack_amount": 50, "ammo_pack_price_money": 70,
	},
	"mitraglietta_militare": {
		"label": "Mitraglietta militare", "category": "mitragliette", "tier": 4, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 1750, "price_material": "metallo", "price_amount": 70,
		"damage": 14.0, "fire_cooldown": 0.07, "magazine_size": 45, "range": 15.0, "reload_time": 1.3, "draw_time": 0.09,
		"ammo_pack_amount": 55, "ammo_pack_price_money": 90,
	},
	"mitraglietta_incursione": {
		"label": "Mitraglietta da incursione", "category": "mitragliette", "tier": 5, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 2400, "price_material": "metallo", "price_amount": 90,
		"damage": 17.0, "fire_cooldown": 0.06, "magazine_size": 50, "range": 16.0, "reload_time": 1.2, "draw_time": 0.06,
		"ammo_pack_amount": 60, "ammo_pack_price_money": 115,
	},

	"mitra_artigianale": {
		"label": "Fucile d'assalto artigianale", "category": "mitra", "tier": 1, "fire_mode": "auto", "fire_style": "semiautomatica",
		"price_money": 800, "price_material": "metallo", "price_amount": 35,
		"damage": 14.0, "fire_cooldown": 0.14, "magazine_size": 25, "range": 15.0, "reload_time": 1.7, "draw_time": 0.18,
		"ammo_pack_amount": 35, "ammo_pack_price_money": 50,
	},
	"mitra_pattuglia": {
		"label": "Fucile d'assalto da pattuglia", "category": "mitra", "tier": 2, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 1100, "price_material": "metallo", "price_amount": 45,
		"damage": 17.0, "fire_cooldown": 0.12, "magazine_size": 28, "range": 16.0, "reload_time": 1.6, "draw_time": 0.15,
		"ammo_pack_amount": 40, "ammo_pack_price_money": 62,
	},
	"mitra_pesante": {
		"label": "Fucile d'assalto pesante", "category": "mitra", "tier": 3, "fire_mode": "auto", "fire_style": "semiautomatica",
		"price_money": 1500, "price_material": "metallo", "price_amount": 60,
		"damage": 21.0, "fire_cooldown": 0.11, "magazine_size": 32, "range": 17.0, "reload_time": 1.5, "draw_time": 0.13,
		"ammo_pack_amount": 45, "ammo_pack_price_money": 78,
	},
	"fucile_tricolpo": {
		"label": "Fucile a raffica tricolpo", "category": "mitra", "tier": 3, "fire_mode": "burst", "fire_style": "raffica a 3 colpi",
		"burst_count": 3, "burst_delay": 0.09,
		"price_money": 1650, "price_material": "metallo", "price_amount": 68,
		"damage": 18.0, "fire_cooldown": 0.6, "magazine_size": 24, "range": 17.0, "reload_time": 1.5, "draw_time": 0.12,
		"ammo_pack_amount": 45, "ammo_pack_price_money": 80,
	},
	"mitra_assalto": {
		"label": "Fucile d'assalto avanzato", "category": "mitra", "tier": 4, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 2050, "price_material": "metallo", "price_amount": 78,
		"damage": 25.0, "fire_cooldown": 0.10, "magazine_size": 35, "range": 18.0, "reload_time": 1.4, "draw_time": 0.10,
		"ammo_pack_amount": 50, "ammo_pack_price_money": 98,
	},
	"mitra_guerra": {
		"label": "Fucile d'assalto da guerra", "category": "mitra", "tier": 5, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 2800, "price_material": "metallo", "price_amount": 100,
		"damage": 30.0, "fire_cooldown": 0.09, "magazine_size": 40, "range": 19.0, "reload_time": 1.3, "draw_time": 0.07,
		"ammo_pack_amount": 55, "ammo_pack_price_money": 125,
	},

	# Il campo "damage" dei fucili a pompa è il danno DI OGNUNO dei pallini
	# sparati in un colpo solo (vedi pellet_count/pellet_base_spread_degrees
	# più sotto): da vicino i pallini colpiscono quasi tutti lo stesso
	# bersaglio (danno alto e concentrato), da lontano il cono si allarga e
	# colpisce più nemici vicini tra loro, ognuno per meno danno.
	"pompa_arrugginito": {
		"label": "Fucile a pompa arrugginito", "category": "fucile_a_pompa", "tier": 1, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 900, "price_material": "metallo", "price_amount": 38,
		"damage": 8.0, "fire_cooldown": 0.8, "magazine_size": 4, "range": 8.0, "reload_time": 2.2, "draw_time": 0.30,
		"ammo_pack_amount": 10, "ammo_pack_price_money": 40,
	},
	"pompa_corto": {
		"label": "Fucile a pompa corto", "category": "fucile_a_pompa", "tier": 2, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 1250, "price_material": "metallo", "price_amount": 50,
		"damage": 8.5, "fire_cooldown": 0.75, "magazine_size": 5, "range": 9.0, "reload_time": 2.0, "draw_time": 0.26,
		"ammo_pack_amount": 12, "ammo_pack_price_money": 52,
	},
	"pompa_tattico": {
		"label": "Fucile a pompa semiautomatico", "category": "fucile_a_pompa", "tier": 3, "fire_mode": "auto", "fire_style": "semiautomatica",
		"price_money": 1700, "price_material": "metallo", "price_amount": 65,
		"damage": 9.0, "fire_cooldown": 0.7, "magazine_size": 6, "range": 10.0, "reload_time": 1.8, "draw_time": 0.22,
		"ammo_pack_amount": 14, "ammo_pack_price_money": 66,
	},
	"pompa_militare": {
		"label": "Fucile a pompa automatico militare", "category": "fucile_a_pompa", "tier": 4, "fire_mode": "auto", "fire_style": "automatica",
		"price_money": 2300, "price_material": "metallo", "price_amount": 85,
		"damage": 10.0, "fire_cooldown": 0.65, "magazine_size": 7, "range": 11.0, "reload_time": 1.6, "draw_time": 0.18,
		"ammo_pack_amount": 16, "ammo_pack_price_money": 85,
	},
	"pompa_demolizione": {
		"label": "Fucile a pompa da demolizione", "category": "fucile_a_pompa", "tier": 5, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 3100, "price_material": "metallo", "price_amount": 110,
		"damage": 12.0, "fire_cooldown": 0.6, "magazine_size": 8, "range": 12.0, "reload_time": 1.4, "draw_time": 0.12,
		"ammo_pack_amount": 18, "ammo_pack_price_money": 110,
	},

	"fucile_caccia": {
		"label": "Fucile da caccia modificato", "category": "cecchino", "tier": 1, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 1200, "price_material": "metallo", "price_amount": 50,
		"damage": 70.0, "fire_cooldown": 1.2, "magazine_size": 4, "range": 26.0, "reload_time": 2.0, "draw_time": 0.35,
		"ammo_pack_amount": 6, "ammo_pack_price_money": 60,
	},
	"carabina_precisione": {
		"label": "Carabina semiautomatica di precisione", "category": "cecchino", "tier": 2, "fire_mode": "auto", "fire_style": "semiautomatica",
		"price_money": 1700, "price_material": "metallo", "price_amount": 65,
		"damage": 95.0, "fire_cooldown": 1.1, "magazine_size": 5, "range": 30.0, "reload_time": 1.9, "draw_time": 0.30,
		"ammo_pack_amount": 6, "ammo_pack_price_money": 78,
	},
	"tiratore_scelto": {
		"label": "Fucile da tiratore scelto", "category": "cecchino", "tier": 3, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 2400, "price_material": "metallo", "price_amount": 85,
		"damage": 130.0, "fire_cooldown": 1.0, "magazine_size": 5, "range": 34.0, "reload_time": 1.8, "draw_time": 0.25,
		"ammo_pack_amount": 6, "ammo_pack_price_money": 98,
	},
	"anti_materiale": {
		"label": "Fucile anti-materiale semiautomatico", "category": "cecchino", "tier": 4, "fire_mode": "auto", "fire_style": "semiautomatica",
		"price_money": 3300, "price_material": "metallo", "price_amount": 110,
		"damage": 180.0, "fire_cooldown": 1.4, "magazine_size": 5, "range": 38.0, "reload_time": 2.2, "draw_time": 0.20,
		"ammo_pack_amount": 5, "ammo_pack_price_money": 125,
	},
	"cecchino_leggendario": {
		"label": "Fucile da cecchino leggendario", "category": "cecchino", "tier": 5, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 4500, "price_material": "metallo", "price_amount": 150,
		"damage": 260.0, "fire_cooldown": 1.6, "magazine_size": 5, "range": 42.0, "reload_time": 2.5, "draw_time": 0.12,
		"ammo_pack_amount": 5, "ammo_pack_price_money": 160,
	},

	# Lanciagranate: il proiettile ha una traiettoria a parabola (vedi
	# scripts/lobbed_grenade.gd), rimbalza una volta a terra e poi esplode
	# (danno ad area "frag"), oppure esplode subito se colpisce un nemico.
	"lanciagranate_improvvisato": {
		"label": "Lanciagranate improvvisato", "category": "lanciagranate", "tier": 1, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 1800, "price_material": "metallo", "price_amount": 70,
		"damage": 60.0, "fire_cooldown": 1.8, "magazine_size": 1, "range": 10.0, "reload_time": 2.5, "draw_time": 0.3,
		"ammo_pack_amount": 4, "ammo_pack_price_money": 90,
		"projectile_type": "grenade_lobbed", "grenade_type": "frag", "explosion_radius": 3.5,
	},
	"lanciagranate_a_pompa": {
		"label": "Lanciagranate a pompa", "category": "lanciagranate", "tier": 2, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 2400, "price_material": "metallo", "price_amount": 90,
		"damage": 75.0, "fire_cooldown": 1.6, "magazine_size": 1, "range": 11.0, "reload_time": 2.2, "draw_time": 0.26,
		"ammo_pack_amount": 4, "ammo_pack_price_money": 105,
		"projectile_type": "grenade_lobbed", "grenade_type": "frag", "explosion_radius": 3.8,
	},
	"lanciagranate_semiautomatico": {
		"label": "Lanciagranate semiautomatico", "category": "lanciagranate", "tier": 3, "fire_mode": "single", "fire_style": "semiautomatica",
		"price_money": 3200, "price_material": "metallo", "price_amount": 115,
		"damage": 90.0, "fire_cooldown": 1.4, "magazine_size": 3, "range": 12.0, "reload_time": 2.8, "draw_time": 0.24,
		"ammo_pack_amount": 6, "ammo_pack_price_money": 125,
		"projectile_type": "grenade_lobbed", "grenade_type": "frag", "explosion_radius": 4.0,
	},
	"lanciagranate_militare": {
		"label": "Lanciagranate militare", "category": "lanciagranate", "tier": 4, "fire_mode": "single", "fire_style": "semiautomatica",
		"price_money": 4200, "price_material": "metallo", "price_amount": 145,
		"damage": 110.0, "fire_cooldown": 1.2, "magazine_size": 4, "range": 13.0, "reload_time": 3.0, "draw_time": 0.2,
		"ammo_pack_amount": 6, "ammo_pack_price_money": 150,
		"projectile_type": "grenade_lobbed", "grenade_type": "frag", "explosion_radius": 4.3,
	},
	"lanciagranate_pesante": {
		"label": "Lanciagranate pesante", "category": "lanciagranate", "tier": 5, "fire_mode": "single", "fire_style": "semiautomatica",
		"price_money": 5400, "price_material": "metallo", "price_amount": 180,
		"damage": 140.0, "fire_cooldown": 1.0, "magazine_size": 5, "range": 14.0, "reload_time": 3.2, "draw_time": 0.16,
		"ammo_pack_amount": 8, "ammo_pack_price_money": 175,
		"projectile_type": "grenade_lobbed", "grenade_type": "frag", "explosion_radius": 4.6,
	},

	# Lanciarazzi: il proiettile vola dritto come un proiettile normale
	# (niente parabola) ma esplode con danno ad area maggiore dei lanciagranate.
	"lanciarazzi_tubo": {
		"label": "Lanciarazzi di fortuna", "category": "lanciarazzi", "tier": 1, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 2200, "price_material": "metallo", "price_amount": 85,
		"damage": 100.0, "fire_cooldown": 2.2, "magazine_size": 1, "range": 18.0, "reload_time": 3.0, "draw_time": 0.35,
		"ammo_pack_amount": 3, "ammo_pack_price_money": 120,
		"projectile_type": "grenade_straight", "grenade_type": "frag", "explosion_radius": 4.5,
	},
	"lanciarazzi_improvvisato": {
		"label": "Lanciarazzi improvvisato", "category": "lanciarazzi", "tier": 2, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 2900, "price_material": "metallo", "price_amount": 105,
		"damage": 125.0, "fire_cooldown": 2.0, "magazine_size": 1, "range": 20.0, "reload_time": 2.8, "draw_time": 0.3,
		"ammo_pack_amount": 3, "ammo_pack_price_money": 135,
		"projectile_type": "grenade_straight", "grenade_type": "frag", "explosion_radius": 4.8,
	},
	"lanciarazzi_militare": {
		"label": "Lanciarazzi militare", "category": "lanciarazzi", "tier": 3, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 3800, "price_material": "metallo", "price_amount": 130,
		"damage": 155.0, "fire_cooldown": 1.8, "magazine_size": 2, "range": 22.0, "reload_time": 3.2, "draw_time": 0.26,
		"ammo_pack_amount": 4, "ammo_pack_price_money": 155,
		"projectile_type": "grenade_straight", "grenade_type": "frag", "explosion_radius": 5.2,
	},
	"lanciarazzi_pesante": {
		"label": "Lanciarazzi pesante", "category": "lanciarazzi", "tier": 4, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 4900, "price_material": "metallo", "price_amount": 160,
		"damage": 190.0, "fire_cooldown": 1.6, "magazine_size": 2, "range": 24.0, "reload_time": 3.5, "draw_time": 0.22,
		"ammo_pack_amount": 4, "ammo_pack_price_money": 180,
		"projectile_type": "grenade_straight", "grenade_type": "frag", "explosion_radius": 5.6,
	},
	"lanciarazzi_avanzato": {
		"label": "Lanciarazzi avanzato", "category": "lanciarazzi", "tier": 5, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 6200, "price_material": "metallo", "price_amount": 200,
		"damage": 230.0, "fire_cooldown": 1.4, "magazine_size": 3, "range": 26.0, "reload_time": 3.8, "draw_time": 0.18,
		"ammo_pack_amount": 5, "ammo_pack_price_money": 210,
		"projectile_type": "grenade_straight", "grenade_type": "frag", "explosion_radius": 6.0,
	},

	# Armi speciali: ognuna con munizioni particolari, riusando gli stessi
	# tipi di granata delle armi da lancio (vedi scripts/throwables.gd).
	"balestra_potenziata": {
		"label": "Balestra potenziata", "category": "armi_speciali", "tier": 1, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 1500, "price_material": "metallo", "price_amount": 60,
		"damage": 180.0, "fire_cooldown": 1.5, "magazine_size": 1, "range": 30.0, "reload_time": 2.0, "draw_time": 0.2,
		"ammo_pack_amount": 6, "ammo_pack_price_money": 95,
		"projectile_type": "bullet",
	},
	"lanciagranate_puzzolente": {
		"label": "Lanciagranate puzzolente", "category": "armi_speciali", "tier": 2, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 2600, "price_material": "metallo", "price_amount": 95,
		"damage": 0.0, "fire_cooldown": 1.6, "magazine_size": 2, "range": 12.0, "reload_time": 2.6, "draw_time": 0.26,
		"ammo_pack_amount": 4, "ammo_pack_price_money": 115,
		"projectile_type": "grenade_lobbed", "grenade_type": "puzzosa", "explosion_radius": 3.8,
		"burn_duration": 10.0, "burn_dps": 7.0,
	},
	"lanciarazzi_incendiario": {
		"label": "Lanciarazzi incendiario", "category": "armi_speciali", "tier": 3, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 3600, "price_material": "metallo", "price_amount": 125,
		"damage": 40.0, "fire_cooldown": 2.0, "magazine_size": 1, "range": 20.0, "reload_time": 3.0, "draw_time": 0.3,
		"ammo_pack_amount": 3, "ammo_pack_price_money": 145,
		"projectile_type": "grenade_straight", "grenade_type": "molotov", "explosion_radius": 4.5,
		"burn_duration": 6.0, "burn_dps": 10.0,
	},
	"lanciagranate_a_grappolo_speciale": {
		"label": "Lanciagranate a grappolo", "category": "armi_speciali", "tier": 4, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 4800, "price_material": "metallo", "price_amount": 165,
		"damage": 45.0, "fire_cooldown": 1.8, "magazine_size": 2, "range": 12.0, "reload_time": 2.8, "draw_time": 0.24,
		"ammo_pack_amount": 3, "ammo_pack_price_money": 175,
		"projectile_type": "grenade_lobbed", "grenade_type": "cluster", "explosion_radius": 3.0,
		"cluster_count": 4, "cluster_radius": 3.5,
	},
	"lanciarazzi_tossico": {
		"label": "Lanciarazzi tossico", "category": "armi_speciali", "tier": 5, "fire_mode": "single", "fire_style": "manuale",
		"price_money": 6000, "price_material": "metallo", "price_amount": 195,
		"damage": 0.0, "fire_cooldown": 2.0, "magazine_size": 1, "range": 20.0, "reload_time": 3.2, "draw_time": 0.2,
		"ammo_pack_amount": 3, "ammo_pack_price_money": 200,
		"projectile_type": "grenade_straight", "grenade_type": "puzzosa", "explosion_radius": 5.0,
		"burn_duration": 12.0, "burn_dps": 9.0,
	},
}

const UPGRADE_TRACK_ORDER := ["portata", "velocita", "danno", "estrazione", "mirino", "caricatore"]

const UPGRADE_TRACKS := {
	"portata": {"label": "Portata", "desc": "Aumenta la gittata dell'arma", "material": "legno", "per_level": 0.03},
	"velocita": {"label": "Cadenza di fuoco", "desc": "Riduce il tempo tra un colpo e l'altro", "material": "metallo", "per_level": 0.025},
	"danno": {"label": "Danno", "desc": "Aumenta il danno per colpo", "material": "metallo", "per_level": 0.06},
	"estrazione": {"label": "Velocità di estrazione", "desc": "Riduce il tempo per impugnare l'arma", "material": "cablaggi", "per_level": 0.08},
	"mirino": {"label": "Mirino", "desc": "Allunga la linea di mira e aumenta la precisione dell'arma", "material": "cablaggi", "per_level": 0.08},
	"caricatore": {"label": "Caricatore", "desc": "Aumenta di un intero caricatore la scorta massima di proiettili che puoi portare con te", "material": "metallo", "per_level": 0.0},
}

const RESERVE_CAP_MAGAZINES := 3

static func final_reserve_cap(weapon_id: String, upgrades: Dictionary) -> int:
	var mag: int = WEAPONS[weapon_id].magazine_size
	var level: int = upgrades.get("caricatore", 0)
	return mag * (RESERVE_CAP_MAGAZINES + level)

# Velocità del proiettile e dispersione di base per categoria (non per singola
# arma, per evitare di dover ripetere gli stessi due campi su 25 armi): le
# pistole sparano proiettili lenti, i cecchini velocissimi; il fucile a pompa
# ha già la sua dispersione "a pallini" e non ha bisogno di uno spread extra.
const CATEGORY_BASE_BULLET_SPEED := {
	"pistole": 22.0,
	"mitragliette": 30.0,
	"mitra": 34.0,
	"fucile_a_pompa": 26.0,
	"cecchino": 55.0,
	"lanciagranate": 0.0,  # non usata: traiettoria a parabola calcolata dalla gittata
	"lanciarazzi": 32.0,
	"armi_speciali": 36.0,
}

const CATEGORY_BASE_SPREAD := {
	"pistole": 2.5,
	"mitragliette": 4.5,
	"mitra": 3.0,
	"fucile_a_pompa": 0.0,
	"cecchino": 0.7,
	"lanciagranate": 0.0,
	"lanciarazzi": 1.0,
	"armi_speciali": 0.8,
}

static func bullet_speed(weapon_id: String) -> float:
	var def: Dictionary = WEAPONS[weapon_id]
	var base: float = CATEGORY_BASE_BULLET_SPEED.get(def.category, 40.0)
	return base + float(int(def.tier) - 1) * 3.0

static func pellet_count(weapon_id: String) -> int:
	var def: Dictionary = WEAPONS[weapon_id]
	if def.category != "fucile_a_pompa":
		return 1
	return 5 + int(def.tier)

static func pellet_base_spread_degrees(weapon_id: String) -> float:
	var def: Dictionary = WEAPONS[weapon_id]
	if def.category != "fucile_a_pompa":
		return 0.0
	return 11.0 - float(def.tier)

const UPGRADE_MAX_LEVEL := 10
const UPGRADE_BASE_MONEY := 35
const UPGRADE_BASE_MAT := 3
const UPGRADE_GROWTH := 1.3

static func upgrade_cost_money(weapon_id: String, level: int) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	return int(round(UPGRADE_BASE_MONEY * tier * pow(UPGRADE_GROWTH, level)))

static func upgrade_cost_material(weapon_id: String, level: int) -> int:
	var tier: int = WEAPONS[weapon_id].tier
	return int(round(UPGRADE_BASE_MAT * tier * pow(UPGRADE_GROWTH, level)))

static func upgrade_is_maxed(level: int) -> bool:
	return level >= UPGRADE_MAX_LEVEL

static func upgrade_effect(track_id: String, level: int) -> float:
	return level * float(UPGRADE_TRACKS[track_id].per_level)

static func final_damage(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].damage
	var level: int = upgrades.get("danno", 0)
	return base * (1.0 + upgrade_effect("danno", level))

static func final_cooldown(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].fire_cooldown
	var level: int = upgrades.get("velocita", 0)
	return max(base * (1.0 - upgrade_effect("velocita", level)), 0.05)

static func final_range(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].range
	var level: int = upgrades.get("portata", 0)
	return base * (1.0 + upgrade_effect("portata", level))

static func final_draw_time(weapon_id: String, upgrades: Dictionary) -> float:
	var base: float = WEAPONS[weapon_id].draw_time
	var level: int = upgrades.get("estrazione", 0)
	return max(base * (1.0 - upgrade_effect("estrazione", level)), 0.0)

const AIM_LINE_BASE_LENGTH := 6.0

static func final_aim_line_length(_weapon_id: String, upgrades: Dictionary) -> float:
	var level: int = upgrades.get("mirino", 0)
	return AIM_LINE_BASE_LENGTH * (1.0 + upgrade_effect("mirino", level))

static func final_spread_degrees(weapon_id: String, upgrades: Dictionary) -> float:
	var def: Dictionary = WEAPONS[weapon_id]
	var base: float = CATEGORY_BASE_SPREAD.get(def.category, 2.0)
	var level: int = upgrades.get("mirino", 0)
	return base * max(0.2, 1.0 - level * 0.08)

static func final_pellet_spread_degrees(weapon_id: String, upgrades: Dictionary) -> float:
	var base := pellet_base_spread_degrees(weapon_id)
	var level: int = upgrades.get("mirino", 0)
	return base * max(0.4, 1.0 - level * 0.06)
