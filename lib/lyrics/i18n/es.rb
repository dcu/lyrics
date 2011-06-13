cli.usage = Uso: %1 [OPCIONES]
cli.description = Busca letras en varios sitios y/o sube letras a Lyriki y LyricWiki.
cli.values.true = verdadero
cli.values.false = falso
cli.options = Opciones:
cli.options.artist = Artista de canción (obligatorio a menos que se especifique %1).
cli.options.title = Título de canción (obligatorio a menos que se especifique %1).
cli.options.album = Álbum de canción.
cli.options.year = Año del álbum.
cli.options.featfix = Corregir artista/título cuando el último contiene "feat. ARTIST" (%1 por defecto).
cli.options.batchfile = Archivo de proceso por lotes (espera entradas artista;título;álbum;año en cada línea).
cli.options.cleanup = Corregir formato de letras encontradas (%1 por defecto).
cli.options.sites = Sitios en que se buscarán las letras, orden incluido (%1 por defecto; ver %2).
cli.options.sites.list = Listar sitios disponibles.
cli.options.sites.list.available = Sitios disponibles:
cli.options.submit = Sitio wiki al cual se subirán contenidos (requiere %1 y %2).
cli.options.username = Usuario (obligatorio si %1 es especificado).
cli.options.password = Password (obligatorio si %1 es especificado).
cli.options.persist = Restaurar/salvar sesión desde y a archivo (requiere %1 y %2)
cli.options.prompt.review = Revisar contenidos antes de enviar (%1 por defecto, requiere %2).
cli.options.prompt.autogen = Revisar páginas marcadas como auto-generadas (%1 por defecto, requiere %2).
cli.options.prompt.nolyrics = Mostrar diálogo para enviar aún si no se encontraron letras (%1 por defecto, requiere %2).
cli.options.proxy = URL de servidor proxy.
cli.options.toolkits = Prioridad de toolkits gráficos. La carga continúa con el próximo toolkit si uno falla; una lista vacía causa que no se muestren diálogos y que el contenido sea imprimido en la salida estándar (%1 por defecto).
cli.options.help = Mostrar este mensaje y salir.
cli.options.version = Mostrar versión y salir.
cli.error.missingoption = %1 no especificado
cli.error.missingdependency = %1 requiere %1
cli.error.incompatibleoptions = %1 no permite %2
cli.error.invalidoptionvalue = valor para %1 inválido: %2
cli.error.nosite = debe proveer al menos un sitio
cli.error.notoolkit = debe proveer al menos un toolkit gráfico para usar el modo de revisión

cli.application.searchinglyrics = buscando letras para %1 por %2...
cli.application.lyricsfound = letras para %1 por %2 encontradas en %3
cli.application.nolyricsfound = no se encontraron letras para %1 por %2
cli.application.plugintimeout = la solicitud a %1 ha expirado, el sitio %2 probablemente esté caído
cli.application.batchmode = operando en modo batch
cli.application.processedcount = %1 archivos procesados

amarok.application.error.connectionrefused = Fallo al conectarse a Internet (verifique las opciones de proxy)
amarok.application.error.connectiondown = La conexión está caída, saliendo
amarok.application.error.notoolkit = Lo sentimos...\nNecesita QtRuby, RubyGTK o TkRuby para ejecutar este programa
amarok.application.error.nopluginsselected = No se seleccionaron sitios para buscar letras
amarok.application.search.current = Buscar letras de canción en reproducción
amarok.application.search.current.nosongplaying = no hay ninguna canción en reproducción
amarok.application.search.selected = Buscar letras de canción seleccionada
amarok.application.search.noinfofound = no se encontró información sobre la canción en la base de datos de Amarok
amarok.application.search.nolyricsfound = no se encontraron letras para <b>%1</b> por <b>%2</b>
amarok.application.search.plugintimeout = ¡La solicitud a %1 ha expirado! El sitio %2 probablemente esté caído
amarok.application.clearlyricscache = Limpiar caché de letras
amarok.application.clearlyricscache.confirm = ¿Está seguro de que desea limpiar el cache de letras?
amarok.application.clearlyricscache.done = caché de letras limpiado

