/* =====================================================================
   SmartGrid — base de la mise en situation professionnelle (évaluation)
   Module « Optimisation SQL et performance des requêtes »
   Mastère 2 Data & IA — NEXA Digital School 2026-2027
   Auteur : Nesrine AZOUZ ABDELADHIM
   PostgreSQL 16 — durée : 3 à 6 min (≈ 1,5 Go)
   Usage : createdb -U postgres smartgrid
           psql -U postgres -d smartgrid -f M01_SmartGrid_creation_donnees.sql
   La base reproduit l'état « tel que livré » par l'équipe précédente :
   NE PAS la corriger avant d'avoir mesuré la situation de départ.
   ===================================================================== */
SET client_min_messages = warning;
SET TimeZone = 'Europe/Paris';
DO $$ BEGIN EXECUTE format('ALTER DATABASE %I SET TimeZone = %L', current_database(), 'Europe/Paris'); END $$;
\timing on
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

DROP TABLE IF EXISTS interventions, techniciens, alertes, mesures, compteurs, clients_energie, zones_reseau, communes CASCADE;

-- ---------------------------------------------------------------------
-- 1. Référentiels
-- ---------------------------------------------------------------------
CREATE TABLE communes (
    commune_id    integer PRIMARY KEY,
    nom           text    NOT NULL,
    departement   char(3) NOT NULL,
    region        text    NOT NULL
);

CREATE TABLE zones_reseau (               -- poste source > départ HTA > poste de distribution
    zone_id         integer PRIMARY KEY,
    parent_zone_id  integer REFERENCES zones_reseau (zone_id),
    nom             text    NOT NULL,
    niveau          smallint NOT NULL
);

CREATE TABLE clients_energie (
    client_id      integer PRIMARY KEY,
    type_client    text    NOT NULL,
    commune_id     integer NOT NULL REFERENCES communes (commune_id),
    offre          text    NOT NULL,
    puissance_kva  smallint NOT NULL,
    date_contrat   date    NOT NULL,
    email          text    NOT NULL
);

CREATE TABLE compteurs (
    compteur_id    integer PRIMARY KEY,
    numero_serie   varchar(20) NOT NULL UNIQUE,
    client_id      integer NOT NULL REFERENCES clients_energie (client_id),
    zone_id        integer NOT NULL REFERENCES zones_reseau (zone_id),
    modele         text    NOT NULL,
    date_pose      date    NOT NULL,
    statut         text    NOT NULL
);

CREATE TABLE mesures (                    -- un relevé journalier par compteur
    mesure_id    bigint  PRIMARY KEY,
    compteur_id  integer NOT NULL REFERENCES compteurs (compteur_id),
    jour         date    NOT NULL,
    kwh          numeric(9,3) NOT NULL,
    qualite      varchar(255) NOT NULL,   -- 'MESURE', 'ESTIMEE', 'CORRIGEE'
    source       varchar(255) NOT NULL,   -- 'TELERELEVE', 'MANUEL'
    recu_le      timestamptz NOT NULL
) WITH (autovacuum_enabled = false);      -- réglage hérité de l'ancien ETL

CREATE TABLE alertes (
    alerte_id    bigint  PRIMARY KEY,
    compteur_id  integer NOT NULL REFERENCES compteurs (compteur_id),
    type_alerte  text    NOT NULL,
    niveau       smallint NOT NULL,
    horodatage   text    NOT NULL,        -- stocké en texte ISO 8601 par l'ancien outil
    statut       text    NOT NULL,
    details      jsonb
);

CREATE TABLE techniciens (
    technicien_id  integer PRIMARY KEY,
    nom            text    NOT NULL,
    secteur        text    NOT NULL
);

CREATE TABLE interventions (
    intervention_id   bigint  PRIMARY KEY,
    compteur_id       integer NOT NULL REFERENCES compteurs (compteur_id),
    technicien_id     integer NOT NULL REFERENCES techniciens (technicien_id),
    type_intervention text    NOT NULL,
    date_prevue       date    NOT NULL,
    date_realisation  date,
    cout              numeric(8,2)
);

-- ---------------------------------------------------------------------
-- 2. Données
-- ---------------------------------------------------------------------
SELECT setseed(0.21);
INSERT INTO communes
SELECT i, 'Commune-' || i, lpad((1 + i % 95)::text, 2, '0'),
       (ARRAY['Île-de-France', 'Auvergne-Rhône-Alpes', 'Occitanie', 'Nouvelle-Aquitaine', 'Grand Est', 'Hauts-de-France', 'Bretagne', 'Normandie'])[1 + i % 8]
FROM generate_series(1, 400) AS i;

INSERT INTO zones_reseau SELECT i, NULL, 'Poste source ' || i, 1 FROM generate_series(1, 20) AS i;
INSERT INTO zones_reseau SELECT 100 + i, 1 + (i - 1) / 5, 'Départ HTA ' || i, 2 FROM generate_series(1, 100) AS i;
INSERT INTO zones_reseau SELECT 1000 + i, 100 + 1 + (i - 1) / 10, 'Poste HTA/BT ' || i, 3 FROM generate_series(1, 1000) AS i;

INSERT INTO clients_energie
SELECT i,
       CASE WHEN r < 0.85 THEN 'particulier' WHEN r < 0.98 THEN 'professionnel' ELSE 'collectivite' END,
       1 + (i * 37) % 400,
       (ARRAY['BASE', 'HC_HP', 'HC_HP', 'TEMPO'])[1 + i % 4],
       (ARRAY[6, 6, 9, 9, 12, 36])[1 + i % 6],
       date '2010-01-01' + (random() * 5500)::int,
       'client' || i || '@exemple.fr'
