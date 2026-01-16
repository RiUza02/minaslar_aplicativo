class Aparelho {
  String? id; // O ID do documento no Firebase (opcional na criação)
  String marca; // Marca do aparelho
  String cor; // Cor do aparelhos
  int quantidadeBocas; // Número inteiro para contar as bocas

  Aparelho({
    this.id,
    required this.marca,
    required this.cor,
    required this.quantidadeBocas,
  });

  // Converte para salvar no Banco de Dados (Firebase)
  Map<String, dynamic> toMap() {
    return {'marca': marca, 'cor': cor, 'quantidadeBocas': quantidadeBocas};
  }

  // Converte do Banco de Dados para o App
  factory Aparelho.fromMap(Map<String, dynamic> map, String documentId) {
    return Aparelho(
      id: documentId,
      marca: map['marca'] ?? '',
      cor: map['cor'] ?? '',
      // Garante que seja um número inteiro, mesmo que venha nulo
      quantidadeBocas: map['quantidadeBocas']?.toInt() ?? 4,
    );
  }
}
