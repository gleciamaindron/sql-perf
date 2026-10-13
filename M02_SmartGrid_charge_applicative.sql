/* =====================================================================
   SmartGrid — rejouer la charge applicative d'une journée type (échantillon)
   Chaque requête de l'application est exécutée plusieurs fois avec des paramètres
   différents ; pg_stat_statements les regroupe ensuite par « forme » de requête.
   Durée : 2 à 4 min avant optimisation. Le job W8 dépasse le délai de 30 s
   et sera interrompu (message d'erreur attendu) — comme en production.
   Usage : psql -U postgres -d smartgrid -f M02_SmartGrid_charge_applicative.sql
   Auteur : Nesrine AZOUZ ABDELADHIM — Mastère 2 Data & IA, NEXA 2026-2027
   ===================================================================== */
\set ON_ERROR_STOP off
\pset pager off
\o /dev/null
SELECT pg_stat_statements_reset();
SET statement_timeout = '30s';

-- W1 · Courbe de consommation d'un compteur — Application client (graphique 30 jours) (≈ 120 000 exécutions / jour)
SELECT jour, kwh
FROM mesures
WHERE compteur_id = 8150
  AND jour >= '2025-08-01'
ORDER BY jour;
SELECT jour, kwh
FROM mesures
WHERE compteur_id = 120
  AND jour >= '2025-08-01'
ORDER BY jour;
SELECT jour, kwh
FROM mesures
WHERE compteur_id = 33333
  AND jour >= '2025-08-01'
ORDER BY jour;
SELECT jour, kwh
FROM mesures
WHERE compteur_id = 2024
  AND jour >= '2025-08-01'
ORDER BY jour;
SELECT jour, kwh
FROM mesures
WHERE compteur_id = 777
  AND jour >= '2025-08-01'
ORDER BY jour;

-- W2 · Consommation mensuelle d'un client — Espace client (≈ 40 000 exécutions / jour)
SELECT date_trunc('month', m.jour) AS mois, sum(m.kwh) AS kwh
FROM compteurs AS c
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE c.client_id = 1234
GROUP BY 1
ORDER BY 1;
SELECT date_trunc('month', m.jour) AS mois, sum(m.kwh) AS kwh
FROM compteurs AS c
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE c.client_id = 50
GROUP BY 1
ORDER BY 1;
SELECT date_trunc('month', m.jour) AS mois, sum(m.kwh) AS kwh
FROM compteurs AS c
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE c.client_id = 3001
GROUP BY 1
ORDER BY 1;
SELECT date_trunc('month', m.jour) AS mois, sum(m.kwh) AS kwh
FROM compteurs AS c
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE c.client_id = 17777
GROUP BY 1
ORDER BY 1;
SELECT date_trunc('month', m.jour) AS mois, sum(m.kwh) AS kwh
FROM compteurs AS c
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE c.client_id = 9
GROUP BY 1
ORDER BY 1;

-- W3 · Alertes ouvertes critiques — Supervision (rafraîchie chaque minute) (≈ 1 440 exécutions / jour)
SELECT alerte_id, compteur_id, type_alerte, niveau, horodatage
FROM alertes
WHERE statut = 'OUVERTE'
  AND niveau >= 3
  AND horodatage::timestamptz >= '2025-09-06'
ORDER BY horodatage DESC;
SELECT alerte_id, compteur_id, type_alerte, niveau, horodatage
FROM alertes
WHERE statut = 'OUVERTE'
  AND niveau >= 3
  AND horodatage::timestamptz >= '2025-09-05'
ORDER BY horodatage DESC;
SELECT alerte_id, compteur_id, type_alerte, niveau, horodatage
FROM alertes
WHERE statut = 'OUVERTE'
  AND niveau >= 3
  AND horodatage::timestamptz >= '2025-09-07'
ORDER BY horodatage DESC;
SELECT alerte_id, compteur_id, type_alerte, niveau, horodatage
FROM alertes
WHERE statut = 'OUVERTE'
  AND niveau >= 3
  AND horodatage::timestamptz >= '2025-09-04'
ORDER BY horodatage DESC;
SELECT alerte_id, compteur_id, type_alerte, niveau, horodatage
FROM alertes
WHERE statut = 'OUVERTE'
  AND niveau >= 3
  AND horodatage::timestamptz >= '2025-09-06 12:00'
ORDER BY horodatage DESC;

