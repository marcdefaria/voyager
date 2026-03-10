import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'trip_model.dart';
import 'chat_provider.dart';

class TripsProvider extends ChangeNotifier {
  final String _uid;
  final List<Trip> _trips = [];
  bool isLoading = true;

  TripsProvider(this._uid) {
    _load();
  }

  List<Trip> get trips => List.unmodifiable(_trips);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users').doc(_uid).collection('trips');

  Future<void> _load() async {
    try {
      final snap = await _col.orderBy('createdAt', descending: true).get();
      _trips.addAll(snap.docs.map((d) => Trip.fromFirestore(d)));
    } catch (e) {
      debugPrint('TripsProvider: failed to load trips: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<Trip> createTrip() async {
    final trip = Trip(id: const Uuid().v4(), createdAt: DateTime.now());
    _trips.insert(0, trip);
    notifyListeners();
    await _col.doc(trip.id).set(trip.toFirestore());
    return trip;
  }

  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
    await _col.doc(id).delete();
  }

  Future<void> updateTrip(String id, HolidayState state, List<ChatMessage> messages) async {
    final index = _trips.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _trips[index].state    = state;
    _trips[index].messages = List.from(messages);
    notifyListeners();
    await _col.doc(id).update({
      'state':     state.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
