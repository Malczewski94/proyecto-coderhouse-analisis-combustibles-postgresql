"""Reconstruye el dataset desde fuente_original.csv. Python 3.10+, biblioteca estándar.
El modelo utiliza establecimientos reales como clientes de un mayorista ficticio y crea pedidos mensuales.
"""
from pathlib import Path
from collections import defaultdict
from decimal import Decimal as D
import csv, hashlib, json
from datetime import date

ROOT=Path(__file__).resolve().parent
MAPA={
 'Nafta (súper) entre 92 y 95 Ron':('Nafta','L'),
 'Nafta (premium) de más de 95 Ron':('Nafta','L'),
 'Nafta (común) hasta 92 Ron':('Nafta','L'),
 'Gas Oil Grado 2':('Gasoil','L'), 'Gas Oil Grado 3':('Gasoil','L'),
 'Kerosene':('Queroseno','L'), 'GNC':('GNC','m3')}

def read(name):
 with (ROOT/name).open(encoding='utf8',newline='') as f:return list(csv.DictReader(f))
def write(name,rows,fields=None):
 fields=fields or list(rows[0])
 with (ROOT/name).open('w',encoding='utf8',newline='') as f:
  w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)
def dec(x):
 if x is None or str(x).strip() in ('','N/D'):return None
 return D(str(x))