-- W4 · Recherche d'un compteur par numéro de série — Application technicien (saisie libre) (≈ 5 000 exécutions / jour)
SELECT compteur_id, client_id, statut
FROM compteurs
WHERE upper(numero_serie) = upper('lky539850m08150');
SELECT compteur_id, client_id, statut
FROM compteurs
WHERE upper(numero_serie) = upper('LKY000120A00120');
SELECT compteur_id, client_id, statut
FROM compteurs
WHERE upper(numero_serie) = upper('lky123456b00001');
SELECT compteur_id, client_id, statut
FROM compteurs
WHERE upper(numero_serie) = upper('LKY539850M08150');
SELECT compteur_id, client_id, statut
FROM compteurs
WHERE upper(numero_serie) = upper('lky0');

-- W5 · Top 20 des surconsommations de la semaine — Équipe data science (modèle de détection) (≈ 24 exécutions / jour)
SELECT compteur_id, sum(kwh) AS kwh_7j
FROM mesures
WHERE jour >= '2025-09-01' AND jour < date '2025-09-01' + 7
GROUP BY compteur_id
ORDER BY kwh_7j DESC
LIMIT 20;
SELECT compteur_id, sum(kwh) AS kwh_7j
FROM mesures
WHERE jour >= '2025-08-25' AND jour < date '2025-08-25' + 7
GROUP BY compteur_id
ORDER BY kwh_7j DESC
LIMIT 20;
SELECT compteur_id, sum(kwh) AS kwh_7j
FROM mesures
WHERE jour >= '2025-06-02' AND jour < date '2025-06-02' + 7
GROUP BY compteur_id
ORDER BY kwh_7j DESC
LIMIT 20;
SELECT compteur_id, sum(kwh) AS kwh_7j
FROM mesures
WHERE jour >= '2025-01-06' AND jour < date '2025-01-06' + 7
GROUP BY compteur_id
ORDER BY kwh_7j DESC
LIMIT 20;
SELECT compteur_id, sum(kwh) AS kwh_7j
FROM mesures
WHERE jour >= '2025-03-03' AND jour < date '2025-03-03' + 7
GROUP BY compteur_id
ORDER BY kwh_7j DESC
LIMIT 20;

-- W6 · Interventions en retard — Planification des techniciens (≈ 500 exécutions / jour)
SELECT intervention_id, compteur_id, technicien_id, date_prevue
FROM interventions
WHERE date_realisation IS NULL
  AND date_prevue < '2025-09-08'
ORDER BY date_prevue;
SELECT intervention_id, compteur_id, technicien_id, date_prevue
FROM interventions
WHERE date_realisation IS NULL
  AND date_prevue < '2025-09-01'
ORDER BY date_prevue;
SELECT intervention_id, compteur_id, technicien_id, date_prevue
FROM interventions
WHERE date_realisation IS NULL
  AND date_prevue < '2025-08-25'
ORDER BY date_prevue;
SELECT intervention_id, compteur_id, technicien_id, date_prevue
FROM interventions
WHERE date_realisation IS NULL
  AND date_prevue < '2025-09-05'
ORDER BY date_prevue;
SELECT intervention_id, compteur_id, technicien_id, date_prevue
FROM interventions
WHERE date_realisation IS NULL
  AND date_prevue < '2025-09-08'
ORDER BY date_prevue;

-- W7 · Export paginé vers le data lake — Batch nocturne (pages de 1 000 lignes) (≈ 10 000 exécutions / jour)
SELECT mesure_id, compteur_id, jour, kwh
FROM mesures
ORDER BY mesure_id
LIMIT 1000 OFFSET 8000000;
SELECT mesure_id, compteur_id, jour, kwh
FROM mesures
ORDER BY mesure_id
LIMIT 1000 OFFSET 2000000;
SELECT mesure_id, compteur_id, jour, kwh
FROM mesures
ORDER BY mesure_id
LIMIT 1000 OFFSET 5000000;
SELECT mesure_id, compteur_id, jour, kwh
FROM mesures
ORDER BY mesure_id
LIMIT 1000 OFFSET 9000000;
SELECT mesure_id, compteur_id, jour, kwh
FROM mesures
ORDER BY mesure_id
LIMIT 1000 OFFSET 100000;

-- W8 · Compteurs actifs muets depuis le 5 septembre — Supervision (toutes les 15 min) (≈ 96 exécutions / jour)
SELECT c.compteur_id, c.numero_serie
FROM compteurs AS c
WHERE c.statut = 'ACTIF'
  AND c.compteur_id NOT IN (SELECT m.compteur_id
                            FROM mesures AS m
                            WHERE m.jour >= '2025-09-05');

-- W9 · Consommation d'une zone du réseau et de ses sous-zones — Pilotage réseau (≈ 200 exécutions / jour)
WITH RECURSIVE z AS (
  SELECT zone_id FROM zones_reseau WHERE zone_id = 3
  UNION ALL
  SELECT r.zone_id FROM zones_reseau AS r JOIN z ON r.parent_zone_id = z.zone_id)
