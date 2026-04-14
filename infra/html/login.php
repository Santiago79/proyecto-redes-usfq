<?php
// login.php
// Conexión a la IP de tu contenedor base_datos
$conexion = new mysqli("172.20.20.10", "appuser", "apppass", "empresa");

if ($conexion->connect_error) {
    die("Error de conexión: " . $conexion->connect_error);
}

$usuario = $_POST['usuario'] ?? '';
$password = $_POST['password'] ?? '';

// LA INYECCIÓN: Concatenación directa sin preparar
$query = "SELECT * FROM usuarios WHERE user = '$usuario' AND pass = '$password'";
$resultado = $conexion->query($query);

?>
<!DOCTYPE html>
<html>
<head><title>Login - EmpresaX</title></head>
<body>
    <h2>Portal Administrativo EmpresaX</h2>
    
    <?php
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if ($resultado && $resultado->num_rows > 0) {
            echo "<h3 style='color: green;'>✅ Acceso Concedido. Bienvenido al sistema.</h3>";
            // Mostrar los datos robados para que el profe lo vea
            while($row = $resultado->fetch_assoc()) {
                echo "Datos extraídos -> ID: " . $row["id"]. " - Usuario: " . $row["user"]. " - Clave: " . $row["pass"]. "<br>";
            }
        } else {
            echo "<h3 style='color: red;'>❌ Acceso Denegado. Intruso detectado.</h3>";
        }
    }
    ?>

    <form method="POST" action="login.php">
        Usuario: <input type="text" name="usuario"><br><br>
        Clave: <input type="password" name="password"><br><br>
        <input type="submit" value="Entrar">
    </form>
</body>
</html>