/// Modelo que representa as finanças consolidadas de um mês/ano no sistema
class Financas {
  /// ID do registro no Supabase (nulo durante a criação)
  final String? id;

  /// Mês de referência (ex: 10)
  final int mes;

  /// Ano de referência (ex: 2024)
  final int ano;

  /// Valor total faturado no mês
  final double faturamento;

  /// Quantidade de orçamentos gerados no período da manhã/dia
  final int orcamentosDia;

  /// Quantidade de orçamentos gerados no período da tarde
  final int orcamentosTarde;

  /// Total geral de orçamentos criados no mês
  final int totalOrcamentos;

  /// Quantidade de novos clientes cadastrados no mês
  final int novosClientes;

  /// Quantidade de acionamentos de garantia (retornos) no mês
  final int retornosGarantia;

  /// Construtor do modelo
  const Financas({
    this.id,
    required this.mes,
    required this.ano,
    this.faturamento = 0.0,
    this.orcamentosDia = 0,
    this.orcamentosTarde = 0,
    this.totalOrcamentos = 0,
    this.novosClientes = 0,
    this.retornosGarantia = 0,
  });

  // ==================================================
  // MÉTODOS DE SERIALIZAÇÃO (SUPABASE)
  // ==================================================

  /// Converte o objeto Dart num Map para envio ao Supabase
  Map<String, dynamic> toMap() {
    return {
      'mes': mes,
      'ano': ano,
      'faturamento': faturamento,
      'orcamentos_dia': orcamentosDia,
      'orcamentos_tarde': orcamentosTarde,
      'total_orcamentos': totalOrcamentos,
      'novos_clientes': novosClientes,
      'retornos_garantia': retornosGarantia,
    };
  }

  /// Cria um objeto Financas a partir de um Map retornado pelo Supabase
  factory Financas.fromMap(Map<String, dynamic> map) {
    return Financas(
      id: map['id']?.toString(),
      mes: map['mes'] ?? DateTime.now().month,
      ano: map['ano'] ?? DateTime.now().year,
      faturamento: (map['faturamento'] ?? 0.0).toDouble(),
      orcamentosDia: map['orcamentos_dia'] ?? 0,
      orcamentosTarde: map['orcamentos_tarde'] ?? 0,
      totalOrcamentos: map['total_orcamentos'] ?? 0,
      novosClientes: map['novos_clientes'] ?? 0,
      retornosGarantia: map['retornos_garantia'] ?? 0,
    );
  }

  // ==================================================
  // MÉTODOS DE CÓPIA E COMPARAÇÃO
  // ==================================================

  /// Cria uma cópia deste registo de finanças, alterando apenas os campos desejados.
  /// Útil para editar os dados sem mutar o objeto original.
  Financas copyWith({
    String? id,
    int? mes,
    int? ano,
    double? faturamento,
    int? orcamentosDia,
    int? orcamentosTarde,
    int? totalOrcamentos,
    int? novosClientes,
    int? retornosGarantia,
  }) {
    return Financas(
      id: id ?? this.id,
      mes: mes ?? this.mes,
      ano: ano ?? this.ano,
      faturamento: faturamento ?? this.faturamento,
      orcamentosDia: orcamentosDia ?? this.orcamentosDia,
      orcamentosTarde: orcamentosTarde ?? this.orcamentosTarde,
      totalOrcamentos: totalOrcamentos ?? this.totalOrcamentos,
      novosClientes: novosClientes ?? this.novosClientes,
      retornosGarantia: retornosGarantia ?? this.retornosGarantia,
    );
  }

  /// Compara se dois objetos Financas são iguais pelo CONTEÚDO
  /// e não pela referência de memória.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Financas &&
        other.id == id &&
        other.mes == mes &&
        other.ano == ano &&
        other.faturamento == faturamento &&
        other.orcamentosDia == orcamentosDia &&
        other.orcamentosTarde == orcamentosTarde &&
        other.totalOrcamentos == totalOrcamentos &&
        other.novosClientes == novosClientes &&
        other.retornosGarantia == retornosGarantia;
  }

  /// Gera um código hash único baseado nos dados das finanças.
  /// Necessário para usar o objeto em Sets ou como chave de Maps.
  @override
  int get hashCode {
    return id.hashCode ^
        mes.hashCode ^
        ano.hashCode ^
        faturamento.hashCode ^
        orcamentosDia.hashCode ^
        orcamentosTarde.hashCode ^
        totalOrcamentos.hashCode ^
        novosClientes.hashCode ^
        retornosGarantia.hashCode;
  }
}
