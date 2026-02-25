import 'package:flutter/material.dart';
import '../servicos/IA.dart'; // Importe o arquivo que criamos acima!

class TelaAssistente extends StatefulWidget {
  final bool isAdmin;

  const TelaAssistente({super.key, this.isAdmin = false});

  @override
  State<TelaAssistente> createState() => _TelaAssistenteState();
}

class _TelaAssistenteState extends State<TelaAssistente> {
  final TextEditingController _controller = TextEditingController();
  final IaService _iaService = IaService();

  String _respostaIA = "Olá! Como posso ajudar você hoje?";
  bool _carregando = false;
  late Color _corPrincipal;

  @override
  void initState() {
    super.initState();
    // Define a cor principal com base no status de admin
    _corPrincipal = widget.isAdmin ? Colors.red[900]! : Colors.blue[900]!;
  }

  void _enviarPergunta() async {
    if (_controller.text.isEmpty) return;

    setState(() {
      _carregando = true;
      _respostaIA = "Pensando...";
    });

    // Chama o serviço de IA passando a pergunta e o status de admin do widget
    final resposta = await _iaService.perguntarParaIA(
      perguntaUsuario: _controller.text,
      isAdmin: widget.isAdmin,
    );

    setState(() {
      _respostaIA = resposta;
      _carregando = false;
    });

    _controller.clear(); // Limpa a caixa de texto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Mantendo o padrão do seu app
      appBar: AppBar(
        title: const Text('Assistente Virtual'),
        centerTitle: true,
        backgroundColor: _corPrincipal, // Cor dinâmica
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Caixa onde aparece a resposta
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Sua cor de card
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _respostaIA,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Caixa de digitar e botão de enviar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ex: Quais clientes atendi ontem?",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _corPrincipal, // Cor dinâmica
                  radius: 25,
                  child: _carregando
                      ? const CircularProgressIndicator(color: Colors.white)
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _enviarPergunta,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
