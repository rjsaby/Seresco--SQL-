drop table if exists temp_preliminar_analisis_areas;

create temp table temp_preliminar_analisis_areas as 
(
		select distinct terrenosdigitalizadoslote6.predio_t_id
		,terrenosdigitalizadoslote6.predio_numero_predial
		,analisisareasfmilote6.folio_matricula
		,terrenosdigitalizadoslote6.terreno_area_terreno area_terreno_bd_m
		,analisisareasfmilote6.area_total_registral_m area_registral_m
		,ST_Area(geometria) area_calculada_m2
		,terrenosdigitalizadoslote6.codigo_unidad_intervencion
		,(case when ST_Area(geometria) <= 2000 then 0.10
				when ST_Area(geometria) > 2000 and ST_Area(geometria) <= 10000 then 0.09
				when ST_Area(geometria) > 10000 and ST_Area(geometria) <= 100000 then 0.07
				when ST_Area(geometria) > 100000 and ST_Area(geometria) <= 500000 then 0.04
				when ST_Area(geometria) > 500000 then 0.02
				else 0
				end) tolerancia
		,ROUND(abs(ST_Area(geometria) - analisisareasfmilote6.area_total_registral_m)) diferencia_area_calculada_vs_registral
		from public.terrenos_digitalizados_lote_6 terrenosdigitalizadoslote6
		-- Analisa el informe de los tecnico jur�dicos en cuanto a �reas registrales.
		-- Por el momento solo existe para las UI 001 y 006 de El Paso
		inner join public.analisis_areas_fmi_lote_6 analisisareasfmilote6																	 	
			on terrenosdigitalizadoslote6.predio_numero_predial = analisisareasfmilote6.numero_predial
	);

-- *** Creaci�n Tabla verificacion_fisico_juridica_areas_lote_6

drop table if exists verificacion_fisico_juridica_areas_lote_6;

	create table verificacion_fisico_juridica_areas_lote_6 as
	(
	select t1.predio_t_id
		,t1.predio_numero_predial
		,t1.folio_matricula
		,t1.area_terreno_bd_m
		,t1.area_registral_m
		,t1.area_calculada_m2
		,t1.codigo_unidad_intervencion
		,t1.tolerancia
		,t1.diferencia_area_calculada_vs_registral
		,t1.rango_area
		,(case when diferencia_area_calculada_vs_registral <= rango_area then 'No Requiere'
			   when diferencia_area_calculada_vs_registral > rango_area then 'Requiere'
			   else 'Sin informaci�n'
			   end) verificacion_linderos_o_info_juridica
	from 
	(
		select predio_t_id
			,predio_numero_predial
			,folio_matricula
			,area_terreno_bd_m
			,area_registral_m
			,area_calculada_m2
			,codigo_unidad_intervencion
			,tolerancia
			,diferencia_area_calculada_vs_registral
			,round((area_calculada_m2 * tolerancia)) rango_area
		from temp_preliminar_analisis_areas
	) t1
);

-- Creaci�n de Vista -vw_verificacion_fisico_juridica_x_diferencia_areas-
select terrenosdigitalizadoslote6.*
	,verificacionfisicojuridicaareaslote6.area_terreno_bd_m
	,verificacionfisicojuridicaareaslote6.area_registral_m
	,verificacionfisicojuridicaareaslote6.area_calculada_m2
	,verificacionfisicojuridicaareaslote6.tolerancia
	,verificacion_linderos_o_info_juridica
from public.terrenos_digitalizados_lote_6 terrenosdigitalizadoslote6 
inner join verificacion_fisico_juridica_areas_lote_6 verificacionfisicojuridicaareaslote6
on terrenosdigitalizadoslote6.predio_numero_predial = verificacionfisicojuridicaareaslote6.predio_numero_predial