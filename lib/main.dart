import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

void main() {
  runApp(const DoDailyApp());
}

// ─── CORES ─────────────────────────────────────────────────────────
class AppColors {
  static const bg         = Color(0xFF0A0A0A);
  static const surface    = Color(0xFF141414);
  static const surfaceHi  = Color(0xFF1C1C1C);
  static const border     = Color(0xFF242424);
  static const borderHi   = Color(0xFF2E2E2E);
  static const text       = Color(0xFFFAFAFA);
  static const textDim    = Color(0xFFA0A0A0);
  static const textMute   = Color(0xFF5A5A5A);
  static const accent     = Color(0xFFFF6B1A);
  static const accentDim  = Color(0x24FF6B1A);
  static const priAlta    = Color(0xFFFF5C5C);
  static const priMedia   = Color(0xFFF5A623);
  static const priBaixa   = Color(0xFF4ADE80);
  static const catTrabalho = Color(0xFF7DA3FF);
  static const catEstudo   = Color(0xFFC084FC);
  static const catPessoal  = Color(0xFFFF8FAB);
  static const catSaude    = Color(0xFF4ADE80);
  static const catOutras   = Color(0xFFA0A0A0);

  static Color catColor(String c) {
    switch (c) {
      case 'Trabalho': return catTrabalho;
      case 'Estudo':   return catEstudo;
      case 'Pessoal':  return catPessoal;
      case 'Saúde':    return catSaude;
      default:         return catOutras;
    }
  }

  static Color priColor(String p) {
    switch (p) {
      case 'Alta':  return priAlta;
      case 'Média': return priMedia;
      case 'Baixa': return priBaixa;
      default:      return priMedia;
    }
  }
}

// ─── MODELO ────────────────────────────────────────────────────────
class Task {
  String id, title, description, category, priority;
  bool isCompleted;
  DateTime createdAt;
  DateTime? dueDate;

  Task({
    required this.id, required this.title,
    this.description = '', this.category = 'Pessoal',
    this.priority = 'Média', this.isCompleted = false,
    required this.createdAt, this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'category': category, 'priority': priority,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'], title: j['title'],
    description: j['description'] ?? '',
    category: j['category'] ?? 'Pessoal',
    priority: j['priority'] ?? 'Média',
    isCompleted: j['isCompleted'] ?? false,
    createdAt: DateTime.parse(j['createdAt']),
    dueDate: j['dueDate'] != null ? DateTime.parse(j['dueDate']) : null,
  );

  bool get isOverdue => dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());
  bool get isDueSoon => dueDate != null && !isCompleted && !isOverdue && dueDate!.difference(DateTime.now()).inDays <= 1;
}

// ─── HELPERS ───────────────────────────────────────────────────────
String detectCategory(String title) {
  final t = title.toLowerCase();
  if (['estudar', 'prova', 'aula', 'faculdade', 'escola', 'pesquisa', 'ler'].any((k) => t.contains(k))) return 'Estudo';
  if (['academia', 'médico', 'correr', 'treinar', 'treino', 'saúde', 'remédio', 'consulta'].any((k) => t.contains(k))) return 'Saúde';
  if (['reunião', 'cliente', 'projeto', 'relatório', 'meeting', 'prazo', 'trabalho'].any((k) => t.contains(k))) return 'Trabalho';
  if (['comprar', 'mercado', 'ligar', 'pagar', 'banco'].any((k) => t.contains(k))) return 'Pessoal';
  return '';
}

String motivationalPhrase(double pct) {
  if (pct == 0) return 'Comece pelo menor passo. 🚀';
  if (pct >= 1) return 'Tudo pronto! Aproveite o descanso. 🎉';
  if (pct >= 0.7) return 'Quase lá, não pare agora! 💪';
  return 'Continue assim, você está indo bem. 🔥';
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ─── APP ───────────────────────────────────────────────────────────
class DoDailyApp extends StatelessWidget {
  const DoDailyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DoDaily',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
      ),
    ),
    home: const SplashScreen(),
  );
}

// ─── SPLASH ────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOutBack)));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 400),
      ));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(child: FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 32, spreadRadius: 4)],
          ),
          child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 20),
        RichText(text: const TextSpan(
          children: [
            TextSpan(text: 'Do', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1.5)),
            TextSpan(text: 'Daily', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: -1.5)),
          ],
        )),
        const SizedBox(height: 8),
        const Text('Organize. Foque. Conquiste.', style: TextStyle(fontSize: 13, color: AppColors.textMute, letterSpacing: 1.2)),
      ]),
    ))),
  );
}

