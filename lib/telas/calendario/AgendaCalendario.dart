import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // NECESSÁRIO PARA O ERRO DE LOCALE
import 'ListaOrcamentosDia.dart'; // Import da tela de detalhes

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
  bool _isLoading = true;

  final Color corFundo = Colors.black;
  final Color corPrincipal = Colors.red[900]!;
  final Color corTextoClaro = Colors.white;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // CORREÇÃO DO ERRO DE LOCALE: Inicializa a formatação de data
    initializeDateFormatting('pt_BR', null).then((_) {
      _carregarEventosDoMes();
    });
  }

  Future<void> _carregarEventosDoMes() async {
    try {
      // CORREÇÃO DO ERRO DE COLUNA: Trocado 'data_servico' por 'data_pega'
      final response = await Supabase.instance.client
          .from('orcamentos')
          .select('data_pega');

      final Map<DateTime, List<dynamic>> eventos = {};

      for (var item in response) {
        if (item['data_pega'] != null) {
          // Trocado aqui também
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

  void _abrirDetalhesDoDia(DateTime dia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListaOrcamentosDia(dataSelecionada: dia),
      ),
    ).then((_) => _carregarEventosDoMes());
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: corPrincipal))
          // Adicionado SingleChildScrollView para evitar overflow em telas pequenas
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
                      selectedDecoration: BoxDecoration(
                        color: corPrincipal,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),

                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _abrirDetalhesDoDia(selectedDay);
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: _getEventosDoDia,
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Dias com serviços agendados",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
