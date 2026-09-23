-- Comprueba que la conexión corresponde a capstone_project.
-- Elimina los esquemas combustibles y combustibles_v1 y sus objetos dependientes con CASCADE.
-- La transacción agrupa la comprobación de la base y la eliminación de ambos esquemas.
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
