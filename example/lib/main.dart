import 'package:candle_reader/candle_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const CandleLightDemoApp());
}

class CandleLightDemoApp extends StatelessWidget {
  const CandleLightDemoApp({super.key});

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
  static const List<_PaletteChoice> _palettes = <_PaletteChoice>[
    _PaletteChoice('Warm', FlamePalette.warm),
    _PaletteChoice('Blue', FlamePalette.blue),
    _PaletteChoice('Green', FlamePalette.green),
    _PaletteChoice('Red', FlamePalette.red),
    _PaletteChoice('Violet', FlamePalette.violet),
  ];

  int _paletteIndex = 0;
  CandleLightInteraction _mode = CandleLightInteraction.twoFinger;

  _PaletteChoice get _palette => _palettes[_paletteIndex];

  bool get _pinchMode => _mode == CandleLightInteraction.grab;

  void _cyclePalette() {
    HapticFeedback.selectionClick();
    setState(() => _paletteIndex = (_paletteIndex + 1) % _palettes.length);
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _mode = _pinchMode
          ? CandleLightInteraction.twoFinger
          : CandleLightInteraction.grab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CandleLight(
            interaction: _mode,
            palette: _palette.value,
            initialRadius: 180,
            onExtinguished: () => debugPrint('candle: blown out'),
            onRelit: () => debugPrint('candle: re-lit'),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(28, 110, 28, 90),
              physics: _pinchMode
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: _chapters.length,
              itemBuilder: (context, i) => _ChapterView(chapter: _chapters[i]),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: _TopBar(
                paletteName: _palette.name,
                swatch: _palette.value.mid,
                onCyclePalette: _cyclePalette,
                pinchMode: _pinchMode,
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
}

class _PaletteChoice {
  const _PaletteChoice(this.name, this.value);
  final String name;
  final FlamePalette value;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.paletteName,
    required this.swatch,
    required this.onCyclePalette,
    required this.pinchMode,
    required this.onToggleMode,
  });

  final String paletteName;
  final Color swatch;
  final VoidCallback onCyclePalette;
  final bool pinchMode;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'CANDLE READER',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11.5,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pinchMode ? 'PINCH MODE' : 'READ MODE',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 22,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _PillButton(
            onTap: onToggleMode,
            icon: pinchMode ? Icons.pan_tool_rounded : Icons.swap_vert_rounded,
            iconColor:
                Colors.amber.withValues(alpha: pinchMode ? 0.95 : 0.75),
            label: pinchMode ? 'PINCH' : 'READ',
          ),
          const SizedBox(width: 2),
          Container(
            width: 1,
            height: 22,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          _PillButton(
            onTap: onCyclePalette,
            swatch: swatch,
            label: paletteName.toUpperCase(),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.onTap,
    required this.label,
    this.icon,
    this.iconColor,
    this.swatch,
  });

  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (swatch != null)
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: swatch,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: swatch!.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              if (icon != null) Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

class _ChapterView extends StatelessWidget {
  const _ChapterView({required this.chapter});

  final _Chapter chapter;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Georgia',
        color: Color(0xFFEFE3CE),
        fontSize: 17,
        height: 1.75,
        letterSpacing: 0.15,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              chapter.label,
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
              chapter.title,
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
            Text(chapter.body, textAlign: TextAlign.justify),
          ],
        ),
      ),
    );
  }
}

class _Chapter {
  const _Chapter(this.label, this.title, this.body);
  final String label;
  final String title;
  final String body;
}

const List<_Chapter> _chapters = <_Chapter>[
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
    'COLDER FIRES',
    'Not every flame is the color you expect. Some libraries keep a '
        'shelf of old travelers\' journals — and in one of them, a '
        'woman describes a chapel lamp that burned blue for a week '
        'after her daughter was born. She never said what kind of oil '
        'the lamp took. She only said she read by it, and the pages '
        'had looked colder than usual, though the room was warm.\n\n'
        'Duis leo. Fusce fermentum odio nec arcu. Vivamus laoreet. '
        'Nullam tincidunt adipiscing enim. Phasellus tempus. '
        'Proin viverra, ligula sit amet ultrices semper, ligula arcu '
        'tristique sapien, a accumsan nisi mauris ac eros.',
  ),
  _Chapter(
    'Chapter V',
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
