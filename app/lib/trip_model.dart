import 'chat_provider.dart';

enum TripStatus { dreaming, planning, booked, ready }

extension TripStatusX on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.dreaming: return 'Dreaming';
      case TripStatus.planning: return 'Planning';
      case TripStatus.booked:   return 'Booked';
      case TripStatus.ready:    return 'Ready';
    }
  }
}

class Trip {
  final String id;
  final DateTime createdAt;
  HolidayState state;
  List<ChatMessage> messages;
  List<String> participants;

  Trip({
    required this.id,
    required this.createdAt,
    HolidayState? state,
    List<ChatMessage>? messages,
    this.participants = const [],
  })  : state = state ?? const HolidayState(),
        messages = messages ?? [];

  String get displayName => state.tripTitle ?? state.destination ?? 'New Trip';

  TripStatus get status {
    if (state.destination == null) return TripStatus.dreaming;
    final hasBookingInfo =
        state.dateFrom != null && state.dateTo != null && state.accommodation != null;
    if (hasBookingInfo) {
      final allDone = state.todos.isNotEmpty && state.todos.every((t) => t.done);
      return allDone ? TripStatus.ready : TripStatus.booked;
    }
    return TripStatus.planning;
  }

  double get progress {
    final fields = [
      state.destination,
      state.dateFrom,
      state.dateTo,
      state.budget,
      state.accommodation,
    ];
    int filled = fields.where((f) => f != null).length;
    int total = fields.length;

    if (state.todos.isNotEmpty) {
      filled += state.todos.where((t) => t.done).length;
      total += state.todos.length;
    }

    return total == 0 ? 0.0 : filled / total;
  }
}
