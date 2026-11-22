# Releases y versionado

TolochaTracks se distribuye **solo como APK** en GitHub Releases. Play Store queda
aplazada. El versionado y la publicación son automáticos al fusionar en `dev`.

## Ramas

- `main`: producción. Se actualiza con un PR `dev → main` cuando se quiere congelar una
  versión.
- `dev`: integración y destino de todos los PR. Cada fusión dispara el versionado.
- `feature/<tipo>-<id8>-<slug>`: rama opcional de un change con PR a `dev`.

## Formato de versión

Semver `X.Y.Z` y un número de build creciente en `pubspec.yaml`:

```yaml
version: 0.9.3+16
```

La versión se mantiene en `0.x` hasta que el usuario decida `1.0.0`. No se toca a mano
salvo decisión explícita; lo normal es dejar que `version.yml` haga el bump.

## Cálculo del bump

`version.yml` analiza los commits desde el último tag:

| Commit | Bump |
|---|---|
| `feat:` o change de tipo `feature` | **minor** |
| `fix:` o change de tipo `bug` | **patch** |
| `BREAKING CHANGE` o `!` | **major** |
| `infra:`, `docs:`, `refactor:`, `test:`, `chore:` | **patch** (salvo breaking) |

El script `scripts/bump.js` actualiza `pubspec.yaml` y `package.json`, crea el commit
`chore(release): vX.Y.Z` y el tag `vX.Y.Z`. Los commits que ya empiezan por
`chore(release)` no vuelven a disparar el proceso.

## Cadena de CI/CD

### `ci.yml`

Se ejecuta en PRs a `dev`/`main` y en push a `dev`:

- `scripts/check_changes.sh` y `scripts/check_openspec_config.sh`.
- `dart format`, `flutter analyze` y `flutter test` mediante `scripts/verificar.sh`.
- Commitlint en PRs.
- Build de comprobación del APK en push y en PRs que tocan código.

### `version.yml`

Se ejecuta en push a `dev`:

1. Comprueba que la CI del commit está en verde; sin CI verde no hay tag ni release.
2. Calcula el bump y ejecuta `node scripts/bump.js <bump>`.
3. Publica el commit y el tag en `dev`.
4. Llama a `release.yml`.

### `release.yml`

- Compila `flutter build apk --release`.
- Materializa el keystore desde los secretos `ANDROID_KEYSTORE_BASE64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` y `ANDROID_KEY_PASSWORD`.
- Publica `tolochatracks.apk` y su `sha256` en la release del tag.
- Los assets usan nombres estables para permitir enlaces de descarga directa.

## Firma local

Para compilar un APK de release en local se necesita `android/key.properties` y un
keystore fuera del repositorio:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=release.jks
```

`android/app/build.gradle.kts` usa esa configuración si existe; si no, compila con la
firma de debug. Nunca se commitean el keystore ni `key.properties`: están en `.gitignore`
y la copia de seguridad se guarda fuera del repositorio. Las actualizaciones se instalan
encima sin desinstalar mientras se mantenga la misma firma.

## Descarga

Enlace estable del último APK:

```
https://github.com/izquierdojl/tolochatracks/releases/latest/download/tolochatracks.apk
```

Al estar fuera de Play Store, Android pedirá permitir la instalación desde el navegador o
el gestor de archivos.

## OpenSpec y releases

La configuración personalizada de OpenSpec vive en `openspec/config.yaml` y está protegida
por el marcador `tolochatracks:config-personalizada` y por
`scripts/check_openspec_config.sh`. Si `openspec update` regenera los skills, las reglas
de release y la configuración se re-aplican desde `AGENTS.md` y ese archivo.
