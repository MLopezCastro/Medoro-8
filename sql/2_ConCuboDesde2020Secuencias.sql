CREATE OR ALTER VIEW VistaConCuboDesde2020Secuencias AS
WITH Base AS (
    SELECT *,
        DATEDIFF(SECOND, Inicio_Corregido, Fin_Corregido) / 3600.0 AS Duracion_Horas
    FROM ConCuboDesde2020
)
SELECT
    ID,
    ID_Limpio,
    Renglon,
    Estado,
    Inicio_Corregido,
    Fin_Corregido,
    Inicio_Legible_Texto,
    Fin_Legible_Texto,
    CONVERT(DATE, Inicio_Corregido) AS Fecha,

    -- Duración total y por tipo de estado
    Duracion_Horas AS Total_Horas,
    CASE WHEN Estado = 'Producción' THEN Duracion_Horas ELSE 0 END AS Horas_Produccion,
    CASE WHEN Estado = 'Preparación' THEN Duracion_Horas ELSE 0 END AS Horas_Preparacion,
    CASE WHEN Estado = 'Maquina Parada' THEN Duracion_Horas ELSE 0 END AS Horas_Parada,
    CASE WHEN Estado = 'Mantenimiento' THEN Duracion_Horas ELSE 0 END AS Horas_Mantenimiento,

    -- Producción buena y mala
    CantidadBuenosProducida,
    CantidadMalosProducida,

    -- Nuevas columnas solicitadas
    Turno,
    Maquinista,
    Operario,
    codproducto,
    Motivo

FROM Base;
