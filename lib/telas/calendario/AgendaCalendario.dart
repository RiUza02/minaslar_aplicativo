import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'ListaOrcamentosDia.dart';
import '../clienteOrcamento/DetalhesOrcamento.dart';

class AgendaCalendario extends StatefulWidget {
  const AgendaCalendario({super.key});

  @override
  State<AgendaCalendario> createState() => _AgendaCalendarioState();
}

class _AgendaCalendarioState extends State<AgendaCalendario> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<dynamic>> _eventosPorDia = {};
  List<dynamic> _eventosSelecionados = [];

  bool _isLoading = true;

  final Color corFundo = Colors.black;
  final Color corPrincipal = Colors.red[900]!;
  final Color corTextoClaro = Colors.white;
  final Color corTextoCinza = Colors.grey[400]!;
  final Color corHoje = Colors.amber;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('pt_BR', null).then((_) {
      _carregarEventosDoMes();
    });
  }

  Future<void> _carregarEventosDoMes() async {
    try {
      final response = await Supabase.instance.client
          .from('orcamentos')
          .select('id, data_pega, titulo, horario_do_dia, clientes(nome)');

      final Map<DateTime, List<dynamic>> eventos = {};

      for (var item in response) {
        if (item['data_pega'] != null) {
          final dataOriginal = DateTime.parse(item['data_pega']);
          final dataNormalizada = DateTime(
            dataOriginal.year,
            dataOriginal.month,
            dataOriginal.day,
          );

          if (eventos[dataNormalizada] == null) {
            eventos[dataNormalizada] = [];
          }
          eventos[dataNormalizada]!.add(item);
        }
      }

      if (mounted) {
        setState(() {
          _eventosPorDia = eventos;
          _eventosSelecionados = _getEventosDoDia(_selectedDay!);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar eventos: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEventosDoDia(DateTime dia) {
    final dataNormalizada = DateTime(dia.year, dia.month, dia.day);
    return _eventosPorDia[dataNormalizada] ?? [];
  }

  // Navega para a Lista Geral do dia (Botão Grande)
  void _navegarParaListaDoDia() {
    if (_selectedDay != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ListaOrcamentosDia(dataSelecionada: _selectedDay!),
        ),
      ).then((_) => _carregarEventosDoMes());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        title: const Text("Agenda de Serviços"),
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: "Ir para Hoje",
            onPressed: () {
              setState(() {
                final hoje = DateTime.now();
                _focusedDay = hoje;
                _selectedDay = hoje;
                _eventosSelecionados = _getEventosDoDia(hoje);
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          : SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    locale: 'pt_BR',
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        color: corTextoClaro,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: TextStyle(color: corTextoClaro),
                      weekendTextStyle: const TextStyle(
                        color: Colors.redAccent,
                      ),
                      outsideTextStyle: const TextStyle(color: Colors.grey),
                      markerDecoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      markerSize: 6.0,
                      selectedDecoration: BoxDecoration(
                        color: corPrincipal,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: corHoje, width: 2.0),
                      ),
                      todayTextStyle: TextStyle(
                        color: corHoje,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      selectedBuilder: (context, date, focusedDay) {
                        if (isSameDay(date, DateTime.now())) {
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: corPrincipal,
                              shape: BoxShape.circle,
                              border: Border.all(color: corHoje, width: 2.0),
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _eventosSelecionados = _getEventosDoDia(selectedDay);
                      });
                    },
                    onFormatChanged: (format) =>
                        setState(() => _calendarFormat = format),
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    eventLoader: _getEventosDoDia,
                  ),
                  const SizedBox(height: 20),

                  // BOTÃO: GERENCIAR DIA (Mantive indo para ListaOrcamentosDia)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corHoje,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _navegarParaListaDoDia,
                        icon: const Icon(Icons.list_alt),
                        label: Text(
                          "Gerenciar Dia (${DateFormat("d/MM").format(_selectedDay!)})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Orçamentos deste dia:",
                        style: TextStyle(
                          color: corTextoClaro,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _eventosSelecionados.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Text(
                            "Nenhum serviço agendado.",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _eventosSelecionados.length,
                          itemBuilder: (context, index) {
                            final item = _eventosSelecionados[index];

                            final titulo = item['titulo'] ?? 'Sem Título';
                            String nomeCliente = 'Cliente não identificado';
                            if (item['clientes'] != null) {
                              nomeCliente =
                                  item['clientes']['nome'] ?? 'Sem Nome';
                            }

                            final horario = item['horario_do_dia'] ?? 'Manhã';
                            final isTarde = horario == 'Tarde';
                            final iconHorario = isTarde
                                ? Icons.wb_twilight
                                : Icons.wb_sunny_outlined;
                            final colorHorario = isTarde
                                ? Colors.orangeAccent
                                : Colors.yellowAccent;

                            return Card(
                              color: const Color(0xFF1E1E1E),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    iconHorario,
                                    color: colorHorario,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  titulo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 14,
                                        color: corTextoCinza,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          nomeCliente,
                                          style: TextStyle(
                                            color: corTextoCinza,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorHorario.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: colorHorario.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    horario.toUpperCase(),
                                    style: TextStyle(
                                      color: colorHorario,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // AQUI ESTÁ A ALTERAÇÃO PRINCIPAL:
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      // Assume que DetalhesOrcamento aceita um ID
                                      // Ajuste 'orcamentoId' conforme o construtor da sua tela
                                      builder: (context) => DetalhesOrcamento(
                                        orcamentoInicial: item,
                                      ),
                                    ),
                                  ).then((_) {
                                    // Recarrega os eventos ao voltar, caso algo tenha mudado
                                    _carregarEventosDoMes();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