// ─── HOME ──────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Task> _tasks = [];
  List<Task> _filtered = [];
  String _search = '', _filterCat = 'Todas', _filterPri = 'Todas', _sortBy = 'data';
  bool _showDone = true;
  int _currentTab = 0;

  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  final _cats = ['Todas', 'Trabalho', 'Estudo', 'Pessoal', 'Saúde', 'Outro'];
  final _pris = ['Todas', 'Alta', 'Média', 'Baixa'];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _loadTasks();
  }

  @override
  void dispose() { _progressCtrl.dispose(); super.dispose(); }

  void _animateProgress(double target) {
    final current = _progressAnim.value;
    _progressAnim = Tween<double>(begin: current, end: target)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward(from: 0);
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('dodaily_tasks');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _tasks = list.map((e) => Task.fromJson(e)).toList();
        _applyFilters();
      });
      _updateProgress();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dodaily_tasks', jsonEncode(_tasks.map((e) => e.toJson()).toList()));
  }

  void _updateProgress() {
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isCompleted).length;
    _animateProgress(total == 0 ? 0 : done / total);
  }

  void _applyFilters() {
    setState(() {
      _filtered = _tasks.where((t) {
        final s = _search.toLowerCase();
        return (t.title.toLowerCase().contains(s) || t.description.toLowerCase().contains(s))
            && (_filterCat == 'Todas' || t.category == _filterCat)
            && (_filterPri == 'Todas' || t.priority == _filterPri)
            && (_showDone || !t.isCompleted);
      }).toList();

      _filtered.sort((a, b) {
        if (_sortBy == 'prioridade') {
          const o = {'Alta': 0, 'Média': 1, 'Baixa': 2};
          return (o[a.priority] ?? 1).compareTo(o[b.priority] ?? 1);
        }
        if (_sortBy == 'vencimento') {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        }
        return b.createdAt.compareTo(a.createdAt);
      });
    });
  }

  void _openForm({Task? task}) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(task: task),
    );
    if (result != null) {
      setState(() {
        if (task == null) { _tasks.insert(0, result); }
        else { final i = _tasks.indexWhere((t) => t.id == task.id); if (i != -1) _tasks[i] = result; }
        _applyFilters();
      });
      _updateProgress();
      await _save();
    }
  }

  void _confirmDelete(String id) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: AppColors.surfaceHi,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Excluir tarefa?', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
      content: const Text('Esta ação não pode ser desfeita.', style: TextStyle(color: AppColors.textDim)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textDim))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.priAlta, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () async {
            Navigator.pop(context);
            setState(() { _tasks.removeWhere((t) => t.id == id); _applyFilters(); });
            _updateProgress();
            await _save();
          },
          child: const Text('Excluir', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _toggle(Task t) async {
    setState(() { t.isCompleted = !t.isCompleted; _applyFilters(); });
    _updateProgress();
    await _save();
  }

  void _showSortSheet() {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceHi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderHi, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          const Text('Ordenar por', style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...['data', 'prioridade', 'vencimento'].map((s) => ListTile(
            leading: Icon(s == 'data' ? Icons.calendar_today_rounded : s == 'prioridade' ? Icons.flag_rounded : Icons.alarm_rounded,
              color: _sortBy == s ? AppColors.accent : AppColors.textDim),
            title: Text(s == 'data' ? 'Data de criação' : s == 'prioridade' ? 'Prioridade' : 'Vencimento',
              style: TextStyle(color: _sortBy == s ? AppColors.accent : AppColors.text)),
            trailing: _sortBy == s ? const Icon(Icons.check_rounded, color: AppColors.accent) : null,
            onTap: () { setState(() => _sortBy = s); _applyFilters(); Navigator.pop(context); },
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isCompleted).length;
    final pct = total == 0 ? 0.0 : done / total;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: Stack(children: [
        // Conteúdo principal
        _currentTab == 0
            ? SafeArea(child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header
                    Row(children: [
                      Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      RichText(text: const TextSpan(children: [
                        TextSpan(text: 'Do', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5)),
                        TextSpan(text: 'Daily', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accent, letterSpacing: -0.5)),
                      ])),
                      const Spacer(),
                      _HeaderBtn(icon: Icons.sort_rounded, label: 'Ordenar', onTap: _showSortSheet),
                      const SizedBox(width: 8),
                      _HeaderBtn(
                        icon: _showDone ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        onTap: () { setState(() => _showDone = !_showDone); _applyFilters(); },
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // Card de progresso
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Progresso', style: TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w500)),
                          AnimatedBuilder(animation: _progressAnim, builder: (_, __) =>
                            Text('${(_progressAnim.value * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 15)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        AnimatedBuilder(animation: _progressAnim, builder: (_, __) =>
                          ClipRRect(borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _progressAnim.value, minHeight: 6,
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          _MiniStat('Total', total.toString(), AppColors.text),
                          Container(width: 1, height: 24, color: AppColors.border),
                          _MiniStat('Feitas', done.toString(), AppColors.priBaixa),
                          Container(width: 1, height: 24, color: AppColors.border),
                          _MiniStat('Pendentes', (total - done).toString(), AppColors.priAlta),
                        ]),
                        const SizedBox(height: 10),
                        Text(motivationalPhrase(pct),
                          style: const TextStyle(color: AppColors.textMute, fontSize: 12, fontStyle: FontStyle.italic)),
                      ]),
                    ),
                    const SizedBox(height: 12),

                    // Busca
                    Container(
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: TextField(
                        style: const TextStyle(color: AppColors.text, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Buscar tarefas...', hintStyle: TextStyle(color: AppColors.textMute),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMute, size: 20),
                          border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (v) { _search = v; _applyFilters(); },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filtros categoria
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _cats.map((c) => _CatChip(
                        label: c,
                        selected: _filterCat == c,
                        onTap: () { setState(() => _filterCat = c); _applyFilters(); },
                      )).toList()),
                    ),
                    const SizedBox(height: 4),
                  ]),
                ),

                // Lista
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 64, height: 64,
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
                            child: const Icon(Icons.inbox_rounded, size: 32, color: AppColors.textMute)),
                          const SizedBox(height: 12),
                          const Text('Nenhuma tarefa', style: TextStyle(color: AppColors.textDim, fontSize: 15)),
                          const SizedBox(height: 4),
                          const Text('Toque em + para adicionar', style: TextStyle(color: AppColors.textMute, fontSize: 12)),
                        ]))
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 120),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final task = _filtered[i];
                            return _TaskCard(
                              key: ValueKey(task.id),
                              task: task,
                              onToggle: () => _toggle(task),
                              onEdit: () => _openForm(task: task),
                              onDelete: () => _confirmDelete(task.id),
                            );
                          },
                        ),
                ),
              ]))
            : StatsScreen(tasks: _tasks),

        // Navbar com blur
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: const Color(0xE60A0A0A),
                padding: EdgeInsets.only(bottom: bottomPad),
                height: 72 + bottomPad,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _NavItem(icon: Icons.check_circle_outline_rounded, label: 'Tarefas', selected: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
                  GestureDetector(
                    onTap: () => _openForm(),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  _NavItem(icon: Icons.bar_chart_rounded, label: 'Estatísticas', selected: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
// ─── TASK CARD ─────────────────────────────────────────────────────
class _TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle, onEdit, onDelete;

  const _TaskCard({super.key, required this.task, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.97), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.97, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _handleToggle() {
    _ctrl.forward(from: 0);
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final catColor = AppColors.catColor(task.category);
    final priColor = AppColors.priColor(task.priority);

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (_, child) => Transform.scale(scale: _scaleAnim.value, child: child),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: task.isCompleted ? 0.45 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 10, 16),
              child: GestureDetector(
                onTap: _handleToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: task.isCompleted ? AppColors.accent : AppColors.borderHi,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),

            // Conteúdo
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 8, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task.title,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.textDim,
                    decorationThickness: 1.5,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(task.description,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _Badge(label: task.category, color: catColor),
                  _Badge(label: task.priority, color: priColor, isPriority: true),
                  if (task.dueDate != null)
                    _Badge(
                      label: _formatDate(task.dueDate!),
                      color: task.isOverdue ? AppColors.priAlta : task.isDueSoon ? AppColors.priMedia : AppColors.textMute,
                      icon: task.isOverdue ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                    ),
                ]),
              ]),
            )),

            // Ações
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _ActionBtn(icon: Icons.edit_rounded, color: AppColors.textMute, onTap: widget.onEdit),
              _ActionBtn(icon: Icons.delete_rounded, color: AppColors.priAlta.withValues(alpha: 0.7), onTap: widget.onDelete),
            ]),
            const SizedBox(width: 6),
          ]),
        ),
      ),
    );
  }
}

