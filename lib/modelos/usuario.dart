class Usuario {
  String? id;
  String nome;
  String email;
  String telefone;
  bool isAdmin;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.isAdmin = false,
  });

  // Converte para salvar no Supabase
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'telefone': telefone,
      // ⚠️ MUDANÇA: O nome da coluna no banco é snake_case
      'is_admin': isAdmin,
    };
  }

  // Cria objeto vindo do Supabase
  // ⚠️ Removi o 'documentId', pois o ID já vem dentro do map
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'], // O ID vem aqui dentro
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      // ⚠️ MUDANÇA: Lendo a coluna correta do banco
      isAdmin: map['is_admin'] ?? false,
    );
  }
}
