cli.usage = Použitie: %1 [VOĽBY]
cli.description = Stiahni texty piesní z rôznych webových stránok a/alebo pošli texty na Lyriki a LyricWiki.
cli.values.true = pravda
cli.values.false = nepravda
cli.options = Voľby:
cli.options.artist = Interpret skladby (povinné, ak nie je zadané %1).
cli.options.title = Názov skladby (povinné, ak nie je zadané %1).
cli.options.album = Skladba z albumu.
cli.options.year = Rok vydania albumu.
cli.options.featfix = Opraviť interpreta/názov, keď je neskorší zapísaný ako "feat. ARTIST" (%1 je východzím nastavením).
cli.options.batchfile = Súbor s dávkou na spracovanie (očakáva v každom riadku položky interpret;názov;album;rok).
cli.options.cleanup = Prečistiť stiahnuté texty (%1 je východzím nastavením).
cli.options.sites = Stránky, na ktorých sa majú vyhľadávať texty, pri dodržaní poradia (%1 je východzím; viď %2).
cli.options.sites.list = Zoznam dostupných stránok.
cli.options.sites.list.available = Dostupné stránky:
cli.options.submit = Wiki stránky, na ktoré sa bude odosielať obsah (vyžaduje %1 a %2).
cli.options.username = Meno užívateľa, ktoré bude použité pre login (povinné, keď je zadané %1).
cli.options.password = Heslo, ktoré bude použité pre login (povinné, keď je zadané %1).
cli.options.persist = Obnoviť/uložiť sedenie zo/do súboru (vyžaduje %1 a %2).
cli.options.prompt.review = Výzva na kontrolu pred odoslaním obsahu (%1 je východzím nastavením, vyžaduje %2).
cli.options.prompt.autogen = Výzva na kontrolu automaticky generovaných stránok (%1 je východzím nastavením, vyžaduje %2).
cli.options.prompt.nolyrics = Výzva na odoslanie, aj keď nebol nájdený žiaden text na odoslanie (%1 je východzím nastavením, vyžaduje %2).
cli.options.proxy = URL proxy servera.
cli.options.toolkits = Priorita GUI toolkitov. Načítavanie pokračuje ďalším toolkitom, keď predchádzajúci zlyhá; prázdny zoznam spôsobí to, že sa nezobrazí žiaden dialóg a text skladby bude vypísaný na štandardný výstup (východzím nastavením je %1).
cli.options.help = Zobraziť túto správu a ukončiť.
cli.options.version = Zobraziť verziu a ukončiť.
cli.error.missingoption = chýba %1
cli.error.missingdependency = %1 vyžaduje %1
cli.error.incompatibleoptions = %1 nepovoľuje %2
cli.error.invalidoptionvalue = neplatná %1 hodnota: %2
cli.error.nosite = musí obsahovať aspoň jednu stránku
cli.error.notoolkit = musí obsahovať aspoň jeden toolkit pre použitie s režimom kontroly

cli.application.searchinglyrics = vyhľadávam text skladby %1 od %2...
cli.application.lyricsfound = text skladby %1 od %2 nájdený na %3
cli.application.nolyricsfound = nebol nájdený text skladby %1 od %2
cli.application.plugintimeout = požiadavka na %1 vypršala, stránka %2 je pravdepodobne mimo prevádzky
cli.application.batchmode = vykonávam operácie v dávkovom režime
cli.application.processedcount = %1 súborov spracovaných

amarok.application.error.connectionrefused = Nemôžem sa pripojiť na internet (skontrolujte nastavenia proxy)
amarok.application.error.connectiondown = Spojenie je mimo prevádzky, ukončujem
amarok.application.error.notoolkit = Ľutujem...\nNa spustenie programu potrebuje QtRuby, RubyGTK alebo TkRuby
amarok.application.error.nopluginsselected = Neboli špecifikované žiadne stránky pre vyhľadávanie textov
amarok.application.search.current = Hľadať text aktuálnej skladby
amarok.application.search.current.nosongplaying = momentálne nie je prehrávaná žiadna skladba
amarok.application.search.selected = Hľadať text vybranej piesne
amarok.application.search.noinfofound = v databázy Amaroku neboli nájdené informácie o skladbe
amarok.application.search.nolyricsfound = nebol nájdený text skladby <b>%1</b> od <b>%2</b>
amarok.application.search.plugintimeout = požiadavka na %1 vypršala! Stránka %2 je pravdepodobne mimo prevádzky
amarok.application.clearlyricscache = Vymazať cache pre texty
amarok.application.clearlyricscache.confirm = Určite chcete vymazať cache textov piesní?
amarok.application.clearlyricscache.done = cache textov piesní vymazaná

