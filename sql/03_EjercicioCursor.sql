/* =====================================================================
   Actividad 4 - ETL | 03: Ejercicio de ETL mediante cursores
   Registros con SourceRowId entre 1 y 100:
     1. Se importan a una tabla de staging sin cambiar nada.
     2. Un cursor los recorre uno por uno: limpia textos, convierte los
        importes, valida y calcula el balance mensual.
     3. Los validos van a CursorAceptados y los rechazados a
        CursorRechazados con el motivo.
   Reglas: un importe desconocido NO se reemplaza por cero, y un balance
   negativo es valido (no causa rechazo).
   ===================================================================== */

USE PersonasMER;
GO

/* ---------- Requisito: permitir leer el Excel desde SQL Server ---------- */
EXEC sp_configure 'show advanced options', 1;            RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;       RECONFIGURE;
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.16.0', N'AllowInProcess', 1;
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.16.0', N'DynamicParameters', 1;
GO

/* ---------- 1. Staging: copia fiel de las filas 1 a 100 ---------- */
DROP TABLE IF EXISTS dbo.CursorStaging;

SELECT *
INTO dbo.CursorStaging
FROM OPENROWSET('Microsoft.ACE.OLEDB.16.0',
     'Excel 12.0 Xml;HDR=YES;IMEX=1;Database=C:\Users\henry\Desktop\Universidad\Big Data\Actividad 4 - ETL SSIS\datos-original\PersonasETLActividad4.xlsx',
     'SELECT * FROM [Personas$]')
WHERE TRY_CAST(SourceRowId AS INT) BETWEEN 1 AND 100;

/* ---------- Tablas de destino ---------- */
DROP TABLE IF EXISTS dbo.CursorAceptados;
DROP TABLE IF EXISTS dbo.CursorRechazados;

CREATE TABLE dbo.CursorAceptados (
    SourceRowId      INT            NOT NULL PRIMARY KEY,
    TipoDocumento    VARCHAR(5)     NOT NULL,
    NumeroDocumento  VARCHAR(20)    NOT NULL,
    PrimerNombre     NVARCHAR(50)   NOT NULL,
    PrimerApellido   NVARCHAR(50)   NOT NULL,
    IngresoOriginal  NVARCHAR(255)  NULL,     -- como venia en el Excel
    GastoOriginal    NVARCHAR(255)  NULL,
    IngresoMensual   DECIMAL(18,2)  NOT NULL, -- ya convertido
    GastoMensual     DECIMAL(18,2)  NOT NULL,
    BalanceMensual   DECIMAL(18,2)  NOT NULL
);

CREATE TABLE dbo.CursorRechazados (
    SourceRowId      INT            NOT NULL PRIMARY KEY,
    Motivo           NVARCHAR(400)  NOT NULL
);
GO

/* ---------- 2. Cursor ---------- */
SET NOCOUNT ON;

DECLARE @SourceRowId INT,
        @TipoDoc NVARCHAR(255), @NumDoc NVARCHAR(255),
        @Nombre  NVARCHAR(255), @Apellido NVARCHAR(255),
        @IngresoTxt NVARCHAR(255), @GastoTxt NVARCHAR(255);

DECLARE @Ingreso DECIMAL(18,2), @Gasto DECIMAL(18,2),
        @Limpio NVARCHAR(255), @Motivo NVARCHAR(400),
        @Procesados INT = 0, @Aceptados INT = 0, @Rechazados INT = 0;

-- DECLARACION del cursor
DECLARE cur_personas CURSOR LOCAL FAST_FORWARD FOR
    SELECT CAST(SourceRowId AS INT), DocumentType, DocumentNumber,
           FirstName, LastName, MonthlyIncome, MonthlyExpenses
    FROM dbo.CursorStaging
    ORDER BY CAST(SourceRowId AS INT);

-- APERTURA
OPEN cur_personas;

-- LECTURA del primer registro
FETCH NEXT FROM cur_personas
    INTO @SourceRowId, @TipoDoc, @NumDoc, @Nombre, @Apellido, @IngresoTxt, @GastoTxt;

