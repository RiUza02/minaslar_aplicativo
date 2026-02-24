import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../modelos/Usuario.dart';
import '../criarConta/Login.dart';
import '../../servicos/servicos.dart';

class Configuracoes extends StatefulWidget {
  final bool isAdmin;

  const Configuracoes({super.key, required this.isAdmin});

  @override
  State<Configuracoes> createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {
  // ==================================================
  // ESTADO E VARIÁVEIS
  // ==================================================
  bool _isLoading = true;
  bool _semInternet = false;
  final String _myUserId = Supabase.instance.client.auth.currentUser!.id;

  Usuario? _meuUsuario;
  List<Usuario> _outrosUsuarios = []; // Lista para armazenar os contatos

  // Controladores para edição
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();

  // Cores
  late Color corPrincipal;
  final Color corFundo = const Color(0xFF121212);
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoCinza = Colors.grey[400]!;
  final Color corTextoBranco = Colors.white;

  // Formatador de Telefone
  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    // Define a cor principal com base no tipo de usuário
    corPrincipal = widget.isAdmin ? Colors.red[900]! : Colors.blue[900]!;
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE DADOS
  // ==================================================

  Future<void> _carregarDados() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _semInternet = false;
      });
    }

    if (!await Servicos.temConexao()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _semInternet = true;
        });
      }
      return;
    }
    try {
      final supabase = Supabase.instance.client;

      // 1. Busca TODOS os usuários ordenados por nome
      final response = await supabase.from('usuarios').select().order('nome');

      final List<dynamic> dados = response;
      final todosUsuarios = dados.map((map) => Usuario.fromMap(map)).toList();

      // 2. Separa "Eu" dos "Outros"
      final meuPerfil = todosUsuarios.firstWhere(
        (u) => u.id == _myUserId,
        orElse: () => todosUsuarios.first,
      );

      final outros = todosUsuarios.where((u) => u.id != _myUserId).toList();

      setState(() {
        _meuUsuario = meuPerfil;
        _outrosUsuarios = outros;

        // Preenche controladores
        _nomeController.text = meuPerfil.nome;
        _telefoneController.text = maskTelefone.maskText(meuPerfil.telefone);

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao carregar dados: $e")));
      }
    }
  }

  /// Salva as alterações do perfil
  Future<void> _salvarPerfil() async {
    if (_meuUsuario == null) return;

    final String nomeFinal = _nomeController.text.trim();
    final String telefoneFinal = maskTelefone.unmaskText(
      _telefoneController.text,
    );

    // Compara com os dados originais para ver se houve mudança
    if (nomeFinal == _meuUsuario!.nome &&
        telefoneFinal == _meuUsuario!.telefone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma alteração foi feita.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dadosParaEnvio = {'nome': nomeFinal, 'telefone': telefoneFinal};

      await Supabase.instance.client
          .from('usuarios')
          .update(dadosParaEnvio)
          .eq('id', _myUserId);

      if (mounted) {
        setState(() {
          _meuUsuario = _meuUsuario!.copyWith(
            nome: nomeFinal,
            telefone: telefoneFinal,
          );
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Perfil atualizado!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao atualizar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fazerLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  // ==================================================
  // UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Equipe & Perfil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: corPrincipal,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _fazerLogout,
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : _semInternet
          ? _semInternetWidget()
          : _buildContent(),
    );
  }

  Widget _semInternetWidget() {
    return RefreshIndicator(
      onRefresh: _carregarDados,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_outlined,
                  size: 80,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 16),
                Text(
                  "Sem conexão com a internet.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 1. ÁREA EDITÁVEL (EXPANSÍVEL)
        Container(
          color: corCard,
          child: ExpansionTile(
            collapsedIconColor: corPrincipal,
            iconColor: corPrincipal,
            leading: CircleAvatar(
              backgroundColor: corPrincipal.withValues(alpha: 0.2),
              child: Text(
                _getInitials(_meuUsuario?.nome ?? ""),
                style: TextStyle(
                  color: corPrincipal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              _meuUsuario?.nome ?? "Meu Perfil",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              "Toque para editar seus dados",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nomeController,
                      label: "Meu Nome",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _telefoneController,
                      label: "Meu Telefone",
                      icon: Icons.phone,
                      formatter: maskTelefone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corPrincipal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _salvarPerfil,
                        child: const Text(
                          "SALVAR MEUS DADOS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Divisor visual
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.group, color: corTextoCinza, size: 18),
              const SizedBox(width: 8),
              Text(
                "CONTATOS DO SISTEMA",
                style: TextStyle(
                  color: corTextoCinza,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                "${_outrosUsuarios.length} encontrados",
                style: TextStyle(color: corTextoCinza, fontSize: 12),
              ),
            ],
          ),
        ),

        // 2. CONTEÚDO PRINCIPAL: LISTA DE USUÁRIOS
        Expanded(
          child: _outrosUsuarios.isEmpty
              ? Center(
                  child: Text(
                    "Nenhum outro usuário encontrado.",
                    style: TextStyle(color: corTextoCinza),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _outrosUsuarios.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = _outrosUsuarios[index];
                    return _buildUserCard(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Usuario user) {
    return Container(
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: user.isAdmin
              ? Colors.amber.withValues(alpha: 0.2) // Destaque se for admin
              : Colors.blue.withValues(alpha: 0.2),
          child: Text(
            _getInitials(user.nome),
            style: TextStyle(
              color: user.isAdmin ? Colors.amber : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.isAdmin)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  "ADMIN",
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          user.telefone.isNotEmpty
              ? maskTelefone.maskText(user.telefone)
              : 'Sem telefone',
          style: TextStyle(color: corTextoCinza, fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botão Ligar
            if (user.telefone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.blueAccent),
                onPressed: () => Servicos.fazerLigacao(user.telefone),
                tooltip: "Ligar",
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                ),
              ),
            const SizedBox(width: 8),
            // Botão WhatsApp
            if (user.telefone.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.greenAccent),
                onPressed: () => Servicos.abrirWhatsApp(user.telefone),
                tooltip: "WhatsApp",
                style: IconButton.styleFrom(
                  backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputFormatter? formatter,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatter != null ? [formatter] : [],
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: corTextoCinza),
        prefixIcon: Icon(icon, color: corPrincipal),
        filled: true,
        fillColor: Colors.black26,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: corPrincipal),
        ),
      ),
    );
  }

  String _getInitials(String nome) {
    if (nome.isEmpty) return "?";
    List<String> parts = nome.trim().split(" ");
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return nome[0].toUpperCase();
  }
}
