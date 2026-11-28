<?php
// Version: 1.1
// Portal CiberNova - Incidencias de Sistemas (intranet interna). 27/11/2026 - Max.
// Va en /var/www/html/portal/index.php de LNX01 y LNX02 (identico en los dos).
// Se conecta a la VIP (.27) con web_cibernova; credenciales en /etc/cibernova/web.ini (clave bbdd_portal).
// Seguridad: consultas preparadas (sin inyeccion SQL), salida escapada (sin XSS), validacion de datos,
// POST-redirect-GET y errores solo en el log. Sin inicio de sesion propio: prevista autenticacion contra
// el AD desde Apache (mod_authnz_ldap) cuando los DC esten en Proxmox.
// v1.1: diseno nuevo (cabecera, resumen, tarjetas y etiquetas de color). Sin recursos externos (CDN, fuentes):
//       la intranet no depende de Internet. La logica y las consultas no cambian.
declare(strict_types=1);

$SEDES = ['Barcelona', 'Madrid', 'Valencia'];
$PRIORIDADES = ['Baja', 'Media', 'Alta'];
$nodo = gethostname();

function e(?string $s): string { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

function pagina(string $cuerpo, string $nodo, string $principal = ''): void {
    header('Content-Type: text/html; charset=utf-8');
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    $bd = $principal !== ''
        ? '<span class="chip ok">SQL Server: ' . e($principal) . '</span>'
        : '<span class="chip ko">SQL Server: no disponible</span>';
    echo <<<HTML
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Portal CiberNova · Incidencias</title>
<style>
:root{--azul:#0b4f9c;--azul2:#1f6fd1;--fondo:#f2f5f9;--tarjeta:#fff;--texto:#1d2733;--suave:#64748b;--borde:#e2e8f0;
--rojo:#c62828;--rojo-f:#fde8e8;--naranja:#b45309;--naranja-f:#fef3c7;--verde:#15803d;--verde-f:#dcfce7;--gris-f:#eef2f6}
*{box-sizing:border-box}
body{margin:0;font-family:"Segoe UI",system-ui,-apple-system,Roboto,Ubuntu,sans-serif;background:var(--fondo);color:var(--texto)}
header{background:linear-gradient(120deg,var(--azul),var(--azul2));color:#fff;padding:1.1rem 2rem;display:flex;align-items:center;gap:1rem;flex-wrap:wrap}
.logo{width:2.6rem;height:2.6rem;border-radius:.7rem;background:rgba(255,255,255,.18);display:grid;place-items:center;font-weight:800;font-size:1.2rem}
header h1{margin:0;font-size:1.35rem;font-weight:650}
header p{margin:.1rem 0 0;opacity:.85;font-size:.9rem}
.estado{margin-left:auto;display:flex;gap:.5rem;flex-wrap:wrap}
.chip{font-size:.8rem;padding:.3rem .7rem;border-radius:999px;background:rgba(255,255,255,.16);white-space:nowrap}
.chip::before{content:"";display:inline-block;width:.5rem;height:.5rem;border-radius:50%;margin-right:.4rem;background:#9ae6b4}
.chip.ko::before{background:#feb2b2}
main{max-width:72rem;margin:1.5rem auto;padding:0 1.25rem}
.resumen{display:grid;grid-template-columns:repeat(auto-fit,minmax(11rem,1fr));gap:1rem;margin-bottom:1.25rem}
.dato{background:var(--tarjeta);border:1px solid var(--borde);border-radius:.9rem;padding:1rem 1.2rem}
.dato b{display:block;font-size:1.8rem;line-height:1.2}
.dato span{color:var(--suave);font-size:.85rem}
.dato.alta b{color:var(--rojo)}.dato.abiertas b{color:var(--azul)}.dato.cerradas b{color:var(--verde)}
.tarjeta{background:var(--tarjeta);border:1px solid var(--borde);border-radius:.9rem;padding:1.25rem 1.4rem;margin-bottom:1.25rem}
.tarjeta h2{margin:0 0 1rem;font-size:1.05rem}
.fila{display:grid;grid-template-columns:2fr 1fr 1fr;gap:.9rem}
label{display:block;font-size:.8rem;font-weight:600;color:var(--suave);margin-bottom:.3rem}
input[type=text],textarea,select{width:100%;padding:.55rem .7rem;border:1px solid var(--borde);border-radius:.55rem;font:inherit;background:#fff}
input[type=text]:focus,textarea:focus,select:focus{outline:2px solid var(--azul2);border-color:transparent}
textarea{resize:vertical;min-height:4.5rem}
.acciones{margin-top:.9rem;display:flex;justify-content:flex-end}
button{font:inherit;border:0;border-radius:.55rem;cursor:pointer}
.principal{background:var(--azul);color:#fff;padding:.6rem 1.2rem;font-weight:600}
.principal:hover{background:var(--azul2)}
.cerrar{background:var(--gris-f);color:var(--texto);padding:.35rem .8rem;font-size:.85rem}
.cerrar:hover{background:var(--verde-f);color:var(--verde)}
.aviso{padding:.75rem 1rem;border-radius:.6rem;margin-bottom:1.25rem;font-size:.95rem}
.aviso.ok{background:var(--verde-f);color:var(--verde)}.aviso.error{background:var(--rojo-f);color:var(--rojo)}
table{width:100%;border-collapse:collapse;font-size:.92rem}
th{text-align:left;font-size:.75rem;text-transform:uppercase;letter-spacing:.04em;color:var(--suave);padding:.6rem .5rem;border-bottom:2px solid var(--borde)}
td{padding:.75rem .5rem;border-bottom:1px solid var(--borde);vertical-align:top}
tr.Cerrada td{color:var(--suave)}tr.Cerrada .titulo{text-decoration:line-through}
.titulo{font-weight:600}.desc{color:var(--suave);font-size:.85rem;margin-top:.2rem}
.etq{display:inline-block;font-size:.75rem;font-weight:600;padding:.2rem .6rem;border-radius:999px}
.etq.Alta{background:var(--rojo-f);color:var(--rojo)}.etq.Media{background:var(--naranja-f);color:var(--naranja)}
.etq.Baja,.etq.Cerrada{background:var(--gris-f);color:var(--suave)}.etq.Abierta{background:#e0ecff;color:var(--azul)}
.mini{font-size:.78rem;color:var(--suave)}
.vacio{text-align:center;color:var(--suave);padding:2rem}
footer{text-align:center;color:var(--suave);font-size:.8rem;padding:1rem 0 2rem}
@media(max-width:700px){.fila{grid-template-columns:1fr}.ocultable{display:none}header{padding:1rem}}
</style>
</head>
<body>
<header>
  <div class="logo">CN</div>
  <div><h1>Portal CiberNova</h1><p>Incidencias del departamento de Sistemas y Ciberseguridad</p></div>
  <div class="estado"><span class="chip">Nodo web: {$nodo}</span>{$bd}</div>
</header>
<main>
{$cuerpo}
</main>
<footer>CiberNova Solutions · Intranet interna · Alta disponibilidad con Pacemaker (VIP 192.168.202.27) y SQL Server Always On</footer>
</body>
</html>
HTML;
}

$c = parse_ini_file('/etc/cibernova/web.ini');
try {
    $db = new PDO(
        "sqlsrv:Server={$c['servidor']};Database={$c['bbdd_portal']};Encrypt=yes;TrustServerCertificate=yes;LoginTimeout=5",
        $c['usuario'], $c['clave'], [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $ex) {
    error_log('Portal CiberNova: ' . $ex->getMessage());
    http_response_code(503);
    pagina('<div class="aviso error">La base de datos no está disponible en este momento. Si se está produciendo '
         . 'una conmutación, vuelve a cargar la página en unos segundos.</div>', e($nodo));
    exit;
}

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $accion = (string)($_POST['accion'] ?? '');
    if ($accion === 'nueva') {
        $titulo = trim((string)($_POST['titulo'] ?? ''));
        $desc = trim((string)($_POST['descripcion'] ?? ''));
        $sede = (string)($_POST['sede'] ?? '');
        $prio = (string)($_POST['prioridad'] ?? '');
        if (preg_match('/^.{1,150}$/su', $titulo) && preg_match('/^.{0,2000}$/su', $desc)
            && in_array($sede, $SEDES, true) && in_array($prio, $PRIORIDADES, true)) {
            $st = $db->prepare('INSERT INTO dbo.incidencias (titulo, descripcion, sede, prioridad, servidor_bd, nodo_web) '
                             . 'VALUES (?, ?, ?, ?, @@SERVERNAME, ?)');
            $st->execute([$titulo, $desc === '' ? null : $desc, $sede, $prio, $nodo]);
            header('Location: ./?ok=creada', true, 303);
            exit;
        }
        $error = 'Revisa los datos: el título es obligatorio (máximo 150 caracteres) y la descripción, de 2.000 como máximo.';
    } elseif ($accion === 'cerrar') {
        $id = filter_var($_POST['id'] ?? '', FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
        if ($id !== false) {
            $st = $db->prepare("UPDATE dbo.incidencias SET estado = N'Cerrada', cerrada = SYSDATETIME() WHERE id = ? AND estado = N'Abierta'");
            $st->execute([$id]);
        }
        header('Location: ./?ok=cerrada', true, 303);
        exit;
    }
}

$filas = $db->query("SELECT TOP 100 id, titulo, descripcion, sede, prioridad, estado, "
    . "CONVERT(varchar(16), creada, 120) AS creada, CONVERT(varchar(16), cerrada, 120) AS cerrada, servidor_bd, nodo_web "
    . "FROM dbo.incidencias ORDER BY CASE estado WHEN N'Abierta' THEN 0 ELSE 1 END, id DESC")->fetchAll(PDO::FETCH_ASSOC);
$t = $db->query("SELECT SUM(CASE WHEN estado = N'Abierta' THEN 1 ELSE 0 END) AS abiertas, "
    . "SUM(CASE WHEN estado = N'Cerrada' THEN 1 ELSE 0 END) AS cerradas, "
    . "SUM(CASE WHEN estado = N'Abierta' AND prioridad = N'Alta' THEN 1 ELSE 0 END) AS altas FROM dbo.incidencias")->fetch(PDO::FETCH_ASSOC);
$principal = (string)$db->query('SELECT @@SERVERNAME')->fetchColumn();

$html = '';
$ok = (string)($_GET['ok'] ?? '');
if ($ok === 'creada') { $html .= '<div class="aviso ok">Incidencia registrada correctamente.</div>'; }
if ($ok === 'cerrada') { $html .= '<div class="aviso ok">Incidencia cerrada.</div>'; }
if ($error !== '') { $html .= '<div class="aviso error">' . e($error) . '</div>'; }

$html .= '<section class="resumen">'
       . '<div class="dato abiertas"><b>' . (int)$t['abiertas'] . '</b><span>Incidencias abiertas</span></div>'
       . '<div class="dato alta"><b>' . (int)$t['altas'] . '</b><span>Abiertas de prioridad alta</span></div>'
       . '<div class="dato cerradas"><b>' . (int)$t['cerradas'] . '</b><span>Incidencias cerradas</span></div>'
       . '</section>';

$opc = fn(array $l) => implode('', array_map(fn($v) => '<option>' . e($v) . '</option>', $l));
$html .= '<section class="tarjeta"><h2>Nueva incidencia</h2><form method="post">'
       . '<input type="hidden" name="accion" value="nueva">'
       . '<div class="fila"><div><label for="titulo">Título</label>'
       . '<input type="text" id="titulo" name="titulo" maxlength="150" required placeholder="Ej.: La impresora de Madrid no imprime"></div>'
       . '<div><label for="sede">Sede</label><select id="sede" name="sede">' . $opc($SEDES) . '</select></div>'
       . '<div><label for="prioridad">Prioridad</label><select id="prioridad" name="prioridad">' . $opc($PRIORIDADES) . '</select></div></div>'
       . '<div style="margin-top:.9rem"><label for="descripcion">Descripción</label>'
       . '<textarea id="descripcion" name="descripcion" maxlength="2000" placeholder="Qué ocurre, desde cuándo y a quién afecta"></textarea></div>'
       . '<div class="acciones"><button class="principal" type="submit">Registrar incidencia</button></div>'
       . '</form></section>';

$html .= '<section class="tarjeta"><h2>Incidencias</h2><table><thead><tr><th>#</th><th>Incidencia</th><th>Sede</th>'
       . '<th>Prioridad</th><th>Estado</th><th class="ocultable">Fechas</th><th class="ocultable">Guardada en</th><th></th></tr></thead><tbody>';
foreach ($filas as $f) {
    $cerrar = $f['estado'] === 'Abierta'
        ? '<form method="post"><input type="hidden" name="accion" value="cerrar"><input type="hidden" name="id" value="'
          . (int)$f['id'] . '"><button class="cerrar" type="submit">Cerrar</button></form>'
        : '';
    $fechas = 'Abierta: ' . e($f['creada']) . ($f['cerrada'] ? '<br>Cerrada: ' . e($f['cerrada']) : '');
    $html .= '<tr class="' . e($f['estado']) . '"><td class="mini">' . (int)$f['id'] . '</td>'
           . '<td><div class="titulo">' . e($f['titulo']) . '</div>'
           . ($f['descripcion'] ? '<div class="desc">' . nl2br(e($f['descripcion'])) . '</div>' : '') . '</td>'
           . '<td>' . e($f['sede']) . '</td>'
           . '<td><span class="etq ' . e($f['prioridad']) . '">' . e($f['prioridad']) . '</span></td>'
           . '<td><span class="etq ' . e($f['estado']) . '">' . e($f['estado']) . '</span></td>'
           . '<td class="mini ocultable">' . $fechas . '</td>'
           . '<td class="mini ocultable">BD: ' . e($f['servidor_bd']) . '<br>Web: ' . e($f['nodo_web']) . '</td>'
           . '<td>' . $cerrar . '</td></tr>';
}
if (!$filas) { $html .= '<tr><td colspan="8" class="vacio">No hay incidencias registradas.</td></tr>'; }
$html .= '</tbody></table></section>';

pagina($html, e($nodo), $principal);