amarok.wikiplugin.checksong = Verificar/Enviar canción
amarok.wikiplugin.checksong.noinfofound = no se encontró información de la canción en la base de datos de Amarok
amarok.wikiplugin.checkalbum = Verificar/Enviar álbum
amarok.wikiplugin.checkalbum.noinfofound = no se encontró información del álbum en la base de datos de Amarok
amarok.wikiplugin.uploadcover = Subir carátula de álbum
amarok.wikiplugin.uploadcover.invalidalbumparams = parámetros inválidos de álbum recibidos
amarok.wikiplugin.uploadcover.noimagepath = ruta a imagen de carátula no recibida
amarok.wikiplugin.uploadcover.searching = buscando carátula para el álbum <b>%1</b> por <b>%2</b>...
amarok.wikiplugin.uploadcover.found = carátula encontrada (no es necesario subirla)
amarok.wikiplugin.submitcontent = Enviar contenidos

gui.common.cut = Cortar
gui.common.copy = Copiar
gui.common.paste = Pegar
gui.common.delete = Eliminar
gui.common.selectall = Seleccionar Todo
gui.common.undo = Deshacer
gui.common.redo = Rehacer

gui.common.accept = Aceptar
gui.common.cancel = Cancelar
gui.common.submit = Enviar
gui.common.load = Cargar
gui.common.fix = Reparar
gui.common.url = URL
gui.common.artist = Artista
gui.common.song = Canción
gui.common.album = Álbum
gui.common.year = Año
gui.common.month = Mes
gui.common.day = Día
gui.common.released = Fecha
gui.common.credits = Compositores
gui.common.lyricist = Autor
gui.common.image = Imagen
gui.common.reviewed = He revisado los contenidos del este formulario

gui.searchlyrics.title = Buscar letras
gui.searchlyrics.search = Opciones de búsqueda

gui.lyrics.title = Letras de %1 por %2

gui.pluginsmanager.title = Configuración de script %1
gui.pluginsmanager.sites = Sitios
gui.pluginsmanager.sites.inuse = En uso
gui.pluginsmanager.sites.available = Disponibles
gui.pluginsmanager.sites.moveup = Subir
gui.pluginsmanager.sites.movedown = Bajar
gui.pluginsmanager.sites.add = << Agregar
gui.pluginsmanager.sites.remove = >> Eliminar
gui.pluginsmanager.misc = Misceláneos
gui.pluginsmanager.misc.cleanup = Corregir formato de letras encontradas
gui.pluginsmanager.misc.singlethreaded = Usar un único hilo de ejecución para ahorrar batería (requiere reiniciar)
gui.pluginsmanager.misc.writelog = Guardar log en %1

gui.wikiplugin.title = Configurar opciones de %1
gui.wikiplugin.general = Opciones generales
gui.wikiplugin.general.submit = Enviar contenidos a %1
gui.wikiplugin.general.review = Solicitar revisión antes de enviar contenidos
gui.wikiplugin.general.autogen = Solicitar revisión de páginas marcadas como auto-generadas
gui.wikiplugin.general.nolyrics = Mostrar diálogo para enviar aún si no se encontraron letras
gui.wikiplugin.login = Opciones de conexión
gui.wikiplugin.login.username = Usuario
gui.wikiplugin.login.password = Contraseña

gui.submitsong.title.submit = %1 - Enviar página de canción
gui.submitsong.title.edit = %1 - Revisar página de canción
gui.submitsong.instrumental = La canción es instrumental

gui.submitalbum.title = %1 - Enviar página de álbum
gui.submitalbum.coverfound = (carátula encontrada, no es necesario subirla)

gui.uploadcover.title = %1 - Subir carátula de álbum
gui.uploadcover.imagepath = Ruta
gui.uploadcover.browseimage.title = Seleccione la imagen correspondiente a la carátula del álbum
gui.uploadcover.browseimage.images = Imágenes
gui.uploadcover.browseimage.allfiles = Todos los archivos

