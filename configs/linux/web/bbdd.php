<?php
// Pagina de prueba de la cadena completa: VIP -> Apache -> PHP-FPM -> SQL Server (AG).
// Va en /var/www/html/bbdd.php de LNX01 y LNX02 (los dos iguales). 26/11/2026.
// Las credenciales estan en /etc/cibernova/web.ini (640 root:www-data), fuera de la carpeta web.
$c = parse_ini_file('/etc/cibernova/web.ini');
try {
    $db = new PDO("sqlsrv:Server={$c['servidor']};Database={$c['bbdd']};Encrypt=yes;TrustServerCertificate=yes", $c['usuario'], $c['clave']);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->exec("INSERT INTO dbo.prueba_ha (servidor) VALUES (@@SERVERNAME)");
    echo "Web servida por: " . gethostname() . "\n";
    echo "Ultimas filas en SQL Server:\n";
    foreach ($db->query("SELECT TOP 5 id, servidor, fecha FROM dbo.prueba_ha ORDER BY id DESC") as $f) {
        echo "{$f['id']} {$f['servidor']} {$f['fecha']}\n";
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo "Error de conexion con la base de datos\n";
    error_log($e->getMessage());
}
