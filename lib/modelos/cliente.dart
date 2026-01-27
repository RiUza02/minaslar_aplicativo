/// Modelo que representa um cliente no sistema
class Cliente {
  /// ID do registro no Supabase
  /// (nulo durante a criação)
  String? id;

  /// Nome completo do cliente
  String nome;

  /// Rua do cliente
  String rua;

  /// Número do endereço (Novo campo obrigatório)
  String numero;

  /// Bairro do cliente
  String bairro;

  /// Telefone para contato
  String telefone;

  /// CPF do cliente (pessoa física)
  /// Pode ser nulo se for pessoa jurídica
  String? cpf;

  /// CNPJ do cliente (pessoa jurídica)
  /// Pode ser nulo se for pessoa física
  String? cnpj;

  /// Indica se o cliente possui histórico problemático
  bool clienteProblematico;

  /// Observações adicionais sobre o cliente
  String? observacao;

  /// Construtor do modelo
  Cliente({
    this.id,
    required this.nome,
    required this.rua,
    required this.numero, // Adicionado como obrigatório
    required this.bairro,
    required this.telefone,
    this.cpf,
    this.cnpj,
    this.clienteProblematico = false,
    this.observacao,
  });

  /// Converte o objeto Dart em um Map
  /// para envio ao Supabase
  Map<String, dynamic> toMap() {
    return {
      // O ID não é enviado,
      // pois o Supabase gera automaticamente
      'nome': nome,
      'rua': rua,
      'numero': numero, // Mapeado para coluna 'numero'
      'bairro': bairro,
      'telefone': telefone,
      'cpf': cpf,
      'cnpj': cnpj,
      'observacao': observacao,

      // Conversão de camelCase (Dart)
      // para snake_case (Banco de Dados)
      'cliente_problematico': clienteProblematico,
    };
  }

  /// Cria um objeto Cliente a partir
  /// de um Map retornado pelo Supabase
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      // O ID já vem dentro do Map
      id: map['id']?.toString(),

      // Dados básicos
      nome: map['nome'] ?? '',
      rua: map['rua'] ?? '',
      // Se o campo for nulo no banco (registros antigos), retorna string vazia
      numero: map['numero']?.toString() ?? '',
      bairro: map['bairro'] ?? '',
      telefone: map['telefone'] ?? '',

      // Documentos (podem ser nulos)
      cpf: map['cpf'],
      cnpj: map['cnpj'],

      // Leitura da coluna em snake_case
      clienteProblematico: map['cliente_problematico'] ?? false,
      observacao: map['observacao'],
    );
  }
}