// ─── TASK FORM BOTTOM SHEET ────────────────────────────────────────
class TaskFormSheet extends StatefulWidget {
  final Task? task;
  const TaskFormSheet({super.key, this.task});
  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title, _desc;
  String _cat = 'Pessoal', _pri = 'Média';
  DateTime? _dueDate;
  bool _autoCategory = false;

  final _cats = ['Trabalho', 'Estudo', 'Pessoal', 'Saúde', 'Outro'];
  final _pris = ['Alta', 'Média', 'Baixa'];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _desc = TextEditingController(text: widget.task?.description ?? '');
    _cat = widget.task?.category ?? 'Pessoal';
    _pri = widget.task?.priority ?? 'Média';
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }

  void _onTitleChanged(String value) {
    final detected = detectCategory(value);
    if (detected.isNotEmpty && detected != _cat) {
      setState(() { _cat = detected; _autoCategory = true; });
    } else if (detected.isEmpty) {
      setState(() { _autoCategory = false; });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.accent, surface: AppColors.surfaceHi),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, Task(
        id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        description: _desc.text.trim(),
        category: _cat, priority: _pri,
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        dueDate: _dueDate,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final keyboardPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomPad + keyboardPad),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.borderHi, borderRadius: BorderRadius.circular(999))),
        const SizedBox(height: 16),

        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text(widget.task == null ? 'Nova tarefa' : 'Editar tarefa',
              style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 30, height: 30,
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(999)),
                child: const Icon(Icons.close_rounded, color: AppColors.textDim, size: 16)),
            ),
          ]),
        ),
        const SizedBox(height: 20),

        // Form
        Flexible(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Título
            _SheetLabel('TÍTULO'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _title,
              autofocus: true,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: _inputDeco('Ex: estudar para a prova'),
              onChanged: _onTitleChanged,
              validator: (v) => v == null || v.trim().isEmpty ? 'Informe um título' : null,
            ),

            // Badge auto categoria
            if (_autoCategory) ...[
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('✨ ', style: TextStyle(fontSize: 11)),
                    Text('AUTO — $_cat', style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ],

            const SizedBox(height: 16),

            // Descrição
            _SheetLabel('DESCRIÇÃO'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _desc,
              maxLines: 2,
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: _inputDeco('Detalhes opcionais'),
            ),
            const SizedBox(height: 16),

            // Categoria
            _SheetLabel('CATEGORIA'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: _cats.map((c) {
              final sel = _cat == c;
              final color = AppColors.catColor(c);
              return GestureDetector(
                onTap: () => setState(() { _cat = c; _autoCategory = false; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? color.withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
                  ),
                  child: Text(c, style: TextStyle(
                    color: sel ? color : AppColors.textDim,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  )),
                ),
              );
            }).toList()),
            const SizedBox(height: 16),

            // Prioridade
            _SheetLabel('PRIORIDADE'),
            const SizedBox(height: 8),
            Row(children: _pris.map((p) {
              final sel = _pri == p;
              final color = AppColors.priColor(p);
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _pri = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: p != 'Baixa' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? color.withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? color : AppColors.border, width: sel ? 1.5 : 1),
                  ),
                  child: Column(children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(height: 6),
                    Text(p, style: TextStyle(
                      color: sel ? color : AppColors.textDim,
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                    )),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 16),

            // Data Limite
            _SheetLabel('DATA LIMITE'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _dueDate != null ? AppColors.accent : AppColors.border),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded,
                    size: 16, color: _dueDate != null ? AppColors.accent : AppColors.textMute),
                  const SizedBox(width: 10),
                  Text(
                    _dueDate != null ? _formatDate(_dueDate!) : 'Selecionar data (opcional)',
                    style: TextStyle(color: _dueDate != null ? AppColors.text : AppColors.textMute, fontSize: 14),
                  ),
                  const Spacer(),
                  if (_dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMute),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // Botão salvar
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  widget.task == null ? 'Salvar tarefa' : 'Salvar alterações',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ])),
        )),
      ]),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMute),
    filled: true, fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.priAlta)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ─── ESTATÍSTICAS ──────────────────────────────────────────────────