def fmt(x):return format(x,'f') if isinstance(x,D) else str(x)
def key(r):return tuple(r[k].strip() for k in ['Nro Inscripción','CUIT','Provincia','Localidad','Dirección'])
def main():
 raw=read('fuente_original.csv')
 keys=sorted(set(key(r) for r in raw))
 ops=[];opids={}
 for i,k in enumerate(keys,1):
  r=next(r for r in raw if key(r)==k); oid=f'O{i:03d}';opids[k]=oid
  identities={(x['Operador'],x['Bandera']) for x in raw if key(x)==k}
  assert len(identities)==1,'Identidad de establecimiento variable'
  ops.append(dict(id_operador=oid,nro_inscripcion=k[0],cuit=k[1],nombre_operador=r['Operador'].strip(),bandera=r['Bandera'].strip(),provincia=k[2],localidad=k[3],direccion=k[4],tipo_negocio=r['Tipo Negocio'].strip(),origen='real'))
 products=[];pids={}
 for i,p in enumerate(sorted(set(r['Producto'] for r in raw)&set(MAPA)),1):
  pid=f'P{i:03d}';pids[p]=pid;category,unit=MAPA[p]
  products.append(dict(id_producto=pid,nombre_original=p,categoria=category,unidad_venta=unit,unidad_precio='ARS/'+unit,origen_nombre='real',origen_categoria='derivado'))
 sources=[];excluded=[];warnings=[];seen=set()
 for r in raw:
  reasons=[]
  if r['Canal de Comercialización'].strip()!='Al público':reasons.append('fuera_del_canal_al_publico')
  if r['NO Movimientos'].strip()!='NO':reasons.append('sin_movimiento')
  if r['Producto'] not in MAPA:reasons.append('producto_fuera_del_alcance')
  v=dec(r['Volumen']);p=dec(r['Precio con impuestos'])
  if v is None or v<=0:reasons.append('volumen_nulo_o_no_positivo')
  if p is None or p<=0:reasons.append('precio_nulo_o_no_positivo')
  digest=hashlib.sha256(json.dumps({k:v for k,v in r.items() if k!='_fila_extraida'},sort_keys=True,ensure_ascii=False).encode()).hexdigest()
  if digest in seen:reasons.append('duplicado_exacto')
  seen.add(digest)
  if reasons:
   excluded.append(dict(fila_extraida=r['_fila_extraida'],motivo=';'.join(reasons)))
   continue
  unit=MAPA[r['Producto']][1];q=v*(1000 if unit=='L' else 1)
  fid='F'+str(r['_fila_extraida']).zfill(6)
  sources.append(dict(id_fuente=fid,fila_extraida=r['_fila_extraida'],id_operador=opids[key(r)],periodo=r['Período'].replace('/','-')+'-01',id_producto=pids[r['Producto']],canal=r['Canal de Comercialización'],volumen_original_m3=v,unidad_original='m3',cantidad_venta=q,unidad_venta=unit,precio_promedio_con_impuestos_ars=p,precio_surtidor_ars=dec(r['Precio surtidor']),origen='real_con_conversion'))
  pump=dec(r['Precio surtidor'])
  if pump is not None and pump>0 and (pump/p<D('.5') or pump/p>D('2')):
   warnings.append(dict(id_fuente=fid,campo='Precio surtidor',valor=pump,motivo='Difiere más del doble del promedio mensual; no se usa para importes ni se corrige. Revisar fuente.'))
  if unit=='m3' and v<D('100'):
   warnings.append(dict(id_fuente=fid,campo='Volumen',valor=v,motivo='GNC mensual menor a 100 m3: revisar posible escala o carga. Se preserva bajo la unidad documentada; sin inferir factor adicional.'))
 sources.sort(key=lambda s:s['id_fuente'])
 # Una cuenta comercial por establecimiento; la identidad es real, la relación es simulada.
 clients=[];client_ids={}
 for i,op in enumerate(ops,1):
  cid=f'C{i:04d}';client_ids[op['id_operador']]=cid
  clients.append(dict(id_cliente=cid,id_operador=op['id_operador'],nombre=op['nombre_operador'],provincia=op['provincia'],origen_identidad='real',relacion_comercial='simulada'))
 # El primer día representa el mes contable, no una entrega diaria observada.
 order_keys=sorted({(s['id_operador'],s['periodo']) for s in sources})
 order_ids={k:f'V{i:06d}' for i,k in enumerate(order_keys,1)}
 orders=[dict(id_pedido=order_ids[k],fecha=k[1],id_cliente=client_ids[k[0]],estado='Concretado',origen='sintetico_mensual') for k in order_keys]
 details=[]
 for i,s in enumerate(sources,1):
  details.append(dict(id_detalle=f'D{i:07d}',id_pedido=order_ids[(s['id_operador'],s['periodo'])],id_producto=s['id_producto'],id_fuente=s['id_fuente'],cantidad=s['cantidad_venta'],precio_unitario_ars=s['precio_promedio_con_impuestos_ars'],origen='simulado_con_referencia_minorista'))
 # Copia de entrada didáctica. No altera los archivos de fuente real.
 entry=[d.copy() for d in details];incidents=[]
 for i in range(36,len(entry),137):
  incidents.append(dict(id_detalle=entry[i]['id_detalle'],campo='precio_unitario_ars',incidencia='nulo_sintetico',recuperacion='COALESCE con precio de id_fuente; todos los pedidos usan ese precio por diseño'))
  entry[i]['precio_unitario_ars']=''
 duplicates=[entry[i].copy() for i in range(72,len(entry),389)]
 for d in duplicates:incidents.append(dict(id_detalle=d['id_detalle'],campo='fila',incidencia='duplicado_exacto_sintetico',recuperacion='SELECT DISTINCT'))
 entry+=duplicates
 tables={'operadores':ops,'productos':products,'clientes':clients,'fuente_ventas':sources,'pedidos':orders,'detalle_pedido':details,'detalle_pedido_entrada':entry}
 for name,rows in tables.items():write(name+'.csv',rows)
 write('exclusiones.csv',excluded,['fila_extraida','motivo'])
 write('advertencias_fuente.csv',warnings,['id_fuente','campo','valor','motivo'])
 write('incidencias_simuladas.csv',incidents)
 # Verificaciones independientes usando Decimal, claves y datos leídos desde CSV.
 validate(tables,incidents)
 build_sql(tables)
 summary={'modelo':'Mayorista ficticio; establecimientos reales como clientes; un pedido mensual; precios minoristas de referencia','conteos':{k:len(v) for k,v in tables.items()},'filas_originales_muestra':len(raw),'filas_excluidas':len(excluded),'precios_nulos_simulados':sum(x['incidencia']=='nulo_sintetico' for x in incidents),'duplicados_simulados':len(duplicates),'advertencias_fuente':len(warnings),'productos':products,'periodos':sorted({s['periodo'] for s in sources}),'provincias':sorted({o['provincia'] for o in ops}),'totales_por_unidad':{u:fmt(sum((s['cantidad_venta'] for s in sources if s['unidad_venta']==u),D(0))) for u in ('L','m3')},'importe_referencia_ars':fmt(sum((s['cantidad_venta']*s['precio_promedio_con_impuestos_ars'] for s in sources),D(0))),'interpretacion_importe':'Estimación a precios promedio mensuales declarados, asignados a pedidos sintéticos. No facturación auditada.'}
 (ROOT/'resumen_dataset.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf8')
 hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(ROOT.glob('*.csv'))}
 (ROOT/'sha256_csv.json').write_text(json.dumps(hashes,indent=2))
 print(json.dumps(summary,ensure_ascii=False,indent=2))

