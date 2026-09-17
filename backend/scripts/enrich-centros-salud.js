/**
 * Script de enriquecimiento inteligente de Centros de Salud y Hospitales
 * para Biomark AI (Nicaragua / SILAIS Managua).
 * 
 * Multi-Modelo: Gemini 3.5 Flash Lite -> Gemini 3.1 Flash Lite -> Gemini 3.5 Flash
 * Fallback normativo MOSAFC para Puestos de Salud barriales.
 */

require('dotenv').config({ path: __dirname + '/../.env' });
const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
  console.error('[Error] Falta la variable GEMINI_API_KEY en el archivo .env');
  process.exit(1);
}

if (!SUPABASE_URL || !SUPABASE_KEY) {
  console.error('[Error] Faltan SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY en el archivo .env');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

const args = process.argv.slice(2);
const DRY_RUN = args.includes('--dry-run');
const ENRICH_ALL = args.includes('--all');
const limitArg = args.find(a => a.startsWith('--limit='));
const LIMIT = limitArg ? parseInt(limitArg.split('=')[1], 10) : null;
const DELAY_MS = 2500;

const SQL_OUTPUT_PATH = path.resolve(__dirname, '../../database/seeds/013_centros_salud_enriquecidos.sql');

const FALLBACK_MODELS = [
  'gemini-3.5-flash-lite',
  'gemini-3.1-flash-lite',
  'gemini-3.5-flash',
  'gemini-2.5-flash'
];

async function queryNominatim(centerName, municipality = 'Managua') {
  let cleanName = centerName
    .replace(/\s*\([^)]*\)/g, '')
    .replace(/Hospital\s+(Escuela|Departamental|Nacional|Occidental)\s+/gi, 'Hospital ')
    .trim();

  const query = `${cleanName}, ${municipality}, Nicaragua`;
  const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=1&addressdetails=1`;

  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'BiomarkAI-SaludNicaragua/1.0 (contacto@biomarkai.com)'
      }
    });
    if (!res.ok) return null;
    const items = await res.json();
    if (items && items.length > 0) {
      const best = items[0];
      return {
        lat: parseFloat(best.lat),
        lon: parseFloat(best.lon),
        displayName: best.display_name,
        name: best.name,
        osmId: best.osm_id,
        osmType: best.osm_type,
        address: best.address || {}
      };
    }
  } catch (_) {}
  return null;
}

async function callGeminiModel(model, prompt) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: 'application/json',
        temperature: 0.1
      }
    })
  });

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`API error ${response.status} (${model}): ${errText}`);
  }

  const data = await response.json();
  const rawJson = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!rawJson) throw new Error('Respuesta vacía');
  return JSON.parse(rawJson);
}

async function enrichWithGemini(center, osmMatch, catalogLabels) {
  const prompt = `
Eres un médico y especialista en salud pública e infraestructura hospitalaria de Nicaragua (MINSA / SILAIS Managua).
Tu misión es enriquecer y corregir la información clínica y geográfica del siguiente centro de salud para la aplicación médica Biomark AI.

INFORMACIÓN ACTUAL EN BASE DE DATOS:
- Nombre: "${center.nombre}"
- Tipo de unidad en BD: "${center.tipo}" (${center.tipo_unidad || 'Sin especificar'})
- Dirección actual: "${center.direccion || 'Sin dirección registrada'}"
- Municipio: "${center.municipio || 'Managua'}", Distrito: "${center.distrito || 'No especificado'}"
- Especialidades registradas actuales: ${JSON.stringify(center.especialidades || [])}
- Teléfono actual: "${center.telefono || 'Sin teléfono'}"

DATOS VERIFICADOS EN OPENSTREETMAP:
${osmMatch ? `- Nombre OSM: ${osmMatch.name}\n- Coordenadas OSM: Lat ${osmMatch.lat}, Lon ${osmMatch.lon}\n- Dirección OSM: ${osmMatch.displayName}` : '- No se encontró coincidencia en OSM, usar datos de referencia de Managua.'}

CATÁLOGO ESTRICTO DE ESPECIALIDADES PERMITIDAS (Selecciona ÚNICAMENTE de esta lista las que apliquen verdaderamente):
${JSON.stringify(catalogLabels, null, 2)}

REGLAS MÉDICAS Y DE GEOLOCALIZACIÓN PARA NICARAGUA (OBLIGATORIAS):
1. PUESTOS DE SALUD (Nivel 1 básico comunitarios/barriales):
   - Según el MOSAFC del MINSA, SOLO brindan atención básica: "Atencion general", "Vacunacion", "Curaciones".
   - PROHIBIDO asignar especialidades complejas (como cardiología, oncología, cirugía).
   - "atiende_emergencia": false.
   - "nivel_atencion": 1.
2. CENTROS DE SALUD (Policlínicos distritales de Managua: Carlos Rugama, Edgar Lang, Pedro Altamirano, Francisco Morazán, etc.):
   - Atención primaria y ambulatoria: "Atencion general", "Pediatria", "Gineco-obstetricia", "Salud de la mujer", "Vacunacion", "Curaciones", "Laboratorio".
   - "nivel_atencion": 2.
3. HOSPITALES DE REFERENCIA NACIONAL Y DEPARTAMENTALES:
   - "atiende_emergencia": true (sala de urgencias 24/7).
   - "nivel_atencion": 3.
4. DIRECCIÓN:
   - Proporciona una dirección clara y precisa combinando el nombre formal de la vía/calle y la referencia tradicional nicaragüense.
5. TELÉFONO:
   - Incluir código 22XX-XXXX si se conoce, o null.

Responde ÚNICAMENTE con un objeto JSON válido:
{
  "nombre_normalizado": string,
  "direccion": string,
  "especialidades": string[],
  "atiende_emergencia": boolean,
  "telefono": string or null,
  "horario": { "emergencia": string, "consulta": string },
  "nivel_atencion": number,
  "resumen_atencion": string
}
`;

  let lastError = null;
  for (const model of FALLBACK_MODELS) {
    try {
      const res = await callGeminiModel(model, prompt);
      return res;
    } catch (err) {
      lastError = err;
      if (err.message.includes('429')) {
        continue; // probar siguiente modelo con quota disponible
      }
      throw err;
    }
  }

  // Fallback normativo MOSAFC si todos los modelos agotan cuota
  console.log(`  [Aviso] Cuota agotada en modelos, aplicando normativa MOSAFC estándar de Nicaragua.`);
  if (center.tipo === 'PUESTO_MEDICO' || center.tipo_unidad?.toLowerCase().includes('puesto')) {
    const dir = center.direccion || center.localidad || center.nombre;
    const dist = center.distrito ? `, Distrito ${center.distrito}` : '';
    return {
      nombre_normalizado: center.nombre,
      direccion: `${dir}${dist}, Managua`,
      especialidades: ['Atencion general', 'Vacunacion', 'Curaciones'],
      atiende_emergencia: false,
      telefono: center.telefono || null,
      horario: {
        emergencia: 'No disponible (referencia a Centro de Salud o red hospitalaria)',
        consulta: 'Lunes a Viernes, 7:00 AM - 4:00 PM'
      },
      nivel_atencion: 1,
      resumen_atencion: 'Puesto de salud comunitario del primer nivel de atención (MOSAFC) para consultas preventivas y esquema de vacunación.'
    };
  }

  if (center.tipo === 'CENTRO_SALUD' || center.tipo_unidad?.toLowerCase().includes('centro')) {
    const dir = center.direccion || center.localidad || center.nombre;
    const dist = center.distrito ? `, Distrito ${center.distrito}` : '';
    return {
      nombre_normalizado: center.nombre,
      direccion: `${dir}${dist}, Managua`,
      especialidades: ['Atencion general', 'Pediatria', 'Gineco-obstetricia', 'Salud de la mujer', 'Vacunacion', 'Curaciones', 'Laboratorio'],
      atiende_emergencia: false,
      telefono: center.telefono || null,
      horario: {
        emergencia: 'Atención de urgencias menores diurnas',
        consulta: 'Lunes a Viernes, 7:00 AM - 4:00 PM'
      },
      nivel_atencion: 2,
      resumen_atencion: 'Centro de salud distrital con atención médica general, salud materno-infantil y laboratorio básico.'
    };
  }

  throw lastError;
}

async function main() {
  console.log('=====================================================');
  console.log(' BIOMARK AI — Enriquecimiento de Centros y Hospitales');
  console.log('=====================================================');
  console.log(`Modo: ${DRY_RUN ? 'DRY RUN' : 'APLICACIÓN EN VIVO (Supabase)'}`);
  console.log(`Objetivo: ${ENRICH_ALL ? 'TODOS los centros' : 'Centros sin verificar / incompletos'}`);
  if (LIMIT) console.log(`Límite: ${LIMIT} registros.`);
  console.log('-----------------------------------------------------\n');

  const { data: catalogRows, error: catError } = await supabase.from('catalogo_servicios').select('*');
  if (catError) {
    console.error('Error catalogo_servicios:', catError);
    process.exit(1);
  }
  const catalogLabels = catalogRows.map(c => c.etiqueta);
  const catalogMap = new Map(catalogRows.map(c => [c.etiqueta.toLowerCase(), c.codigo]));

  let query = supabase.from('centros_salud').select('*').order('tipo', { ascending: true }).order('nombre', { ascending: true });
  if (!ENRICH_ALL) {
    query = query.or('fecha_verificacion.is.null,coordenadas_verificadas.eq.false,especialidades.is.null,direccion.is.null');
  }
  if (LIMIT) {
    query = query.limit(LIMIT);
  }

  const { data: centers, error: centersError } = await query;
  if (centersError) {
    console.error('Error obteniendo centros de salud:', centersError);
    process.exit(1);
  }

  console.log(`[Centros pendientes] ${centers.length} registros.`);

  const sqlStatements = [];
  sqlStatements.push(`-- ==========================================================`);
  sqlStatements.push(`-- Biomark AI: Enriquecimiento de Centros de Salud de Managua`);
  sqlStatements.push(`-- Fecha: ${new Date().toISOString()}`);
  sqlStatements.push(`-- ==========================================================\n`);
  sqlStatements.push(`BEGIN;\n`);

  let processed = 0;
  let successCount = 0;
  let osmMatchCount = 0;

  for (const center of centers) {
    processed++;
    const prefix = `[${processed}/${centers.length}]`;
    console.log(`${prefix} Procesando: "${center.nombre}" (${center.tipo})...`);

    const osmMatch = await queryNominatim(center.nombre, center.municipio || 'Managua');
    if (osmMatch) {
      osmMatchCount++;
      console.log(`  -> Match OSM: "${osmMatch.name}" (Lat: ${osmMatch.lat}, Lon: ${osmMatch.lon})`);
    } else {
      console.log(`  -> Sin match exacto en OSM, usando georreferenciación clínica.`);
    }

    try {
      const enriched = await enrichWithGemini(center, osmMatch, catalogLabels);

      const finalLat = osmMatch ? osmMatch.lat : parseFloat(center.latitud);
      const finalLon = osmMatch ? osmMatch.lon : parseFloat(center.longitud);
      const finalFuente = osmMatch ? 'osm' : 'manual';
      const finalOsmId = osmMatch ? osmMatch.osmId : (center.osm_id || null);

      console.log(`  ✓ Especialidades (${enriched.especialidades.length}): ${enriched.especialidades.slice(0, 4).join(', ')}${enriched.especialidades.length > 4 ? '...' : ''}`);
      console.log(`  ✓ Emergencia: ${enriched.atiende_emergencia ? 'SÍ' : 'NO'} | Nivel: ${enriched.nivel_atencion}`);
      console.log(`  ✓ Dirección: ${enriched.direccion.slice(0, 75)}...`);

      const matchedCodigos = [];
      for (const esp of enriched.especialidades) {
        const cod = catalogMap.get(esp.toLowerCase());
        if (cod) matchedCodigos.push(cod);
      }

      const escapedAddress = enriched.direccion.replace(/'/g, "''");
      const escapedPhone = enriched.telefono ? `'${enriched.telefono.replace(/'/g, "''")}'` : 'NULL';
      const escapedHorario = JSON.stringify(enriched.horario || {}).replace(/'/g, "''");
      const espSqlArray = `ARRAY[${enriched.especialidades.map(e => `'${e.replace(/'/g, "''")}'`).join(',')}]`;

      sqlStatements.push(`-- Centro: ${center.nombre} (${center.id})`);
      sqlStatements.push(`UPDATE public.centros_salud SET`);
      sqlStatements.push(`  direccion = '${escapedAddress}',`);
      sqlStatements.push(`  latitud = ${finalLat},`);
      sqlStatements.push(`  longitud = ${finalLon},`);
      sqlStatements.push(`  geog = st_setsrid(st_makepoint(${finalLon}, ${finalLat}), 4326)::geography,`);
      sqlStatements.push(`  telefono = ${escapedPhone},`);
      sqlStatements.push(`  especialidades = ${espSqlArray},`);
      sqlStatements.push(`  atiende_emergencia = ${enriched.atiende_emergencia ? 'true' : 'false'},`);
      sqlStatements.push(`  horario = '${escapedHorario}'::jsonb,`);
      sqlStatements.push(`  nivel_atencion = ${enriched.nivel_atencion},`);
      sqlStatements.push(`  coordenadas_verificadas = true,`);
      sqlStatements.push(`  fuente_coordenada = '${finalFuente}',`);
      if (finalOsmId) sqlStatements.push(`  osm_id = ${finalOsmId},`);
      sqlStatements.push(`  fecha_verificacion = now()`);
      sqlStatements.push(`WHERE id = '${center.id}';\n`);

      if (matchedCodigos.length > 0) {
        sqlStatements.push(`DELETE FROM public.centro_servicios WHERE centro_id = '${center.id}';`);
        sqlStatements.push(`INSERT INTO public.centro_servicios (centro_id, codigo) VALUES`);
        sqlStatements.push(matchedCodigos.map(c => `  ('${center.id}', '${c}')`).join(',\n') + ';');
        sqlStatements.push('');
      }

      if (!DRY_RUN) {
        const updatePayload = {
          direccion: enriched.direccion,
          latitud: finalLat,
          longitud: finalLon,
          geog: `POINT(${finalLon} ${finalLat})`,
          telefono: enriched.telefono,
          especialidades: enriched.especialidades,
          atiende_emergencia: enriched.atiende_emergencia,
          horario: enriched.horario,
          nivel_atencion: enriched.nivel_atencion,
          coordenadas_verificadas: true,
          fuente_coordenada: finalFuente,
          fecha_verificacion: new Date().toISOString()
        };
        if (finalOsmId) updatePayload.osm_id = finalOsmId;

        const { error: updateError } = await supabase
          .from('centros_salud')
          .update(updatePayload)
          .eq('id', center.id);

        if (updateError) {
          console.error(`  [!] Error actualizando Supabase para ${center.nombre}:`, updateError.message);
        } else {
          if (matchedCodigos.length > 0) {
            await supabase.from('centro_servicios').delete().eq('centro_id', center.id);
            const inserts = matchedCodigos.map(cod => ({
              centro_id: center.id,
              codigo: cod
            }));
            await supabase.from('centro_servicios').insert(inserts);
          }
          console.log(`  ✓ Guardado en Supabase exitosamente.`);
        }
      }

      successCount++;
    } catch (err) {
      console.error(`  [X] Error procesando ${center.nombre}:`, err.message);
    }

    if (processed < centers.length) {
      await new Promise(r => setTimeout(r, DELAY_MS));
    }
  }

  sqlStatements.push(`COMMIT;\n`);

  fs.appendFileSync(SQL_OUTPUT_PATH, '\n' + sqlStatements.join('\n'), 'utf8');
  console.log('\n=====================================================');
  console.log(` Enriquecimiento completado:`);
  console.log(` - Procesados: ${processed}`);
  console.log(` - Exitosos: ${successCount}`);
  console.log(` - Matches en OSM: ${osmMatchCount}`);
  console.log(` - Archivo SQL actualizado: ${SQL_OUTPUT_PATH}`);
  console.log('=====================================================\n');
}

main().catch(err => {
  console.error('[Fatal Error]:', err);
  process.exit(1);
});
