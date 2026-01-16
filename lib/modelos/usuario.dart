class Usuario {
  String?
  id; // Geralmente aqui usamos o UID gerado pelo Firebase Authentication
  String nome; // Nome completo do usuário
  String email; // Email do usuário
  bool isAdmin; // Se for TRUE, é administrador. Se for FALSE, é usuário comum.

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    this.isAdmin = false,
  });

  // Converte para salvar no Banco de Dados
  Map<String, dynamic> toMap() {
    return {'nome': nome, 'email': email, 'isAdmin': isAdmin};
  }

  // Converte do Banco de Dados para o App
  factory Usuario.fromMap(Map<String, dynamic> map, String documentId) {
    return Usuario(
      id: documentId,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      // Garante que se o campo não existir, ele assume que NÃO é admin
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
