import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const IraqEduApp());

class IraqEduApp extends StatefulWidget {
  const IraqEduApp({super.key});
  @override
  State<IraqEduApp> createState() => _IraqEduAppState();
}

class _IraqEduAppState extends State<IraqEduApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('darkMode') ?? false;
    if (mounted) setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await prefs.setBool('darkMode', newMode == ThemeMode.dark);
    if (mounted) setState(() => _themeMode = newMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اختبار الأطفال العراقي',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F8F7),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade900,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: toggleTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ═══════════════════════════════════════════
// الشاشة الرئيسية
// ═══════════════════════════════════════════
class HomeScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  const HomeScreen({super.key, required this.isDark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🎓 اختبار الأطفال العراقي'),
          actions: [
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: onToggleTheme,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, size: 80, color: Colors.teal.shade800),
              ),
              const SizedBox(height: 20),
              const Text(
                'اختر الصف الدراسي',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'المرحلة الابتدائية — المنهج العراقي',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildGradeButton(
                context,
                grade: 1,
                title: 'الصف الأول',
                subtitle: '5,000 سؤال',
                emoji: '📗',
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              _buildGradeButton(
                context,
                grade: 2,
                title: 'الصف الثاني',
                subtitle: '10,000 سؤال',
                emoji: '📘',
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildGradeButton(
                context,
                grade: 3,
                title: 'الصف الثالث',
                subtitle: '10,000 سؤال',
                emoji: '📙',
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeButton(
    BuildContext context, {
    required int grade,
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(grade: grade),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 45)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// شاشة الاختبار
// ═══════════════════════════════════════════
class QuizScreen extends StatefulWidget {
  final int grade;
  const QuizScreen({super.key, required this.grade});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _nameCtrl = TextEditingController();

  List<dynamic> _questions = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _loading = true;
  bool _finished = false;
  String _userName = '';
  bool _isSpeaking = false;
  String _errorMsg = '';

  // ⚠️ استبدل IP هنا إذا تغيّر
  final String _apiBase = 'http://192.168.0.100:8080/iraq_edu';

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadQuestions();
  }

  @override
  void dispose() {
    _tts.stop();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _tts.stop();
      if (mounted) setState(() => _isSpeaking = true);
      await _tts.speak(text);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('Speak error: $e');
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _errorMsg = '';
    });

    try {
      final url = Uri.parse('$_apiBase/quiz.php?grade=${widget.grade}&count=20');
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data['success'] == true) {
        setState(() {
          _questions = data['questions'] ?? [];
          _loading = false;
          _currentIndex = 0;
          _correctCount = 0;
          _selectedAnswer = null;
          _showResult = false;
          _finished = false;
          _userName = '';
        });
      } else {
        throw Exception(data['error'] ?? 'فشل تحميل الأسئلة');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'تعذر الاتصال بالخادم\nتأكد من تشغيل Apache و PostgreSQL\n\n$e';
      });
    }
  }

  void _speakQuestion() {
    if (_questions.isEmpty || _currentIndex >= _questions.length) return;
    final q = _questions[_currentIndex];
    final text = '${q['question']}. '
        'الخيار الأول: ${q['option_a']}. '
        'الخيار الثاني: ${q['option_b']}. '
        'الخيار الثالث: ${q['option_c']}. '
        'الخيار الرابع: ${q['option_d']}.';
    _speak(text);
  }

  void _selectAnswer(int index, String correct) {
    if (_showResult) return;
    final letters = ['a', 'b', 'c', 'd'];
    final isCorrect = letters[index] == correct;

    setState(() {
      _selectedAnswer = index;
      _showResult = true;
      if (isCorrect) _correctCount++;
    });

    final delay = isCorrect
        ? const Duration(milliseconds: 1500)
        : const Duration(milliseconds: 3000);

    Future.delayed(delay, () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _showResult = false;
        });
      } else {
        setState(() => _finished = true);
      }
    });
  }

  Color _getOptionColor(int index, bool isDark) {
    if (!_showResult) {
      return _selectedAnswer == index
          ? (isDark ? Colors.blue.shade900 : Colors.blue.shade100)
          : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    }
    final q = _questions[_currentIndex];
    final letters = ['a', 'b', 'c', 'd'];
    if (letters[index] == q['correct']) {
      return isDark ? Colors.green.shade900 : Colors.green.shade200;
    }
    if (_selectedAnswer == index) {
      return isDark ? Colors.red.shade900 : Colors.red.shade200;
    }
    return isDark ? const Color(0xFF1E1E1E) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الصف ${_gradeName(widget.grade)}'),
          actions: [
            if (_questions.isNotEmpty && !_finished)
              IconButton(
                icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                onPressed: () {
                  if (_isSpeaking) {
                    _tts.stop();
                    setState(() => _isSpeaking = false);
                  } else {
                    _speakQuestion();
                  }
                },
              ),
          ],
        ),
        body: _buildBody(isDark),
      ),
    );
  }

  String _gradeName(int g) {
    if (g == 1) return 'الأول';
    if (g == 2) return 'الثاني';
    return 'الثالث';
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري تحميل الأسئلة...', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 80),
              const SizedBox(height: 16),
              Text(_errorMsg, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadQuestions,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_finished) {
      if (_userName.isEmpty) return _buildNameEntry();
      return _buildResultScreen(isDark);
    }

    return _buildQuestionScreen(isDark);
  }

  Widget _buildQuestionScreen(bool isDark) {
    final q = _questions[_currentIndex];
    final options = [q['option_a'], q['option_b'], q['option_c'], q['option_d']];
    final letters = ['أ', 'ب', 'ج', 'د'];
    final progress = (_currentIndex + 1) / _questions.length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: isDark ? Colors.teal.shade900.withOpacity(0.3) : Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'السؤال ${_currentIndex + 1} من ${_questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '✅ $_correctCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation(Colors.teal),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      q['subject'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q['question'] ?? '',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _speakQuestion,
                    icon: const Icon(Icons.volume_up, size: 26),
                    label: const Text('اقرأ السؤال', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 4,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: InkWell(
                    onTap: () => _selectAnswer(i, q['correct']),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getOptionColor(i, isDark),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal.shade700,
                            child: Text(
                              letters[i],
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              options[i]?.toString() ?? '',
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameEntry() {
    final passed = _correctCount >= 10;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 100,
              color: passed ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'انتهى الاختبار!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'أجبت على $_correctCount من ${_questions.length} بشكل صحيح',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            const Text(
              '✍️ اكتب اسمك لعرض نتيجتك:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22),
              decoration: const InputDecoration(
                hintText: 'اكتب اسمك هنا',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, size: 30),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى كتابة اسمك أولاً'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  setState(() => _userName = name);
                  final msg = passed
                      ? 'مبروك $name، لقد نجحت في الاختبار. عدد نقاطك $_correctCount من أصل ${_questions.length}'
                      : 'حاول مرة أخرى يا $name. عدد نقاطك $_correctCount من أصل ${_questions.length}';
                  _speak(msg);
                },
                icon: const Icon(Icons.check_circle, size: 30),
                label: const Text('عرض النتيجة', style: TextStyle(fontSize: 22)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen(bool isDark) {
    final passed = _correctCount >= 10;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 120,
              color: passed ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              passed
                  ? '🎉 مبروك $_userName، لقد نجحت!'
                  : '😔 حاول مرة أخرى يا $_userName',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: passed ? Colors.green : Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              color: passed
                  ? (isDark ? Colors.green.shade900.withOpacity(0.3) : Colors.green.shade50)
                  : (isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'نتيجتك يا $_userName',
                      style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_correctCount / ${_questions.length}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: passed ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      passed
                          ? '✅ نجحت في الاختبار!'
                          : '❌ تحتاج 10 إجابات صحيحة للنجاح',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final msg = passed
                    ? 'مبروك $_userName، لقد نجحت في الاختبار. عدد نقاطك $_correctCount من أصل ${_questions.length}'
                    : 'حاول مرة أخرى يا $_userName. عدد نقاطك $_correctCount من أصل ${_questions.length}';
                _speak(msg);
              },
              icon: const Icon(Icons.volume_up),
              label: const Text('اقرأ النتيجة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text('اختبار جديد', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home),
              label: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}
