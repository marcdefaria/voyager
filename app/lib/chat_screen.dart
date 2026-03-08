import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatProvider>().send(text).then((_) => _scrollToBottom());
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
      backgroundColor: const Color(0xFF0F0F0F),
      body: Row(
        children: [
          // ── Left: Dashboard ──────────────────────────────────────────────
          Expanded(child: _DashboardPanel()),
          // Divider
          Container(width: 1, color: const Color(0xFF2A2A2A)),
          // ── Right: Chat ──────────────────────────────────────────────────
          Expanded(child: _ChatPanel(scrollCtrl: _scrollCtrl, controller: _controller, onSend: _send)),
        ],
      ),
    );
  }
}

// ─── Dashboard Panel ──────────────────────────────────────────────────────────

class _DashboardPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<ChatProvider>().state;

    return Container(
      color: const Color(0xFF111111),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DestinationHero(state: s),
                  const SizedBox(height: 24),
                  _InfoGrid(state: s),
                  const SizedBox(height: 24),
                  if (s.vibe.isNotEmpty)     _TagRow(label: 'Vibe', tags: s.vibe, color: const Color(0xFF1A73E8)),
                  if (s.mustDos.isNotEmpty)  _TagRow(label: 'Must-dos', tags: s.mustDos, color: const Color(0xFF34A853)),
                  if (s.constraints.isNotEmpty) _TagRow(label: 'Constraints', tags: s.constraints, color: const Color(0xFFEA4335)),
                  const SizedBox(height: 24),
                  _TodoList(todos: s.todos),
                  const SizedBox(height: 24),
                  _MetaBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
    ),
    child: Row(children: [
      const Text('✈', style: TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      Text('Voyager', style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      )),
      const Spacer(),
      Text('Holiday Planner', style: TextStyle(color: Colors.white38, fontSize: 12)),
    ]),
  );
}

class _DestinationHero extends StatelessWidget {
  final HolidayState state;
  const _DestinationHero({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A73E8).withOpacity(0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DESTINATION', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            state.destination ?? 'Not decided yet...',
            style: TextStyle(
              color: state.destination != null ? Colors.white : Colors.white24,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (state.dateFrom != null || state.dateTo != null) ...[
            const SizedBox(height: 8),
            Text(
              '${state.dateFrom ?? '?'} → ${state.dateTo ?? '?'}',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

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
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: items.map((item) => _InfoCard(label: item.$1, value: item.$2)).toList(),
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
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(
            value ?? '—',
            style: TextStyle(
              color: value != null ? Colors.white : Colors.white24,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

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
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                border: Border.all(color: color.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t, style: TextStyle(color: color, fontSize: 12)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

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
        Row(children: [
          const Text('TODOS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${pending.length} left', style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 10)),
          ),
        ]),
        const SizedBox(height: 10),
        ...pending.map((t) => _TodoItem(todo: t)),
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 8),
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(children: [
          Icon(
            todo.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: todo.done ? const Color(0xFF34A853) : Colors.white38,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            todo.text,
            style: TextStyle(
              color: todo.done ? Colors.white38 : Colors.white70,
              fontSize: 13,
              decoration: todo.done ? TextDecoration.lineThrough : null,
            ),
          )),
        ]),
      ),
    );
  }
}

class _MetaBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<ChatProvider>();
    if (p.lastResponseMs == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
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
      Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ],
  );
}

// ─── Chat Panel ───────────────────────────────────────────────────────────────

class _ChatPanel extends StatelessWidget {
  final ScrollController scrollCtrl;
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatPanel({
    required this.scrollCtrl,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: Row(children: [
            const Text('Chat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (provider.isLoading)
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A73E8))),
          ]),
        ),

        // Messages
        Expanded(
          child: provider.messages.isEmpty
              ? _EmptyState()
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
            color: const Color(0xFFEA4335).withOpacity(0.1),
            child: Text(provider.error!, style: const TextStyle(color: Color(0xFFEA4335), fontSize: 12)),
          ),

        // Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tell me about your dream holiday...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1A73E8)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ],
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
          color: isUser ? const Color(0xFF1A73E8) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white.withOpacity(0.85),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✈', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Where do you want to go?',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting to plan your holiday',
            style: TextStyle(color: Colors.white24, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
