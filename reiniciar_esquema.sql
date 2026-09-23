-- Limito el reinicio a capstone_project para reducir el riesgo de borrar objetos en otra base.
-- Elimino solo los esquemas del proyecto para reconstruir la simulación sin conservar una carga anterior.
-- CASCADE retira sus dependencias; la transacción evita un reinicio parcialmente aplicado.
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
