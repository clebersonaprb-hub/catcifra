import 'package:flutter/material.dart';
// import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CatCifraApp());
}

class CatCifraApp extends StatefulWidget {
  const CatCifraApp({super.key});

  @override
  State<CatCifraApp> createState() => _CatCifraAppState();
}

class _CatCifraAppState extends State<CatCifraApp> {
  bool modoEscuro = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CatCifra',
      theme: modoEscuro ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(
        modoEscuro: modoEscuro,
        onToggleTheme: () {
          setState(() {
            modoEscuro = !modoEscuro;
          });
        },
      ),
    );
  }
}

// ================= MODEL =================
class Musica {
  final String titulo;
  final String referencia;
  final String tema;
  final String youtube;
  final String conteudo;

  Musica({
    required this.titulo,
    required this.referencia,
    required this.tema,
    required this.youtube,
    required this.conteudo,
  });
}

class Playlist {
  String nome;
  List<Musica> musicas;

  Playlist({
    required this.nome,
    required this.musicas,
  });
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  final bool modoEscuro;
  final VoidCallback onToggleTheme;

  const HomePage({
    super.key,
    required this.modoEscuro,
    required this.onToggleTheme,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool sidebarAberta = true;
  double fonte = 12;
  String busca = "";

  bool modoCatalogo = false;

  late Playlist playlistAtual;

  final List<Musica> todasMusicas = [];

  final List<Playlist> playlists = [
    Playlist(
      nome: "Missa",
      musicas: [
        Musica(
          titulo: "Parabéns Pra Você",
          referencia: "Popular",
          tema: "Festas",
          youtube: "",
          conteudo: """
G          D
Parabéns pra você

C
Muitas felicidades
""",
        ),
        Musica(
          titulo: "Aclamação",
          referencia: "Aclamação",
          tema: "Missa",
          youtube: "",
          conteudo: """
G            D
Aleluia aleluia

Em           C
Aleluia aleluia
""",
        ),
      ],
    ),
  ];

// ================= SALVAR DADOS =================
  
Future<void> salvarDados() async {
  final prefs = await SharedPreferences.getInstance();

  final listaJson = todasMusicas.map((m) => {
        'titulo': m.titulo,
        'referencia': m.referencia,
        'tema': m.tema,
        'youtube': m.youtube,
        'conteudo': m.conteudo,
      }).toList();

  await prefs.setString('musicas', jsonEncode(listaJson));
}

// ================= CARREGAR DADOS =================

Future<void> carregarDados() async {
  final prefs = await SharedPreferences.getInstance();

  final data = prefs.getString('musicas');

  if (data != null) {
    final lista = jsonDecode(data);

    setState(() {
      todasMusicas.clear();

      for (var m in lista) {
        todasMusicas.add(
          Musica(
            titulo: m['titulo'],
            referencia: m['referencia'],
            tema: m['tema'],
            youtube: m['youtube'],
            conteudo: m['conteudo'],
          ),
        );
      }
    });
  }
}

  // ================= IMPORTAR TXT =================

  Future<void> importarTxt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      final file = result.files.first;

      
      final conteudo = file.bytes != null
          ? utf8.decode(file.bytes!, allowMalformed: true)
          : "";




      print(conteudo);

                final linhas = conteudo.split("\n");

          String titulo = "";
          String referencia = "";
          String conteudoFinal = "";

          if (linhas.isNotEmpty) {
            titulo = linhas[0].trim();
          }

          if (linhas.length > 1) {
            referencia = linhas[1].trim();
          }

          conteudoFinal = linhas.skip(2).join("\n");

          final musicaEditada = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditarMusicaPage(
                musica: Musica(
                  titulo: titulo,
                  referencia: referencia,
                  tema: "Importado",
                  youtube: "",
                  conteudo: conteudoFinal,
                ),
              ),
            ),
          );

          if (musicaEditada != null) {

            
          String normalizar(String texto) {
            return texto
                .toLowerCase()
                .trim()
                .replaceAll(RegExp(r'\s+'), ' '); // remove espaços duplicados
          }

          final jaExiste = todasMusicas.any((m) =>
              normalizar(m.titulo) == normalizar(musicaEditada.titulo));


            if (jaExiste) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                content: Text("A música '${musicaEditada.titulo}' já existe no catalago."),
                ),
              );
              return;
            }

            setState(() {
              todasMusicas.add(musicaEditada); // ✅ só catálogo
              musicaSelecionada = musicaEditada;
            });
          }


    }
  }

