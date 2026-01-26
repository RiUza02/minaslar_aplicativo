/// Modelo que representa um orçamento no sistema
class Orcamento {
  /// ID do registro no Supabase (nulo durante a criação)
  String? id;

  /// ID do cliente relacionado ao orçamento (chave estrangeira)
  String clienteId;

  /// Título do serviço (Ex: "Formatação PC", "Troca de Tela")
  String titulo;

  /// Descrição detalhada do serviço realizado (Antigo oQueFoiFeito)
  String? descricao;

  /// Data em que o serviço foi iniciado
  DateTime dataPega;

  /// Data prevista ou efetiva de entrega do serviço
  DateTime? dataEntrega;

  /// Valor do orçamento
  double? valor;

  /// Turno do agendamento ('Manhã' ou 'Tarde')
  String horarioDoDia;

  /// Indica se o serviço foi concluído/entregue
  bool entregue;

  /// Indica se o serviço é um retorno de garantia/revisão
  bool ehRetorno;

  /// Construtor do modelo
  Orcamento({
    this.id,
    required this.clienteId,
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
      'titulo': titulo,
      'descricao': descricao,
      'data_pega': dataPega.toIso8601String(),
      'data_entrega': dataEntrega?.toIso8601String(),
      'valor': valor,
      'horario_do_dia': horarioDoDia,
      'entregue': entregue,
      'eh_retorno': ehRetorno,
    };
  }

  /// Cria um objeto Orcamento a partir de um Map retornado pelo Supabase
  factory Orcamento.fromMap(Map<String, dynamic> map) {
    return Orcamento(
      id: map['id']?.toString(),
      clienteId: map['cliente_id'] ?? '',
      titulo: map['titulo'] ?? 'Sem Título',
      descricao: map['descricao'] ?? '',

      dataPega: DateTime.parse(map['data_pega']),

      dataEntrega: map['data_entrega'] != null
          ? DateTime.parse(map['data_entrega'])
          : null,

      valor: map['valor'] != null ? (map['valor'] as num).toDouble() : null,

      // Recupera do banco. Se for nulo (registros antigos), define como 'Manhã'
      horarioDoDia: map['horario_do_dia'] ?? 'Manhã',

      // Recupera do banco. Se for nulo, assume false
      entregue: map['entregue'] ?? false,

      // Recupera do banco. Se for nulo, assume false
      ehRetorno: map['eh_retorno'] ?? false,
    );
  }
}
