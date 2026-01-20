import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para TextInputFormatter
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart'; // Import do pacote
import '../../modelos/Cliente.dart';

class EditarCliente extends StatefulWidget {
  final Cliente cliente;

  const EditarCliente({super.key, required this.cliente});

  @override
  State<EditarCliente> createState() => _EditarClienteState();
}

class _EditarClienteState extends State<EditarCliente> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores de Texto
  late TextEditingController _nomeController;
  late TextEditingController _telefoneController;
  late TextEditingController _enderecoController;
  late TextEditingController _cpfController;
  late TextEditingController _cnpjController;
  late TextEditingController _obsController;

  // Estado do switch
  late bool _isProblematico;

  // --- DEFINIÇÃO DAS MÁSCARAS ---
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

  @override
  void initState() {
    super.initState();
    // Inicializa os campos com os dados atuais
    _nomeController = TextEditingController(text: widget.cliente.nome);
    _enderecoController = TextEditingController(text: widget.cliente.endereco);

    _obsController = TextEditingController(
      text: widget.cliente.observacao ?? '',
    );
    _isProblematico = widget.cliente.clienteProblematico;

    // Inicializa aplicando a máscara caso o dado já exista no banco sem formatação
    // Se o banco já salva formatado, o maskText não estraga, ele apenas confirma.
    _telefoneController = TextEditingController(
      text: maskTelefone.maskText(widget.cliente.telefone),
    );

    _cpfController = TextEditingController(
      text: maskCPF.maskText(widget.cliente.cpf ?? ''),
    );

    _cnpjController = TextEditingController(
      text: maskCNPJ.maskText(widget.cliente.cnpj ?? ''),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Nota: Estamos salvando os dados FORMATADOS (com pontos e traços).
      // Se quiser salvar apenas números, use: maskCPF.getUnmaskedText()

      await Supabase.instance.client
          .from('clientes')
          .update({
            'nome': _nomeController.text.trim(),
            'telefone': _telefoneController.text.trim(),
            'endereco': _enderecoController.text.trim(),
            'cpf': _cpfController.text.isEmpty
                ? null
                : _cpfController.text.trim(),
            'cnpj': _cnpjController.text.isEmpty
                ? null
                : _cnpjController.text.trim(),
            'observacao': _obsController.text.trim(),
            'cliente_problematico': _isProblematico,
          })
          .eq('id', widget.cliente.id as Object);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente atualizado com sucesso!')),
        );
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

  @override
  Widget build(BuildContext context) {
    final Color corFundo = Colors.black;
    final Color corCard = const Color(0xFF1E1E1E);
    final Color corTextoClaro = Colors.white;
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
                    // TELEFONE COM MÁSCARA
                    _buildTextField(
                      controller: _telefoneController,
                      label: "Telefone",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [maskTelefone], // <--- AQUI
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _enderecoController,
                      label: "Endereço",
                      icon: Icons.location_on,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card de Documentos
              _buildCard(
                corCard,
                corTextoClaro,
                Column(
                  children: [
                    // CPF COM MÁSCARA
                    _buildTextField(
                      controller: _cpfController,
                      label: "CPF (Opcional)",
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskCPF], // <--- AQUI
                    ),
                    const SizedBox(height: 16),
                    // CNPJ COM MÁSCARA
                    _buildTextField(
                      controller: _cnpjController,
                      label: "CNPJ (Opcional)",
                      icon: Icons.domain,
                      keyboardType: TextInputType.number,
                      inputFormatters: [maskCNPJ], // <--- AQUI
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Card de Status e Obs
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
                      label: "Observações",
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

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

  // ATUALIZADO: Aceita inputFormatters
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters, // <--- Novo parâmetro
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters, // <--- Aplicando formatadores
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
