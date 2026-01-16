class Aparelho {
  // Identificador do documento no Firebase
  // Pode ser nulo ao criar um novo registro
  String? id;

  // Marca do aparelho (ex: Brastemp, Electrolux)
  String marca;

  // Cor do aparelho
  String cor;

  // Quantidade de bocas do aparelho
  int quantidadeBocas;

  Aparelho({
    this.id,
    required this.marca,
    required this.cor,
    required this.quantidadeBocas,
  });

  // Converte o objeto Aparelho em um Map
  // Usado para salvar os dados no Firebase
  Map<String, dynamic> toMap() {
    return {'marca': marca, 'cor': cor, 'quantidadeBocas': quantidadeBocas};
  }

  // Cria um objeto Aparelho a partir dos dados vindos do Firebase
  // documentId representa o ID do documento no banco
  factory Aparelho.fromMap(Map<String, dynamic> map, String documentId) {
    return Aparelho(
      id: documentId,
      // Usa string vazia caso o valor não exista
      marca: map['marca'] ?? '',
      cor: map['cor'] ?? '',
      // Garante que o valor seja inteiro e define um padrão (4) se for nulo
      quantidadeBocas: map['quantidadeBocas']?.toInt() ?? 4,
    );
  }
}
