CREATE OR ALTER VIEW ConCuboDesde2020 AS
WITH DatosParseados AS (
    SELECT *,
        TRY_CAST(Inicio AS DATETIME) AS InicioDT,
        TRY_CAST(Fin AS DATETIME) AS FinDT
    FROM ConCubo
    WHERE 
        TRY_CAST(Inicio AS DATETIME) >= '2020-01-01' AND
        ISNUMERIC(SUBSTRING(ID, PATINDEX('%[0-9]%', ID), LEN(ID))) = 1
),
HorasCalculadas AS (
    SELECT *,
        DATEDIFF(SECOND, InicioDT, FinDT) / 3600.0 AS Total_Horas
    FROM DatosParseados
)
SELECT
    ID,

    -- Clave limpia
    TRY_CAST(SUBSTRING(ID, PATINDEX('%[0-9]%', ID), LEN(ID)) AS INT) AS ID_Limpio,

    Renglon,
    Estado,

    -- Fechas corregidas (resta de 2 días)
    DATEADD(DAY, -2, InicioDT) AS Inicio_Corregido,
    DATEADD(DAY, -2, FinDT) AS Fin_Corregido,

    -- Fechas legibles como texto
    CONVERT(VARCHAR(16), DATEADD(DAY, -2, InicioDT), 120) AS Inicio_Legible_Texto,
    CONVERT(VARCHAR(16), DATEADD(DAY, -2, FinDT), 120) AS Fin_Legible_Texto,

    -- Fecha agrupada (solo día)
    CONVERT(DATE, DATEADD(DAY, -2, InicioDT)) AS Fecha,

    -- Duración total y por tipo de estado
    Total_Horas,
    CASE WHEN Estado = 'Producción' THEN Total_Horas ELSE 0 END AS Horas_Produccion,
    CASE WHEN Estado = 'Preparación' THEN Total_Horas ELSE 0 END AS Horas_Preparacion,
    CASE WHEN Estado = 'Maquina Parada' THEN Total_Horas ELSE 0 END AS Horas_Parada,
    CASE WHEN Estado = 'Mantenimiento' THEN Total_Horas ELSE 0 END AS Horas_Mantenimiento,

    -- Producción buena y mala
    TRY_CAST(CantidadBuenosProducida AS FLOAT) AS CantidadBuenosProducida,
    TRY_CAST(CantidadMalosProducida AS FLOAT) AS CantidadMalosProducida,

    -- Nuevas columnas solicitadas
    Turno,
    Maquinista,
    Operario,
    codproducto,
    motivo

FROM HorasCalculadas;
