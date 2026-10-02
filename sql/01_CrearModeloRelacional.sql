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
DROP TABLE IF EXISTS dbo.StgPersonas;
DROP TABLE IF EXISTS dbo.ResumenCargas;
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
    CodigoDepartamento  NVARCHAR(10)   NOT NULL CONSTRAINT UQ_Departamentos_Codigo UNIQUE,
    NombreDepartamento  NVARCHAR(60)  NOT NULL
);

CREATE TABLE dbo.Municipios (
    IdMunicipio         INT IDENTITY(1,1) CONSTRAINT PK_Municipios PRIMARY KEY,
    IdDepartamento      INT           NOT NULL
        CONSTRAINT FK_Municipios_Departamentos REFERENCES dbo.Departamentos (IdDepartamento),
    NombreMunicipio     NVARCHAR(60)  NOT NULL,
    CodigoMunicipio     NVARCHAR(10)   NOT NULL CONSTRAINT UQ_Municipios_Codigo UNIQUE
);

CREATE TABLE dbo.NivelesEducativos (
    IdNivelEducativo    INT IDENTITY(1,1) CONSTRAINT PK_NivelesEducativos PRIMARY KEY,
    NombreNivel         NVARCHAR(30)   NOT NULL CONSTRAINT UQ_NivelesEducativos_Nombre UNIQUE
);

CREATE TABLE dbo.SituacionesLaborales (
    IdSituacionLaboral  INT IDENTITY(1,1) CONSTRAINT PK_SituacionesLaborales PRIMARY KEY,
    NombreSituacion     NVARCHAR(30)   NOT NULL CONSTRAINT UQ_SituacionesLaborales_Nombre UNIQUE
);

CREATE TABLE dbo.Ocupaciones (
    IdOcupacion         INT IDENTITY(1,1) CONSTRAINT PK_Ocupaciones PRIMARY KEY,
    CodigoOcupacion     NVARCHAR(10)   NOT NULL CONSTRAINT UQ_Ocupaciones_Codigo UNIQUE,
    NombreOcupacion     NVARCHAR(60)  NOT NULL
);

/* ---------- Personas: una por tipo + numero de documento ---------- */

CREATE TABLE dbo.Personas (
    IdPersona           INT IDENTITY(1,1) CONSTRAINT PK_Personas PRIMARY KEY,
    TipoDocumento       NVARCHAR(5)    NOT NULL,
    NumeroDocumento     NVARCHAR(20)   NOT NULL,
    PrimerNombre        NVARCHAR(50)  NOT NULL,
    SegundoNombre       NVARCHAR(50)  NULL,
    PrimerApellido      NVARCHAR(50)  NOT NULL,
    SegundoApellido     NVARCHAR(50)  NULL,
    FechaNacimiento     DATE          NULL,
    Sexo                NVARCHAR(2)    NULL,
    EstadoCivil         NVARCHAR(20)   NULL,
    Correo              NVARCHAR(100)  NULL,
    Telefono            NVARCHAR(20)   NULL,
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
    Zona                NVARCHAR(10)   NULL,
    Direccion           NVARCHAR(100) NULL,
    TipoVivienda        NVARCHAR(20)   NULL,
    Estrato             TINYINT       NULL CONSTRAINT CK_Observaciones_Estrato CHECK (Estrato BETWEEN 1 AND 6),
    IdSituacionLaboral  INT           NOT NULL
        CONSTRAINT FK_Observaciones_SituacionesLaborales REFERENCES dbo.SituacionesLaborales (IdSituacionLaboral),
    IdNivelEducativo    INT           NOT NULL
        CONSTRAINT FK_Observaciones_NivelesEducativos REFERENCES dbo.NivelesEducativos (IdNivelEducativo),
    IdOcupacion         INT           NULL
        CONSTRAINT FK_Observaciones_Ocupaciones REFERENCES dbo.Ocupaciones (IdOcupacion),
    Empleador           NVARCHAR(60)  NULL,
    TipoContrato        NVARCHAR(20)   NULL,
    FechaInicioEmpleo   DATE          NULL,
    IngresoMensual      DECIMAL(18,2) NOT NULL CONSTRAINT CK_Observaciones_Ingreso CHECK (IngresoMensual >= 0),
    GastoMensual        DECIMAL(18,2) NOT NULL CONSTRAINT CK_Observaciones_Gasto   CHECK (GastoMensual >= 0),
    BalanceMensual      DECIMAL(18,2) NOT NULL,   -- puede ser negativo
    PersonasACargo      TINYINT       NULL,
    TamanoHogar         TINYINT       NULL CONSTRAINT CK_Observaciones_Hogar CHECK (TamanoHogar >= 1),
    RegimenSalud        NVARCHAR(20)   NULL,
    Discapacidad        NVARCHAR(2)    NULL,
    CanalOrigen         NVARCHAR(20)   NULL,
    FechaActualizacion  DATETIME      NULL,
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
    Campo               NVARCHAR(50)    NOT NULL,
    ValorAnterior       NVARCHAR(200)  NULL,
    ValorNuevo          NVARCHAR(200)  NULL,
    Regla               NVARCHAR(200)  NOT NULL,
    FechaProceso        DATETIME2(0)   NOT NULL CONSTRAINT DF_LogCambios_Fecha DEFAULT SYSDATETIME()
);

