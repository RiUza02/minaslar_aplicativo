class Aparelho {
  String? id;
  String marca;
  String cor;
  int quantidadeBocas;
  String clienteId; // ⚠️ NOVO: Necessário para vincular ao cliente

  Aparelho({
    this.id,
    required this.marca,
    required this.cor,
    required this.quantidadeBocas,
    required this.clienteId, // ⚠️ Obrigatório agora
  });

  // Converte para salvar no Supabase
  Map<String, dynamic> toMap() {
    return {
      // O Supabase não precisa que envie o ID na criação (ele gera sozinho)
      'marca': marca,
      'cor': cor,
      // ⚠️ AQUI: Mapeando do Dart (quantidadeBocas) para o SQL (quantidade_bocas)
      'quantidade_bocas': quantidadeBocas,
      'cliente_id': clienteId,
    };
  }

  // Cria objeto vindo do Supabase
  factory Aparelho.fromMap(Map<String, dynamic> map) {
    return Aparelho(
      // No Supabase, o 'id' já vem dentro do map, não precisa passar separado
      id: map['id'],
      marca: map['marca'] ?? '',
      cor: map['cor'] ?? '',
      // ⚠️ Lendo a coluna com underline do banco
      quantidadeBocas: map['quantidade_bocas'] ?? 4,
      clienteId: map['cliente_id'] ?? '',
    );
  }
}
