class Usuario {
  // Identificador do usuário
  // Normalmente é o UID gerado pelo Firebase Authentication
  String? id;

  // Nome completo do usuário
  String nome;

  // Endereço de e-mail do usuário
  String email;

  // Define o nível de acesso do usuário
  // true  -> administrador
  // false -> usuário comum
  bool isAdmin;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    this.isAdmin = false,
  });

  // Converte o objeto Usuario em um Map
  // Usado para salvar os dados no Firebase
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'email': email, 'isAdmin': isAdmin};
  }

  // Cria um objeto Usuario a partir dos dados do Firebase
  // documentId representa o ID do documento no banco
  factory Usuario.fromMap(Map<String, dynamic> map, String documentId) {
    return Usuario(
      id: documentId,
      // Define valores padrão caso os campos não existam
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      // Se o campo não existir, assume que o usuário não é administrador
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
