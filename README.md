# Actividad 4 – Extracción, Transformación y Limpieza de Datos (Big Data)

Universidad de Cundinamarca – Big Data (701N SIS BD-A).

**Integrantes:** Henry Alejandro Ortega · José Rodolfo Hernández Suárez

## Contenido

| Carpeta / archivo | Qué hay |
|---|---|
| `datos-original/` | `PersonasETLActividad4.xlsx`, el Excel original (no se modifica; los datos son ficticios) |
| `DIAGNOSTICO.md` | Diagnóstico inicial: vacíos, formatos, inválidos y duplicados |
| `sql/` | Scripts SQL: creación del modelo relacional y del DW, ejercicio con cursor y consultas |
| `ETLPersonas/` | Proyecto SSIS de Visual Studio (`ETLPersonas.sln`) con el Paquete A (Excel → relacional) y el Paquete B (relacional → DW estrella) |
| `diagramas/` | Diagramas del modelo relacional y del modelo estrella |
| `evidencias/` | Diagramas y capturas de ejecución |
| `Informe_Actividad4_ETL.pdf` | Informe técnico de la entrega |

## Herramientas
- SQL Server 2022 Developer + SSMS
- Visual Studio 2022 + SQL Server Integration Services Projects

## Cómo ejecutarlo
1. En SSMS ejecutar `sql/01_CrearModeloRelacional.sql` y `sql/02_CrearModeloEstrella.sql`.
2. (Opcional) `sql/03_EjercicioCursor.sql` para el ejercicio con cursores.
3. Abrir `ETLPersonas/ETLPersonas.sln` en Visual Studio y ejecutar `PaqueteA_ExcelARelacional.dtsx` y luego `PaqueteB_RelacionalADW.dtsx`.
   La conexión de Excel apunta a `datos-original/PersonasETLActividad4.xlsx`; si el repositorio se clona en otra ruta, hay que ajustarla.
4. `sql/04_Consultas.sql`: las cuatro consultas y la verificación contra el modelo relacional.
