# Détection de Signaux d'Alerte (CSD) sur les Cryptomonnaies (SAS)

**Projet académique (Master 1 Économétrie, Statistiques)** - [Voir le rapport complet (PDF)](./Memoire_critical_slowing_down.pdf)

## 1. Objectif

Ce projet applique la théorie du **"Critical Slowing Down" (CSD)** pour identifier des signaux d'alerte précoces avant les krachs boursiers majeurs du **Bitcoin (BTC)** et de **l'Ethereum (ETH)**.

L'hypothèse est qu'à l'approche d'un point de bascule ("tipping point"), le système perd en résilience, ce qui se mesure par une augmentation de l'autocorrélation et de la variance.

## 2. Méthodologie Économétrique

1.  **Données :** Analyse des prix de clôture quotidiens sur des périodes de 500 jours avant trois krachs identifiés.
2.  **Pré-traitement :** "Détrending" des séries temporelles à l'aide d'un **lissage par noyau Gaussien** (implémenté via `PROC...`).
3.  **Calcul des Indicateurs :** Calcul des métriques de résilience (Écart-type, Coefficient AR(1), Skewness) sur des **fenêtres glissantes** (via des macros SAS ou `PROC EXPAND`).
4.  **Analyse :** Mesure de la tendance de ces indicateurs à l'aide du **Kendall's Tau**.

## 3. Résultats Clés

* L'analyse a confirmé une **augmentation statistiquement significative** des indicateurs (surtout l'écart-type et l'AR(1)) avant les trois transitions critiques.
* Une tendance positive forte a été mesurée, avec un **Kendall's Tau atteignant 0.72** pour le coefficient AR(1) lors du krach de 2017, validant l'hypothèse du CSD.

## 4. Technologie

* L'ensemble de l'analyse économétrique et statistique a été implémenté en **SAS 9.4** (potentiellement avec `SAS/STAT`, `SAS/ETS`).
