export type ParamType = "int" | "text" | "date" | "time" | "decimal";

export type ProcParam = {
  name: string;
  label: string;
  type: ParamType;
  /** Opcional: si se deja vacío no se pasa y rige el valor por defecto del SP. */
  optional?: boolean;
  /** Parámetro OUTPUT: no se carga, se muestra el valor devuelto. */
  output?: boolean;
  placeholder?: string;
  /** Columna de la que salen las sugerencias (su dominio cerrado o los valores de su tabla padre). */
  source?: { table: string; column: string };
};

export type ProcDef = {
  name: string;
  title: string;
  description: string;
  params: ProcParam[];
};

export const PROCEDURES: ProcDef[] = [
  {
    name: "SP_ALTA_GRUPO_FAMILIAR",
    title: "Alta de grupo familiar",
    description: "Crea el grupo y su titular (nro_orden 0) en una transacción.",
    params: [
      { name: "telefono", label: "Teléfono", type: "text" },
      { name: "domicilio", label: "Domicilio", type: "text" },
      { name: "nombre_titular", label: "Nombre del titular", type: "text" },
      { name: "fecha_nacimiento", label: "Fecha de nacimiento", type: "date" },
      { name: "nombre_categoria", label: "Categoría", type: "text", placeholder: "mayores / vitalicios / infantiles", source: { table: "CATEGORIA", column: "nombre_categoria" } },
      { name: "correo_electronico", label: "Correo electrónico", type: "text", optional: true },
      { name: "celular", label: "Celular", type: "text", optional: true },
      { name: "nro_socio_base", label: "nro_socio_base generado", type: "int", output: true },
    ],
  },
  {
    name: "SP_ALTA_ACTIVIDAD_ARANCELADA",
    title: "Alta de actividad arancelada",
    description: "Crea la actividad y su subentidad arancelada.",
    params: [
      { name: "cod_actividad", label: "Código de actividad", type: "int" },
      { name: "nombre", label: "Nombre", type: "text" },
      { name: "arancel", label: "Arancel", type: "decimal" },
      { name: "meses_por_cuota", label: "Meses por cuota", type: "int", source: { table: "ACTIVIDAD_ARANCELADA", column: "meses_por_cuota" } },
    ],
  },
  {
    name: "SP_ALTA_ACTIVIDAD_GRATUITA",
    title: "Alta de actividad gratuita",
    description: "Crea la actividad y su subentidad gratuita.",
    params: [
      { name: "cod_actividad", label: "Código de actividad", type: "int" },
      { name: "nombre", label: "Nombre", type: "text" },
    ],
  },
  {
    name: "SP_ALTA_DICTADO",
    title: "Alta de dictado",
    description: "Crea dictado, un día, un profesional a cargo y un área.",
    params: [
      { name: "cod_actividad", label: "Código de actividad", type: "int", source: { table: "DICTADO", column: "cod_actividad" } },
      { name: "fecha_desde", label: "Fecha desde", type: "date" },
      { name: "fecha_fin", label: "Fecha fin", type: "date" },
      { name: "hora_inicio", label: "Hora inicio", type: "time", placeholder: "HH:MM" },
      { name: "hora_fin", label: "Hora fin", type: "time", placeholder: "HH:MM" },
      { name: "dia_semana", label: "Día de la semana", type: "int", placeholder: "1 a 7", source: { table: "DICTADO_DIA", column: "dia_semana" } },
      { name: "dni", label: "DNI del profesional", type: "int", source: { table: "A_CARGO_DE", column: "dni" } },
      { name: "cod_area", label: "Código de área", type: "text", source: { table: "SE_DESARROLLA_EN", column: "cod_area" } },
      { name: "cod_dictado", label: "cod_dictado generado", type: "int", output: true },
    ],
  },
  {
    name: "SP_ALTA_AREA",
    title: "Alta de área",
    description: "Crea el área y su primer estado de mantenimiento en una transacción. Sin fecha rige la actual.",
    params: [
      { name: "cod_area", label: "Código de área", type: "text" },
      { name: "ubicacion", label: "Ubicación", type: "text" },
      { name: "capacidad", label: "Capacidad", type: "int" },
      { name: "nombre_estado", label: "Estado inicial", type: "text", source: { table: "HISTORIAL_AREA_ESTADO", column: "nombre_estado" } },
      { name: "fecha_desde", label: "Estado desde", type: "date", optional: true },
    ],
  },
  {
    name: "SP_CAMBIAR_ESTADO_AREA",
    title: "Cambiar estado de un área",
    description: "Registra un nuevo estado del área desde una fecha (por defecto, la actual). Puede volver a un estado anterior.",
    params: [
      { name: "cod_area", label: "Código de área", type: "text", source: { table: "HISTORIAL_AREA_ESTADO", column: "cod_area" } },
      { name: "nombre_estado", label: "Nuevo estado", type: "text", source: { table: "HISTORIAL_AREA_ESTADO", column: "nombre_estado" } },
      { name: "fecha_desde", label: "Estado desde", type: "date", optional: true },
    ],
  },
  {
    name: "SP_INSCRIBIR_ACTIVIDAD",
    title: "Inscribir socio en actividad",
    description: "Si la actividad es arancelada genera la cuota 1 por adelantado.",
    params: [
      { name: "nro_socio_base", label: "nro_socio_base", type: "int", source: { table: "INSCRIPCION", column: "nro_socio_base" } },
      { name: "nro_orden", label: "nro_orden", type: "int", source: { table: "INSCRIPCION", column: "nro_orden" } },
      { name: "cod_actividad", label: "Código de actividad", type: "int", source: { table: "INSCRIPCION", column: "cod_actividad" } },
      { name: "fecha_inscripcion", label: "Fecha de inscripción", type: "date" },
    ],
  },
  {
    name: "SP_LIQUIDAR_CUOTA_SOCIAL",
    title: "Liquidar cuota social",
    description: "Genera la cuota social del mes para cada grupo que no la tenga.",
    params: [
      { name: "anio", label: "Año", type: "int" },
      { name: "mes", label: "Mes", type: "int", source: { table: "CUOTA_SOCIAL", column: "mes" } },
    ],
  },
  {
    name: "SP_LIQUIDAR_CUOTA_ARANCEL",
    title: "Liquidar cuota de arancel",
    description: "Puesta al día: genera las cuotas de arancel vencidas hasta el mes indicado.",
    params: [
      { name: "anio", label: "Año", type: "int" },
      { name: "mes", label: "Mes", type: "int", source: { table: "CUOTA_SOCIAL", column: "mes" } },
    ],
  },
];

export const VIEWS: { name: string; title: string; description: string }[] = [
  {
    name: "VW_TITULARES_DEUDA_ANIO_ACTUAL",
    title: "Consulta 1: titulares con deuda (año actual)",
    description: "Titulares con deuda en las cuotas sociales del año en curso, con importe total e integrantes.",
  },
  {
    name: "VW_SOCIOS_GRATUITAS_ANIO_ANTERIOR",
    title: "Consulta 2: socios en todas las gratuitas (año anterior)",
    description: "Cantidad de socios por categoría inscriptos en todas las actividades gratuitas el año pasado.",
  },
  {
    name: "VW_ESTADO_ACTUAL_AREA",
    title: "Estado actual de las áreas",
    description: "Estado vigente de cada área según su historial (el de mayor fecha que no sea futura). Un área sin historial figura con estado NULL.",
  },
  {
    name: "VW_CONFLICTOS_DICTADO",
    title: "Conflictos de dictados",
    description: "Pares de dictados que coinciden en día, horario y período con un área o profesional en común.",
  },
];
