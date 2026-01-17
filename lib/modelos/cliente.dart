class Cliente {
  String? id;
  String nome;
  String endereco;
  String telefone;
  String? cpf;
  String? cnpj;
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

  // Converte para salvar no Supabase
  Map<String, dynamic> toMap() {
    return {
      // Nota: Não enviamos o ID aqui (o banco gera automático)
      'nome': nome,
      'endereco': endereco,
      'telefone': telefone,
      'cpf': cpf,
      'cnpj': cnpj,
      // ⚠️ IMPORTANTE: Nome da coluna com underline (snake_case)
      'cliente_problematico': clienteProblematico,
    };
  }

  // Cria objeto vindo do Supabase
  // ⚠️ Removi o parâmetro 'documentId' porque o ID já vem dentro do map
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'], // O ID vem aqui dentro agora
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      telefone: map['telefone'] ?? '',
      cpf: map['cpf'],
      cnpj: map['cnpj'],
      // ⚠️ Lendo da coluna correta do banco
      clienteProblematico: map['cliente_problematico'] ?? false,
    );
  }
}
