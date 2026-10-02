# Diagnóstico inicial – PersonasETLActividad4.xlsx

Hoja `Personas`: 1.000 registros, 37 columnas (todas llegan como texto). Revisado el 1-oct-2026, sin modificar el Excel.

## Problemas encontrados por columna

| Columna | Problema | Cantidad | Tratamiento propuesto |
|---|---|---|---|
| DocumentType | minúsculas (`cc`, `pa`, `ce`) | 23 | Pasar a mayúsculas (corrección) |
| DocumentNumber | vacío | 45 | Rechazo: sin documento no hay clave de persona |
| DocumentNumber | `SIN-DATO` | 23 | Rechazo (mismo motivo) |
| FirstName | vacío | 22 | Rechazo: falta primer nombre |
| FirstName | en minúsculas | 23 | Primera letra en mayúscula |
| LastName | en MAYÚSCULAS | 23 | Primera letra en mayúscula |
| SecondLastName / MiddleName | vacíos | 77 / 301 | Se dejan NULL (son opcionales) |
| BirthDate | formato `dd/mm/aaaa` | 68 | Convertir (día/mes/año, según el enunciado) |
| BirthDate | fechas imposibles (`31/02/1990`) o futuras (`2035-01-01`) | por medir | Rechazo o revisión: fecha inválida |
| ReportedAge | no coincide con nacimiento + fecha de encuesta | por medir | Marcar como inconsistencia (a revisión) |
| Sex | valor `Z` (fuera de M/F/ND) | 22 | Pasar a ND o rechazar (decidir) |
| MaritalStatus | minúsculas | 44 | Pasar a mayúsculas |
| Email | sin `@` | 22 | Dejar NULL y marcar email inválido (no se rechaza la persona) |
| Phone | con guion `000-0000004` | 45 | Quitar el guion |
| Phone | solo 3 dígitos (`000`) | 22 | Teléfono inválido, dejar NULL |
| MunicipalityName | minúsculas o sin tilde (`chia`, `medellin`) | 22 | Estandarizar con el código del municipio (Lookup) |
| Municipio ↔ Departamento | código de departamento que no corresponde al municipio (por ejemplo, Medellín con D01) | ~31 | Corregir el departamento a partir del municipio (Lookup) |
| MunicipalityCode | `M999 MUNICIPIO DESCONOCIDO` | 45 | Municipio desconocido: a revisión, no se inventa |
| Zone | valor `CENTRO` (fuera de URBANA/RURAL) | 22 | Inválido, dejar NULL o a revisión |
| SocioeconomicStratum | `0`, `9`, `ALTO` (válidos solo del 1 al 6) | 22 | Inválido, dejar NULL |
| EducationLevel | minúsculas | 44 | Pasar a mayúsculas |
| OccupationCode | `O99 SIN CLASIFICAR` | 22 | Se conserva como categoría |
| Ocupación ↔ situación laboral | EMPLEADO sin empleador o contrato, o DESEMPLEADO con contrato | por medir | Consistencia laboral (a revisión) |
| MonthlyIncome | texto `dos millones` | 44 | Rechazo (no se inventa el valor) |
| MonthlyIncome | negativo `-500000` | 22 | Rechazo |
| MonthlyIncome | formato `$ 14.700.000,00` | 22 | Convertir: quitar `$` y puntos, la coma es el decimal |
| MonthlyExpenses | vacío | 22 | Rechazo (no se reemplaza por 0) |
| MonthlyExpenses | decimal con coma `8900000,50` | 22 | Convertir |
| Dependents | `2.5`, `muchos`, `-2` | 44 | Inválido |
| HouseholdSize | `0` | 22 | Inválido (el hogar tiene al menos 1 persona); revisar que personas a cargo < tamaño del hogar |
| HealthRegime | `NULL`, `sin dato`, `N/A` | 22 | Pasar a NULL |
| Disability | `0`, `1`, `no`, `sí` | 44 | Estandarizar a SI/NO |
| SourceChannel | `FAX` | 44 | Valor raro; se conserva como categoría |

## Duplicados
- Clave de persona = tipo + número de documento. Clave de observación = persona + `SurveyDate`.
- Filas **951–1000** repiten las filas **801–850** (50 pares):
  - **25 pares idénticos**: se descarta la copia.
  - **25 pares con versión distinta**: cambian `MonthlyIncome` y `UpdatedAt` (12:30 frente a 18:45). **Se conserva la de `UpdatedAt` más reciente**, porque es la última actualización del dato.
- Los 23 `SIN-DATO` no son duplicados: son personas distintas sin documento, y van a rechazo.

## Filas 1–100 (ejercicio del cursor)
- Hay problemas de ingreso y gasto en las filas 13, 18, 19, 20, 21, 22, 49, 54, 55, 56, 57, 58, 85, 90, 91, 92, 93 y 94.
- Ejemplos:
  - 13 `dos millones`: rechazo.
  - 18 `$ 14.700.000,00`: corrección a 14700000.
  - 19 `-500000`: rechazo.
  - 21 gasto vacío: rechazo.
  - 22 `8900000,50`: corrección a 8900000.50.
- Los errores se repiten cada 36 filas (el dataset es sintético y tiene un patrón).

## Datos de prueba que NO son errores (lo dice el enunciado)
- Documentos `SIM` + 7 dígitos.
- Teléfonos que empiezan por 000.
- Códigos `D0x` y `M0xx`, que son internos.
