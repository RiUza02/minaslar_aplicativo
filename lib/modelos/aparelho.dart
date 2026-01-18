/// Modelo que representa um aparelho cadastrado no sistema
class Aparelho {
  /// ID do registro no Supabase
  /// (nulo ao criar, pois o banco gera automaticamente)
  String? id;

  /// Marca do aparelho
  String marca;

  /// Cor do aparelho
  String cor;

  /// Quantidade de bocas do aparelho
  int quantidadeBocas;

  /// ID do cliente ao qual o aparelho pertence
  /// Necessário para vincular o aparelho a um usuário
  String clienteId;

  /// Construtor do modelo
  Aparelho({
    this.id,
    required this.marca,
    required this.cor,
    required this.quantidadeBocas,
    required this.clienteId,
  });

  /// Converte o objeto Dart em um Map
  /// para ser enviado ao Supabase
  Map<String, dynamic> toMap() {
    return {
      // O ID não é enviado na criação,
      // pois o Supabase gera automaticamente
      'marca': marca,
      'cor': cor,

      // Conversão do padrão Dart (camelCase)
      // para o padrão do banco (snake_case)
      'quantidade_bocas': quantidadeBocas,

      // Relacionamento com o cliente
      'cliente_id': clienteId,
    };
  }

  /// Cria um objeto Aparelho a partir
  /// de um Map retornado pelo Supabase
  factory Aparelho.fromMap(Map<String, dynamic> map) {
    return Aparelho(
      // O Supabase retorna o ID no próprio Map
      id: map['id'],

      // Campos básicos
      marca: map['marca'] ?? '',
      cor: map['cor'] ?? '',

      // Leitura da coluna em snake_case
      quantidadeBocas: map['quantidade_bocas'] ?? 4,

      // ID do cliente vinculado
      clienteId: map['cliente_id'] ?? '',
    );
  }
}
