/// Modelo que representa um usuário do sistema
class Usuario {
  /// ID do usuário no Supabase
  /// (nulo durante a criação)
  String? id;

  /// Nome completo do usuário
  String nome;

  /// E-mail de acesso do usuário
  String email;

  /// Telefone para contato
  String telefone;

  /// Define se o usuário possui permissão de administrador
  bool isAdmin;

  /// Construtor do modelo
  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.isAdmin = false,
  });

  /// Converte o objeto Dart em um Map
  /// para envio ao Supabase
  Map<String, dynamic> toMap() {
    return {
      // O ID não é enviado,
      // pois o Supabase gera automaticamente
      'nome': nome,
      'email': email,
      'telefone': telefone,

      // Conversão de camelCase (Dart)
      // para snake_case (Banco de Dados)
      'is_admin': isAdmin,
    };
  }

  /// Cria um objeto Usuario a partir
  /// de um Map retornado pelo Supabase
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      // O ID já vem dentro do Map
      id: map['id'],

      // Dados principais
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',

      // Leitura da coluna em snake_case
      isAdmin: map['is_admin'] ?? false,
    );
  }
}
