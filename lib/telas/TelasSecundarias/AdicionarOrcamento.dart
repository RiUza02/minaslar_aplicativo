import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../modelos/Cliente.dart';

/// Tela responsável pelo cadastro de novos orçamentos vinculados a um cliente.
class AdicionarOrcamento extends StatefulWidget {
  final Cliente cliente;
  final DateTime? dataSelecionada;

  const AdicionarOrcamento({
    super.key,
    required this.cliente,
    this.dataSelecionada,
  });

  @override
  State<AdicionarOrcamento> createState() => _AdicionarOrcamentoState();
}

class _AdicionarOrcamentoState extends State<AdicionarOrcamento> {
  final _formKey = GlobalKey<FormState>();

  // ==================================================
  // CONFIGURAÇÕES VISUAIS E CORES
  // ==================================================
  final Color corPrincipal = Colors.red[900]!;
  final Color corSecundaria = Colors.blue[300]!;
  final Color corComplementar = Colors.amber;
  final Color corFundo = Colors.black;
  final Color corCard = const Color(0xFF1E1E1E);
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;

  // ==================================================
  // CONTROLADORES E ESTADO
  // ==================================================
  // Inputs de Texto
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();

  // Controle de Datas e Horários
  late DateTime _dataPega;
  DateTime? _dataEntrega;
  String _horarioSelecionado = 'Manhã';

  // Estado de Carregamento
  bool _isLoading = false;
  bool _ehRetorno = false;

  // ==================================================
  // CICLO DE VIDA
  // ==================================================
  @override
  void initState() {
    super.initState();
    // Inicializa com a data passada por parâmetro ou a data atual
    _dataPega = widget.dataSelecionada ?? DateTime.now();
  }

