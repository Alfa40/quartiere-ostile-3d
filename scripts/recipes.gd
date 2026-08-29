class_name Recipes
extends RefCounted

# 5 piatti in progressione: più costano cucinarli, più vita rigenerano
# (punti vita fissi, non una frazione della vita massima) quando vengono
# mangiati al tavolo — così un potenziamento della vita massima non rende
# automaticamente più efficaci i piatti già sbloccati: serviranno più
# piatti, o piatti più costosi, per ripristinarla tutta. Il costo usa il
# legno (la legna per il fuoco del forno), senza introdurre una risorsa
# dedicata solo a questo.
const ORDER := ["panino", "zuppa", "pasta", "arrosto", "banchetto"]

const DISHES := {
	"panino": {"label": "Panino", "cost_money": 40, "cost_material": "legno", "cost_amount": 5, "heal_amount": 15.0},
	"zuppa": {"label": "Zuppa calda", "cost_money": 90, "cost_material": "legno", "cost_amount": 10, "heal_amount": 30.0},
	"pasta": {"label": "Pasta al sugo", "cost_money": 160, "cost_material": "legno", "cost_amount": 18, "heal_amount": 50.0},
	"arrosto": {"label": "Arrosto", "cost_money": 260, "cost_material": "legno", "cost_amount": 28, "heal_amount": 75.0},
	"banchetto": {"label": "Banchetto completo", "cost_money": 400, "cost_material": "legno", "cost_amount": 45, "heal_amount": 100.0},
}
