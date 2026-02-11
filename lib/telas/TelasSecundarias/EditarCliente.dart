import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../modelos/Cliente.dart';

// ==================================================
// TELA DE EDIÇÃO DE CLIENTE
// ==================================================
class EditarCliente extends StatefulWidget {
  final Cliente cliente;

  const EditarCliente({super.key, required this.cliente});

  @override
  State<EditarCliente> createState() => _EditarClienteState();
}

class _EditarClienteState extends State<EditarCliente> {
  // ==================================================
  // VARIÁVEIS DE ESTADO E CONTROLADORES
  // ==================================================

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late bool _isProblematico;

  // Controladores de Texto
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _ruaController;
  late TextEditingController _apartamentoController;
  late TextEditingController _numeroController;
  late TextEditingController _bairroController;
  late TextEditingController _cpfController;
  late TextEditingController _cnpjController;
  late TextEditingController _obsController;

  // ==================================================
  // MÁSCARAS DE FORMATAÇÃO
  // ==================================================

  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final maskCPF = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final maskCNPJ = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  /// Função para capitalizar a primeira letra de cada palavra
  String _formatarTexto(String texto) {
    if (texto.trim().isEmpty) return "";
    return texto
        .trim()
        .split(' ')
        .map((palavra) {
          if (palavra.isEmpty) return "";
          return "${palavra[0].toUpperCase()}${palavra.substring(1).toLowerCase()}";
        })
        .join(' ');
  }

  // ==================================================
  // CICLO DE VIDA (INIT & DISPOSE)
  // ==================================================
  @override
  void initState() {
    super.initState();
    // Preenche os controladores com os dados existentes do cliente
    _nomeController = TextEditingController(text: widget.cliente.nome);
    _ruaController = TextEditingController(text: widget.cliente.rua);
    _numeroController = TextEditingController(text: widget.cliente.numero);
    _apartamentoController = TextEditingController(
      text: widget.cliente.apartamento ?? '',
    );
    _bairroController = TextEditingController(text: widget.cliente.bairro);
    _obsController = TextEditingController(
      text: widget.cliente.observacao ?? '',
    );
    _isProblematico = widget.cliente.clienteProblematico;

    // Inicializa os controllers com os dados PUROS. O Formatter na UI vai aplicar a máscara.
    _telefoneController = TextEditingController(text: widget.cliente.telefone);
    _cpfController = TextEditingController(text: widget.cliente.cpf ?? '');
    _cnpjController = TextEditingController(text: widget.cliente.cnpj ?? '');
  }

  @override
  void dispose() {
    // Limpeza de memória dos controladores
    _nomeController.dispose();
    _telefoneController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _apartamentoController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE PERSISTÊNCIA (SUPABASE)
  // ==================================================

  Future<void> _salvarAlteracoes() async {
    // Valida o formulário antes de qualquer coisa
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. PREPARAÇÃO DOS DADOS
      final nomeFormatado = _formatarTexto(_nomeController.text);
      final ruaFormatada = _formatarTexto(_ruaController.text);
      final bairroFormatado = _formatarTexto(_bairroController.text);

      // Garante que o número não vá com espaços vazios
      final numeroFormatado = _numeroController.text.trim();

      // Opcional: Formatar apartamento se existir
      final aptoFormatado = _apartamentoController.text.isNotEmpty
          ? _formatarTexto(_apartamentoController.text)
          : null;

      // 2. ATUALIZA NO BANCO DE DADOS
      await Supabase.instance.client
          .from('clientes')
          .update({
            'nome': nomeFormatado,
            'rua': ruaFormatada,
            'bairro': bairroFormatado,
            'numero':
                numeroFormatado, // <--- CORREÇÃO: Usando a variável tratada
            'apartamento': aptoFormatado,
            'telefone': maskTelefone.unmaskText(_telefoneController.text),
            'cpf': _cpfController.text.isEmpty
                ? null
                : maskCPF.unmaskText(_cpfController.text),
            'cnpj': _cnpjController.text.isEmpty
                ? null
                : maskCNPJ.unmaskText(_cnpjController.text),
            'observacao': _obsController.text.trim(),
            'cliente_problematico': _isProblematico,
          })
          .eq('id', widget.cliente.id as Object);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        // Retorna true para a tela anterior recarregar a lista
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================================================
  // INTERFACE VISUAL (UI)
  // ==================================================

  @override
  Widget build(BuildContext context) {
    // Configuração de cores locais
    const Color corFundo = Colors.black;
    const Color corCard = Color(0xFF1E1E1E);
    const Color corTextoClaro = Colors.white;
    final Color corPrincipal = Colors.red[900]!;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text("Editar Cliente"),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- SEÇÃO: DADOS PESSOAIS E CONTATO ---
              _buildCard(
                corCard,
                corTextoClaro,
                Column(
                  children: [
                    _buildTextField(
                      controller: _nomeController,
                      label: "Nome Completo",
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _telefoneController,
                      label: "Telefone",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [maskTelefone],
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- RUA (Agora ocupa a largura total) ---
                    _buildTextField(
                      controller: _ruaController,
                      keyboardType: TextInputType.number,
                      label: 'Rua',
                      icon: Icons.add_road,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),

                    const SizedBox(height: 16),

                    // --- LINHA COM NÚMERO E APARTAMENTO ---
                    Row(
                      children: [
                        // Campo Número
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _numeroController,
                            keyboardType: TextInputType.number,
                            label: 'Nº',
                            icon: Icons.home_filled,
                            validator: (v) => v!.isEmpty ? 'Req.' : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Campo Apartamento [NOVO]
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _apartamentoController,
                            keyboardType: TextInputType.number,
                            label: 'Apt/Comp',
                            icon: Icons.apartment,
                            // Sem validador pois é opcional
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _bairroController,
                      label: "Bairro",
                      icon: Icons.location_city,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- SEÇÃO: DOCUMENTAÇÃO ---
              _buildCard(
                corCard,
                corTextoClaro,
                Column(
                  children: [
                    _buildTextField(
                      controller: _cpfController,
                      label: "CPF (Opcional)",
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskCPF],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cnpjController,
                      label: "CNPJ (Opcional)",
                      icon: Icons.domain,
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskCNPJ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- SEÇÃO: STATUS E OBSERVAÇÕES ---
              _buildCard(
                corCard,
                corTextoClaro,
                Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.redAccent,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        "Cliente Problemático?",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        "Marque se houver histórico de problemas",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _isProblematico,
                      onChanged: (val) => setState(() => _isProblematico = val),
                    ),
                    const Divider(color: Colors.white24),
                    _buildTextField(
                      controller: _obsController,
                      keyboardType: TextInputType.visiblePassword,
                      label: "Observações",
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- BOTÃO DE AÇÃO ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _salvarAlteracoes,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "SALVAR ALTERAÇÕES",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // WIDGETS AUXILIARES E COMPONENTES
  // ==================================================

  // Widget para agrupar campos visualmente (Container estilizado)
  Widget _buildCard(Color color, Color textColor, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  // Widget para padronizar TextFields e reduzir repetição de código
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blue[300]),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
    );
  }
}