amarok.wikiplugin.checksong = Skontrolovať/Odoslať stránku so skladbou
amarok.wikiplugin.checksong.noinfofound = v databázy Amaroku neboli nájdené informácie o piesni
amarok.wikiplugin.checkalbum = Skontrolovať/Odoslať stránku s albumom
amarok.wikiplugin.checkalbum.noinfofound = v Amarok databázy neboli nájdené informácie o albume
amarok.wikiplugin.uploadcover = Uploadovať obal albumu
amarok.wikiplugin.uploadcover.invalidalbumparams = prijaté neplatné parametre pre album
amarok.wikiplugin.uploadcover.noimagepath = neboli prijaté žiadne obrázky obalu
amarok.wikiplugin.uploadcover.searching = hľadám obal albumu <b>%1</b> od <b>%2</b>...
amarok.wikiplugin.uploadcover.found = bol nájdený obal albumu (nie je potreba ho uploadovať)
amarok.wikiplugin.submitcontent =

gui.common.cut = Vystrihnúť
gui.common.copy = Kopírovať
gui.common.paste = Vložiť
gui.common.delete = Vymazať
gui.common.selectall = Vybrať všetko
gui.common.undo = Vrátiť sa
gui.common.redo = Odvolať vrátené

gui.common.accept = Prijať
gui.common.cancel = Zrušiť
gui.common.submit = Odoslať
gui.common.load = Načítať
gui.common.fix = Opraviť
gui.common.url = URL
gui.common.artist = Interpret
gui.common.song = Pieseň
gui.common.album = Album
gui.common.year = Rok
gui.common.month = Mesiac
gui.common.day = Deň
gui.common.released = Vydaný
gui.common.credits = Zásluhy
gui.common.lyricist = Autor textu
gui.common.image = Obrázok
gui.common.reviewed =

gui.searchlyrics.title = Hľadať text piesne
gui.searchlyrics.search = Nastavenie hľadania

gui.lyrics.title = Text %1 od %2

gui.pluginsmanager.title = %1 nastavenie skriptu
gui.pluginsmanager.sites = Stránky
gui.pluginsmanager.sites.inuse = Momentálne používané
gui.pluginsmanager.sites.available = Dostupné
gui.pluginsmanager.sites.moveup = Presunúť vyššie
gui.pluginsmanager.sites.movedown = Presunúť nižšie
gui.pluginsmanager.sites.add = << Pridať
gui.pluginsmanager.sites.remove = >> Odstrániť
gui.pluginsmanager.misc = Rôzne
gui.pluginsmanager.misc.cleanup = Prečistiť stiahnuté texty
gui.pluginsmanager.misc.writelog = Zapísať log do %1

gui.wikiplugin.title = Konfigurovať %1 nastavenia
gui.wikiplugin.general = Všeobecné nastavenia
gui.wikiplugin.general.submit = Odoslať obsah na %1
gui.wikiplugin.general.review = Výzva na kontrolu pred odoslaním obsahu
gui.wikiplugin.general.autogen = Upraviť stránky piesní označené ako automaticky generované
gui.wikiplugin.general.nolyrics = Zobraziť dialóg odoslania, aj keď nebol nájdený žiaden text piesne
gui.wikiplugin.login = Nastavenia prihlásenia
gui.wikiplugin.login.username = Meno užívateľa
gui.wikiplugin.login.password = Heslo

gui.submitsong.title.submit = %1 - Odoslať stránku piesne
gui.submitsong.title.edit = %1 - Upraviť stránku piesne
gui.submitsong.instrumental = Inštrumentálna