// ================= IMPORTAR BACKUP =================
  Future<void> importarBackupTxt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null) {
      final file = result.files.first;

      String conteudo =
          file.bytes != null ? String.fromCharCodes(file.bytes!) : "";

      List<String> blocos = conteudo.split("===MUSICA===");

      List<Musica> novas = [];

      for (var b in blocos) {
        if (b.trim().isEmpty) continue;

        String titulo = "";
        String tema = "";
        String conteudoMusica = "";

        List<String> linhas = b.split("\n");

        for (var linha in linhas) {
          if (linha.startsWith("titulo:")) {
            titulo = linha.replaceFirst("titulo:", "").trim();
          } else if (linha.startsWith("tema:")) {
            tema = linha.replaceFirst("tema:", "").trim();
          } else {
            conteudoMusica += linha + "\n";
          }
        }
        if (titulo.isNotEmpty) {
          novas.add(
            Musica(
              titulo: titulo,
              referencia: "",
              tema: tema,
              youtube: "",
              conteudo: conteudoMusica,
            ),
          );
        }
      }

      setState(() {
        
        todasMusicas.addAll(novas);
        playlistAtual.musicas.addAll(novas);

        if (novas.isNotEmpty) {
          musicaSelecionada = novas.first;
        }
      });
    }
  }

  final List<Musica> musicas = [
    Musica(
      titulo: "Parabéns Pra Você",
      referencia: "Popular",
      tema: "Festas",
      youtube: "https://youtube.com",
      conteudo: """

 G              D
Parabéns pra você

      D7      G
Nesta data querida

 C
Muitas felicidades

 G       D      G
Muitos anos de vida
""",
    ),
    Musica(
      titulo: "Aclamação",
      referencia: "Aclamação",
      tema: "Missa",
      youtube: "",
      conteudo: """

 G            D
Aleluia aleluia

 Em           C
Aleluia aleluia
""",
    ),
  ];

  Musica? musicaSelecionada;

  @override
  void initState() {
    super.initState();

    playlistAtual = playlists.first;

    if (playlistAtual.musicas.isNotEmpty) {
      musicaSelecionada = playlistAtual.musicas.first;
    }
  }

  Widget botaoControl({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: child,
      ),
    );
  }
  
        bool ehLinhaDeAcordes(String linha) {
          if (linha.trim().isEmpty) return false;

          final acordes = linha.trim().split(RegExp(r'\s+'));

          final regexAcorde = RegExp(
            r'^[A-G](#|b)?(m|maj|min|sus|dim|aug|add)?[0-9°+\-/()]*$'
          );

          // precisa ter pelo menos 2 acordes válidos
          int validos = acordes.where((a) => regexAcorde.hasMatch(a)).length;

          return validos >= 2;
        }

  Widget renderizarLinha(String linha) {
    if (linha.trim().isEmpty) {
      return SizedBox(height: fonte * 0.8);
    }

    bool ehCifra = ehLinhaDeAcordes(linha);

    return Text(
      linha,
      style: TextStyle(
        fontFamily: "monospace",
        fontSize: fonte,
        height: ehCifra ? 1.0 : 1.2,
        color: ehCifra
            ? (widget.modoEscuro ? Colors.amber : Colors.blue)
            : (widget.modoEscuro ? Colors.white : Colors.black),
        fontWeight: ehCifra ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    
final listaBase = modoCatalogo
      ? todasMusicas
      : playlistAtual.musicas;

  final listaFiltrada = listaBase.where((m) {
    if (busca.isEmpty) return true;

    final texto = busca.toLowerCase();

    return m.titulo.toLowerCase().contains(texto) ||
           m.referencia.toLowerCase().contains(texto) ||
           m.tema.toLowerCase().contains(texto);
  }).toList();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // ================= SIDEBAR =================
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: sidebarAberta ? 180 : 0,
                    color: const Color(0xFF181818),
                    child: sidebarAberta
                        ? Column(
                            children: [
                              // MENU
                              Container(
                                height: 26,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.add,
                                              size: 18, color: Colors.white),
                                          onPressed: () {
                                            // SE ESTIVER NO CATÁLOGO
                                            if (modoCatalogo) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      OpcoesInsercaoPage(
                                                    onImportarTxt: importarTxt,
                                                    onImportarBackup:
                                                        importarBackupTxt,
                                                    onAdicionarManual:
                                                        (musica) {
                                                      setState(() {
                                                        todasMusicas
                                                            .add(musica);
                                                        musicaSelecionada =
                                                            musica;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
                                            // SE ESTIVER NA PLAYLIST
                                            else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      SelecionarMusicaPage(
                                                    todasMusicas: todasMusicas,
                                                    onSelecionar: (musica) {
                                                      setState(() {
                                                        playlistAtual.musicas
                                                            .add(musica);
                                                      });
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.label,
                                              size: 18, color: Colors.white),
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.queue_music,
                                          size: 18, color: Colors.white),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),

                              // HEADER
                              Container(
                                height: 34,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Image.asset("assets/logo.png", height: 20),
                                    const SizedBox(width: 6),
                                    const Text(
                                      "CatCifra",
                                      style: TextStyle(
                                        fontFamily: "Garet",
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      modoCatalogo
                                          ? "Todas"
                                          : playlistAtual.nome,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz,
                                          size: 16, color: Colors.white70),
                                      onPressed: () {
                                        setState(() {
                                          modoCatalogo = !modoCatalogo;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // BUSCA
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                 
                                  onChanged: (value) {
                                    setState(() {
                                      busca = value;
                                    });
                                  },

                                  style: const TextStyle(
                                    color: Colors.white, // ✅ texto digitado
                                    fontSize: 10,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Buscar...",
                                    hintStyle: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white54,
                                    ),

                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 16,
                                      color: Colors.white54,
                                    ),

                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 2),

                                    constraints: const BoxConstraints(
                                      minHeight: 30,
                                      maxHeight: 30,
                                    ),

                                    filled: true,
                                    fillColor:
                                        const Color(0xFF2A2A2A), // ✅ FIXO

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),

// ✅ LISTA SIDEBAR GERAL (SEM ListTile)
                              Expanded(
                                child: ReorderableListView.builder(
                                  itemCount: listaFiltrada.length,
                                  
                                  onReorder: (oldIndex, newIndex) {
                                    if (modoCatalogo || busca.isNotEmpty)
                                      return;
                                  // 🔒 não reorganiza catálogo

                                    setState(() {
                                      if (newIndex > oldIndex) {
                                        newIndex -= 1;
                                      }

                                      final item = playlistAtual.musicas
                                          .removeAt(oldIndex);
                                      playlistAtual.musicas
                                          .insert(newIndex, item);
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    final musica = listaFiltrada[index];

                                    return Column(
                                      key: ValueKey("${musica.titulo}_$index"),
                                      children: [
                                        Dismissible(
                                          key: Key("${musica.titulo}_$index"),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                                right: 16),
                                            child: const Icon(Icons.delete,
                                                color: Colors.white),
                                          ),
                                          onDismissed: (direction) {
                                            setState(() {
                                              if (!modoCatalogo) {
                                                playlistAtual.musicas
                                                    .removeAt(index);
                                              }
                                            });
                                          },
                                          child: Container(
                                            color: musicaSelecionada == musica
                                                ? Colors.white.withAlpha(40)
                                                : Colors.transparent,
                                            child: ListTile(
                                              dense: true,
                                              visualDensity:
                                                  const VisualDensity(
                                                      vertical: -4),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              title: Text(
                                                musica.titulo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                musica.referencia,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 8,
                                                ),
                                              ),
                                              trailing:
                                                  ReorderableDragStartListener(
                                                index: index,
                                                child: const Icon(
                                                  Icons.drag_handle,
                                                  color: Colors.white54,
                                                ),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  musicaSelecionada = musica;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const Divider(
                                          height: 1,
                                          thickness: 0.6,
                                          indent: 10,
                                          endIndent: 10,
                                          color: Colors.white12,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              Container(
                                height: 30,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.white12,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "${modoCatalogo ? todasMusicas.length : playlistAtual.musicas.length} músicas",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color.fromARGB(
                                        205, 255, 255, 255),
                                    fontFamily: "Garet",
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),

                  // MUSICA
                  Expanded(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (musicaSelecionada?.conteudo ?? "")
                              .split("\n")
                              .map(renderizarLinha)
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BARRA
            Container(
              height: 50,
              color: const Color(0xFF181818),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // MENU
                  botaoControl(
                    child:
                        const Icon(Icons.menu, size: 20, color: Colors.white),
                    onTap: () {
                      setState(() {
                        sidebarAberta = !sidebarAberta;
                      });
                    },
                  ),

                  // ✏️ EDITAR
                  botaoControl(
                    child:
                        const Icon(Icons.edit, size: 20, color: Colors.white),
                    onTap: () {},
                  ),

                  // A-
                  botaoControl(
                    child:
                        const Text("A−", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        fonte = (fonte - 2).clamp(12, 100);
                      });
                    },
                  ),

                  // A+
                  botaoControl(
                    child:
                        const Text("A+", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        fonte += 2;
                      });
                    },
                  ),

                  // TRANSPO
                  botaoControl(
                      child: const Text("♭",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {}),
                  botaoControl(
                      child: const Text("♯",
                          style: TextStyle(color: Colors.white)),
                      onTap: () {}),

                  // ✅ ✅ YOUTUBE (AQUI!!!)
                  if (musicaSelecionada != null &&
                      musicaSelecionada!.youtube.isNotEmpty)
                    botaoControl(
                      child: const Icon(
                        Icons.play_arrow,
                        size: 20,
                        color: Colors.white,
                      ),
                      onTap: () {},
                    ),

                  // DARK MODE
                  botaoControl(
                    child: Icon(
                      widget.modoEscuro ? Icons.dark_mode : Icons.light_mode,
                      size: 20,
                      color: Colors.white,
                    ),
                    onTap: widget.onToggleTheme,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class EditarMusicaPage extends StatefulWidget {
  final Musica? musica;

  const EditarMusicaPage({super.key, this.musica});

  @override
  State<EditarMusicaPage> createState() => _EditarMusicaPageState();
}

class _EditarMusicaPageState extends State<EditarMusicaPage> {
  final tituloController = TextEditingController();
  final referenciaController = TextEditingController();
  final temaController = TextEditingController();
  final youtubeController = TextEditingController();
  final conteudoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.musica != null) {
      tituloController.text = widget.musica!.titulo;
      referenciaController.text = widget.musica!.referencia;
      temaController.text = widget.musica!.tema;
      youtubeController.text = widget.musica!.youtube;
      conteudoController.text = widget.musica!.conteudo;
    }
  }

  Widget campo(String label, TextEditingController c) {
    return TextField(
      controller: c,
      style: const TextStyle(fontSize: 10),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        constraints: const BoxConstraints(
          minHeight: 28,
          maxHeight: 28,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent, width: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text("Nova Música", style: TextStyle(fontSize: 14)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              final novaMusica = Musica(
                titulo: tituloController.text,
                referencia: referenciaController.text,
                tema: temaController.text,
                youtube: youtubeController.text,
                conteudo: conteudoController.text,
              );

              Navigator.pop(context, novaMusica);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            campo("Título", tituloController),
            const SizedBox(height: 4),
            campo("Referência (Autor)", referenciaController),
            const SizedBox(height: 4),
            campo("Tema", temaController),
            const SizedBox(height: 4),
            campo("YouTube (opcional)", youtubeController),
            const SizedBox(height: 4),
            Expanded(
              child: TextField(
                controller: conteudoController,
                expands: true,
                maxLines: null,
                style: const TextStyle(
                  fontFamily: "monospace",
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  labelText: "Cifra / Letra",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            modoEscuro: true,
            onToggleTheme: () {},
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Image.asset(
          "assets/splash.png",
          width: 160,
        ),
      ),
    );
  }
}

class OpcoesInsercaoPage extends StatelessWidget {
  final VoidCallback onImportarTxt;
  final VoidCallback onImportarBackup;
  final Function(Musica) onAdicionarManual;

  const OpcoesInsercaoPage({
    super.key,
    required this.onImportarTxt,
    required this.onImportarBackup,
    required this.onAdicionarManual,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar Música"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // MANUAL
            ElevatedButton.icon(
              onPressed: () async {
                final novaMusica = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditarMusicaPage(),
                  ),
                );

                if (novaMusica != null) {
                  onAdicionarManual(novaMusica);
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text("Inserir Manual"),
            ),

            const SizedBox(height: 10),

            // TXT
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onImportarTxt();
              },
              icon: const Icon(Icons.upload_file),
              label: const Text("Importar TXT"),
            ),

            const SizedBox(height: 10),

            // BACKUP
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onImportarBackup();
              },
              icon: const Icon(Icons.folder),
              label: const Text("Importar Backup Completo"),
            ),

            const SizedBox(height: 10),

            // LINK (FUTURO)
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.link),
              label: const Text("Importar via Link"),
            ),
          ],
        ),
      ),
    );
  }
}

class SelecionarMusicaPage extends StatelessWidget {
  final List<Musica> todasMusicas;
  final Function(Musica) onSelecionar;

  const SelecionarMusicaPage({
    super.key,
    required this.todasMusicas,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adicionar à Playlist"),
      ),
      body: ListView.builder(
        itemCount: todasMusicas.length,
        itemBuilder: (context, index) {
          final musica = todasMusicas[index];

          return ListTile(
            title: Text(musica.titulo),
            subtitle: Text(musica.tema),
            onTap: () {
              onSelecionar(musica);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