  @override
  void dispose() {
    // Libera recursos dos controladores para evitar vazamento de memória
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  // ==================================================
  // LÓGICA DE NEGÓCIO
  // ==================================================

  /// Exibe o calendário para seleção de data de Entrada ou Entrega.
  Future<void> _selecionarData({required bool isEntrega}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isEntrega ? (_dataEntrega ?? _dataPega) : _dataPega,
      // Impede que a data de entrega seja anterior à data de entrada
      firstDate: isEntrega ? _dataPega : DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        // Personalização do tema do DatePicker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: corPrincipal,
              onPrimary: Colors.white,
              surface: corCard,
              onSurface: corTextoClaro,
            ),
            dialogTheme: DialogThemeData(backgroundColor: corCard),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isEntrega) {
          _dataEntrega = picked;
        } else {
          _dataPega = picked;
        }
      });
    }
  }

  /// Valida o formulário e persiste o orçamento no Supabase.
  Future<void> _salvarOrcamento() async {
    if (!_formKey.currentState!.validate()) return;

    // Validação extra: Data de entrega não pode ser anterior à de entrada
    if (_dataEntrega != null &&
        _dataEntrega!.isBefore(DateUtils.dateOnly(_dataPega))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A data de entrega não pode ser anterior à de entrada.',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Pega o ID do usuário logado para associar ao orçamento
    final userId = Supabase.instance.client.auth.currentUser?.id;

    // Validação de segurança: Garante que há um usuário logado
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro de autenticação. Faça login novamente."),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // TRATAMENTO LÓGICO PARA CAMPOS OPCIONAIS
      // Valor: Se vazio, envia null. Se preenchido, converte.
      final String valorTexto = _valorController.text
          .replaceAll(',', '.')
          .trim();
      final double? valorFinal = valorTexto.isEmpty
          ? null
          : double.tryParse(valorTexto);

      // Descrição: Se vazia, envia string vazia ou null (depende da sua preferência, aqui envio o texto direto mesmo se vazio)
      final String descricaoFinal = _descricaoController.text.trim();

      // Prepara o payload para inserção
      final Map<String, dynamic> dadosNovoOrcamento = {
        'user_id': userId, // Adiciona o ID do usuário que está criando
        'cliente_id': widget.cliente.id,
        'titulo': _tituloController.text.trim(),
        'descricao': descricaoFinal, // Agora aceita vazio
        'valor': valorFinal, // Agora aceita null
        'data_pega': _dataPega.toIso8601String(),
        'data_entrega': _dataEntrega?.toIso8601String(),
        'horario_do_dia': _horarioSelecionado,
        'eh_retorno': _ehRetorno,
      };

      // Insere no banco de dados
      await Supabase.instance.client
          .from('orcamentos')
          .insert(dadosNovoOrcamento);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Orçamento adicionado com sucesso!'),
            backgroundColor: Colors.green[700],
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Retorna true para atualizar a lista anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================================================
  // WIDGETS AUXILIARES
  // ==================================================

  /// Cria um bloco visual padronizado (Card) para agrupar campos.
  Widget _buildBlock({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// Título padrão para os campos do formulário.
  Widget _tituloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        texto,
        style: TextStyle(
          color: corTextoCinza,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Botão customizado para seleção de turno (Manhã/Tarde).
  Widget _botaoSelecaoHorario({required String valor, required IconData icon}) {
    final bool isSelected = _horarioSelecionado == valor;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _horarioSelecionado = valor;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? corPrincipal : Colors.black26,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Colors.redAccent, width: 2)
                : Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : corTextoCinza,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: TextStyle(
                  color: isSelected ? Colors.white : corTextoCinza,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botão que exibe a data selecionada e aciona o DatePicker.
  Widget _botaoData({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
    Color? corTexto,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: corTextoCinza, size: 20),
            const SizedBox(width: 12),
            Text(
              texto,
              style: TextStyle(color: corTexto ?? corTextoClaro, fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  /// Estilização padrão para TextFormFields.
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: corTextoCinza),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: corPrincipal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  // ==================================================
  // INTERFACE PRINCIPAL (BUILD)
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text(
          "Novo Orçamento",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // Botão de Ação Flutuante ou Fixo na base
      bottomNavigationBar: Container(
        color: corCard,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: _isLoading ? null : _salvarOrcamento,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "ADICIONAR ORÇAMENTO",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --------------------------------------------------
              // CABEÇALHO DO CLIENTE
              // --------------------------------------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: corCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: corComplementar, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: corComplementar.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.person,
                        color: corComplementar,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "CLIENTE SELECIONADO",
                            style: TextStyle(
                              fontSize: 12,
                              color: corTextoCinza,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cliente.nome,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: corTextoClaro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --------------------------------------------------
              // BLOCO EXTRA: MARCAR COMO RETORNO
              // --------------------------------------------------
              _buildBlock(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Marcar como Retorno",
                      style: TextStyle(
                        color: corTextoClaro,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Use para serviços de garantia ou revisão.",
                      style: TextStyle(color: corTextoCinza, fontSize: 12),
                    ),
                    value: _ehRetorno,
                    onChanged: (value) {
                      setState(() => _ehRetorno = value);
                    },
                    activeThumbColor: corComplementar, // Amber
                    secondary: Icon(Icons.history, color: corComplementar),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --------------------------------------------------
              // BLOCO 1: DETALHES DO SERVIÇO
              // --------------------------------------------------
              _buildBlock(
                children: [
                  _tituloCampo("Título do Serviço"),
                  TextFormField(
                    controller: _tituloController,
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration('Ex: Limpeza', Icons.title),
                    validator: (v) => v!.isEmpty ? 'Informe um título' : null,
                  ),
                  const SizedBox(height: 20),

                  // Campo Descrição (AGORA OPCIONAL - Validator removido)
                  _tituloCampo("Descrição do Serviço"),
                  TextFormField(
                    controller: _descricaoController,
                    keyboardType: TextInputType.visiblePassword,
                    maxLines: 3,
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration(
                      'Descreva o serviço...',
                      Icons.description_outlined,
                    ),
                    // Sem validator pois é opcional
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // BLOCO 2: FINANCEIRO
              // --------------------------------------------------
              _buildBlock(
                children: [
                  // Campo Valor (AGORA OPCIONAL - Validator removido)
                  _tituloCampo("Valor (R\$) - Opcional"),
                  TextFormField(
                    controller: _valorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: corTextoClaro),
                    decoration: _inputDecoration(
                      '0,00',
                      Icons.monetization_on_outlined,
                    ),
                    // Sem validator pois é opcional
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // BLOCO 3: PRAZOS E HORÁRIOS
              // --------------------------------------------------
              _buildBlock(
                children: [
                  _tituloCampo("Preferência de Horário"),
                  Row(
                    children: [
                      _botaoSelecaoHorario(
                        valor: 'Manhã',
                        icon: Icons.wb_sunny_outlined,
                      ),
                      const SizedBox(width: 12),
                      _botaoSelecaoHorario(
                        valor: 'Tarde',
                        icon: Icons.wb_twilight,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),

                  _tituloCampo("Data de Entrada"),
                  _botaoData(
                    icon: Icons.calendar_today,
                    texto: DateFormat('dd/MM/yyyy').format(_dataPega),
                    onTap: () => _selecionarData(isEntrega: false),
                  ),

                  const SizedBox(height: 20),

                  _tituloCampo("Data de Entrega / Previsão"),
                  Row(
                    children: [
                      Expanded(
                        child: _botaoData(
                          icon: Icons.event_available,
                          texto: _dataEntrega != null
                              ? DateFormat('dd/MM/yyyy').format(_dataEntrega!)
                              : "Definir data...",
                          onTap: () => _selecionarData(isEntrega: true),
                        ),
                      ),
                      if (_dataEntrega != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: IconButton(
                            onPressed: () =>
                                setState(() => _dataEntrega = null),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                            tooltip: "Remover data",
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
