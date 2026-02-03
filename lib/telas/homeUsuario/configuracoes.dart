import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../servicos/servicos.dart';
import '../../../modelos/Usuario.dart';

class Configuracoes extends StatefulWidget {
  const Configuracoes({super.key});

  @override
  State<Configuracoes> createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {
  // ==================================================
  // ESTADO E VARIÁVEIS
  // ==================================================
  bool _isLoading = true;
  final String _myUserId = Supabase.instance.client.auth.currentUser!.id;

  Usuario? _meuUsuario;
  List<Usuario> _listaAdmins = [];
  List<Usuario> _listaEquipe = [];

  // Cores
  final Color corPrincipal = Colors.blue[900]!;
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
    _carregarDados();
  }

  // ==================================================
  // LÓGICA DE DADOS (SUPABASE)
  // ==================================================
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .order('nome', ascending: true);

      final List<Usuario> todosUsuarios = (response as List)
          .map((map) => Usuario.fromMap(map))
          .toList();

      Usuario? eu;
      try {
        eu = todosUsuarios.firstWhere((u) => u.id == _myUserId);
      } catch (e) {
        eu = null;
      }

      final admins = todosUsuarios
          .where((u) => u.isAdmin == true && u.id != _myUserId)
          .toList();

      final equipe = todosUsuarios
          .where((u) => u.isAdmin == false && u.id != _myUserId)
          .toList();

      if (mounted) {
        setState(() {
          _meuUsuario = eu;
          _listaAdmins = admins;
          _listaEquipe = equipe;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  Future<void> _atualizarMeuPerfil(String nome, String telefone) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'nome': nome, 'telefone': telefone})
          .eq('id', _myUserId);

      if (mounted) {
        setState(() {
          if (_meuUsuario != null) {
            _meuUsuario!.nome = nome;
            _meuUsuario!.telefone = telefone;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================================================
  // DIALOG DE EDIÇÃO
  // ==================================================
  void _mostrarDialogEditar() {
    if (_meuUsuario == null) return;

    final nomeController = TextEditingController(text: _meuUsuario!.nome);
    final telController = TextEditingController(text: _meuUsuario!.telefone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: corCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Editar Meus Dados',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nome Completo',
                labelStyle: TextStyle(color: corTextoCinza),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: corTextoCinza),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: corPrincipal),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: telController,
              inputFormatters: [maskTelefone],
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Telefone',
                labelStyle: TextStyle(color: corTextoCinza),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: corTextoCinza),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: corPrincipal),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _atualizarMeuPerfil(
              nomeController.text.trim(),
              telController.text.trim(),
            ),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // INTERFACE (UI)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Configurações",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("MEU PERFIL"),
                  const SizedBox(height: 10),
                  _buildMyProfileCard(),

                  const SizedBox(height: 30),

                  if (_listaAdmins.isNotEmpty) ...[
                    _buildSectionTitle("ADMINISTRADORES"),
                    const SizedBox(height: 10),
                    ..._listaAdmins.map((admin) => _buildUserTile(admin)),
                    const SizedBox(height: 24),
                  ],

                  if (_listaEquipe.isNotEmpty) ...[
                    _buildSectionTitle("EQUIPE"),
                    const SizedBox(height: 10),
                    ..._listaEquipe.map((user) => _buildUserTile(user)),
                  ],

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await Supabase.instance.client.auth.signOut();
                        navigator.pop();
                      },
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        "Sair da Conta",
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ==================================================
  // WIDGETS AUXILIARES
  // ==================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          color: corTextoCinza,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildMyProfileCard() {
    if (_meuUsuario == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: corPrincipal,
            child: Text(
              _getInitials(_meuUsuario!.nome),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _meuUsuario!.nome.isNotEmpty ? _meuUsuario!.nome : 'Sem Nome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _meuUsuario!.telefone.isNotEmpty
                      ? maskTelefone.maskText(_meuUsuario!.telefone)
                      : 'Sem Telefone',
                  style: TextStyle(color: corTextoCinza, fontSize: 14),
                ),
                Text(
                  _meuUsuario!.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _mostrarDialogEditar,
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            tooltip: "Editar Perfil",
            style: IconButton.styleFrom(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  // --- AQUI ESTÁ A IMPLEMENTAÇÃO QUE FALTAVA ---
  Widget _buildUserTile(Usuario user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2C2C2C),
          child: Text(
            _getInitials(user.nome),
            style: TextStyle(color: corTextoCinza, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.nome.isNotEmpty ? user.nome : 'Sem Nome',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
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
            // Botão Ligar (Chama o serviço criado)
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
            // Botão WhatsApp (Chama o serviço criado)
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

  String _getInitials(String nome) {
    if (nome.isEmpty) return "?";
    List<String> parts = nome.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
