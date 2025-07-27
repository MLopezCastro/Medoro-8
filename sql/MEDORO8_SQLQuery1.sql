--Nuevas vistas finales Medoro 8

SELECT * FROM ConCubo;

--1vista inicial: ConCuboDesde2020

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

---
SELECT *
FROM ConCuboDesde2020
WHERE ID_Limpio = 14620
ORDER BY Inicio_Corregido;

--
--2vista segunda: ConCuboDesde2020Secuencias

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
    Duracion_Horas AS Total_Horas,

    CASE WHEN Estado = 'Producción' THEN Duracion_Horas ELSE 0 END AS Horas_Produccion,
    CASE WHEN Estado = 'Preparación' THEN Duracion_Horas ELSE 0 END AS Horas_Preparacion,
    CASE WHEN Estado = 'Maquina Parada' THEN Duracion_Horas ELSE 0 END AS Horas_Parada,
    CASE WHEN Estado = 'Mantenimiento' THEN Duracion_Horas ELSE 0 END AS Horas_Mantenimiento,

    CantidadBuenosProducida,
    CantidadMalosProducida,

    -- ✅ Columnas nuevas pedidas
    Turno,
    Maquinista,
    Operario,
    codproducto,
    Motivo

FROM Base;


--
SELECT *
FROM VistaConCuboDesde2020Secuencias
WHERE ID_Limpio = 14620;

--
--3vista: ConCuboDesde2020SecuenciasFlag

CREATE OR ALTER VIEW ConCuboDesde2020SecuenciasFlag AS

-- Primer CTE: agrega un número de secuencia por ID_Limpio y máquina (Renglon)
WITH Base AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ID_Limpio, Renglon
            ORDER BY Inicio_Corregido ASC
        ) AS Nro_Secuencia
    FROM VistaConCuboDesde2020Secuencias
),

-- Segundo CTE: detecta inicio de bloque de preparación
PrepFlag AS (
    SELECT *,
        CASE 
            WHEN Estado = 'Preparación' AND (
                LAG(Estado) OVER (
                    PARTITION BY ID_Limpio, Renglon 
                    ORDER BY Inicio_Corregido
                ) IS DISTINCT FROM 'Preparación'
            ) THEN 1
            ELSE 0
        END AS FlagPreparacion
    FROM Base
),

-- Tercer CTE: genera la secuencia acumulativa de bloques de preparación
PrepSecuencia AS (
    SELECT *,
        SUM(FlagPreparacion) OVER (
            PARTITION BY ID_Limpio, Renglon
            ORDER BY Inicio_Corregido
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS SecuenciaPreparacion
    FROM PrepFlag
)

-- Resultado final
SELECT
    ID,
    ID_Limpio,
    Renglon,
    Estado,
    Inicio_Corregido,
    Fin_Corregido,
    Inicio_Legible_Texto,
    Fin_Legible_Texto,
    Fecha,
    Total_Horas,
    Horas_Produccion,
    Horas_Preparacion,
    Horas_Parada,
    Horas_Mantenimiento,
    CantidadBuenosProducida,
    CantidadMalosProducida,
    Turno,
    Maquinista,
    Operario,
    CodProducto,
    Motivo,
    Nro_Secuencia,
    FlagPreparacion,
    SecuenciaPreparacion

FROM PrepSecuencia;

--
SELECT *
FROM ConCuboDesde2020SecuenciasFlag
WHERE ID_Limpio = 14620;


--
SELECT * FROM TablaVinculadaUNION;

--4vista final: ConCuboFinal

CREATE OR ALTER VIEW ConCuboFinal AS
SELECT
    s.ID,
    s.ID_Limpio,
    s.Renglon,
    s.Estado,
    s.Inicio_Corregido,
    s.Fin_Corregido,
    s.Inicio_Legible_Texto,
    s.Fin_Legible_Texto,
    s.Fecha,

    -- ✅ Las 5 columnas adicionales reales
    s.Turno,
    s.Maquinista,
    s.Operario,
    s.CodProducto,
    s.Motivo,

    s.Total_Horas,
    s.Horas_Produccion,
    s.Horas_Preparacion,
    s.Horas_Parada,
    s.Horas_Mantenimiento,
    s.CantidadBuenosProducida,
    s.CantidadMalosProducida,
    s.Nro_Secuencia,
    s.FlagPreparacion,
    s.SecuenciaPreparacion,

    -- ✅ Solo esta columna viene del JOIN
    VU.saccod1

FROM ConCuboDesde2020SecuenciasFlag s
LEFT JOIN TablaVinculadaUNION VU
    ON ISNUMERIC(VU.OP) = 1
    AND TRY_CAST(VU.OP AS INT) = s.ID_Limpio
WHERE YEAR(s.Inicio_Corregido) >= 2020;


--
SELECT *
FROM ConCuboFinal
WHERE ID = '14620'
ORDER BY Inicio_Corregido;

--
SELECT
    ID,
    SUM(Horas_Preparacion) AS Total_Horas_Preparacion,
    SUM(Horas_Produccion) AS Total_Horas_Produccion,
    SUM(Horas_Parada) AS Total_Horas_Parada,
    SUM(Horas_Mantenimiento) AS Total_Horas_Mantenimiento,
    SUM(CantidadBuenosProducida) AS Total_Buenos,
    SUM(CantidadMalosProducida) AS Total_Malos
FROM ConCuboFinal
WHERE ID = '14620'
GROUP BY ID;


--FIN




