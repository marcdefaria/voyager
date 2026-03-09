import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser})
      : timestamp = DateTime.now();
}

class Todo {
  final String id;
  final String text;
  bool done;

  Todo({required this.id, required this.text, this.done = false});

  factory Todo.fromJson(Map<String, dynamic> j) => Todo(
        id:   j['id']?.toString() ?? '',
        text: j['text'] ?? '',
        done: j['done'] ?? false,
      );
}

class HolidayState {
  final String? tripTitle;
  final String? destination;
  final String? dateFrom;
  final String? dateTo;
  final String? duration;
  final List<String> travellers;
  final String? budget;
  final String? accommodation;
  final List<String> vibe;
  final List<String> mustDos;
  final List<String> constraints;
  final List<Todo> todos;

  const HolidayState({
    this.tripTitle,
    this.destination,
    this.dateFrom,
    this.dateTo,
    this.duration,
    this.travellers = const [],
    this.budget,
    this.accommodation,
    this.vibe = const [],
    this.mustDos = const [],
    this.constraints = const [],
    this.todos = const [],
  });

  factory HolidayState.fromJson(Map<String, dynamic> j) {
    final dates = j['dates'] as Map<String, dynamic>? ?? {};
    return HolidayState(
      tripTitle:     j['tripTitle'] as String?,
      destination:   j['destination'] as String?,
      dateFrom:      dates['from'] as String?,
      dateTo:        dates['to'] as String?,
      duration:      j['duration']?.toString(),
      travellers:    _toStringList(j['travellers']),
      budget:        j['budget']?.toString(),
      accommodation: j['accommodation'] as String?,
      vibe:          _toStringList(j['vibe']),
      mustDos:       _toStringList(j['mustDos']),
      constraints:   _toStringList(j['constraints']),
      todos: (j['todos'] as List<dynamic>? ?? [])
          .map((t) => Todo.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v.map((e) {
        if (e is Map) return (e['name'] ?? e.values.firstOrNull)?.toString() ?? '';
        return e.toString();
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

class ChatProvider extends ChangeNotifier {
  static const _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  final String sessionId;
  final List<ChatMessage> messages;
  HolidayState state;
  bool isLoading = false;
  String? error;

  ChatProvider({
    String? sessionId,
    HolidayState? initialState,
    List<ChatMessage>? initialMessages,
  })  : sessionId = sessionId ?? const Uuid().v4(),
        state = initialState ?? const HolidayState(),
        messages = List.from(initialMessages ?? []);

  // Last call metadata
  int? lastResponseMs;
  double? lastCostUsd;
  int? lastTokensIn;
  int? lastTokensOut;

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(text: text, isUser: true));
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionId': sessionId, 'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        messages.add(ChatMessage(text: data['message'] ?? '', isUser: false));

        if (data['state'] != null) {
          state = HolidayState.fromJson(data['state'] as Map<String, dynamic>);
        }

        final meta = data['meta'] as Map<String, dynamic>?;
        if (meta != null) {
          lastResponseMs = meta['responseMs'] as int?;
          lastCostUsd    = (meta['costUsd'] as num?)?.toDouble();
          lastTokensIn   = meta['inputTokens'] as int?;
          lastTokensOut  = meta['outputTokens'] as int?;
        }
      } else {
        error = 'Server error ${response.statusCode}';
      }
    } catch (e) {
      error = 'Could not reach server. Is it running?';
    }

    isLoading = false;
    notifyListeners();
  }

  void toggleTodo(String id) {
    final todo = state.todos.firstWhere((t) => t.id == id, orElse: () => Todo(id: '', text: ''));
    if (todo.id.isEmpty) return;
    todo.done = !todo.done;
    notifyListeners();
  }
}
