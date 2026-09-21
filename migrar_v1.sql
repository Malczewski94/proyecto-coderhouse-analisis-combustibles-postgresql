-- Ejecutar UNA VEZ en la base que contiene el modelo anterior.
-- Preserva todas las tablas, vistas y datos anteriores bajo combustibles_v1.
-- Después ejecutar estructura.sql V2 en la misma base. No se elimina información.
BEGIN;
DO $$
BEGIN
    IF to_regnamespace('combustibles_v1') IS NOT NULL THEN
        RAISE EXCEPTION 'Ya existe combustibles_v1. No se sobrescribe el respaldo.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'combustibles' AND table_name = 'clientes'
          AND column_name = 'segmento'
    ) THEN
        RAISE EXCEPTION 'No se reconoce el modelo V1. No se modificó ningún esquema.';
    END IF;
END $$;
ALTER SCHEMA combustibles RENAME TO combustibles_v1;
COMMIT;
