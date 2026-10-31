# Regenera los .pw.toml de todo lo que hay en jars/ y corre packwiz refresh.
# Para mods nuevos: agrega el inicio de su nombre de archivo a $cliente o $servidor
# (todo lo que no este en esas listas queda como "both").

$usuario = "gmndz2184"
$repo    = "modpack"
$rama    = "main"

$cliente  = "chat_heads","Controlling","cwb-forge","embeddium","justzoom","konkrete","MouseTweaks","oculus","Searchables","skinlayers3d","sodiumdynamiclights","sodiumextras","sodiumoptionsapi","xaerominimap","xaeroworldmap"
$servidor = "SimpleBackups","TAB","Chunky","ftb-essentials","ftb-ranks"

Set-Location $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)
New-Item -ItemType Directory -Force -Path mods | Out-Null

$existentes = @{}
foreach ($f in Get-ChildItem mods -Filter *.pw.toml) {
  $c = Get-Content $f.FullName -Raw
  if ($c -match '(?m)^filename = "([^"]+)"') { $existentes[$matches[1]] = $f.FullName }
}

foreach ($jar in Get-ChildItem jars -Filter *.jar) {
  $archivo = $jar.Name

  if ($existentes.ContainsKey($archivo)) {
    $ruta = $existentes[$archivo]
    $c = Get-Content $ruta -Raw
    $side = "both"
    if ($c -match '(?m)^side = "([^"]+)"') { $side = $matches[1] }
    $nombre = $jar.BaseName
    if ($c -match '(?m)^name = "([^"]+)"') { $nombre = $matches[1] }
    $accion = "Rehecho"
  } else {
    $side = "both"
    foreach ($p in $cliente)  { if ($archivo -like "$p*") { $side = "client" } }
    foreach ($p in $servidor) { if ($archivo -like "$p*") { $side = "server" } }
    $nombre = $jar.BaseName
    $slug = ($nombre.ToLower() -replace '[^a-z0-9.+_-]','-')
    $ruta = Join-Path $PWD "mods\$slug.pw.toml"
    $accion = "Nuevo"
  }

  $hash = (Get-FileHash $jar.FullName -Algorithm SHA256).Hash.ToLower()
  $url = "https://raw.githubusercontent.com/$usuario/$repo/$rama/jars/" + [uri]::EscapeDataString($archivo)

  $texto = "name = `"$nombre`"`nfilename = `"$archivo`"`nside = `"$side`"`n`n[download]`nurl = `"$url`"`nhash-format = `"sha256`"`nhash = `"$hash`"`n"
  [System.IO.File]::WriteAllText($ruta, $texto, $utf8)
  Write-Host "$accion  $side  $archivo"
}

Write-Host ""
Write-Host "Corriendo packwiz refresh..."
packwiz refresh
Write-Host ""
Write-Host "Listo. Ahora haz Commit y Push en GitHub Desktop."