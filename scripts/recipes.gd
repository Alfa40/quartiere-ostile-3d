class_name Recipes
extends RefCounted

# 7 piatti in progressione: più costano cucinarli, più vita rigenerano
# (punti vita fissi, non una frazione della vita massima) quando vengono
# mangiati al tavolo — così un potenziamento della vita massima non rende
# automaticamente più efficaci i piatti già sbloccati: serviranno più
# piatti, o piatti più costosi, per ripristinarla tutta. Il costo usa
# soldi + legno (la legna per il fuoco del forno) più un fungo (vedi
# mushrooms.gd) via via più raro: i due piatti più prelibati (in fondo a
# ORDER) non esistevano nella prima versione della cucina, sbloccati solo
# trovando i funghi più rari in giro per il campo.
const ORDER := ["panino", "zuppa", "pasta", "arrosto", "banchetto", "manicaretto_reale", "elisir_del_bosco"]

const DISHES := {
	"panino": {"label": "Panino", "cost_money": 40, "cost_material": "legno", "cost_amount": 5, "heal_amount": 15.0, "mushroom_id": "comune", "mushroom_amount": 1},
	"zuppa": {"label": "Zuppa calda", "cost_money": 90, "cost_material": "legno", "cost_amount": 10, "heal_amount": 30.0, "mushroom_id": "maculato", "mushroom_amount": 1},
	"pasta": {"label": "Pasta al sugo", "cost_money": 160, "cost_material": "legno", "cost_amount": 18, "heal_amount": 50.0, "mushroom_id": "dorato", "mushroom_amount": 1},
	"arrosto": {"label": "Arrosto", "cost_money": 260, "cost_material": "legno", "cost_amount": 28, "heal_amount": 75.0, "mushroom_id": "silvestre", "mushroom_amount": 1},
	"banchetto": {"label": "Banchetto completo", "cost_money": 400, "cost_material": "legno", "cost_amount": 45, "heal_amount": 100.0, "mushroom_id": "leggendario", "mushroom_amount": 1},
	"manicaretto_reale": {"label": "Manicaretto reale", "cost_money": 550, "cost_material": "legno", "cost_amount": 60, "heal_amount": 130.0, "mushroom_id": "dorato_splendente", "mushroom_amount": 1},
	"elisir_del_bosco": {"label": "Elisir del bosco", "cost_money": 750, "cost_material": "legno", "cost_amount": 80, "heal_amount": 160.0, "mushroom_id": "aurora", "mushroom_amount": 1},
}
