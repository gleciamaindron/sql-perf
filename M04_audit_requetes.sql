-- Requêtes d'audit utilisées dans le corrigé (et fournies dans le sujet)
-- A. Les requêtes qui coûtent le plus (pg_stat_statements)
SELECT left(regexp_replace(query, '\s+', ' ', 'g'), 70) AS requete, calls,
       round(mean_exec_time::numeric, 1) AS moy_ms, round(total_exec_time::numeric) AS total_ms,
       shared_blks_read + shared_blks_hit AS blocs_lus
FROM pg_stat_statements
WHERE query NOT ILIKE '%pg_stat%' AND query NOT ILIKE 'SET%' AND query NOT ILIKE 'RESET%'
ORDER BY mean_exec_time DESC
LIMIT 12;
-- B. État des tables : lignes, lectures séquentielles, dernière analyse
SELECT relname, n_live_tup, n_dead_tup, seq_scan, idx_scan, last_analyze, last_autoanalyze, last_vacuum, last_autovacuum
FROM pg_stat_user_tables ORDER BY n_live_tup DESC;
-- C. Index : taille et utilisation
SELECT s.relname AS table_name, s.indexrelname AS index_name, s.idx_scan,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS taille
FROM pg_stat_user_indexes AS s ORDER BY s.idx_scan, pg_relation_size(s.indexrelid) DESC;
-- D. Index en double (mêmes colonnes, même table)
SELECT indrelid::regclass AS table_name, array_agg(indexrelid::regclass) AS index_identiques
FROM pg_index GROUP BY indrelid, indkey::text, coalesce(indexprs::text, ''), coalesce(indpred::text, '')
HAVING count(*) > 1;
-- E. Colonnes et types (repérer les dates stockées en texte, les types surdimensionnés)
SELECT table_name, column_name, data_type, character_maximum_length
FROM information_schema.columns WHERE table_schema = 'public' AND table_name NOT LIKE 'pg_stat%' ORDER BY table_name, ordinal_position;