-- Conteos de cada ejecucion del Paquete A (los llena el paquete con Row Count)
CREATE TABLE dbo.ResumenCargas (
    IdResumen           INT IDENTITY(1,1) CONSTRAINT PK_ResumenCargas PRIMARY KEY,
    FechaProceso        DATETIME2(0)   NOT NULL CONSTRAINT DF_ResumenCargas_Fecha DEFAULT SYSDATETIME(),
    Leidos              INT            NOT NULL,
    Rechazados          INT            NOT NULL,
    EnRevision          INT            NOT NULL,
    Validos             INT            NOT NULL,
    DuplicadosDescartados INT          NOT NULL,
    Cargados            INT            NOT NULL
);

/* ---------- Staging: datos ya limpios y sin duplicados ----------
   El Paquete A la llena en el primer flujo y de aqui salen
   los catalogos, las personas y las observaciones. */

CREATE TABLE dbo.StgPersonas (
    SourceRowId         INT            NOT NULL,
    TipoDocumento       NVARCHAR(5)    NOT NULL,
    NumeroDocumento     NVARCHAR(20)   NOT NULL,
    PrimerNombre        NVARCHAR(50)   NOT NULL,
    SegundoNombre       NVARCHAR(50)   NULL,
    PrimerApellido      NVARCHAR(50)   NOT NULL,
    SegundoApellido     NVARCHAR(50)   NULL,
    FechaNacimiento     DATE           NULL,
    EdadReportada       INT            NULL,
    Sexo                NVARCHAR(2)    NULL,
    EstadoCivil         NVARCHAR(20)   NULL,
    Correo              NVARCHAR(100)  NULL,
    Telefono            NVARCHAR(20)   NULL,
    CodigoMunicipio     NVARCHAR(10)   NOT NULL,
    Zona                NVARCHAR(10)   NULL,
    Direccion           NVARCHAR(100)  NULL,
    TipoVivienda        NVARCHAR(20)   NULL,
    Estrato             TINYINT        NULL,
    NivelEducativo      NVARCHAR(30)   NOT NULL,
    SituacionLaboral    NVARCHAR(30)   NOT NULL,
    CodigoOcupacion     NVARCHAR(10)   NULL,
    NombreOcupacion     NVARCHAR(60)   NULL,
    Empleador           NVARCHAR(60)   NULL,
    TipoContrato        NVARCHAR(20)   NULL,
    FechaInicioEmpleo   DATE           NULL,
    IngresoMensual      DECIMAL(18,2)  NOT NULL,
    GastoMensual        DECIMAL(18,2)  NOT NULL,
    BalanceMensual      DECIMAL(18,2)  NOT NULL,
    PersonasACargo      TINYINT        NULL,
    TamanoHogar         TINYINT        NULL,
    RegimenSalud        NVARCHAR(20)   NULL,
    Discapacidad        NVARCHAR(2)    NULL,
    CanalOrigen         NVARCHAR(20)   NULL,
    FechaEncuesta       DATE           NOT NULL,
    FechaActualizacion  DATETIME       NULL
);
GO

/* ---------- Datos maestros de referencia (catalogo geografico interno) ----------
   Codigos internos del dataset (no son DIVIPOLA). Se toman de la combinacion
   codigo-nombre que trae el Excel. Sirven para validar la coherencia entre
   municipio y departamento y para estandarizar el nombre del municipio.
   M999 "MUNICIPIO DESCONOCIDO" no se incluye: esas filas van a revision. */

INSERT INTO dbo.Departamentos (CodigoDepartamento, NombreDepartamento) VALUES
    (N'D01', N'CUNDINAMARCA'),
    (N'D02', N'BOGOTÁ D.C.'),
    (N'D03', N'ANTIOQUIA'),
    (N'D04', N'BOYACÁ'),
    (N'D05', N'VALLE DEL CAUCA');

INSERT INTO dbo.Municipios (IdDepartamento, NombreMunicipio, CodigoMunicipio)
SELECT d.IdDepartamento, v.Nombre, v.Codigo
FROM (VALUES
    (N'M001', N'CHÍA',        N'D01'),
    (N'M002', N'CAJICÁ',      N'D01'),
    (N'M003', N'ZIPAQUIRÁ',   N'D01'),
    (N'M004', N'SOACHA',      N'D01'),
    (N'M005', N'BOGOTÁ D.C.', N'D02'),
    (N'M006', N'MEDELLÍN',    N'D03'),
    (N'M007', N'ENVIGADO',    N'D03'),
    (N'M008', N'TUNJA',       N'D04'),
    (N'M009', N'DUITAMA',     N'D04'),
    (N'M010', N'CALI',        N'D05')
) AS v (Codigo, Nombre, CodDepto)
JOIN dbo.Departamentos d ON d.CodigoDepartamento = v.CodDepto;
GO

PRINT 'Modelo relacional PersonasMER creado.';
