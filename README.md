# Proyecto Medoro 8 – Vista Final ConCubo desde 2020

Este proyecto corresponde a la **octava versión del análisis de eficiencia operativa en planta**, realizado para la empresa **Félix A. Medoro S.A.**. La finalidad es mejorar el cálculo y visualización de los tiempos de producción, preparación, mantenimiento y paradas de máquina, tomando como base la tabla heredada `ConCubo`. A diferencia de versiones anteriores, esta implementación parte **desde 2020**, incluye **nuevas columnas operativas** (como turno, maquinista, operario, etc.) y conserva todas las mejoras de validación anteriores.

---

## 🧱 Estructura general

El flujo de vistas SQL es el siguiente:

1. `ConCuboDesde2020`: Limpieza base, corrección de fechas y cálculo de tiempos.
2. `VistaConCuboDesde2020Secuencias`: Refinamiento del cálculo de duración por estado.
3. `ConCuboDesde2020SecuenciasFlag`: Secuenciación de eventos por orden y máquina.
4. `ConCuboFinal`: Vista consolidada con columnas adicionales y relación con tabla externa (`TablaVinculadaUNION`).

Todas las vistas están optimizadas para conectar directamente con Power BI en modo Import.

---

## 1️⃣ Vista `ConCuboDesde2020`

### Objetivo

Realizar la limpieza inicial de los datos provenientes de `ConCubo`, corrigiendo fechas, calculando duraciones y generando claves limpias (`ID_Limpio`). Se filtran registros desde el año 2020.

### Transformaciones clave

* Conversión de `Inicio` y `Fin` a tipo `DATETIME`.
* Corrección del desfase de fechas (-2 días).
* Cálculo de `Total_Horas`.
* Segmentación del tiempo por tipo de estado (`Producción`, `Preparación`, `Maquina Parada`, `Mantenimiento`).
* Incorporación de nuevas columnas operativas: `Turno`, `Maquinista`, `Operario`, `CodProducto`, `Motivo`.

### Código completo

```sql
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
    TRY_CAST(SUBSTRING(ID, PATINDEX('%[0-9]%', ID), LEN(ID)) AS INT) AS ID_Limpio,
    Renglon,
    Estado,
    DATEADD(DAY, -2, InicioDT) AS Inicio_Corregido,
    DATEADD(DAY, -2, FinDT) AS Fin_Corregido,
    CONVERT(VARCHAR(16), DATEADD(DAY, -2, InicioDT), 120) AS Inicio_Legible_Texto,
    CONVERT(VARCHAR(16), DATEADD(DAY, -2, FinDT), 120) AS Fin_Legible_Texto,
    CONVERT(DATE, DATEADD(DAY, -2, InicioDT)) AS Fecha,
    Total_Horas,
    CASE WHEN Estado = 'Producción' THEN Total_Horas ELSE 0 END AS Horas_Produccion,
    CASE WHEN Estado = 'Preparación' THEN Total_Horas ELSE 0 END AS Horas_Preparacion,
    CASE WHEN Estado = 'Maquina Parada' THEN Total_Horas ELSE 0 END AS Horas_Parada,
    CASE WHEN Estado = 'Mantenimiento' THEN Total_Horas ELSE 0 END AS Horas_Mantenimiento,
    TRY_CAST(CantidadBuenosProducida AS FLOAT) AS CantidadBuenosProducida,
    TRY_CAST(CantidadMalosProducida AS FLOAT) AS CantidadMalosProducida,
    Turno,
    Maquinista,
    Operario,
    codproducto,
    motivo
FROM HorasCalculadas;
```

---

## 2️⃣ Vista `VistaConCuboDesde2020Secuencias`

### Objetivo

Asegurar que las duraciones de los eventos estén bien calculadas, usando `Inicio_Corregido` y `Fin_Corregido`.

### Código completo

```sql
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
    Turno,
    Maquinista,
    Operario,
    codproducto,
    motivo
FROM Base;
```

---

## 3️⃣ Vista `ConCuboDesde2020SecuenciasFlag`

### Objetivo

Detectar bloques de eventos de preparación (inicio de cada secuencia) y generar un número de secuencia por ID y máquina.

### Código completo

```sql
CREATE OR ALTER VIEW ConCuboDesde2020SecuenciasFlag AS
WITH Base AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ID_Limpio, Renglon
            ORDER BY Inicio_Corregido ASC
        ) AS Nro_Secuencia
    FROM VistaConCuboDesde2020Secuencias
),
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
PrepSecuencia AS (
    SELECT *,
        SUM(FlagPreparacion) OVER (
            PARTITION BY ID_Limpio, Renglon
            ORDER BY Inicio_Corregido
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS SecuenciaPreparacion
    FROM PrepFlag
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
    codproducto,
    motivo,
    Nro_Secuencia,
    FlagPreparacion,
    SecuenciaPreparacion
FROM PrepSecuencia;
```

---

## 4️⃣ Vista Final `ConCuboFinal`

### Objetivo

Consolidar todos los datos ya corregidos y enriquecidos con el campo `saccod1` proveniente de la tabla externa `TablaVinculadaUNION`, usando `ID_Limpio` como clave.

### Código completo

```sql
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
    s.Turno,
    s.Maquinista,
    s.Operario,
    s.codproducto,
    s.motivo,
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
    VU.saccod1
FROM ConCuboDesde2020SecuenciasFlag s
LEFT JOIN TablaVinculadaUNION VU
    ON ISNUMERIC(VU.OP) = 1
    AND TRY_CAST(VU.OP AS INT) = s.ID_Limpio
WHERE YEAR(s.Inicio_Corregido) >= 2020;
```

---

## ✅ Beneficios de esta versión

* Se conserva **toda la lógica validada en versiones previas** (como Medoro 7).
* Incluye **nuevas columnas operativas** para mejorar los filtros de análisis.
* Soluciona definitivamente los problemas de fechas, duplicación de preparación y cálculos inconsistentes.
* Puede ser conectada de forma estable a Power BI.

---



