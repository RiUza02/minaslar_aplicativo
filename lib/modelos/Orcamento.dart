/// Enum para representar os turnos de agendamento,
/// evitando o uso de "magic strings".
enum Turno {
  manha('Manhã'),
  tarde('Tarde');

  const Turno(this.valor);
  final String valor;
}

/// Modelo que representa um orçamento no sistema
class Orcamento {
  /// ID do registro no Supabase (nulo durante a criação)
  final String? id;

  /// ID do cliente relacionado ao orçamento (chave estrangeira)
  final String clienteId;

  /// ID do usuário que criou o orçamento (chave estrangeira)
  final String? userId;

  /// Título do serviço (Ex: "Formatação PC", "Troca de Tela")
  final String titulo;

  /// Descrição detalhada do serviço realizado (Antigo oQueFoiFeito)
  final String? descricao;

  /// Data em que o serviço foi iniciado
  final DateTime dataPega;

  /// Data prevista ou efetiva de entrega do serviço
  final DateTime? dataEntrega;

  /// Valor do orçamento
  final double? valor;

  /// Turno do agendamento ('Manhã' ou 'Tarde')
  final Turno horarioDoDia;

  /// Indica se o serviço foi concluído/entregue
  final bool entregue;

  /// Indica se o serviço é um retorno de garantia/revisão
  final bool ehRetorno;

  /// Construtor do modelo
  Orcamento({
    this.id,
    required this.clienteId,
    this.userId,
    required this.titulo,
    this.descricao,
    required this.dataPega,
    this.dataEntrega,
    this.valor,
    required this.horarioDoDia,
    this.entregue = false,
    this.ehRetorno = false,
  });

  /// Converte o objeto Dart em um Map para envio ao Supabase
  Map<String, dynamic> toMap() {
    return {
      // O ID não é enviado pois o Supabase gera automaticamente
      'cliente_id': clienteId,
      'user_id': userId,
      'titulo': titulo,
      'descricao': descricao,
      'data_pega': dataPega.toIso8601String(),
      'data_entrega': dataEntrega?.toIso8601String(),
      'valor': valor,
      'horario_do_dia':
          horarioDoDia.valor, // Converte o enum para a string do banco
      'entregue': entregue,
      'eh_retorno': ehRetorno,
    };
  }

  /// Cria um objeto Orcamento a partir de um Map retornado pelo Supabase
  factory Orcamento.fromMap(Map<String, dynamic> map) {
    return Orcamento(
      id: map['id']?.toString(),
      clienteId: map['cliente_id'] ?? '',
      userId: map['user_id'],
      titulo: map['titulo'] ?? 'Sem Título',
      descricao: map['descricao'] ?? '',

      dataPega: map['data_pega'] != null
          ? DateTime.parse(map['data_pega'])
          : DateTime.now(), // Fallback para evitar crash com dados antigos/nulos

      dataEntrega: map['data_entrega'] != null
          ? DateTime.parse(map['data_entrega'])
          : null,

      valor: map['valor'] != null ? (map['valor'] as num).toDouble() : null,

      // Converte a string do banco para o enum.
      // Se for nulo ou inválido, assume 'Manhã' como padrão.
      horarioDoDia: (map['horario_do_dia'] ?? 'Manhã') == 'Tarde'
          ? Turno.tarde
          : Turno.manha,

      // Recupera do banco. Se for nulo, assume false
      entregue: map['entregue'] ?? false,

      // Recupera do banco. Se for nulo, assume false
      ehRetorno: map['eh_retorno'] ?? false,
    );
  }
  // ==================================================
  // COMPARAÇÃO DE OBJETOS
  // ==================================================
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Orcamento &&
        other.id == id &&
        other.clienteId == clienteId &&
        other.userId == userId &&
        other.titulo == titulo &&
        other.descricao == descricao &&
        other.dataPega == dataPega &&
        other.dataEntrega == dataEntrega &&
        other.valor == valor &&
        other.horarioDoDia == horarioDoDia &&
        other.entregue == entregue &&
        other.ehRetorno == ehRetorno;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      clienteId,
      userId,
      titulo,
      descricao,
      dataPega,
      dataEntrega,
      valor,
      horarioDoDia,
      entregue,
      ehRetorno,
    );
  }
}
