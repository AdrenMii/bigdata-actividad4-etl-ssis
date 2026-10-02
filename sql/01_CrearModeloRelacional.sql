/* =====================================================================
   Actividad 4 - ETL | 01: Modelo relacional (MER)
   Base de datos destino del Paquete SSIS A (Excel -> relacional).
   Tablas segun el diagrama: diagramas/Diagrama_Modelo_Relacional
   ===================================================================== */

IF DB_ID('PersonasMER') IS NULL
    CREATE DATABASE PersonasMER;
GO

USE PersonasMER;
GO

-- Se borran en orden inverso a las llaves foraneas para poder re-ejecutar el script
DROP TABLE IF EXISTS dbo.Observaciones;
DROP TABLE IF EXISTS dbo.Personas;
DROP TABLE IF EXISTS dbo.Municipios;
DROP TABLE IF EXISTS dbo.Departamentos;
DROP TABLE IF EXISTS dbo.NivelesEducativos;
DROP TABLE IF EXISTS dbo.SituacionesLaborales;
DROP TABLE IF EXISTS dbo.Ocupaciones;
DROP TABLE IF EXISTS dbo.Rechazos;
DROP TABLE IF EXISTS dbo.LogCambios;
GO

/* ---------- Catalogos ---------- */

CREATE TABLE dbo.Departamentos (
    IdDepartamento      INT IDENTITY(1,1) CONSTRAINT PK_Departamentos PRIMARY KEY,
    CodigoDepartamento  VARCHAR(10)   NOT NULL CONSTRAINT UQ_Departamentos_Codigo UNIQUE,
    NombreDepartamento  NVARCHAR(60)  NOT NULL
);

CREATE TABLE dbo.Municipios (
    IdMunicipio         INT IDENTITY(1,1) CONSTRAINT PK_Municipios PRIMARY KEY,
    IdDepartamento      INT           NOT NULL
        CONSTRAINT FK_Municipios_Departamentos REFERENCES dbo.Departamentos (IdDepartamento),
    NombreMunicipio     NVARCHAR(60)  NOT NULL,
    CodigoMunicipio     VARCHAR(10)   NOT NULL CONSTRAINT UQ_Municipios_Codigo UNIQUE
);

CREATE TABLE dbo.NivelesEducativos (
    IdNivelEducativo    INT IDENTITY(1,1) CONSTRAINT PK_NivelesEducativos PRIMARY KEY,
    NombreNivel         VARCHAR(30)   NOT NULL CONSTRAINT UQ_NivelesEducativos_Nombre UNIQUE
);

CREATE TABLE dbo.SituacionesLaborales (
    IdSituacionLaboral  INT IDENTITY(1,1) CONSTRAINT PK_SituacionesLaborales PRIMARY KEY,
    NombreSituacion     VARCHAR(30)   NOT NULL CONSTRAINT UQ_SituacionesLaborales_Nombre UNIQUE
);

CREATE TABLE dbo.Ocupaciones (
    IdOcupacion         INT IDENTITY(1,1) CONSTRAINT PK_Ocupaciones PRIMARY KEY,
    CodigoOcupacion     VARCHAR(10)   NOT NULL CONSTRAINT UQ_Ocupaciones_Codigo UNIQUE,
    NombreOcupacion     NVARCHAR(60)  NOT NULL
);

/* ---------- Personas: una por tipo + numero de documento ---------- */

CREATE TABLE dbo.Personas (
    IdPersona           INT IDENTITY(1,1) CONSTRAINT PK_Personas PRIMARY KEY,
    TipoDocumento       VARCHAR(5)    NOT NULL,
    NumeroDocumento     VARCHAR(20)   NOT NULL,
    PrimerNombre        NVARCHAR(50)  NOT NULL,
    SegundoNombre       NVARCHAR(50)  NULL,
    PrimerApellido      NVARCHAR(50)  NOT NULL,
    SegundoApellido     NVARCHAR(50)  NULL,
    FechaNacimiento     DATE          NULL,
    Sexo                VARCHAR(2)    NULL,
    EstadoCivil         VARCHAR(20)   NULL,
    Correo              VARCHAR(100)  NULL,
    Telefono            VARCHAR(20)   NULL,
    CONSTRAINT UQ_Personas_Documento UNIQUE (TipoDocumento, NumeroDocumento)
);

