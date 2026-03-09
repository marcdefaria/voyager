import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'trip_model.dart';
import 'chat_provider.dart';

class TripsProvider extends ChangeNotifier {
  final List<Trip> _trips = [];

  List<Trip> get trips => List.unmodifiable(_trips);

  Trip createTrip() {
    final trip = Trip(id: const Uuid().v4(), createdAt: DateTime.now());
    _trips.insert(0, trip);
    notifyListeners();
    return trip;
  }

  void updateTrip(String id, HolidayState state, List<ChatMessage> messages) {
    final index = _trips.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _trips[index].state = state;
    _trips[index].messages = List.from(messages);
    notifyListeners();
  }
}