SELECT sum(m.kwh) AS kwh
FROM z
JOIN compteurs AS c ON c.zone_id = z.zone_id
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE m.jour = '2025-09-07';
WITH RECURSIVE z AS (
  SELECT zone_id FROM zones_reseau WHERE zone_id = 101
  UNION ALL
  SELECT r.zone_id FROM zones_reseau AS r JOIN z ON r.parent_zone_id = z.zone_id)
SELECT sum(m.kwh) AS kwh
FROM z
JOIN compteurs AS c ON c.zone_id = z.zone_id
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE m.jour = '2025-09-06';
WITH RECURSIVE z AS (
  SELECT zone_id FROM zones_reseau WHERE zone_id = 7
  UNION ALL
  SELECT r.zone_id FROM zones_reseau AS r JOIN z ON r.parent_zone_id = z.zone_id)
SELECT sum(m.kwh) AS kwh
FROM z
JOIN compteurs AS c ON c.zone_id = z.zone_id
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE m.jour = '2025-08-15';
WITH RECURSIVE z AS (
  SELECT zone_id FROM zones_reseau WHERE zone_id = 1001
  UNION ALL
  SELECT r.zone_id FROM zones_reseau AS r JOIN z ON r.parent_zone_id = z.zone_id)
SELECT sum(m.kwh) AS kwh
FROM z
JOIN compteurs AS c ON c.zone_id = z.zone_id
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE m.jour = '2025-09-07';
WITH RECURSIVE z AS (
  SELECT zone_id FROM zones_reseau WHERE zone_id = 12
  UNION ALL
  SELECT r.zone_id FROM zones_reseau AS r JOIN z ON r.parent_zone_id = z.zone_id)
SELECT sum(m.kwh) AS kwh
FROM z
JOIN compteurs AS c ON c.zone_id = z.zone_id
JOIN mesures AS m ON m.compteur_id = c.compteur_id
WHERE m.jour = '2025-07-01';

-- W10 · Dernier relevé des compteurs d'une commune — Tableau de bord des communes (≈ 2 000 exécutions / jour)
SELECT compteur_id, jour, kwh
FROM (SELECT m.compteur_id, m.jour, m.kwh,
             ROW_NUMBER() OVER (PARTITION BY m.compteur_id ORDER BY m.jour DESC) AS rn
      FROM mesures AS m
      JOIN compteurs AS c ON c.compteur_id = m.compteur_id
      JOIN clients_energie AS ce ON ce.client_id = c.client_id
      WHERE ce.commune_id = 42) AS x
WHERE rn = 1;
SELECT compteur_id, jour, kwh
FROM (SELECT m.compteur_id, m.jour, m.kwh,
             ROW_NUMBER() OVER (PARTITION BY m.compteur_id ORDER BY m.jour DESC) AS rn
      FROM mesures AS m
      JOIN compteurs AS c ON c.compteur_id = m.compteur_id
      JOIN clients_energie AS ce ON ce.client_id = c.client_id
      WHERE ce.commune_id = 7) AS x
WHERE rn = 1;
SELECT compteur_id, jour, kwh
FROM (SELECT m.compteur_id, m.jour, m.kwh,
             ROW_NUMBER() OVER (PARTITION BY m.compteur_id ORDER BY m.jour DESC) AS rn
      FROM mesures AS m
      JOIN compteurs AS c ON c.compteur_id = m.compteur_id
      JOIN clients_energie AS ce ON ce.client_id = c.client_id
      WHERE ce.commune_id = 300) AS x
WHERE rn = 1;
SELECT compteur_id, jour, kwh
FROM (SELECT m.compteur_id, m.jour, m.kwh,
             ROW_NUMBER() OVER (PARTITION BY m.compteur_id ORDER BY m.jour DESC) AS rn
      FROM mesures AS m
      JOIN compteurs AS c ON c.compteur_id = m.compteur_id
      JOIN clients_energie AS ce ON ce.client_id = c.client_id
      WHERE ce.commune_id = 150) AS x
WHERE rn = 1;
SELECT compteur_id, jour, kwh
FROM (SELECT m.compteur_id, m.jour, m.kwh,
             ROW_NUMBER() OVER (PARTITION BY m.compteur_id ORDER BY m.jour DESC) AS rn
      FROM mesures AS m
      JOIN compteurs AS c ON c.compteur_id = m.compteur_id
      JOIN clients_energie AS ce ON ce.client_id = c.client_id
      WHERE ce.commune_id = 1) AS x
WHERE rn = 1;

\o
RESET statement_timeout;
\echo 'Charge terminée. Consultez pg_stat_statements (voir le sujet, étape 1).'
