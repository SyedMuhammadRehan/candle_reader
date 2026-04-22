import 'package:candle_reader/candle_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CandleReaderApp());
}

class CandleReaderApp extends StatelessWidget {
  const CandleReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candle Light Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060606),
        fontFamily: 'Georgia',
      ),
      home: const BookReaderPage(),
    );
  }
}

class BookReaderPage extends StatefulWidget {
  const BookReaderPage({super.key});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  CandleLightInteraction _mode = CandleLightInteraction.grab;
  final PageController _pc = PageController();
  final ScrollController _sc = ScrollController();
  int _index = 0;

  @override
  void dispose() {
    _pc.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, _pages.length - 1);
    if (next == _index) return;
    HapticFeedback.selectionClick();
    _pc.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = _mode == CandleLightInteraction.grab
          ? CandleLightInteraction.twoFinger
          : CandleLightInteraction.grab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scrolling = _mode == CandleLightInteraction.twoFinger;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CandleLight(
            interaction: _mode,
            initialRadius: 170,
            onExtinguished: () => debugPrint('candle: blown out'),
            onRelit: () => debugPrint('candle: re-lit'),
            child: scrolling ? _buildScrollable() : _buildPaged(),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _TopBar(
                index: _index,
                total: _pages.length,
                mode: _mode,
                onPrev: !scrolling && _index > 0 ? () => _go(-1) : null,
                onNext: !scrolling && _index < _pages.length - 1
                    ? () => _go(1)
                    : null,
                onToggleMode: _toggleMode,
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _MadeInFlutter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaged() {
    return PageView.builder(
      controller: _pc,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pages.length,
      onPageChanged: (i) => setState(() => _index = i),
      itemBuilder: (context, i) => _BookPage(page: _pages[i], paged: true),
    );
  }

  Widget _buildScrollable() {
    return ListView.builder(
      controller: _sc,
      padding: const EdgeInsets.fromLTRB(28, 110, 28, 80),
      itemCount: _pages.length,
      itemBuilder: (context, i) =>
          _BookPage(page: _pages[i], paged: false),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.total,
    required this.mode,
    required this.onPrev,
    required this.onNext,
    required this.onToggleMode,
  });

  final int index;
  final int total;
  final CandleLightInteraction mode;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final paged = mode == CandleLightInteraction.grab;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _NavButton(icon: Icons.chevron_left, onTap: onPrev),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'CANDLE  READER',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  paged ? '${index + 1} / $total' : 'SCROLL MODE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          _NavButton(icon: Icons.chevron_right, onTap: onNext),
          const SizedBox(width: 4),
          Container(
            width: 1,
            height: 22,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onToggleMode,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  paged ? Icons.pan_tool_rounded : Icons.swap_vert_rounded,
                  size: 18,
                  color: Colors.amber.withValues(alpha: paged ? 0.75 : 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white.withValues(alpha: enabled ? 0.8 : 0.2),
          ),
        ),
      ),
    );
  }
}

class _MadeInFlutter extends StatelessWidget {
  const _MadeInFlutter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'MADE IN',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: 9,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.flutter_dash,
            size: 14,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 4),
          Text(
            'FLUTTER',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 9,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPage extends StatelessWidget {
  const _BookPage({required this.page, required this.paged});

  final _Chapter page;
  final bool paged;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          page.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Georgia',
            color: Color(0xFFEFE3CE),
            fontSize: 22,
            fontStyle: FontStyle.italic,
            letterSpacing: 2,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Georgia',
            color: Color(0xFFEFE3CE),
            fontSize: 14,
            letterSpacing: 6,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 28),
        Text(page.body, textAlign: TextAlign.justify),
        if (!paged) const SizedBox(height: 56),
      ],
    );

    if (paged) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(28, 96, 28, 64),
        child: DefaultTextStyle(
          style: _bodyStyle,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: content,
          ),
        ),
      );
    }
    return DefaultTextStyle(style: _bodyStyle, child: content);
  }
}

const TextStyle _bodyStyle = TextStyle(
  fontFamily: 'Georgia',
  color: Color(0xFFEFE3CE),
  fontSize: 17,
  height: 1.75,
  letterSpacing: 0.15,
);

class _Chapter {
  const _Chapter(this.label, this.title, this.body);
  final String label;
  final String title;
  final String body;
}

const List<_Chapter> _pages = <_Chapter>[
  _Chapter(
    'Chapter I',
    'THE LIGHT BENEATH THE PAGE',
    'It was very late, and the house had sunk into that soft, listening '
        'silence that only old houses know. A single candle burned on the '
        'desk beside her, its small flame leaning and trembling as though '
        'it, too, were eavesdropping on the night. She set one fingertip '
        'lightly to the page, and the warm halo of light moved with her, '
        'pooling over each sentence like honey finding its own shape.\n\n'
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer '
        'nec odio. Praesent libero. Sed cursus ante dapibus diam. Sed nisi. '
        'Nulla quis sem at nibh elementum imperdiet. Duis sagittis ipsum. '
        'Praesent mauris. Fusce nec tellus sed augue semper porta.',
  ),
  _Chapter(
    'Chapter II',
    'THE WIND AT THE WINDOW',
    'Outside, the wind stirred a loose shutter. The flame ducked for a '
        'moment, as if bowing, then straightened again — taller, she '
        'thought, and somehow kinder. She read on. Each word caught the '
        'light as it came, and each word fell back into shadow as it '
        'passed, the way small fish will flash once and be gone. She did '
        'not mind. The dark between the sentences belonged to her as much '
        'as the light upon them.\n\n'
        'Class aptent taciti sociosqu ad litora torquent per conubia '
        'nostra, per inceptos himenaeos. Curabitur sodales ligula in '
        'libero. Sed dignissim lacinia nunc. Curabitur tortor. Aenean quam. '
        'In scelerisque sem at dolor.',
  ),
  _Chapter(
    'Chapter III',
    'PAPER, WAX, AND TIME',
    'A page is only paper, she reminded herself, and a candle only '
        'wax; yet together they have outlasted empires, and will outlast '
        'many more, because a small light moved by a careful hand is the '
        'oldest act of reading there is.\n\n'
        'Maecenas aliquet accumsan leo. Nullam dapibus fermentum ipsum. '
        'Etiam quis quam. Integer lacinia. Nulla est. Vivamus a tellus. '
        'Pellentesque habitant morbi tristique senectus et netus et '
        'malesuada fames ac turpis egestas.',
  ),
  _Chapter(
    'Chapter IV',
    'THE LAST WISP',
    'When she had read enough, she did not lean across to blow. She '
        'pinched the flame between thumb and forefinger, the way her '
        'grandfather had — the small, confident snuff that left only a '
        'curl of silver smoke climbing slowly toward the rafters.\n\n'
        'The page went dark. The book remembered its place. The smoke '
        'wrote one last sentence she could not read, and the night took '
        'it from her kindly. Outside, the morning was still two hours '
        'away, and she listened to the slow tick of the old clock on '
        'the landing, a sound so familiar she had long since stopped '
        'hearing it except on nights like this, when the candle had '
        'just gone out.',
  ),
];