-- RECORRIDO: mientras la lectura sea exitosa
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Procesados += 1;
    SET @Motivo = N'';

    -- a) Limpieza de textos: quitar espacios sobrantes y estandarizar mayusculas
    SET @TipoDoc  = UPPER(LTRIM(RTRIM(@TipoDoc)));
    SET @NumDoc   = UPPER(LTRIM(RTRIM(@NumDoc)));
    SET @Nombre   = LTRIM(RTRIM(@Nombre));
    SET @Apellido = LTRIM(RTRIM(@Apellido));
    WHILE CHARINDEX(N'  ', @Nombre)   > 0 SET @Nombre   = REPLACE(@Nombre,   N'  ', N' ');
    WHILE CHARINDEX(N'  ', @Apellido) > 0 SET @Apellido = REPLACE(@Apellido, N'  ', N' ');
    -- Primera letra mayuscula y el resto minuscula ("andrés" / "GARCÍA" -> "Andrés" / "García")
    SET @Nombre   = UPPER(LEFT(@Nombre, 1))   + LOWER(SUBSTRING(@Nombre, 2, 255));
    SET @Apellido = UPPER(LEFT(@Apellido, 1)) + LOWER(SUBSTRING(@Apellido, 2, 255));

    -- b) Campos obligatorios
    IF @NumDoc IS NULL OR @NumDoc = N'' OR @NumDoc = N'SIN-DATO'
        SET @Motivo += N'Sin numero de documento; ';
    IF @Nombre IS NULL OR @Nombre = N''
        SET @Motivo += N'Sin primer nombre; ';
    IF @Apellido IS NULL OR @Apellido = N''
        SET @Motivo += N'Sin primer apellido; ';

    -- c) Ingreso: quitar $ y espacios; el punto es separador de miles y la coma es decimal
    SET @Ingreso = NULL;
    IF @IngresoTxt IS NULL OR LTRIM(RTRIM(@IngresoTxt)) = N''
        SET @Motivo += N'Ingreso faltante; ';
    ELSE
    BEGIN
        SET @Limpio  = REPLACE(REPLACE(REPLACE(REPLACE(@IngresoTxt, N'$', N''), N' ', N''), N'.', N''), N',', N'.');
        SET @Ingreso = TRY_CONVERT(DECIMAL(18,2), @Limpio);
        IF @Ingreso IS NULL
            SET @Motivo += N'Ingreso no numerico (' + @IngresoTxt + N'); ';
        ELSE IF @Ingreso < 0
            SET @Motivo += N'Ingreso negativo (' + @IngresoTxt + N'); ';
    END

    -- d) Gasto: mismo tratamiento
    SET @Gasto = NULL;
    IF @GastoTxt IS NULL OR LTRIM(RTRIM(@GastoTxt)) = N''
        SET @Motivo += N'Gasto faltante; ';
    ELSE
    BEGIN
        SET @Limpio = REPLACE(REPLACE(REPLACE(REPLACE(@GastoTxt, N'$', N''), N' ', N''), N'.', N''), N',', N'.');
        SET @Gasto  = TRY_CONVERT(DECIMAL(18,2), @Limpio);
        IF @Gasto IS NULL
            SET @Motivo += N'Gasto no numerico (' + @GastoTxt + N'); ';
        ELSE IF @Gasto < 0
            SET @Motivo += N'Gasto negativo (' + @GastoTxt + N'); ';
    END

    -- e) Destino: aceptado (con balance) o rechazado (con motivo)
    IF @Motivo = N''
    BEGIN
        INSERT INTO dbo.CursorAceptados
            (SourceRowId, TipoDocumento, NumeroDocumento, PrimerNombre, PrimerApellido,
             IngresoOriginal, GastoOriginal, IngresoMensual, GastoMensual, BalanceMensual)
        VALUES
            (@SourceRowId, @TipoDoc, @NumDoc, @Nombre, @Apellido,
             @IngresoTxt, @GastoTxt, @Ingreso, @Gasto, @Ingreso - @Gasto);  -- balance = ingreso - gasto
        SET @Aceptados += 1;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.CursorRechazados (SourceRowId, Motivo)
        VALUES (@SourceRowId, LEFT(@Motivo, LEN(@Motivo) - 1));
        SET @Rechazados += 1;
    END

    -- Siguiente registro
    FETCH NEXT FROM cur_personas
        INTO @SourceRowId, @TipoDoc, @NumDoc, @Nombre, @Apellido, @IngresoTxt, @GastoTxt;
END

-- CIERRE y LIBERACION de memoria
CLOSE cur_personas;
DEALLOCATE cur_personas;

/* ---------- 3. Resultados ---------- */
PRINT CONCAT('Procesados: ', @Procesados, ' | Aceptados: ', @Aceptados, ' | Rechazados: ', @Rechazados);

SELECT @Procesados AS Procesados, @Aceptados AS Aceptados, @Rechazados AS Rechazados;
GO

-- Rechazados con su motivo
SELECT SourceRowId, Motivo FROM dbo.CursorRechazados ORDER BY SourceRowId;

-- Ejemplos de correccion: importes que venian con otro formato
SELECT SourceRowId, IngresoOriginal, IngresoMensual, GastoOriginal, GastoMensual, BalanceMensual
FROM dbo.CursorAceptados
WHERE IngresoOriginal LIKE N'%$%' OR GastoOriginal LIKE N'%,%'
ORDER BY SourceRowId;

-- Balances negativos (validos, no se rechazan)
SELECT COUNT(*) AS AceptadosConBalanceNegativo FROM dbo.CursorAceptados WHERE BalanceMensual < 0;
