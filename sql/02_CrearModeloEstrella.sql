/* =====================================================================
   Actividad 4 - ETL | 02: Data warehouse en esquema estrella
   Destino del Paquete SSIS B (relacional -> DW).
   Grano de FactObservacion: una observacion por persona y fecha de encuesta.
   Tablas segun el diagrama: diagramas/Diagrama_Modelo_Estrella
   ===================================================================== */

IF DB_ID('PersonasDW') IS NULL
    CREATE DATABASE PersonasDW;
GO

USE PersonasDW;
GO

DROP TABLE IF EXISTS dbo.FactObservacion;
DROP TABLE IF EXISTS dbo.DimTiempo;
DROP TABLE IF EXISTS dbo.DimPersona;
DROP TABLE IF EXISTS dbo.DimUbicacion;
DROP TABLE IF EXISTS dbo.DimEducacion;
DROP TABLE IF EXISTS dbo.DimSituacionLaboral;
GO

/* ---------- Dimensiones (claves sustitutas Sk) ---------- */

CREATE TABLE dbo.DimTiempo (
    SkTiempo        INT IDENTITY(1,1) CONSTRAINT PK_DimTiempo PRIMARY KEY,
    Fecha           DATE         NOT NULL CONSTRAINT UQ_DimTiempo_Fecha UNIQUE,
    Anio            SMALLINT     NOT NULL,
    Mes             TINYINT      NOT NULL,
    NombreMes       NVARCHAR(15)  NOT NULL,
    Trimestre       TINYINT      NOT NULL,
    Dia             TINYINT      NOT NULL
);

CREATE TABLE dbo.DimPersona (
    SkPersona       INT IDENTITY(1,1) CONSTRAINT PK_DimPersona PRIMARY KEY,
    TipoDocumento   NVARCHAR(5)    NOT NULL,
    NumeroDocumento NVARCHAR(20)   NOT NULL,
    NombreCompleto  NVARCHAR(210) NOT NULL,
    Sexo            NVARCHAR(2)    NULL,
    EstadoCivil     NVARCHAR(20)   NULL,
    CONSTRAINT UQ_DimPersona_Documento UNIQUE (TipoDocumento, NumeroDocumento)
);

CREATE TABLE dbo.DimUbicacion (
    SkUbicacion        INT IDENTITY(1,1) CONSTRAINT PK_DimUbicacion PRIMARY KEY,
    CodigoMunicipio    NVARCHAR(10)   NOT NULL,
    Municipio          NVARCHAR(60)  NOT NULL,
    CodigoDepartamento NVARCHAR(10)   NOT NULL,
    Departamento       NVARCHAR(60)  NOT NULL,
    Zona               NVARCHAR(10)   NOT NULL,   -- 'SIN DATO' cuando no se conoce
    CONSTRAINT UQ_DimUbicacion UNIQUE (CodigoMunicipio, Zona)
);

CREATE TABLE dbo.DimEducacion (
    SkEducacion     INT IDENTITY(1,1) CONSTRAINT PK_DimEducacion PRIMARY KEY,
    NivelEducativo  NVARCHAR(30)  NOT NULL CONSTRAINT UQ_DimEducacion UNIQUE
);

CREATE TABLE dbo.DimSituacionLaboral (
    SkSituacionLaboral INT IDENTITY(1,1) CONSTRAINT PK_DimSituacionLaboral PRIMARY KEY,
    SituacionLaboral   NVARCHAR(30)  NOT NULL,
    Ocupacion          NVARCHAR(60) NOT NULL,   -- 'NO APLICA' cuando no tiene
    TipoContrato       NVARCHAR(20)  NOT NULL,
    CONSTRAINT UQ_DimSituacionLaboral UNIQUE (SituacionLaboral, Ocupacion, TipoContrato)
);

/* ---------- Tabla de hechos ---------- */

CREATE TABLE dbo.FactObservacion (
    UniqueID              INT IDENTITY(1,1) CONSTRAINT PK_FactObservacion PRIMARY KEY,
    SkTiempo              INT NOT NULL CONSTRAINT FK_Fact_DimTiempo           REFERENCES dbo.DimTiempo (SkTiempo),
    SkPersona             INT NOT NULL CONSTRAINT FK_Fact_DimPersona          REFERENCES dbo.DimPersona (SkPersona),
    SkUbicacion           INT NOT NULL CONSTRAINT FK_Fact_DimUbicacion        REFERENCES dbo.DimUbicacion (SkUbicacion),
    SkEducacion           INT NOT NULL CONSTRAINT FK_Fact_DimEducacion        REFERENCES dbo.DimEducacion (SkEducacion),
    SkSituacionLaboral    INT NOT NULL CONSTRAINT FK_Fact_DimSituacionLaboral REFERENCES dbo.DimSituacionLaboral (SkSituacionLaboral),
    IngresoMensual        DECIMAL(18,2) NOT NULL,
    GastoMensual          DECIMAL(18,2) NOT NULL,
    BalanceMensual        DECIMAL(18,2) NOT NULL,
    CantidadObservaciones INT NOT NULL CONSTRAINT DF_Fact_Cantidad DEFAULT 1,
    -- El grano: una fila por persona y fecha de encuesta (evita duplicados al re-ejecutar)
    CONSTRAINT UQ_FactObservacion_Grano UNIQUE (SkPersona, SkTiempo)
);
GO

PRINT 'Data warehouse PersonasDW creado.';
