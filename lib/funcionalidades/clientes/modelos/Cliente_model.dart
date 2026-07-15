/// Modelo que representa um cliente no sistema
class Cliente {
  /// ID único do cliente, gerado pelo Supabase.
  /// É nulo ao criar um novo cliente localmente.
  final String? id;

  /// Nome completo do cliente.
  final String nome;

  /// Nome da rua do endereço do cliente.
  final String rua;

  /// Número do imóvel no endereço.
  final String numero;

  /// Complemento do endereço, como número do apartamento ou bloco.
  final String? apartamento;

  /// Bairro do endereço do cliente.
  final String bairro;

  /// Número de telefone para contato.
  final String telefone;

  /// CPF do cliente, caso seja pessoa física.
  final String? cpf;

  /// CNPJ do cliente, caso seja pessoa jurídica.
  final String? cnpj;

  /// Sinalizador que indica se o cliente possui um histórico problemático.
  final bool clienteProblematico;

  /// Campo para anotações e observações gerais sobre o cliente.
  final String? observacao;

  /// Construtor principal para criar uma instância de [Cliente].
  const Cliente({
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

  // ==================================================
  // MÉTODOS DE SERIALIZAÇÃO (SUPABASE)
  // ==================================================

  /// Converte a instância do objeto [Cliente] em um [Map] para ser
  /// enviado ao Supabase. O `id` não é incluído, pois é gerenciado pelo banco.
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

  /// Cria uma instância de [Cliente] a partir de um [Map] (JSON)
  /// retornado pelo Supabase.
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
  // MÉTODOS DE CÓPIA E COMPARAÇÃO
  // ==================================================

  /// Cria uma cópia da instância atual de [Cliente], permitindo a alteração
  /// de campos específicos. Útil para atualizações de estado imutáveis.
  Cliente copyWith({
    String? id,
    String? nome,
    String? rua,
    String? numero,
    String? apartamento,
    String? bairro,
    String? telefone,
    String? cpf,
    String? cnpj,
    bool? clienteProblematico,
    String? observacao,
  }) {
    return Cliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      rua: rua ?? this.rua,
      numero: numero ?? this.numero,
      apartamento: apartamento ?? this.apartamento,
      bairro: bairro ?? this.bairro,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      cnpj: cnpj ?? this.cnpj,
      clienteProblematico: clienteProblematico ?? this.clienteProblematico,
      observacao: observacao ?? this.observacao,
    );
  }

  /// Sobrescreve o operador de igualdade para comparar o conteúdo dos objetos
  /// [Cliente], em vez de suas referências de memória.
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

  /// Sobrescreve o `hashCode` para que objetos com o mesmo conteúdo tenham
  /// o mesmo hash. Essencial para uso em coleções como `Set` e `Map`.
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
