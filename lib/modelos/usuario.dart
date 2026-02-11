/// Modelo que representa um usuário do sistema
class Usuario {
  /// ID do usuário no Supabase (nulo durante a criação local)
  final String? id;

  /// Nome completo do usuário
  final String nome;

  /// E-mail de acesso do usuário
  final String email;

  /// Telefone para contato
  final String telefone;

  /// Define se o usuário possui permissão de administrador
  final bool isAdmin;

  /// Construtor do modelo
  /// (Dica: Usei 'final' nos campos acima para garantir imutabilidade real)
  const Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    this.isAdmin = false,
  });

  // ==================================================
  // MÉTODOS DE SERIALIZAÇÃO (SUPABASE)
  // ==================================================

  /// Converte o objeto Dart em um Map para envio ao Supabase
  Map<String, dynamic> toMap() {
    return {
      // O ID geralmente não é enviado no insert, pois o banco gera,
      // mas se estivermos fazendo um update, pode ser útil ter o ID separado.
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'is_admin': isAdmin, // Snake_case do banco
    };
  }

  /// Cria um objeto Usuario a partir de um Map retornado pelo Supabase
  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String?,
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      telefone: map['telefone'] ?? '',
      isAdmin: map['is_admin'] ?? false,
    );
  }

  // ==================================================
  // MÉTODOS DE CÓPIA E COMPARAÇÃO (NOVIDADE)
  // ==================================================

  /// Cria uma cópia deste usuário, alterando apenas os campos desejados.
  /// Útil para editar um usuário sem mutar o objeto original.
  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? telefone,
    bool? isAdmin,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  /// Compara se dois objetos Usuario são iguais pelo CONTEÚDO
  /// e não pela referência de memória.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Usuario &&
        other.id == id &&
        other.nome == nome &&
        other.email == email &&
        other.telefone == telefone &&
        other.isAdmin == isAdmin;
  }

  /// Gera um código hash único baseado nos dados do usuário.
  /// Necessário para usar o objeto em Sets ou como chave de Maps.
  @override
  int get hashCode {
    return id.hashCode ^
        nome.hashCode ^
        email.hashCode ^
        telefone.hashCode ^
        isAdmin.hashCode;
  }

  /// (Opcional) Facilita a leitura dos dados no console (print)
  @override
  String toString() {
    return 'Usuario(id: $id, nome: $nome, email: $email, isAdmin: $isAdmin)';
  }
}
