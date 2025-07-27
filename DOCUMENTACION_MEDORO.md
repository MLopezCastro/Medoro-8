# 📊 Proyecto Medoro – Optimización de Tiempos en Planta (2025)

**Autor**: Marcelo Fabián López  
**Empresa**: Félix A. Medoro S.A.  
**Fecha**: Julio 2025  

---

## 🧩 Introducción

El presente documento detalla la solución desarrollada para resolver los problemas históricos en el control y análisis de tiempos reales de producción, preparación y parada en planta, utilizando SQL Server y Power BI como herramientas principales.

---

## ❗ Problemas detectados

Los principales desafíos identificados fueron:

1. **Datos mal estructurados** en la base Sispro (`TablaCubo`), con miles de registros desde 2013, difíciles de consultar.
2. **Errores en la medición de tiempos de preparación** cuando varias OT compartían configuración (duplicación).
3. **Inconsistencia entre tiempos reales y programados** para los estados Verde (Producción), Rojo (Parada), Amarillo (Preparación).
4. **Dificultad para establecer secuencia de OTs**.
5. **Falta de datos clave** en las vistas originales (sacabocados, cantidades fabricadas, tipo de estado limpio).
6. **Actualizaciones manuales** y uso de Excel intermedio para cargar a Power BI.

---

## ✅ Solución implementada

Se creó un conjunto de vistas SQL estructuradas que:

- Corregieron el desfase de fechas (`-2 días`).
- Estandarizaron identificadores (`ID_Limpio`, `Renglon` como `INT`).
- Agregaron secuencias reales de producción (`Nro_Secuencia`, `SecuenciaPreparacion`).
- Clasificaron eventos por tipo (`Producción`, `Parada`, `Preparación`, `Mantenimiento`).
- Sumarizaron horas por tipo de evento y por día.
- Incorporaron cantidades fabricadas buenas y malas.
- Relacionaron los sacabocados (`saccod1`) por OT.
- Agruparon por día (`Fecha`) y con versiones legibles (`Inicio_Legible_Texto`).

---

## 🛠️ Componentes técnicos

### Vistas SQL creadas (orden recomendado de instalación)

1. **`vista_ConCubo_Medoro7_All`**  
   Corrección de fechas, tipos, claves limpias y clasificación por estado.

2. **`vista_Medoro7_Secuencia`**  
   Genera la secuencia real de OT para cada máquina.

3. **`vista_Medoro7_Tiempos`**  
   Agrega la clasificación de horas por tipo (producción, preparación, parada, mantenimiento) y agrupa por día.

4. **`vista_Medoro7_Resumen_Final`**  
   Vista final lista para Power BI, incluye:
   - Clave visible `ID_Limpio`
   - Fechas legibles (`Inicio_Legible_Texto`)
   - Horas por tipo
   - Cantidades fabricadas
   - Sacabocados
   - Secuencias
   - Flags de preparación

---

## 📈 Visualización en Power BI

Conectando Power BI directamente a `vista_Medoro7_Resumen_Final` se logra:

- Dashboards con KPIs automáticos y sin errores.
- Comparación de tiempos reales vs. programados.
- Indicadores visuales (`SemáforoPreparación`, etc.).
- Análisis por día, por OT y por máquina.
- Filtros avanzados por secuencia de producción.
- Eliminación total del uso de Excel manual.

---

## 🔒 Requisitos para implementación

- Acceso a SQL Server desde Power BI Desktop en planta.
- Crear las vistas en el orden indicado.
- Verificar nombre del servidor SQL (ejemplo de conexión: `DESKTOP-P1A8QLA\SQLEXPRESS`, base de datos `sispro`).

---

## 🚀 Resultado

- Eliminación de errores históricos de duplicación de tiempos.
- Unificación de criterios en el análisis.
- Mayor velocidad en la consulta.
- Reducción de errores humanos.
- Reporte actualizado en tiempo real con base en SQL.

---

## 📁 Archivos incluidos

- Script `.sql` con todas las vistas (ordenadas y comentadas).
- Archivo `.pbix` conectado a SQL o Excel para validación.
- Capturas de pantalla del dashboard final.

---

## 🙋‍♂️ Contacto

Cualquier duda sobre instalación o replicación del proyecto, contactar a:  
📧 Marcelo López – marcelofabianlopezcastro@gmail.com
