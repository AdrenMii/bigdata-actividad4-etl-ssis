/* =====================================================================
   Actividad 4 - ETL | 04: Consultas sobre el data warehouse
   Cada consulta del DW se compara con la misma pregunta hecha sobre el
   modelo relacional: los resultados deben coincidir.
   ===================================================================== */

USE PersonasDW;
GO

/* ---------- 1. Personas distintas por municipio ---------- */
SELECT u.Departamento, u.Municipio, COUNT(DISTINCT f.SkPersona) AS PersonasDistintas
FROM dbo.FactObservacion f
JOIN dbo.DimUbicacion u ON u.SkUbicacion = f.SkUbicacion
GROUP BY u.Departamento, u.Municipio
ORDER BY u.Departamento, u.Municipio;

/* ---------- 2. Ingreso promedio por nivel educativo ---------- */
SELECT e.NivelEducativo, CAST(AVG(f.IngresoMensual) AS DECIMAL(18,2)) AS IngresoPromedio, SUM(f.CantidadObservaciones) AS Observaciones
FROM dbo.FactObservacion f
JOIN dbo.DimEducacion e ON e.SkEducacion = f.SkEducacion
GROUP BY e.NivelEducativo
ORDER BY IngresoPromedio DESC;

/* ---------- 3. Balance promedio por situacion laboral ---------- */
SELECT s.SituacionLaboral, CAST(AVG(f.BalanceMensual) AS DECIMAL(18,2)) AS BalancePromedio, SUM(f.CantidadObservaciones) AS Observaciones
FROM dbo.FactObservacion f
JOIN dbo.DimSituacionLaboral s ON s.SkSituacionLaboral = f.SkSituacionLaboral
GROUP BY s.SituacionLaboral
ORDER BY BalancePromedio DESC;

/* ---------- 4. Cantidad de observaciones por año y mes ---------- */
SELECT t.Anio, t.Mes, t.NombreMes, SUM(f.CantidadObservaciones) AS Observaciones
FROM dbo.FactObservacion f
JOIN dbo.DimTiempo t ON t.SkTiempo = f.SkTiempo
GROUP BY t.Anio, t.Mes, t.NombreMes
ORDER BY t.Anio, t.Mes;
GO

/* =====================================================================
   Verificacion: la misma informacion calculada desde el modelo relacional.
   Si el DW esta bien cargado, cada comparacion devuelve "Coincide".
   ===================================================================== */

-- 1. Personas por municipio
WITH dw AS (
    SELECT u.CodigoMunicipio, COUNT(DISTINCT f.SkPersona) AS n
    FROM PersonasDW.dbo.FactObservacion f JOIN PersonasDW.dbo.DimUbicacion u ON u.SkUbicacion = f.SkUbicacion
    GROUP BY u.CodigoMunicipio),
mer AS (
    SELECT m.CodigoMunicipio, COUNT(DISTINCT o.IdPersona) AS n
    FROM PersonasMER.dbo.Observaciones o JOIN PersonasMER.dbo.Municipios m ON m.IdMunicipio = o.IdMunicipio
    GROUP BY m.CodigoMunicipio)
SELECT '1. Personas por municipio' AS Consulta,
       CASE WHEN EXISTS (SELECT * FROM dw FULL JOIN mer ON mer.CodigoMunicipio = dw.CodigoMunicipio
                         WHERE dw.n IS NULL OR mer.n IS NULL OR dw.n <> mer.n)
            THEN 'NO coincide' ELSE 'Coincide' END AS Resultado
