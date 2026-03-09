import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'trip_model.dart';

// ─── Theme constants ──────────────────────────────────────────────────────────

const _bg      = Color(0xFFF7F7F7);
const _surface = Color(0xFFFFFFFF);
const _border  = Color(0xFFEBEBEB);
const _text1   = Color(0xFF222222);
const _text2   = Color(0xFF717171);
const _text3   = Color(0xFFB0B0B0);
const _accent  = Color(0xFF1A73E8);

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  final Trip trip;
  final void Function(HolidayState, List<ChatMessage>) onSave;

  const ChatScreen({super.key, required this.trip, required this.onSave});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatProvider>().send(text).then((_) => _scrollToBottom());
  }

  void _handleBack() {
    final provider = context.read<ChatProvider>();
    widget.onSave(provider.state, provider.messages);
    Navigator.pop(context);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          Expanded(child: _DashboardPanel(onBack: _handleBack)),
          Container(width: 1, color: _border),
          Expanded(child: _ChatPanel(
            scrollCtrl: _scrollCtrl,
            controller: _controller,
            onSend: _send,
          )),
        ],
      ),
    );
  }
}

// ─── Dashboard Panel ──────────────────────────────────────────────────────────

class _DashboardPanel extends StatelessWidget {
  final VoidCallback onBack;
  const _DashboardPanel({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ChatProvider>().state;

    return Container(
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DestinationHero(state: s),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoGrid(state: s),
                        const SizedBox(height: 20),
                        if (s.vibe.isNotEmpty)
                          _TagRow(label: 'Vibe', tags: s.vibe, color: _accent),
                        if (s.mustDos.isNotEmpty)
                          _TagRow(label: 'Must-dos', tags: s.mustDos, color: const Color(0xFF34A853)),
                        if (s.constraints.isNotEmpty)
                          _TagRow(label: 'Constraints', tags: s.constraints, color: const Color(0xFFEA4335)),
                        _TodoList(todos: s.todos),
                        const SizedBox(height: 16),
                        _MetaBar(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(16, 20, 24, 16),
    color: _surface,
    child: Row(children: [
      GestureDetector(
        onTap: onBack,
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: _text2, size: 16),
      ),
      const SizedBox(width: 12),
      const Text('✈', style: TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      const Text('Voyager', style: TextStyle(
        color: _text1, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3,
      )),
      const Spacer(),
      const Text('Holiday Planner', style: TextStyle(color: _text2, fontSize: 12)),
    ]),
  );
}

// ─── Destination Hero ─────────────────────────────────────────────────────────

class _DestinationHero extends StatelessWidget {
  final HolidayState state;
  const _DestinationHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final destination = state.destination;
    final tripTitle   = state.tripTitle;

    if (destination == null && tripTitle == null) {
      return Container(
        width: double.infinity,
        height: 160,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F0FE), _bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DESTINATION', style: TextStyle(color: _text2, fontSize: 10, letterSpacing: 1.5)),
            SizedBox(height: 8),
            Text('Not decided yet...', style: TextStyle(color: _text3, fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cartographer.png',
                repeat: ImageRepeat.repeat,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DESTINATION',
                  style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  tripTitle ?? destination ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (state.dateFrom != null || state.dateTo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${state.dateFrom ?? '?'} → ${state.dateTo ?? '?'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Grid ────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final HolidayState state;
  const _InfoGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Duration',      state.duration),
      ('Budget',        state.budget),
      ('Accommodation', state.accommodation),
      ('Travellers',    state.travellers.isEmpty ? null : state.travellers.join(', ')),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.5,
      children: items.map((i) => _InfoCard(label: i.$1, value: i.$2)).toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: _text2, fontSize: 9, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(
            value ?? '—',
            style: TextStyle(color: value != null ? _text1 : _text3, fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Tag Row ──────────────────────────────────────────────────────────────────

class _TagRow extends StatelessWidget {
  final String label;
  final List<String> tags;
  final Color color;
  const _TagRow({required this.label, required this.tags, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: _text2, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Todo List ────────────────────────────────────────────────────────────────

class _TodoList extends StatelessWidget {
  final List<Todo> todos;
  const _TodoList({required this.todos});

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) return const SizedBox.shrink();

    final pending   = todos.where((t) => !t.done).toList();
    final completed = todos.where((t) => t.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(children: [
          const Text('TODOS', style: TextStyle(color: _text2, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${pending.length} left', style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 10),
        ...pending.map((t) => _TodoItem(todo: t)),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...completed.map((t) => _TodoItem(todo: t)),
        ],
      ],
    );
  }
}

class _TodoItem extends StatelessWidget {
  final Todo todo;
  const _TodoItem({required this.todo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<ChatProvider>().toggleTodo(todo.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Icon(
            todo.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: todo.done ? const Color(0xFF34A853) : _accent.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            todo.text,
            style: TextStyle(
              color: todo.done ? _text3 : _text1,
              fontSize: 13,
              decoration: todo.done ? TextDecoration.lineThrough : null,
            ),
          )),
        ]),
      ),
    );
  }
}

// ─── Meta Bar ─────────────────────────────────────────────────────────────────

class _MetaBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ChatProvider>();
    if (p.lastResponseMs == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetaStat(label: 'Time', value: '${p.lastResponseMs}ms'),
          _MetaStat(label: 'Tokens', value: '${(p.lastTokensIn ?? 0) + (p.lastTokensOut ?? 0)}'),
          _MetaStat(label: 'Cost', value: '\$${p.lastCostUsd?.toStringAsFixed(5) ?? '—'}'),
        ],
      ),
    );
  }
}

class _MetaStat extends StatelessWidget {
  final String label, value;
  const _MetaStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(color: _text1, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(color: _text2, fontSize: 10)),
    ],
  );
}

// ─── Chat Panel ───────────────────────────────────────────────────────────────

class _ChatPanel extends StatelessWidget {
  final ScrollController scrollCtrl;
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatPanel({required this.scrollCtrl, required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Container(
      color: _bg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            color: _surface,
            child: Row(children: [
              const Text('Chat', style: TextStyle(color: _text1, fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (provider.isLoading)
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                ),
            ]),
          ),
          Container(height: 1, color: _border),

          Expanded(
            child: provider.messages.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.messages.length,
                    itemBuilder: (_, i) => _Bubble(message: provider.messages[i]),
                  ),
          ),

          if (provider.error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFEA4335).withValues(alpha: 0.08),
              child: Text(provider.error!, style: const TextStyle(color: Color(0xFFEA4335), fontSize: 12)),
            ),

          Container(
            padding: const EdgeInsets.all(16),
            color: _surface,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(color: _text1, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Tell me about your dream holiday...',
                    hintStyle: TextStyle(color: _text3),
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _accent),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.35),
        decoration: BoxDecoration(
          color: isUser ? _accent : _surface,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: isUser ? null : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : _text1, fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✈', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('Where do you want to go?', style: TextStyle(color: _text1, fontSize: 16, fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Text('Start chatting to plan your holiday', style: TextStyle(color: _text2, fontSize: 13)),
        ],
      ),
    );
  }
}
