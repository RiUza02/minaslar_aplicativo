/// Modelo que representa um cliente no sistema
class Cliente {
  /// ID do registro no Supabase
  /// (nulo durante a criação)
  final String? id;

  /// Nome completo do cliente
  final String nome;

  /// Rua do cliente
  final String rua;

  /// Número do endereço
  final String numero;

  /// Apartamento ou complemento
  final String? apartamento;

  /// Bairro do cliente
  final String bairro;

  /// Telefone para contato
  final String telefone;

  /// CPF do cliente (pessoa física)
  /// Pode ser nulo se for pessoa jurídica
  final String? cpf;

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

  // ==================================================
  // COMPARAÇÃO DE OBJETOS (EQUATABLE MANUAL)
  // ==================================================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Cliente &&
        other.id == id &&
        other.nome == nome &&
        other.rua == rua &&
        other.numero == numero &&
        other.apartamento == apartamento &&
        other.bairro == bairro &&
        other.telefone == telefone &&
        other.cpf == cpf &&
        other.cnpj == cnpj &&
        other.clienteProblematico == clienteProblematico &&
        other.observacao == observacao;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nome,
      rua,
      numero,
      apartamento,
      bairro,
      telefone,
      cpf,
      cnpj,
      clienteProblematico,
      observacao,
    );
  }
}
