class Usuario {
  // Identificador do usuário
  // Normalmente é o UID gerado pelo Firebase Authentication
  String? id;

  // Nome completo do usuário
  String nome;

  // Endereço de e-mail do usuário
  String email;

  // Número de telefone do usuário (NOVO CAMPO)
  String telefone;

  // Define o nível de acesso do usuário
  // true  -> administrador
  // false -> usuário comum
  bool isAdmin;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone, // Adicionado ao construtor
    this.isAdmin = false,
  });

  // Converte o objeto Usuario em um Map
  // Usado para salvar os dados no Firebase
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone, // Adicionado aqui para salvar no banco
      'isAdmin': isAdmin,
    };
  }

  // Cria um objeto Usuario a partir dos dados do Firebase
  // documentId representa o ID do documento no banco
  factory Usuario.fromMap(Map<String, dynamic> map, String documentId) {
    return Usuario(
      id: documentId,
      // Define valores padrão caso os campos não existam
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      // Se não existir no banco (usuários antigos), retorna string vazia
      telefone: map['telefone'] ?? '',
      // Se o campo não existir, assume que o usuário não é administrador
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