FROM (SELECT i, random() AS r FROM generate_series(1, 38000) AS i) AS g;

INSERT INTO compteurs
SELECT i,
       'LKY' || lpad((i * 7919 % 1000000)::text, 6, '0') || chr(65 + i % 26) || lpad(i::text, 5, '0'),
       1 + (i - 1) % 38000,
       1001 + (i * 13) % 1000,
       (ARRAY['Linky G1', 'Linky G3', 'Linky G3'])[1 + i % 3],
       date '2016-01-01' + (i * 17) % 2900,
       CASE WHEN i % 97 = 0 THEN 'DEFAUT' WHEN i % 61 = 0 THEN 'RESILIE' ELSE 'ACTIF' END
FROM generate_series(1, 40000) AS i;

-- 250 relevés journaliers par compteur (1er janvier → 7 septembre 2025), arrivés jour par jour
SELECT setseed(0.42);
INSERT INTO mesures
SELECT row_number() OVER (ORDER BY d.jour, c.compteur_id),
       c.compteur_id, d.jour,
       round((CASE WHEN c.compteur_id % 50 = 0 THEN 40 ELSE 6 END
              * (1 + 0.6 * cos(2 * pi() * (extract(doy FROM d.jour) - 15) / 365.0))
              * (0.6 + random() * 0.8))::numeric, 3),
       CASE WHEN random() < 0.94 THEN 'MESURE' WHEN random() < 0.8 THEN 'ESTIMEE' ELSE 'CORRIGEE' END,
       CASE WHEN random() < 0.97 THEN 'TELERELEVE' ELSE 'MANUEL' END,
       d.jour + interval '1 day 2 hours' + random() * interval '3 hours'
FROM generate_series(date '2025-01-01', date '2025-09-07', interval '1 day') AS d(jour)
CROSS JOIN compteurs AS c
WHERE c.statut <> 'RESILIE' AND NOT (c.compteur_id % 211 = 0 AND d.jour > date '2025-09-03');  -- compteurs muets

SELECT setseed(0.63);
INSERT INTO alertes
SELECT i, 1 + floor(power(random(), 1.5) * 40000)::int,
       (ARRAY['SURCONSOMMATION', 'COUPURE', 'TENSION', 'FRAUDE_SUSPECTEE', 'COMMUNICATION'])[1 + floor(random() * 5)::int],
       1 + floor(random() * 4)::int,
       to_char(timestamptz '2025-01-01' + (i / 300000.0) * interval '250 days', 'YYYY-MM-DD"T"HH24:MI:SS'),
       CASE WHEN i > 296000 AND random() < 0.7 THEN 'OUVERTE' WHEN random() < 0.5 THEN 'TRAITEE' ELSE 'FERMEE' END,
       jsonb_build_object('valeur', round((random() * 100)::numeric, 1), 'canal', 'CPL')
FROM generate_series(1, 300000) AS i;

INSERT INTO techniciens
SELECT i, 'Technicien ' || i, (ARRAY['Nord', 'Sud', 'Est', 'Ouest', 'Centre'])[1 + i % 5] FROM generate_series(1, 200) AS i;

SELECT setseed(0.84);
INSERT INTO interventions
SELECT i, 1 + floor(random() * 40000)::int, 1 + floor(random() * 200)::int,
       (ARRAY['DEPANNAGE', 'RELEVE', 'REMPLACEMENT', 'RESILIATION'])[1 + floor(random() * 4)::int],
       dp,
       CASE WHEN dp < date '2025-08-20' OR random() < 0.4 THEN dp + floor(random() * 5)::int END,
       round((50 + random() * 400)::numeric, 2)
FROM (SELECT i, date '2024-01-01' + (i * 615 / 80000) AS dp FROM generate_series(1, 80000) AS i) AS g;

-- ---------------------------------------------------------------------
-- 3. Index créés par l'équipe précédente
-- ---------------------------------------------------------------------
CREATE INDEX idx_mesures_qualite     ON mesures (qualite);
CREATE INDEX idx_mesures_source      ON mesures (source);
CREATE INDEX idx_mesures_jour        ON mesures (jour);
CREATE INDEX idx_compteurs_client    ON compteurs (client_id);
CREATE INDEX idx_compteurs_client_bis ON compteurs (client_id);
CREATE INDEX idx_interventions_cout  ON interventions (cout);
CREATE INDEX idx_alertes_type        ON alertes (type_alerte);

-- Statistiques : seules les petites tables ont été analysées par l'ancien ETL
ANALYZE communes; ANALYZE zones_reseau; ANALYZE clients_energie; ANALYZE compteurs; ANALYZE techniciens;

SELECT 'communes' AS table_name, count(*) AS nb_lignes FROM communes
UNION ALL SELECT 'zones_reseau', count(*) FROM zones_reseau
UNION ALL SELECT 'clients_energie', count(*) FROM clients_energie
UNION ALL SELECT 'compteurs', count(*) FROM compteurs
UNION ALL SELECT 'mesures', count(*) FROM mesures
UNION ALL SELECT 'alertes', count(*) FROM alertes
UNION ALL SELECT 'techniciens', count(*) FROM techniciens
UNION ALL SELECT 'interventions', count(*) FROM interventions;
SELECT pg_size_pretty(pg_database_size(current_database())) AS taille_base;
