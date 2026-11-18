export const TABLE_GROUPS: { title: string; tables: string[] }[] = [
  { title: "Socios", tables: ["CATEGORIA", "GRUPO_FAMILIAR", "SOCIO"] },
  { title: "Cuotas sociales", tables: ["VALOR_CUOTA_SOCIAL", "CUOTA_SOCIAL"] },
  {
    title: "Actividades",
    tables: ["ACTIVIDAD", "ACTIVIDAD_ARANCELADA", "ACTIVIDAD_GRATUITA", "HABILITADA_PARA", "INSCRIPCION", "CUOTA_ARANCEL"],
  },
  {
    title: "Profesionales y áreas",
    tables: ["PROFESIONAL", "AREA", "ESTADO_AREA", "HISTORIAL_AREA_ESTADO", "PUEDE_DESEMPENIARSE_EN", "APTA_PARA"],
  },
  { title: "Dictados", tables: ["DICTADO", "DICTADO_DIA", "A_CARGO_DE", "SE_DESARROLLA_EN"] },
];