def validate(tables,incidents):
 sources={r['id_fuente']:r for r in tables['fuente_ventas']};orders={r['id_pedido']:r for r in tables['pedidos']}
 products={r['id_producto']:r for r in tables['productos']};clients={r['id_cliente']:r for r in tables['clientes']};ops={r['id_operador'] for r in tables['operadores']}
 for name,rows in tables.items():
  if name=='detalle_pedido_entrada':continue
  pk=list(rows[0])[0];assert len({r[pk] for r in rows})==len(rows),(name,'duplicate key')
 assert len(clients)==len(ops) and {c['id_operador'] for c in clients.values()}==ops
 assert len({(o['id_cliente'],o['fecha']) for o in orders.values()})==len(orders)
 assert len(orders)==len(clients)*12
 for o in orders.values():
  assert o['id_cliente'] in clients
  dt=date.fromisoformat(o['fecha']);assert dt.year==2025 and dt.day==1
 volumes=defaultdict(lambda:D(0));amounts=defaultdict(lambda:D(0));months=defaultdict(set)
 for d in read('detalle_pedido.csv'):
  s=sources[d['id_fuente']];o=orders[d['id_pedido']]
  assert d['id_producto']==s['id_producto'] and d['id_producto'] in products
  assert clients[o['id_cliente']]['id_operador']==s['id_operador'] and o['fecha'][:7]==s['periodo'][:7]
  assert dec(d['cantidad'])>0 and dec(d['precio_unitario_ars'])==s['precio_promedio_con_impuestos_ars']
  volumes[d['id_fuente']]+=dec(d['cantidad']);amounts[d['id_fuente']]+=dec(d['cantidad'])*dec(d['precio_unitario_ars'])
 reconciled=[]
 for fid,s in sources.items():
  assert volumes[fid]==s['cantidad_venta'],fid
  expected=s['cantidad_venta']*s['precio_promedio_con_impuestos_ars']
  assert amounts[fid]==expected,fid
  assert products[s['id_producto']]['unidad_venta']==s['unidad_venta']
  months[s['id_operador']].add(s['periodo'])
  reconciled.append(dict(id_fuente=fid,unidad=s['unidad_venta'],cantidad_fuente=s['cantidad_venta'],cantidad_pedidos=volumes[fid],diferencia_cantidad=volumes[fid]-s['cantidad_venta'],importe_fuente_ars=expected,importe_pedidos_ars=amounts[fid],diferencia_importe_ars=amounts[fid]-expected))
 assert len(months)==len(ops) and all(len(v)==12 for v in months.values())
 # Reproducir exactamente la limpieza de la entrada y contrastar todo el detalle.
 clean={}
 for d in read('detalle_pedido_entrada.csv'):
  if d['precio_unitario_ars']=='':d['precio_unitario_ars']=fmt(sources[d['id_fuente']]['precio_promedio_con_impuestos_ars'])
  if d['id_detalle'] in clean:assert clean[d['id_detalle']]==d
  clean[d['id_detalle']]=d
 assert clean=={r['id_detalle']:r for r in read('detalle_pedido.csv')}
 write('conciliacion.csv',reconciled)
 (ROOT/'validacion.json').write_text(json.dumps({'resultado':'CORRECTO','un_cliente_por_establecimiento':True,'un_pedido_por_cliente_mes':True,'fechas_validas_2025':True,'claves_primarias_unicas':True,'relaciones_sin_huerfanos':True,'operador_producto_periodo_coinciden':True,'doce_meses_por_establecimiento':True,'filas_fuente_conciliadas':len(reconciled),'diferencia_total_cantidad_por_registro':'0','diferencia_importe_por_registro_ars':'0','limpieza_recupera_detalle_exacto':True,'motor_validacion':'Python Decimal; PostgreSQL se verifica por separado si está disponible'},ensure_ascii=False,indent=2))