class StatsScreen extends StatefulWidget {
  final List<Task> tasks;
  const StatsScreen({super.key, required this.tasks});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final total = tasks.length;
    final done = tasks.where((t) => t.isCompleted).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    final pct = total == 0 ? 0.0 : done / total;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    final catGroups = <String, int>{};
    final priGroups = <String, int>{};
    for (final t in tasks) {
      catGroups[t.category] = (catGroups[t.category] ?? 0) + 1;
      priGroups[t.priority] = (priGroups[t.priority] ?? 0) + 1;
    }

    return SafeArea(child: AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 20, 16, bottomPad + 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Estatísticas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          const Text('Visão geral do seu desempenho', style: TextStyle(color: AppColors.textDim, fontSize: 14)),
          const SizedBox(height: 20),

          // Grid 2x2
          Row(children: [
            Expanded(child: _StatCard('Total', total.toString(), Icons.format_list_bulleted_rounded, AppColors.accent, _anim.value)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('Concluídas', done.toString(), Icons.task_alt_rounded, AppColors.priBaixa, _anim.value)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard('Pendentes', (total - done).toString(), Icons.pending_actions_rounded, AppColors.priMedia, _anim.value)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('Vencidas', overdue.toString(), Icons.running_with_errors_rounded, AppColors.priAlta, _anim.value)),
          ]),
          const SizedBox(height: 24),

          // Por categoria
          if (catGroups.isNotEmpty) ...[
            _SectionLabel('POR CATEGORIA'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(children: catGroups.entries.map((e) {
                final color = AppColors.catColor(e.key);
                final frac = total == 0 ? 0.0 : e.value / total;
                return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(e.key, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${e.value}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Stack(children: [
                    Container(height: 6, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999))),
                    FractionallySizedBox(
                      widthFactor: frac * _anim.value,
                      child: Container(height: 6, decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(999),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                      )),
                    ),
                  ]),
                ]));
              }).toList()),
            ),
          ],

          const SizedBox(height: 20),

          // Por prioridade
          if (priGroups.isNotEmpty) ...[
            _SectionLabel('POR PRIORIDADE'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(children: ['Alta', 'Média', 'Baixa'].where((p) => priGroups.containsKey(p)).map((p) {
                final color = AppColors.priColor(p);
                final count = priGroups[p] ?? 0;
                final frac = total == 0 ? 0.0 : count / total;
                return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(p, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                    Text('$count', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Stack(children: [
                    Container(height: 6, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999))),
                    FractionallySizedBox(
                      widthFactor: frac * _anim.value,
                      child: Container(height: 6, decoration: BoxDecoration(
                        color: color, borderRadius: BorderRadius.circular(999),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                      )),
                    ),
                  ]),
                ]));
              }).toList()),
            ),
          ],

          const SizedBox(height: 20),

          // Taxa de conclusão
          _SectionLabel('TAXA DE CONCLUSÃO'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              SizedBox(width: 80, height: 80,
                child: CustomPaint(
                  painter: _DonutPainter(value: pct * _anim.value, color: AppColors.accent, bg: AppColors.border),
                  child: Center(child: Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 16))),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$done de $total concluídas',
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(motivationalPhrase(pct),
                  style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
              ])),
            ]),
          ),
        ]),
      ),
    ));
  }
}

