/// Modelo que representa um cliente no sistema
class Cliente {
  /// ID do registro no Supabase
  /// (nulo durante a criação)
  String? id;

  /// Nome completo do cliente
  String nome;

  /// Rua do cliente
  String rua;

  /// Número do endereço
  String numero;

  /// Apartamento ou complemento
  String? apartamento;

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
    required this.numero,
    this.apartamento,
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
      'nome': nome,
      'rua': rua,
      'numero': numero,
      'apartamento': apartamento,
      'bairro': bairro,
      'telefone': telefone,
      'cpf': cpf,
      'cnpj': cnpj,
      'observacao': observacao,
      'cliente_problematico': clienteProblematico,
    };
  }

  /// Cria um objeto Cliente a partir
  /// de um Map retornado pelo Supabase
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id']?.toString(),
      nome: map['nome'] ?? '',
      rua: map['rua'] ?? '',
      numero: map['numero']?.toString() ?? '',
      apartamento: map['apartamento'],
      bairro: map['bairro'] ?? '',
      telefone: map['telefone'] ?? '',
      cpf: map['cpf'],
      cnpj: map['cnpj'],
      clienteProblematico: map['cliente_problematico'] ?? false,
      observacao: map['observacao'],
    );
  }
}
