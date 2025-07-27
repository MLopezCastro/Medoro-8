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