UNION ALL
-- 2. Ingreso promedio por nivel educativo
SELECT '2. Ingreso promedio por nivel educativo',
       CASE WHEN EXISTS (
            SELECT * FROM
              (SELECT e.NivelEducativo AS k, AVG(f.IngresoMensual) AS v FROM PersonasDW.dbo.FactObservacion f
               JOIN PersonasDW.dbo.DimEducacion e ON e.SkEducacion = f.SkEducacion GROUP BY e.NivelEducativo) dw
            FULL JOIN
              (SELECT n.NombreNivel AS k, AVG(o.IngresoMensual) AS v FROM PersonasMER.dbo.Observaciones o
               JOIN PersonasMER.dbo.NivelesEducativos n ON n.IdNivelEducativo = o.IdNivelEducativo GROUP BY n.NombreNivel) mer
            ON mer.k = dw.k WHERE dw.v IS NULL OR mer.v IS NULL OR dw.v <> mer.v)
            THEN 'NO coincide' ELSE 'Coincide' END
UNION ALL
-- 3. Balance promedio por situacion laboral
SELECT '3. Balance promedio por situacion laboral',
       CASE WHEN EXISTS (
            SELECT * FROM
              (SELECT s.SituacionLaboral AS k, AVG(f.BalanceMensual) AS v FROM PersonasDW.dbo.FactObservacion f
               JOIN PersonasDW.dbo.DimSituacionLaboral s ON s.SkSituacionLaboral = f.SkSituacionLaboral GROUP BY s.SituacionLaboral) dw
            FULL JOIN
              (SELECT s.NombreSituacion AS k, AVG(o.BalanceMensual) AS v FROM PersonasMER.dbo.Observaciones o
               JOIN PersonasMER.dbo.SituacionesLaborales s ON s.IdSituacionLaboral = o.IdSituacionLaboral GROUP BY s.NombreSituacion) mer
            ON mer.k = dw.k WHERE dw.v IS NULL OR mer.v IS NULL OR dw.v <> mer.v)
            THEN 'NO coincide' ELSE 'Coincide' END
UNION ALL
-- 4. Observaciones por año y mes
SELECT '4. Observaciones por año y mes',
       CASE WHEN EXISTS (
            SELECT * FROM
              (SELECT t.Anio * 100 + t.Mes AS k, SUM(f.CantidadObservaciones) AS v FROM PersonasDW.dbo.FactObservacion f
               JOIN PersonasDW.dbo.DimTiempo t ON t.SkTiempo = f.SkTiempo GROUP BY t.Anio * 100 + t.Mes) dw
            FULL JOIN
              (SELECT YEAR(o.FechaEncuesta) * 100 + MONTH(o.FechaEncuesta) AS k, COUNT(*) AS v FROM PersonasMER.dbo.Observaciones o
               GROUP BY YEAR(o.FechaEncuesta) * 100 + MONTH(o.FechaEncuesta)) mer
            ON mer.k = dw.k WHERE dw.v IS NULL OR mer.v IS NULL OR dw.v <> mer.v)
            THEN 'NO coincide' ELSE 'Coincide' END;
GO

/* =====================================================================
   Prueba de no duplicados: correr esto, ejecutar otra vez los dos
   paquetes y volver a correrlo. Los conteos deben quedar iguales.
   ===================================================================== */
SELECT 'MER Personas' AS Tabla, COUNT(*) AS Filas FROM PersonasMER.dbo.Personas
UNION ALL SELECT 'MER Observaciones', COUNT(*) FROM PersonasMER.dbo.Observaciones
UNION ALL SELECT 'DW DimTiempo', COUNT(*) FROM PersonasDW.dbo.DimTiempo
UNION ALL SELECT 'DW DimPersona', COUNT(*) FROM PersonasDW.dbo.DimPersona
UNION ALL SELECT 'DW DimUbicacion', COUNT(*) FROM PersonasDW.dbo.DimUbicacion
UNION ALL SELECT 'DW DimEducacion', COUNT(*) FROM PersonasDW.dbo.DimEducacion
UNION ALL SELECT 'DW DimSituacionLaboral', COUNT(*) FROM PersonasDW.dbo.DimSituacionLaboral
UNION ALL SELECT 'DW FactObservacion', COUNT(*) FROM PersonasDW.dbo.FactObservacion;

-- Conteos de cada ejecucion del Paquete A
SELECT * FROM PersonasMER.dbo.ResumenCargas ORDER BY IdResumen;