gui.fixpages.success = Página %1 envíada
gui.fixpages.error = Error enviando página %1

wiki.control.versionblocked = <b>La version %1 ha sido bloqueada</b> y no puede enviar contenidos. Por favor, actualize a la última versión.
wiki.control.userblocked = <b>El usuario %1 ha sido bloqueado</b> y no puede enviar contenidos. Por favor, revise su página de usuario.
wiki.control.updated = Una nueva versión del script ha sido liberada. <b>Por favor, actualize a la versión %1</b>.

wiki.login.attempt = iniciando sesión para usuario <b>%1</b>...
wiki.login.success = sesión iniciada con éxito para usuario <b>%1</b>
wiki.login.error = error iniciando sesión para usuario <b>%1</b>
wiki.logout = sesión finalizada para usuario <b>%1</b>

wiki.session.save.success = sesión de usuario <b>%1</b> salvada
wiki.session.save.error.notloggedin = no puede salvarse la sesión antes de conectarse
wiki.session.save.error = error salvando sesión de usuario <b>%1</b>
wiki.session.restore.success = sesión restaurada para usuario <b>%1</b>
wiki.session.restore.error = error restaurando session para usuario <b>%1</b>
wiki.session.restore.notfound = no se encontró ninguna sesión salvada

wiki.submitsong.searchingpage = buscando página para la canción <b>%1</b> por <b>%2</b>...
wiki.submitsong.pagefound = página encontrada para la canción <b>%1</b> por <b>%2</b>
wiki.submitsong.pagefound.autogenerated = página auto-generada encontrada para la canción <b>%1</b> por <b>%2</b>
wiki.submitsong.nopagefound = no se encontró página para la canción <b>%1</b> por <b>%2</b>
wiki.submitsong.cancelled = envío de página cancelado por usuario
wiki.submitsong.mustreviewcontent = los contenidos no fueron revisados, envío de página cancelado
wiki.submitsong.success = página para la canción <b>%1</b> por <b>%2</b> enviada con éxito
wiki.submitsong.error.invalidsong = el nombre de canción recibido es inválido
wiki.submitsong.error.invalidartist = el artista recibido es inválido
wiki.submitsong.error.nolyrics = no se recibieron letras que enviar
wiki.submitsong.error = se produjo un error enviando la página para la canción <b>%1</b> por <b>%2</b>

wiki.submitalbum.searchingpage = buscando página para el álbum <b>%1</b> por <b>%2</b>...
wiki.submitalbum.pagefound = página encontrada para el álbum <b>%1</b> por <b>%2</b>
wiki.submitalbum.nopagefound = no se encontró página para el álbum <b>%1</b> por <b>%2</b>
wiki.submitalbum.cancelled = envío de página cancelado por usuario
wiki.submitalbum.mustreviewcontent = los contenidos no fueron revisados, envío de página cancelado
wiki.submitalbum.success = página para el álbum <b>%1</b> por <b>%2</b> enviada con éxito
wiki.submitalbum.error.invalidyear = el año recibido es inválido
wiki.submitalbum.error.invalidalbum = el nombre de álbum recibido es inválido
wiki.submitalbum.error.invalidartist = el artista recibido es inválido
wiki.submitalbum.error = se produjo un error enviando la página para el álbum <b>%1</b> por <b>%2</b>

wiki.submitredirect.success = página de redireccionamiento a %1 enviada
wiki.submitredirect.error = se produjo un error enviando la página de redireccionamiento a %1

wiki.uploadcover.uploading = enviando carátula del álbum <b>%1</b> por <b>%2</b>
wiki.uploadcover.success = carátula del álbum <b>%1</b> por <b>%2</b> enviada con éxito
wiki.uploadcover.error.convert = se produjo un error convirtiendo la carátula al formato JPEG
wiki.uploadcover.error = se produjo un error enviando la carátula del álbum <b>%1</b> por <b>%2</b>