class _DonutPainter extends CustomPainter {
  final double value, color2 = 0;
  final Color color, bg;
  const _DonutPainter({required this.value, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()..strokeWidth = 10..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    paint.color = bg;
    canvas.drawCircle(center, radius, paint);
    if (value > 0) {
      paint.color = color;
      paint.shader = SweepGradient(
        startAngle: -pi / 2, endAngle: -pi / 2 + 2 * pi * value,
        colors: [color, color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * value, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.value != value;
}

// ─── WIDGETS AUXILIARES ────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPriority;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.isPriority = false, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 3)],
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? AppColors.accent : AppColors.border),
      ),
      child: Text(label, style: TextStyle(
        color: selected ? Colors.black : AppColors.textDim,
        fontSize: 13,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
      )),
    ),
  );
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: label != null ? 10 : 8, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.textDim),
        if (label != null) ...[const SizedBox(width: 4), Text(label!, style: const TextStyle(fontSize: 12, color: AppColors.textDim))],
      ]),
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: selected ? AppColors.accent : AppColors.textMute),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 11, color: selected ? AppColors.accent : AppColors.textMute,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMute)),
  ]);
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final double animValue;
  const _StatCard(this.label, this.value, this.icon, this.color, this.animValue);

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(0, 16 * (1 - animValue)),
    child: Opacity(opacity: animValue.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
        ]),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: AppColors.textMute, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8));
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(color: AppColors.textMute, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8));
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 18, color: color),
    ),
  );
}