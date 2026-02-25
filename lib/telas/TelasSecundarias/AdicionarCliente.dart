import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import '../../modelos/Cliente.dart';
import '../../servicos/servicos.dart';
import 'AdicionarOrcamento.dart';

class AdicionarCliente extends StatefulWidget {
  const AdicionarCliente({super.key});

  @override
  State<AdicionarCliente> createState() => _AdicionarClienteState();
}

class _AdicionarClienteState extends State<AdicionarCliente> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // ==================================================
  // CONFIGURAÇÕES E VARIÁVEIS DE ESTADO
  // ==================================================

  // Paleta de Cores
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;

  // Controladores de Texto
  final _nomeController = TextEditingController();
  final _ruaController = TextEditingController();
  final _apartamentoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _observacaoController = TextEditingController();

  // Estados de Controle Lógico
  bool _isPessoaFisica = true;
  bool _isProblematico = false;

  // ==================================================
  // FORMATADORES E MÁSCARAS
  // ==================================================
  final maskTelefone = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final maskCPF = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final maskCNPJ = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  /// Função auxiliar para transformar texto em "Title Case"
  /// Ex: "rua das flores" -> "Rua Das Flores"
  String _formatarTexto(String texto) {
    if (texto.trim().isEmpty) return "";

    // Separa por espaços, capitaliza a primeira letra de cada palavra e junta de volta
    return texto
        .trim()
        .split(' ')
        .map((palavra) {
          if (palavra.trim().isEmpty) return "";
          // Pega a primeira letra maiúscula + o resto minúsculo
          return "${palavra[0].toUpperCase()}${palavra.substring(1).toLowerCase()}";
        })
        .join(' ');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _apartamentoController.dispose();
    _bairroController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // ==================================================
  // NOVA FUNCIONALIDADE: IMPORTAÇÃO DE TEXTO
  // ==================================================
  void _mostrarModalImportacao() {
    final importarController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: corCard,
          title: Row(
            children: [
              Icon(Icons.paste, color: corSecundaria),
              const SizedBox(width: 10),
              const Text(
                "Importar Dados",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Cole o texto abaixo na seguinte ordem:\n1. Nome\n2. Telefone\n3. Rua\n4. Número\n5. Bairro",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: importarController,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  hintText: "Cole o texto aqui...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: corPrincipal),
              onPressed: () {
                _processarTextoImportado(importarController.text);
                Navigator.pop(context);
              },
              child: const Text(
                "Preencher Campos",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _processarTextoImportado(String texto) {
    if (texto.trim().isEmpty) return;

    // Separa as linhas e remove espaços em branco das pontas
    List<String> linhas = texto.split('\n').map((l) => l.trim()).toList();

    // =========================================================
    // ETAPA DE VALIDAÇÃO (Bloqueia se não for numérico)
    // =========================================================

    // 1. Validar Linha 2 (Telefone) - Index 1
    if (linhas.length > 1) {
      String linhaTel = linhas[1];
      // Verifica se contém alguma letra (a-z ou A-Z)
      bool temLetras = RegExp(r'[a-zA-Z]').hasMatch(linhaTel);

      if (temLetras) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Erro: A 2ª linha (Telefone) contém letras. Corrija para apenas números.",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Para a execução aqui, não preenche nada
      }
    }

    // 2. Validar Linha 4 (Número da Casa) - Index 3
    if (linhas.length > 3) {
      String linhaNum = linhas[3];
      // Verifica se a linha INTEIRA é composta apenas por dígitos (0 a 9)
      // Se tiver espaço, letra ou traço, retorna falso.
      bool soNumeros = RegExp(r'^[0-9]+$').hasMatch(linhaNum);

      if (!soNumeros) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Erro: A 4ª linha (Número) deve conter APENAS números (sem letras, espaços ou S/N).",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // Para a execução aqui
      }
    }

    // =========================================================
    // PREENCHIMENTO DOS CAMPOS (Só chega aqui se validou)
    // =========================================================
    setState(() {
      // Linha 1 - Nome
      if (linhas.isNotEmpty) _nomeController.text = linhas[0];

      // Linha 2 - Telefone
      if (linhas.length > 1) {
        String telLimpo = linhas[1].replaceAll(RegExp(r'[^0-9]'), '');
        if (telLimpo.length >= 10) {
          var mascaraAplicada = maskTelefone.maskText(telLimpo);
          _telefoneController.text = mascaraAplicada;
        } else {
          _telefoneController.text =
              telLimpo; // Cola o que tiver se for curto (mas sem letras)
        }
      }

      // Linha 3 - Rua
      if (linhas.length > 2) _ruaController.text = linhas[2];

      // Linha 4 - Número
      if (linhas.length > 3) _numeroController.text = linhas[3];

      // Linha 5 - Bairro
      if (linhas.length > 4) _bairroController.text = linhas[4];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Dados importados com sucesso!"),
        backgroundColor: Colors.green[800],
      ),
    );
  }

  // ==================================================
  // LÓGICA DE PERSISTÊNCIA (SUPABASE)
  // ==================================================
  Future<void> _salvarCliente() async {
    // 1. Validação do formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // 2. VERIFICAÇÃO DE DUPLICIDADE
    final clienteEncontrado = await Servicos.verificarClienteDuplicado(
      nome: _nomeController.text,
      rua: _ruaController.text,
      numero: _numeroController.text,
    );

    // Se encontrou um cliente parecido, mostra o diálogo de opções
    if (clienteEncontrado != null) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarDialogoClienteDuplicado(clienteEncontrado);
      }
    } else {
      // Se não encontrou, prossegue com a criação normal
      await _criarNovoCliente();
    }
  }

  /// Lógica final de criação do cliente no banco de dados.
  /// É chamada diretamente ou após a confirmação do admin no diálogo.
  Future<void> _criarNovoCliente() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final String nomeFormatado = _formatarTexto(_nomeController.text);
      final String ruaFormatada = _formatarTexto(_ruaController.text);
      final String bairroFormatado = _formatarTexto(_bairroController.text);
      // Opcional: Se quiser formatar o apartamento também (ex: "bloco a" -> "Bloco A")
      final String? aptoFormatado = _apartamentoController.text.trim().isEmpty
          ? null
          : _formatarTexto(_apartamentoController.text);
      // Criação do objeto Cliente com os textos já formatados
      final novoCliente = Cliente(
        nome: nomeFormatado, // <--- Usando variável formatada
        rua: ruaFormatada, // <--- Usando variável formatada
        numero: _numeroController.text.trim(),
        apartamento: aptoFormatado,
        bairro: bairroFormatado, // <--- Usando variável formatada
        telefone: maskTelefone.unmaskText(_telefoneController.text),
        cpf: _cpfController.text.isEmpty
            ? null
            : maskCPF.unmaskText(_cpfController.text),
        cnpj: _cnpjController.text.isEmpty
            ? null
            : maskCNPJ.unmaskText(_cnpjController.text),
        observacao: _observacaoController.text.trim().isEmpty
            ? null
            : _observacaoController.text.trim(),
        clienteProblematico: _isProblematico,
      );
      // Envio para o Supabase
      await Supabase.instance.client
          .from('clientes')
          .insert(novoCliente.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente adicionado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Mostra um diálogo quando um cliente potencialmente duplicado é encontrado.
  void _mostrarDialogoClienteDuplicado(Cliente clienteEncontrado) {
    showDialog(
      context: context,
      barrierDismissible: false, // Impede de fechar clicando fora
      builder: (context) {
        return AlertDialog(
          backgroundColor: corCard,
          title: const Row(
            children: [
              Icon(Icons.people_alt_outlined, color: Colors.amber),
              SizedBox(width: 10),
              Text("Cliente Parecido", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Encontramos um cliente com nome e endereço semelhantes:",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              // --- CARD DE INFORMAÇÕES DO CLIENTE ENCONTRADO ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clienteEncontrado.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${clienteEncontrado.rua}, ${clienteEncontrado.numero} - ${clienteEncontrado.bairro}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      maskTelefone.maskText(clienteEncontrado.telefone),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "O que você deseja fazer?",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          actions: [
            // Ação 1: Cancelar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            // Ação 2: Criar Mesmo Assim
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
              ),
              onPressed: () {
                Navigator.pop(context); // Fecha o diálogo
                _criarNovoCliente(); // Chama a função de criação
              },
              child: const Text(
                "Criar Mesmo Assim",
                style: TextStyle(color: Colors.white),
              ),
            ),
            // Ação 3: Criar Orçamento
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: corPrincipal),
              onPressed: () {
                Navigator.pop(context); // Fecha o diálogo
                // Substitui a tela atual pela de adicionar orçamento
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdicionarOrcamento(
                      cliente: clienteEncontrado,
                      dataSelecionada: DateTime.now(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_comment, color: Colors.white),
              label: const Text(
                "Criar Orçamento",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================================================
  // INTERFACE (BUILD)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text("Novo Cliente"),
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
              // ==========================================
              // BOTÃO DE IMPORTAÇÃO (NOVO)
              // ==========================================
              InkWell(
                onTap: _mostrarModalImportacao,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue[900]!.withValues(
                      alpha: 0.3,
                    ), // Azul sutil
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.content_paste_go, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text(
                        "Importar Dados de Texto",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ------------------------------------------
              // SEÇÃO 1: DADOS CADASTRAIS BÁSICOS
              // ------------------------------------------
              _buildCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tituloCampo("Nome Completo"),
                    _buildTextField(
                      controller: _nomeController,
                      hintText: "Nome do cliente",
                      icon: Icons.person,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    _tituloCampo("Telefone"),
                    _buildTextField(
                      controller: _telefoneController,
                      hintText: "(32) 99999-9999",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [maskTelefone],
                      validator: (v) =>
                          v!.length < 15 ? 'Telefone incompleto' : null,
                    ),
                    const SizedBox(height: 16),
                    _tituloCampo("Rua"),
                    _buildTextField(
                      controller: _ruaController,
                      hintText: "Ex: Rua das Flores",
                      icon: Icons.add_road,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Campo Número
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            keyboardType: TextInputType.phone,
                            controller: _numeroController,
                            hintText: 'Nº',
                            icon: Icons.home_filled,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Req.' : null,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Campo Apartamento (Novo)
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _apartamentoController,
                            keyboardType: TextInputType.phone,
                            hintText: 'Apt / Comp.',
                            icon: Icons.apartment,
                            // Sem validator pois é opcional
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _tituloCampo("Bairro"),
                    _buildTextField(
                      controller: _bairroController,
                      hintText: "Ex: Centro",
                      icon: Icons.location_city,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------
              // SEÇÃO 2: DOCUMENTAÇÃO (TOGGLE CPF/CNPJ)
              // ------------------------------------------
              _tituloCampo("Documentação (Opcional)"),
              const SizedBox(height: 8),
              _buildCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seletor Pessoa Física vs Jurídica
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildRadioButton("Pessoa Física", true),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white10,
                          ),
                          Expanded(
                            child: _buildRadioButton("Pessoa Jurídica", false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Alternância animada entre os campos de documento
                    AnimatedCrossFade(
                      firstChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tituloCampo("CPF (Opcional)"),
                          _buildTextField(
                            hintText: "000.000.000-00",
                            controller: _cpfController,
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            inputFormatters: [maskCPF],
                            validator: (v) {
                              if (!_isPessoaFisica) return null;
                              if (v != null && v.isNotEmpty && v.length < 14) {
                                return 'CPF incompleto';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _tituloCampo("CNPJ (Opcional)"),
                          _buildTextField(
                            hintText: "00.000.000/0000-00",
                            controller: _cnpjController,
                            icon: Icons.domain,
                            keyboardType: TextInputType.number,
                            inputFormatters: [maskCNPJ],
                            validator: (v) {
                              if (_isPessoaFisica) return null;
                              if (v != null && v.isNotEmpty && v.length < 18) {
                                return 'CNPJ incompleto';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      crossFadeState: _isPessoaFisica
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------
              // SEÇÃO 3: STATUS E OBSERVAÇÕES
              // ------------------------------------------
              _tituloCampo("Status e Observações"),
              const SizedBox(height: 8),
              _buildCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        "Marque se houver historico de problemas",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      value: _isProblematico,
                      onChanged: (val) => setState(() => _isProblematico = val),
                    ),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    _tituloCampo("Observações (Opcional)"),
                    _buildTextField(
                      hintText: "Anotações adicionais sobre o cliente",
                      controller: _observacaoController,
                      icon: Icons.note,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------
              // BOTÃO DE AÇÃO
              // ------------------------------------------
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
                  onPressed: _isLoading ? null : _salvarCliente,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "CADASTRAR CLIENTE",
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
  // WIDGETS AUXILIARES
  // ==================================================

  /// Título padrão para os campos do formulário.
  Widget _tituloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
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
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: corSecundaria),
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

  Widget _buildRadioButton(String title, bool valorEnum) {
    final isSelected = _isPessoaFisica == valorEnum;
    return InkWell(
      onTap: () => setState(() => _isPessoaFisica = valorEnum),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? corSecundaria : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
