enum Turno {
  manha('Manhã'),
  tarde('Tarde');

  const Turno(this.valor);
  final String valor;
}

class Orcamento {
  final String? id;
  final String clienteId;
  final String? userId;
  final String titulo;
  final String? descricao;
  final DateTime dataPega;
  final DateTime? dataEntrega;
  final double? valor;
  final Turno horarioDoDia;
  final bool entregue;
  final bool ehRetorno;

  // Construtor agora é const para otimização de performance
  const Orcamento({
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

  Map<String, dynamic> toMap() {
    return {
      'cliente_id': clienteId,
      'user_id': userId,
      'titulo': titulo,
      'descricao': descricao,
      'data_pega': dataPega.toIso8601String(),
      'data_entrega': dataEntrega?.toIso8601String(),
      'valor': valor,
      'horario_do_dia': horarioDoDia.valor,
      'entregue': entregue,
      'eh_retorno': ehRetorno,
    };
  }

  factory Orcamento.fromMap(Map<String, dynamic> map) {
    return Orcamento(
      id: map['id']?.toString(),
      clienteId: map['cliente_id'] ?? '',
      userId: map['user_id'],
      titulo: map['titulo'] ?? 'Sem Título',
      descricao: map['descricao'] ?? '',
      dataPega: map['data_pega'] != null
          ? DateTime.parse(map['data_pega'])
          : DateTime.now(),
      dataEntrega: map['data_entrega'] != null
          ? DateTime.parse(map['data_entrega'])
          : null,
      valor: map['valor'] != null ? (map['valor'] as num).toDouble() : null,
      horarioDoDia: (map['horario_do_dia'] ?? 'Manhã') == 'Tarde'
          ? Turno.tarde
          : Turno.manha,
      entregue: map['entregue'] ?? false,
      ehRetorno: map['eh_retorno'] ?? false,
    );
  }

  // Novo método copyWith adicionado para paridade com os outros modelos
  Orcamento copyWith({
    String? id,
    String? clienteId,
    String? userId,
    String? titulo,
    String? descricao,
    DateTime? dataPega,
    DateTime? dataEntrega,
    double? valor,
    Turno? horarioDoDia,
    bool? entregue,
    bool? ehRetorno,
  }) {
    return Orcamento(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataPega: dataPega ?? this.dataPega,
      dataEntrega: dataEntrega ?? this.dataEntrega,
      valor: valor ?? this.valor,
      horarioDoDia: horarioDoDia ?? this.horarioDoDia,
      entregue: entregue ?? this.entregue,
      ehRetorno: ehRetorno ?? this.ehRetorno,
    );
  }

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
