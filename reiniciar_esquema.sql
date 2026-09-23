-- Reinicio autorizado del proyecto: carga desde cero, sin esquema de respaldo.
-- Ejecutar en pgAdmin conectado a capstone_project ANTES de estructura.sql.
-- Elimina todos los objetos de los dos esquemas indicados mediante CASCADE.
-- No elimina la base ni otros esquemas. Después ejecutar estructura.sql completo.
BEGIN;
DO $$
BEGIN
    IF current_database() <> 'capstone_project' THEN
        RAISE EXCEPTION 'Reinicio cancelado: conectarse a capstone_project. Base actual: %', current_database();
    END IF;
END
$$;
DROP SCHEMA IF EXISTS combustibles CASCADE;
DROP SCHEMA IF EXISTS combustibles_v1 CASCADE;
COMMIT;