def build_sql(t):
 ddl='''-- Separo identidad real y relación comercial simulada para no atribuir compras mayoristas a la fuente.
-- Uso una transacción para evitar que una carga fallida deje un modelo parcialmente construido.
BEGIN;
CREATE SCHEMA IF NOT EXISTS combustibles;
SET search_path TO combustibles;
-- Identifico establecimientos por inscripción y ubicación porque un CUIT puede tener varias sucursales.
CREATE TABLE operadores (
 id_operador TEXT PRIMARY KEY, nro_inscripcion TEXT NOT NULL, cuit TEXT NOT NULL,
 nombre_operador TEXT NOT NULL, bandera TEXT NOT NULL, provincia TEXT NOT NULL,
 localidad TEXT NOT NULL, direccion TEXT NOT NULL, tipo_negocio TEXT, origen TEXT NOT NULL,
 UNIQUE(nro_inscripcion,cuit,provincia,localidad,direccion)
);
-- Conservo unidades por producto para no sumar litros y m3 como si fueran un mismo volumen.
CREATE TABLE productos (
 id_producto TEXT PRIMARY KEY, nombre_original TEXT NOT NULL UNIQUE,
 categoria TEXT NOT NULL, unidad_venta TEXT NOT NULL CHECK(unidad_venta IN ('L','m3')),
 unidad_precio TEXT NOT NULL, origen_nombre TEXT NOT NULL, origen_categoria TEXT NOT NULL
);
-- La relación única con operador evita duplicar cuentas para un mismo establecimiento.
CREATE TABLE clientes (
 id_cliente TEXT PRIMARY KEY, id_operador TEXT NOT NULL UNIQUE REFERENCES operadores,
 nombre TEXT NOT NULL, provincia TEXT NOT NULL,
 origen_identidad TEXT NOT NULL CHECK(origen_identidad='real'),
 relacion_comercial TEXT NOT NULL CHECK(relacion_comercial='simulada')
);
-- Conservo el registro fuente para justificar cantidades y precios de cada detalle simulado.
-- NUMERIC preserva precisión decimal y el CHECK de conversión evita inconsistencias entre m3 y litros.
CREATE TABLE fuente_ventas (
 id_fuente TEXT PRIMARY KEY, fila_extraida INTEGER NOT NULL UNIQUE,
 id_operador TEXT NOT NULL REFERENCES operadores, periodo DATE NOT NULL,
 id_producto TEXT NOT NULL REFERENCES productos, canal TEXT NOT NULL,
 volumen_original_m3 NUMERIC(18,3) NOT NULL CHECK(volumen_original_m3>0),
 unidad_original TEXT NOT NULL CHECK(unidad_original='m3'),
 cantidad_venta NUMERIC(18,3) NOT NULL CHECK(cantidad_venta>0),
 unidad_venta TEXT NOT NULL CHECK(unidad_venta IN ('L','m3')),
 precio_promedio_con_impuestos_ars NUMERIC(18,2) NOT NULL CHECK(precio_promedio_con_impuestos_ars>0),
 precio_surtidor_ars NUMERIC(18,2), origen TEXT NOT NULL,
 CHECK(cantidad_venta=volumen_original_m3*CASE WHEN unidad_venta='L' THEN 1000 ELSE 1 END)
);
-- La unicidad y el primer día fijan un pedido por cliente y mes, conforme a la granularidad de la fuente.
-- El estado concretado es un supuesto del caso; no hay evidencia de cancelaciones en este modelo.
CREATE TABLE pedidos (
 id_pedido TEXT PRIMARY KEY, fecha DATE NOT NULL, id_cliente TEXT NOT NULL REFERENCES clientes,
 estado TEXT NOT NULL CHECK(estado='Concretado'),
 origen TEXT NOT NULL CHECK(origen='sintetico_mensual'),
 UNIQUE(id_cliente,fecha),
 CHECK(fecha >= DATE '2025-01-01' AND fecha < DATE '2026-01-01' AND EXTRACT(DAY FROM fecha)=1)
);
-- Permito nulos y duplicados en la entrada para representar incidencias didácticas antes de limpiarlas.
CREATE TABLE detalle_pedido_entrada (
 id_detalle TEXT, id_pedido TEXT, id_producto TEXT, id_fuente TEXT,
 cantidad NUMERIC(18,3), precio_unitario_ars NUMERIC(18,2), origen TEXT
);
-- Exijo una única línea por fuente y valores positivos para evitar duplicar o invalidar su valoración.
CREATE TABLE detalle_pedido (
 id_detalle TEXT PRIMARY KEY, id_pedido TEXT NOT NULL REFERENCES pedidos,
 id_producto TEXT NOT NULL REFERENCES productos, id_fuente TEXT NOT NULL UNIQUE REFERENCES fuente_ventas,
 cantidad NUMERIC(18,3) NOT NULL CHECK(cantidad>0),
 precio_unitario_ars NUMERIC(18,2) NOT NULL CHECK(precio_unitario_ars>0), origen TEXT NOT NULL,
 UNIQUE(id_pedido,id_fuente)
);
'''
 def lit(x):
  if x is None or x=='':return 'NULL'
  if isinstance(x,(int,D)):return fmt(x)
  return "'"+str(x).replace("'","''")+"'"
 with (ROOT.parent/'estructura.sql').open('w',encoding='utf8') as f:
  f.write(ddl)
  for name in ['operadores','productos','clientes','fuente_ventas','pedidos','detalle_pedido_entrada']:
   rows=t[name];cols=list(rows[0])
   for start in range(0,len(rows),400):
    f.write('\nINSERT INTO '+name+' ('+','.join(cols)+') VALUES\n')
    f.write(',\n'.join('('+','.join(lit(r[k]) for k in cols)+')' for r in rows[start:start+400])+';\n')
  f.write('''
-- DISTINCT es válido porque las repeticiones didácticas son copias exactas, no ventas diferentes.
-- Recupero el precio de la misma fuente porque ese valor se asigna al pedido por diseño.
-- No uso un promedio ni cero, ya que alterarían el importe de referencia de la simulación.
INSERT INTO detalle_pedido
SELECT DISTINCT e.id_detalle,e.id_pedido,e.id_producto,e.id_fuente,e.cantidad,
 COALESCE(e.precio_unitario_ars,f.precio_promedio_con_impuestos_ars),e.origen
FROM detalle_pedido_entrada e JOIN fuente_ventas f ON f.id_fuente=e.id_fuente;

-- Centralizo las relaciones y el importe para reutilizar una definición consistente de venta simulada.
CREATE VIEW v_ventas AS
SELECT d.id_detalle,p.id_pedido,p.fecha,p.id_cliente,c.id_operador,
 d.id_producto,pr.categoria,pr.unidad_venta,d.id_fuente,d.cantidad,d.precio_unitario_ars,
 d.cantidad*d.precio_unitario_ars AS importe_referencia_ars
FROM detalle_pedido d JOIN pedidos p USING(id_pedido)
JOIN clientes c USING(id_cliente) JOIN productos pr USING(id_producto);

-- LEFT JOIN conserva fuentes sin detalle para que una pérdida de registros sea visible.
-- COALESCE representa ausencia de cantidad conciliada; no imputa precios faltantes.
CREATE VIEW v_conciliacion AS
SELECT f.id_fuente,f.unidad_venta,f.cantidad_venta AS cantidad_fuente,
 COALESCE(SUM(d.cantidad),0) AS cantidad_pedidos,
 COALESCE(SUM(d.cantidad),0)-f.cantidad_venta AS diferencia_cantidad,
 COALESCE(SUM(d.cantidad*d.precio_unitario_ars),0)
 -f.cantidad_venta*f.precio_promedio_con_impuestos_ars AS diferencia_importe_ars
FROM fuente_ventas f LEFT JOIN detalle_pedido d USING(id_fuente)
GROUP BY f.id_fuente,f.unidad_venta,f.cantidad_venta,f.precio_promedio_con_impuestos_ars;
COMMIT;

-- Destaco discrepancias para detectar si la carga o limpieza alteró cantidades o importes de origen.
SELECT * FROM combustibles.v_conciliacion
WHERE diferencia_cantidad<>0 OR diferencia_importe_ars<>0;
''')

if __name__=='__main__':main()

