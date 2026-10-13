/* =====================================================================
   SmartGrid — test du chargement quotidien (≈ 39 000 relevés)
   Mesure le coût des index sur les écritures. La transaction est annulée
   (ROLLBACK) : la base n'est pas modifiée. Lancer 3 fois, garder la médiane.
   Auteur : Nesrine AZOUZ ABDELADHIM — Mastère 2 Data & IA, NEXA 2026-2027
   ===================================================================== */
\timing on
BEGIN;
INSERT INTO mesures (mesure_id, compteur_id, jour, kwh, qualite, source, recu_le)
SELECT 20000000 + c.compteur_id, c.compteur_id, date '2025-09-08',
       round((5 + (c.compteur_id % 17) * 0.4)::numeric, 3), 'MESURE', 'TELERELEVE',
       timestamptz '2025-09-09 03:00'
FROM compteurs AS c
WHERE c.statut <> 'RESILIE';
ROLLBACK;
