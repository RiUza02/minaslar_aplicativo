class Cliente {
  String? id; // O ID do documento no Firebase (opcional na criação)
  String nome; // Nome completo do cliente
  String endereco; // Endereço completo
  String telefone; // Pode ser celular ou fixo
  String? cpf; // Pode ser nulo se for Pessoa Jurídica
  String? cnpj; // Pode ser nulo se for Pessoa Física
  bool clienteProblematico; // Esse é o seu "Label" (True = dá problema)

  Cliente({
    this.id,
    required this.nome,
    required this.endereco,
    required this.telefone,
    this.cpf,
    this.cnpj,
    this.clienteProblematico = false,
  });

  // Converte o objeto Cliente para um Mapa (JSON) para salvar no Firebase
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
      'cpf': cpf,
      'cnpj': cnpj,
      'clienteProblematico': clienteProblematico,
    };
  }

  // Cria um objeto Cliente a partir dos dados vindos do Firebase
  factory Cliente.fromMap(Map<String, dynamic> map, String documentId) {
    return Cliente(
      id: documentId,
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      telefone: map['telefone'] ?? '',
      cpf: map['cpf'],
      cnpj: map['cnpj'],
      clienteProblematico: map['clienteProblematico'] ?? false,
    );
  }
}
