-- Exécuté automatiquement au premier démarrage du conteneur :
-- pg_stat_statements dans la base postgres et dans template1 (hérité par toute nouvelle base)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
\c template1
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