/* ---------- Observaciones: una por persona + fecha de encuesta ---------- */

CREATE TABLE dbo.Observaciones (
    IdObservacion       INT IDENTITY(1,1) CONSTRAINT PK_Observaciones PRIMARY KEY,
    IdPersona           INT           NOT NULL
        CONSTRAINT FK_Observaciones_Personas REFERENCES dbo.Personas (IdPersona),
    IdMunicipio         INT           NULL
        CONSTRAINT FK_Observaciones_Municipios REFERENCES dbo.Municipios (IdMunicipio),
    FechaEncuesta       DATE          NOT NULL,
    EdadReportada       TINYINT       NULL,
    Zona                VARCHAR(10)   NULL,
    Direccion           NVARCHAR(100) NULL,
    TipoVivienda        VARCHAR(20)   NULL,
    Estrato             TINYINT       NULL CONSTRAINT CK_Observaciones_Estrato CHECK (Estrato BETWEEN 1 AND 6),
    IdSituacionLaboral  INT           NOT NULL
        CONSTRAINT FK_Observaciones_SituacionesLaborales REFERENCES dbo.SituacionesLaborales (IdSituacionLaboral),
    IdNivelEducativo    INT           NOT NULL
        CONSTRAINT FK_Observaciones_NivelesEducativos REFERENCES dbo.NivelesEducativos (IdNivelEducativo),
    IdOcupacion         INT           NULL
        CONSTRAINT FK_Observaciones_Ocupaciones REFERENCES dbo.Ocupaciones (IdOcupacion),
    Empleador           NVARCHAR(60)  NULL,
    TipoContrato        VARCHAR(20)   NULL,
    FechaInicioEmpleo   DATE          NULL,
    IngresoMensual      DECIMAL(18,2) NOT NULL CONSTRAINT CK_Observaciones_Ingreso CHECK (IngresoMensual >= 0),
    GastoMensual        DECIMAL(18,2) NOT NULL CONSTRAINT CK_Observaciones_Gasto   CHECK (GastoMensual >= 0),
    BalanceMensual      DECIMAL(18,2) NOT NULL,   -- puede ser negativo
    PersonasACargo      TINYINT       NULL,
    TamanoHogar         TINYINT       NULL CONSTRAINT CK_Observaciones_Hogar CHECK (TamanoHogar >= 1),
    RegimenSalud        VARCHAR(20)   NULL,
    Discapacidad        VARCHAR(2)    NULL,
    CanalOrigen         VARCHAR(20)   NULL,
    FechaActualizacion  DATETIME2(0)  NULL,
    SourceRowId         INT           NOT NULL,
    CONSTRAINT UQ_Observaciones_PersonaFecha UNIQUE (IdPersona, FechaEncuesta)
);

/* ---------- Tablas de control ---------- */

CREATE TABLE dbo.Rechazos (
    IdRechazo           INT IDENTITY(1,1) CONSTRAINT PK_Rechazos PRIMARY KEY,
    SourceRowId         INT            NOT NULL,
    Motivo              NVARCHAR(400)  NOT NULL,
    FechaProceso        DATETIME2(0)   NOT NULL CONSTRAINT DF_Rechazos_Fecha DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.LogCambios (
    IdCambio            INT IDENTITY(1,1) CONSTRAINT PK_LogCambios PRIMARY KEY,
    SourceRowId         INT            NOT NULL,
    Campo               VARCHAR(50)    NOT NULL,
    ValorAnterior       NVARCHAR(200)  NULL,
    ValorNuevo          NVARCHAR(200)  NULL,
    Regla               NVARCHAR(200)  NOT NULL,
    FechaProceso        DATETIME2(0)   NOT NULL CONSTRAINT DF_LogCambios_Fecha DEFAULT SYSDATETIME()
);
GO

PRINT 'Modelo relacional PersonasMER creado.';
