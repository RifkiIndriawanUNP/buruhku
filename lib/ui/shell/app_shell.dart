import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buruhku/data/repositories/app_state/app_state.dart';
import 'package:buruhku/ui/core/ui.dart';
import 'package:buruhku/ui/account/account_screen.dart';
import 'package:buruhku/ui/agent_mode/agent_screen.dart';
import 'package:buruhku/ui/chat/chat_screen.dart';
import 'package:buruhku/ui/home/home_screen.dart';
import 'package:buruhku/ui/home/home_view_model.dart';
import 'package:buruhku/ui/order/order_screen.dart';
import 'package:buruhku/ui/request/request_screen.dart';
import 'package:buruhku/ui/shell/app_shell_view_model.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final AppShellViewModel _vm = AppShellViewModel(store: context.read<AppState>());
  late final HomeViewModel _home = HomeViewModel(store: context.read<AppState>());
  bool _hidden = false;
  double _accumulatedScroll = 0;

  late final List<Widget> _clientPages = [
    HomeTab(viewModel: _home),
    const HistoryTab(),
    const MyRequestsTab(),
    const ChatsTab(),
    const AccountTab(),
  ];

  static const List<Widget> _agentPages = [
    IncomingTab(),
    JobsTab(),
    ChatsTab(),
    EarningsTab(),
    AccountTab(),
  ];

  @override
  void dispose() {
    _vm.dispose();
    _home.dispose();
    super.dispose();
  }

  bool _onNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && notification.metrics.axis == Axis.vertical) {
      final delta = notification.scrollDelta ?? 0;
      if (notification.metrics.pixels <= 10) {
        if (_hidden) setState(() => _hidden = false);
        _accumulatedScroll = 0;
      } else if (delta > 0) {
        _accumulatedScroll = (_accumulatedScroll > 0) ? _accumulatedScroll + delta : delta;
        if (_accumulatedScroll > 40 && !_hidden) {
          setState(() => _hidden = true);
          _accumulatedScroll = 0;
        }
      } else if (delta < 0) {
        _accumulatedScroll = (_accumulatedScroll < 0) ? _accumulatedScroll + delta : delta;
        if (_accumulatedScroll < -25 && _hidden) {
          setState(() => _hidden = false);
          _accumulatedScroll = 0;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: _vm, builder: (context, _) => _body(context));

  Widget _body(BuildContext context) {
    final n = _vm.takeToast();
    if (n != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('${n.title}\n${n.body}', maxLines: 3, overflow: TextOverflow.ellipsis),
              action: SnackBarAction(label: 'Lihat', textColor: cW, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotifPage())))));
      });
    }
    final agent = _vm.agentMode;
    final items = agent
      ? [
          const BarItem(Icons.inbox_outlined, 'Masuk', 0, Icons.inbox),
          const BarItem(Icons.work_outline, 'Pekerjaanku', 0, Icons.work),
          BarItem(Icons.chat_bubble_outline, 'Pesan', _vm.unreadChats, Icons.chat_bubble),
          const BarItem(Icons.account_balance_wallet_outlined, 'Pendapatan', 0, Icons.account_balance_wallet),
          const BarItem(Icons.person_outline, 'Akun', 0, Icons.person),
        ]
      : [
          const BarItem(Icons.home_outlined, 'Beranda', 0, Icons.home),
          const BarItem(Icons.event_note_outlined, 'Aktivitas', 0, Icons.event_note),
          const BarItem(Icons.add, 'Request'),
          BarItem(Icons.chat_bubble_outline, 'Pesan', _vm.unreadChats, Icons.chat_bubble),
          const BarItem(Icons.person_outline, 'Akun', 0, Icons.person),
        ];
    final pages = agent ? _agentPages : _clientPages;
    final i = _vm.tab;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onNotification,
            child: RepaintBoundary(
              child: SafeArea(
                bottom: false,
                child: IndexedStack(index: i, children: [
                  // Tiap tab memutar ulang urutan animasi barisnya setiap kali dibuka. Key memuat mode agar ikut diputar saat ganti mode.
                  for (var k = 0; k < pages.length; k++)
                    RevealTab(key: ValueKey('tab-${agent ? 'a' : 'c'}$k'), active: k == i, child: pages[k]),
                ]),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            // Bar bawah muncul lebih dulu dan lebih singkat, tanpa sapuan.
            child: Reveal(
              blur: 6,
              dy: 18,
              duration: const Duration(milliseconds: 500),
              child: BottomBar(
                index: i,
                items: items,
                center: agent ? null : 2,
                onTap: (v) {
                  if (_hidden) setState(() => _hidden = false);
                  _vm.goTab(v);
                },
                compact: _hidden,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
