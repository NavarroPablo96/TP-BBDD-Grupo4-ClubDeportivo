Este código SQL tiene como objetivo controlar y automatizar la gestión de socios, grupos familiares, actividades, inscripciones, cuotas y dictados de actividades.

* Está compuesto por triggers, procedimientos almacenados y vistas.
* DIVISION:
  * [i1 03_logica_socios_cuota_sql](i1%2003_logica_socios_cuota_sql.md)
  * [i1 Comun i4 03_logica_socios_cuota_sql](i1%20Comun%20i4%2003_logica_socios_cuota_sql.md)
  * [i2 03_logica_socios_cuota_sql](i2%2003_logica_socios_cuota_sql.md)
  * [i4 03_logica_socios_cuota_sql](i4%2003_logica_socios_cuota_sql.md)
  * [i3 03_logica_socios_cuota_sql](i3%2003_logica_socios_cuota_sql.md)
  * [i5 03_logica_socios_cuota_sql](i5%2003_logica_socios_cuota_sql.md)
  * [i6 03_logica_socios_cuota_sql](i6%2003_logica_socios_cuota_sql.md)

Te los ordeno según aparecen en el código original, indicando el tipo, el nombre y la tabla sobre la que trabajan.

|Tipo|Nombre|Tabla / referencia|Integrante|
|----|------|------------------|----------|
|==Trigger 12==|`TR_SOCIO_TITULAR_`<br>`CATEGORIA`|ON SOCIO|I1|
|==Trigger 35==|`TR_SOCIO_BAJA_`<br>`GRUPO`|ON SOCIO|I1|
|==Procedimiento almacenado 72==|`SP_ALTA_GRUPO_`<br>`FAMILIAR`|GRUPO_FAMILIAR, SOCIO|I1|
|==Trigger 114==|`TR_SOCIO_CAMBIO_`<br>`CATEGORIA`|ON SOCIO|I1, I4|
|==Vista 151==|`VW_SOCIOS_GRATUITAS_`<br>`ANIO_ANTERIOR`|CATEGORIA, SOCIO, INSCRIPCION, ACTIVIDAD_GRATUITA|I1, I4|
|==Trigger 183==|`TR_INSCRIPCION_`<br>`CATEGORIA_HABILITADA`|ON INSCRIPCION|I4|
|==Trigger 211==|`TR_INSCRIPCION_`<br>`VIGENTE_UNICA`|ON INSCRIPCION|I4|
|==Trigger 246==|`TR_CUOTA_ARANCEL_`<br>`ACTIVIDAD_ARANCELADA`|ON CUOTA_ARANCEL|I4|
|==Procedimiento almacenado 269==|`SP_INSCRIBIR_`<br>`ACTIVIDAD`|INSCRIPCION, CUOTA_ARANCEL|I4|
|==Procedimiento almacenado 312==|`SP_LIQUIDAR_`<br>`CUOTA_ARANCEL`|CUOTA_ARANCEL, INSCRIPCION, ACTIVIDAD_ARANCELADA|I4|
|==Trigger 403==|`TR_VALOR_CUOTA_`<br>`SOCIAL_VIGENCIA`|ON VALOR_CUOTA_SOCIAL|I2|
|==Procedimiento almacenado 436==|`SP_LIQUIDAR_`<br>`CUOTA_SOCIAL`|CUOTA_SOCIAL, SOCIO, CATEGORIA, VALOR_CUOTA_SOCIAL|I2|
|==Vista 490==|`VW_TITULARES_`<br>`DEUDA_ANIO_ACTUAL`|CUOTA_SOCIAL, SOCIO|I2|
|==Trigger 525==|`TR_ACTIVIDAD_`<br>`ARANCELADA_TIPO`|ON ACTIVIDAD_ARANCELADA|I3|
|==Trigger 547==|`TR_ACTIVIDAD_`<br>`GRATUITA_TIPO`|ON ACTIVIDAD_GRATUITA|I3|
|==Trigger 570==|`TR_ACTIVIDAD_TIPO_`<br>`INMUTABLE`|ON ACTIVIDAD|I3|
|==Procedimiento almacenado 598==|`SP_ALTA_ACTIVIDAD_`<br>`ARANCELADA`|ACTIVIDAD, ACTIVIDAD_ARANCELADA|I3|
|==Procedimiento almacenado 629==|`SP_ALTA_ACTIVIDAD_`<br>`GRATUITA`|ACTIVIDAD, ACTIVIDAD_GRATUITA|I3|
|==Vista 658==|`VW_CONFLICTOS_`<br>`DICTADO`|DICTADO, DICTADO_DIA, SE_DESARROLLA_EN, A_CARGO_DE|I5|
|==Trigger 705==|`TR_DICTADO_`<br>`SOLAPAMIENTO_DICTADO`|ON DICTADO|I5|
|==Trigger 717==|`TR_DICTADO_SOLAPAMIENTO_`<br>`DICTADO_DIA`|ON DICTADO_DIA|I5|
|==Trigger 729==|`TR_DICTADO_SOLAPAMIENTO_`<br>`A_CARGO_DE`|ON A_CARGO_DE|I5|
|==Trigger 741==|`TR_DICTADO_SOLAPAMIENTO_`<br>`SE_DESARROLLA_EN`|ON SE_DESARROLLA_EN|I5|
|==Procedimiento almacenado 742==|`SP_ALTA_`<br>`DICTADO`|DICTADO, DICTADO_DIA, A_CARGO_DE, SE_DESARROLLA_EN|I5|

Aclaración: en los triggers, la tabla indicada es aquella sobre la que están definidos mediante `ON`. En los procedimientos almacenados y las vistas, indico todas las tablas que utilizan.

Total:

* 13 triggers.
* 6 procedimientos almacenados.
* 3 vistas.
