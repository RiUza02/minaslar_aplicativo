class Cliente {
  // Identificador do documento no Firebase
  // É nulo ao criar um novo cliente
  String? id;

  // Nome completo do cliente
  String nome;

  // Endereço residencial ou comercial
  String endereco;

  // Telefone de contato (celular ou fixo)
  String telefone;

  // CPF do cliente (somente para Pessoa Física)
  String? cpf;

  // CNPJ do cliente (somente para Pessoa Jurídica)
  String? cnpj;

  // Indica se o cliente é problemático
  // true  -> cliente dá problemas
  // false -> cliente normal
  bool clienteProblematico;

  Cliente({
    this.id,
    required this.nome,
    required this.endereco,
    required this.telefone,
    this.cpf,
    this.cnpj,
    this.clienteProblematico = false,
  });

  // Converte o objeto Cliente em um Map
  // Usado para salvar os dados no Firebase
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

  // Cria um objeto Cliente a partir dos dados do Firebase
  // documentId representa o ID do documento no banco
  factory Cliente.fromMap(Map<String, dynamic> map, String documentId) {
    return Cliente(
      id: documentId,
      // Define valores padrão caso algum campo não exista
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      telefone: map['telefone'] ?? '',
      cpf: map['cpf'],
      cnpj: map['cnpj'],
      clienteProblematico: map['clienteProblematico'] ?? false,
    );
  }
}
