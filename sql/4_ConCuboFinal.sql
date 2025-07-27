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

    -- ✅ Tiempos por tipo de estado y totales
    s.Total_Horas,
    s.Horas_Produccion,
    s.Horas_Preparacion,
    s.Horas_Parada,
    s.Horas_Mantenimiento,

    -- ✅ Producción buena y defectuosa
    s.CantidadBuenosProducida,
    s.CantidadMalosProducida,

    -- ✅ Secuencias y flags de preparación
    s.Nro_Secuencia,
    s.FlagPreparacion,
    s.SecuenciaPreparacion,

    -- ✅ Unión con saccod1 de la tabla vinculada
    VU.saccod1

FROM ConCuboDesde2020SecuenciasFlag s
LEFT JOIN TablaVinculadaUNION VU
    ON ISNUMERIC(VU.OP) = 1
    AND TRY_CAST(VU.OP AS INT) = s.ID_Limpio
WHERE YEAR(s.Inicio_Corregido) >= 2020;