gui.submitalbum.title = %1 - Odoslať stránku albumu
gui.submitalbum.coverfound = (obal nájdený, nie je treba ho uploadovať)

gui.uploadcover.title = %1 - Uploadovať obal albumu
gui.uploadcover.imagepath = Cesta
gui.uploadcover.browseimage.title = Vyberte cestu k obalom albumov
gui.uploadcover.browseimage.images = Obrázky
gui.uploadcover.browseimage.allfiles = Všetky súbory

gui.fixpages.success = Stránka %1 odoslaná
gui.fixpages.error = Chyba pri odosielaní stránky %1

wiki.login.attempt = prihlasujem sa ako užívateľ <b>%1</b>...
wiki.login.success = úspešne prihlásený ako užívateľ <b>%1</b>
wiki.login.error = chyba pri prihlasovaní užívateľa <b>%1</b>
wiki.logout =

wiki.session.save.success = sedenie uložené pre užívateľa <b>%1</b>
wiki.session.save.error.notloggedin = nemôžem uložiť sedenie pred prihlásením sa
wiki.session.save.error = nastala chyba pri ukladaní sedenia užívateľa <b>%1</b>
wiki.session.restore.success = sedenie pre užívateľa <b>%1</b> obnovené
wiki.session.restore.error = nastala chyba pri obnovovaní sedenia užívateľa <b>%1</b>
wiki.session.restore.notfound = neboli nájdené žiadne uložené sedenia

wiki.submitsong.searchingpage = hľadám stránku s piesňou <b>%1</b> od <b>%2</b>...
wiki.submitsong.pagefound = stránka s piesňou <b>%1</b> od <b>%2</b> nájdená
wiki.submitsong.pagefound.autogenerated = automaticky generovaná stránka s piesňou <b>%1</b> od <b>%2</b> nájdená
wiki.submitsong.nopagefound = nebola nájdená stránka s piesňou <b>%1</b> od <b>%2</b>
wiki.submitsong.cancelled = odosielanie stránky piesne bolo zrušené užívateľom
wiki.submitsong.success = úspešne odoslaná stránka piesne <b>%1</b> od <b>%2</b>
wiki.submitsong.error.invalidsong = prijaté neplatné meno pieseň
wiki.submitsong.error.invalidartist = prijaté neplatné interpret albumu
wiki.submitsong.error.nolyrics = nebol prijatý žiaden text na odoslanie
wiki.submitsong.error = nastala chyba pri odosielaní stránky piesne <b>%1</b> od <b>%2</b>

wiki.submitalbum.searchingpage = hľadám stránku s albumom <b>%1</b> od <b>%2</b>...
wiki.submitalbum.pagefound = stránka s albumom <b>%1</b> od <b>%2</b> nájdená
wiki.submitalbum.nopagefound = nebola nájdená stránka s albumom <b>%1</b> od <b>%2</b>
wiki.submitalbum.cancelled = odosielanie stránky albumu bolo zrušené užívateľom
wiki.submitalbum.success = úspešne odoslaná stránka albumu <b>%1</b> od <b>%2</b>
wiki.submitalbum.error.invalidyear = prijaté neplatné rok albumu
wiki.submitalbum.error.invalidalbum = prijaté neplatné meno albumu
wiki.submitalbum.error.invalidartist = prijaté neplatné interpret albumu
wiki.submitalbum.error = nastala chyba pri odosielaní stránky albumu <b>%1</b> od <b>%2</b>

wiki.submitredirect.success = odoslaná stránka s presmerovaním na %1
wiki.submitredirect.error = nastala chyba pri odosielaní stránky s presmerovaním na %1

wiki.uploadcover.uploading = uploadujem obal albumu <b>%1</b> od <b>%2</b>
wiki.uploadcover.success = úspešne uploadovaný obal albumu <b>%1</b> od <b>%2</b>
wiki.uploadcover.error.convert = nastala chyba počas konverzie obalu albumu do formátu JPEG
wiki.uploadcover.error = nastala chyba počas uploadu obalu albumu <b>%1</b> od <b>%2</b>
