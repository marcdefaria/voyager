import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'trip_model.dart';
import 'trips_provider.dart';
import 'chat_provider.dart';
import 'chat_screen.dart';

// ─── Theme constants (mirrors chat_screen.dart) ────────────────────────────────

const _bg      = Color(0xFFF7F7F7);
const _surface = Color(0xFFFFFFFF);
const _border  = Color(0xFFEBEBEB);
const _text1   = Color(0xFF222222);
const _text2   = Color(0xFF717171);
const _text3   = Color(0xFFB0B0B0);
const _accent  = Color(0xFF1A73E8);

// ─── Screen ───────────────────────────────────────────────────────────────────

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  void _openTrip(BuildContext context, Trip trip) {
    final tripsProvider = context.read<TripsProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ChatProvider(
            sessionId: trip.id,
            initialState: trip.state,
            initialMessages: trip.messages,
          ),
          child: ChatScreen(
            trip: trip,
            onSave: (state, messages) {
              if (state.destination == null && messages.isEmpty) {
                tripsProvider.deleteTrip(trip.id);
              } else {
                tripsProvider.updateTrip(trip.id, state, messages);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _newTrip(BuildContext context) async {
    final trip = await context.read<TripsProvider>().createTrip();
    if (context.mounted) _openTrip(context, trip);
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripsProvider>().trips;

    final isLoading = context.watch<TripsProvider>().isLoading;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onNewTrip: () => _newTrip(context)),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : trips.isEmpty
                ? _EmptyState(onNewTrip: () => _newTrip(context))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: trips.length,
                    itemBuilder: (_, i) => _TripCard(
                      trip: trips[i],
                      onTap: () => _openTrip(context, trips[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onNewTrip;
  const _Header({required this.onNewTrip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: _surface,
      child: Row(
        children: [
          const Text('✈', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          const Text(
            'Voyager',
            style: TextStyle(
              color: _text1,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onNewTrip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('New Trip', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewTrip;
  const _EmptyState({required this.onNewTrip});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('✈', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          const Text('No trips yet', style: TextStyle(color: _text1, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Start planning your next adventure', style: TextStyle(color: _text2, fontSize: 14)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onNewTrip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Plan a trip', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  const _TripCard({required this.trip, required this.onTap});

  Color _statusColor(TripStatus status) {
    switch (status) {
      case TripStatus.dreaming: return _text3;
      case TripStatus.planning: return const Color(0xFF1A73E8);
      case TripStatus.booked:   return const Color(0xFF34A853);
      case TripStatus.ready:    return const Color(0xFFE8A010);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status      = trip.status;
    final progress    = trip.progress;
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('DESTINATION', style: TextStyle(color: _text2, fontSize: 10, letterSpacing: 1.5)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.label,
                            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      trip.displayName,
                      style: TextStyle(
                        color: trip.state.destination != null ? _text1 : _text3,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),

                    if (trip.state.dateFrom != null || trip.state.dateTo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${trip.state.dateFrom ?? '?'} → ${trip.state.dateTo ?? '?'}',
                        style: const TextStyle(color: _text2, fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_add_outlined, size: 13, color: _text2),
                              SizedBox(width: 5),
                              Text('Invite', style: TextStyle(color: _text2, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}% organised',
                          style: const TextStyle(color: _text2, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Progress bar
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: _border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? const Color(0xFFE8A010) : _accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
