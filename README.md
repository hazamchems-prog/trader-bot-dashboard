# Trader Bot Dashboard

Dashboard + règles de risque strictes pour MetaTrader 5.

- **Capital de référence** : 500 €
- **Perte max par trade** : 50 € (hard-capped)
- **Mode** : Paper trading (aucun ordre réel)
- **Broker cible** : MetaTrader 5

## Accès

Ouvre le fichier `dashboard/index.html` dans ton navigateur.

Ou regarde directement sur GitHub.

## Règle d'or

```
Lot size = 50 € ÷ (distance Stop Loss en pips × valeur d’1 pip pour 1 lot)
```

Toujours arrondir à la baisse. Jamais de trade sans Stop Loss défini avant l’entrée.

## Important

Il n’existe pas de trading sans risque. Les petits gains répétés (0,30 € × 100) sont mangés par les spreads et exposent à des pertes importantes en cas de news ou de slippage.

Ce bot propose des analyses et des tailles de position. **Tu valides chaque ordre manuellement.**
