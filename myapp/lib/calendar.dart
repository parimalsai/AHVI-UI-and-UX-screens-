import 'package:flutter/material.dart';

// ── Color palette ──
const Color kBg = Color(0xFF08111F);
const Color kBg2 = Color(0xFF0F1A2D);
const Color kPhoneShell = Color(0xFF192131);
const Color kPhoneShell2 = Color(0xFF111723);
const Color kPanel = Color(0x14FFFFFF); // rgba(255,255,255,.08)
const Color kPanel2 = Color(0x1FFFFFFF); // rgba(255,255,255,.12)
const Color kCardBorder = Color(0x1FFFFFFF);
const Color kText = Color(0xFFF5F7FF);
const Color kMuted = Color(0xB8E6EBFF); // rgba(230,235,255,.72)
const Color kTextDim = Color(0x66E6EBFF); // rgba(230,235,255,.40)
const Color kTextLight = Color(0x80E6EBFF); // rgba(230,235,255,.50)
const Color kAccent = Color(0xFF6B91FF);
const Color kAccent2 = Color(0xFF8D7DFF);
const Color kAccent3 = Color(0xFF04D7C8);
const Color kAccent4 = Color(0xFFFF8EC7);
const Color kAccent5 = Color(0xFFFFD86E);

// Event types
enum EventType { gym, office, party, shopping, study, travel, event, dateNight }

// Plan card data model
class PlanCard {
  final String emoji;
  final String title;
  final String time;
  final String desc;
  final String colorType; // orange, blue, pink, teal, amber, purple, sky
  PlanCard({
    required this.emoji,
    required this.title,
    required this.time,
    required this.desc,
    required this.colorType,
  });
}

// Plans are stored per day after user saves them.

// Outfit suggestion model
class OutfitSuggestion {
  final String vibe;
  final String desc;
  final String tip;
  OutfitSuggestion({required this.vibe, required this.desc, required this.tip});
}

final Map<String, List<OutfitSuggestion>> outfits = {
  'Gym': [
    OutfitSuggestion(vibe: 'Cardio Day', desc: 'Leggings, Sports tank, Running shoes', tip: 'Go breathable — skip cotton.'),
    OutfitSuggestion(vibe: 'Weight Training', desc: 'Gym shorts, Loose tee, Cross-trainers', tip: 'Flat soles = better grip.'),
    OutfitSuggestion(vibe: 'Yoga / Pilates', desc: 'High-waist yoga pants, Fitted top, Grip socks', tip: 'Fitted top only — baggy ones fall forward.'),
  ],
  'Office': [
    OutfitSuggestion(vibe: 'Formal Meeting', desc: 'Dress shirt, Dark trousers, Leather shoes', tip: 'Iron your collar the night before.'),
    OutfitSuggestion(vibe: 'Regular Workday', desc: 'Chinos, Polo or blouse, Loafers', tip: 'Stick to 2–3 neutral colors.'),
    OutfitSuggestion(vibe: 'Creative Office', desc: 'Dark jeans, Knit top, Clean sneakers', tip: 'Swap sneakers for loafers if a client drops in.'),
  ],
  'Party': [
    OutfitSuggestion(vibe: 'Evening Out', desc: 'Slip dress, Strappy heels, Small bag', tip: 'Bold dress OR bold shoes — not both.'),
    OutfitSuggestion(vibe: 'Cocktail Party', desc: 'Wide-leg trousers, Silky top, Block heels', tip: 'Half-tuck the top for polish.'),
    OutfitSuggestion(vibe: 'House Party', desc: 'Jeans, Printed top, Ankle boots', tip: 'Stylish jeans always hit right.'),
  ],
};

class Screen4 extends StatefulWidget {
  const Screen4({super.key});

  @override
  State<Screen4> createState() => _Screen4State();
}

class _Screen4State extends State<Screen4> {
  // Calendar state
  int _viewYear = DateTime.now().year;
  int _viewMonth = DateTime.now().month - 1; // 0-indexed
  DateTime _selectedDay = DateTime.now();
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Page state
  bool _showChat = false;
  String _activeOccasion = 'Gym';
  String _activeOccasionEmoji = '💪';

  // Modal state
  bool _showModal = false;
  String _selectedEvent = '';
  String _selectedEventEmoji = '📅';
  int _pickedOutfitIdx = -1;
  String _selectedAMPM = 'AM';
  bool _showEventInputPanel = false;
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _chatInputController = TextEditingController();
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final Map<DateTime, List<PlanCard>> _plansByDay = {};

  // Chat state
  final List<Map<String, String>> _chatMessages = []; // role: 'ai' | 'user', text

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _chatInputController.dispose();
    _hourController.dispose();
    _minController.dispose();
    super.dispose();
  }

  List<DateTime> _getDaysForMonth() {
    final daysInMonth = DateTime(_viewYear, _viewMonth + 2, 0).day;
    final today = DateTime.now();
    final isCurrentMonth = (_viewMonth == today.month - 1 && _viewYear == today.year);
    final startDay = isCurrentMonth ? today.day : 1;
    final order = <DateTime>[];
    for (int d = startDay; d <= daysInMonth; d++) {
      order.add(DateTime(_viewYear, _viewMonth + 1, d));
    }
    for (int d = 1; d < startDay; d++) {
      order.add(DateTime(_viewYear, _viewMonth + 1, d));
    }
    return order;
  }

  String _dayName(DateTime d) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[d.weekday - 1];
  }

  String _planLabelText() {
    final today = DateTime.now();
    if (_selectedDay.year == today.year &&
        _selectedDay.month == today.month &&
        _selectedDay.day == today.day) {
      return "Today's Plans";
    }
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${weekdays[_selectedDay.weekday - 1]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}";
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  List<PlanCard> _plansForDay(DateTime day) => _plansByDay[_dateOnly(day)] ?? const [];

  bool _hasPlansForDay(DateTime day) => _plansForDay(day).isNotEmpty;

  void _deletePlanForSelectedDay(int index) {
    final key = _dateOnly(_selectedDay);
    final plans = _plansByDay[key];
    if (plans == null || index < 0 || index >= plans.length) return;
    setState(() {
      plans.removeAt(index);
      if (plans.isEmpty) {
        _plansByDay.remove(key);
      }
    });
  }

  String _formatPlanTime() {
    final rawHour = int.tryParse(_hourController.text.trim());
    final rawMinute = int.tryParse(_minController.text.trim());
    final hour = (rawHour != null && rawHour >= 1 && rawHour <= 12) ? rawHour : 9;
    final minute = (rawMinute != null && rawMinute >= 0 && rawMinute <= 59) ? rawMinute : 0;
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hour:$minuteText $_selectedAMPM';
  }

  String _colorTypeForEvent(String event) {
    switch (event.toLowerCase()) {
      case 'gym':
      case 'travel':
        return 'teal';
      case 'office':
      case 'study':
        return 'blue';
      case 'party':
      case 'date night':
        return 'pink';
      case 'shopping':
        return 'amber';
      default:
        return 'orange';
    }
  }

  void _savePlanForSelectedDay() {
    final title = _selectedEvent.isNotEmpty ? _selectedEvent : 'Plan';
    final eventOutfits = outfits[_selectedEvent];
    final desc = (eventOutfits != null &&
            _pickedOutfitIdx >= 0 &&
            _pickedOutfitIdx < eventOutfits.length)
        ? eventOutfits[_pickedOutfitIdx].desc
        : 'Custom plan';
    final newPlan = PlanCard(
      emoji: _selectedEventEmoji,
      title: title,
      time: _formatPlanTime(),
      desc: desc,
      colorType: _colorTypeForEvent(title),
    );
    final key = _dateOnly(_selectedDay);

    setState(() {
      _plansByDay.putIfAbsent(key, () => <PlanCard>[]).add(newPlan);
      _showModal = false;
      _selectedEvent = '';
      _selectedEventEmoji = '📅';
      _pickedOutfitIdx = -1;
      _showEventInputPanel = false;
      _eventNameController.clear();
      _hourController.clear();
      _minController.clear();
      _selectedAMPM = 'AM';
    });
  }

  BoxDecoration _planCardDecoration(String colorType) {
    switch (colorType) {
      case 'orange':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x296B91FF), Color(0x146B91FF)],
          ),
          border: const Border(left: BorderSide(color: kAccent, width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x1F6B91FF), blurRadius: 8, offset: Offset(0, 2))],
        );
      case 'blue':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x268D7DFF), Color(0x128D7DFF)],
          ),
          border: const Border(left: BorderSide(color: kAccent2, width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x1F8D7DFF), blurRadius: 8, offset: Offset(0, 2))],
        );
      case 'pink':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x24FF8EC7), Color(0x12FF8EC7)],
          ),
          border: const Border(left: BorderSide(color: kAccent4, width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x1FFF8EC7), blurRadius: 8, offset: Offset(0, 2))],
        );
      case 'teal':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x2404D7C8), Color(0x1204D7C8)],
          ),
          border: const Border(left: BorderSide(color: kAccent3, width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x1F04D7C8), blurRadius: 8, offset: Offset(0, 2))],
        );
      case 'amber':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x29FFD86E), Color(0x12FFD86E)],
          ),
          border: const Border(left: BorderSide(color: kAccent5, width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x1FFFD86E), blurRadius: 8, offset: Offset(0, 2))],
        );
      default:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x268D7DFF), Color(0x128D7DFF)],
          ),
          border: const Border(left: BorderSide(color: kAccent2, width: 4)),
          boxShadow: const [BoxShadow(color: Color(0x1F8D7DFF), blurRadius: 8, offset: Offset(0, 2))],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Main content or chat page
          _showChat ? _buildChatPage() : _buildMainContent(),
          // Fixed chat input bar (only when chat is active)
          if (_showChat) _buildChatInputBar(),
          // Modal overlay
          if (_showModal) _buildModalOverlay(),
        ],
      ),
    );
  }

  // ── MAIN CONTENT ──
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 18),
          _buildCalendarBox(),
        ],
      ),
    );
  }

  // ── PAGE HEADER ──
  Widget _buildPageHeader() {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPanel,
              shape: BoxShape.circle,
              border: Border.all(color: kCardBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x4D000000), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: const Center(
              child: Icon(Icons.chevron_left_rounded, color: kText, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule / Calendar',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                // Pulse dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccent3,
                    boxShadow: [BoxShadow(color: Color(0xBF04D7C8), blurRadius: 7)],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_getTotalPlans()} outfit plans · ${_getTodayPlans()} today',
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  int _getTotalPlans() =>
      _plansByDay.values.fold<int>(0, (total, plans) => total + plans.length);

  int _getTodayPlans() => _plansForDay(DateTime.now()).length;

  // ── CALENDAR BOX ──
  Widget _buildCalendarBox() {
    return Container(
      decoration: BoxDecoration(
        color: kPhoneShell,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x7200000), blurRadius: 24, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildMonthNav(),
          _buildWeekStrip(),
          // Divider
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, kCardBorder, Colors.transparent],
              ),
            ),
          ),
          _buildPlansSection(),
        ],
      ),
    );
  }

  // ── MONTH NAV ──
  Widget _buildMonthNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavArrow(isLeft: true),
          Text(
            '${_months[_viewMonth]} $_viewYear',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kText,
              letterSpacing: -0.2,
            ),
          ),
          _buildNavArrow(isLeft: false),
        ],
      ),
    );
  }

  Widget _buildNavArrow({required bool isLeft}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isLeft) {
            _viewMonth--;
            if (_viewMonth < 0) {
              _viewMonth = 11;
              _viewYear--;
            }
          } else {
            _viewMonth++;
            if (_viewMonth > 11) {
              _viewMonth = 0;
              _viewYear++;
            }
          }
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: kPanel,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            isLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            color: kText,
            size: 18,
          ),
        ),
      ),
    );
  }

  // ── WEEK STRIP ──
  Widget _buildWeekStrip() {
    final days = _getDaysForMonth();
    final today = DateTime.now();
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, i) {
          final day = days[i];
          final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
          final isSelected = day.year == _selectedDay.year &&
              day.month == _selectedDay.month &&
              day.day == _selectedDay.day;
          final hasPlans = _hasPlansForDay(day);
          return _buildDayPill(day, isToday, isSelected, hasPlans);
        },
      ),
    );
  }

  Widget _buildDayPill(DateTime day, bool isToday, bool isSelected, bool hasPlans) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: 52,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x526B91FF),
              Color(0x388D7DFF),
              Color(0x2E6B91FF),
            ],
          )
              : null,
          color: isSelected ? null : kPanel,
          border: Border.all(
            color: isSelected ? const Color(0x596B91FF) : kCardBorder,
          ),
          boxShadow: isSelected
              ? const [
            BoxShadow(color: Color(0x4D6B91FF), blurRadius: 24, offset: Offset(0, 8)),
            BoxShadow(color: Color(0x1FFFFFFF), blurRadius: 0, offset: Offset(0, 1)),
          ]
              : const [
            BoxShadow(color: Color(0x596B91FF), blurRadius: 12, offset: Offset(0, 3)),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    _dayName(day).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.06,
                      color: isSelected ? kAccent : kMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kText,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Today pip
            if (isToday)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAccent3,
                    boxShadow: [BoxShadow(color: Color(0xBF04D7C8), blurRadius: 7)],
                  ),
                ),
              ),
            // Event dot (only for days with saved plans)
            if (hasPlans)
              const Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 5,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kAccent2,
                        boxShadow: [BoxShadow(color: Color(0x808D7DFF), blurRadius: 5)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── PLANS SECTION ──
  Widget _buildPlansSection() {
    final plansForSelectedDay = _plansForDay(_selectedDay);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plans label
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              _planLabelText(),
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.14,
                color: kMuted,
              ),
            ),
          ),
          // Plans grid (single column)
          Column(
            children: plansForSelectedDay.isNotEmpty
                ? List.generate(
              plansForSelectedDay.length,
                  (index) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildPlanCard(plansForSelectedDay[index], index),
              ),
            )
                : [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No plans yet.\nTap below to add one! ✨',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kMuted,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // Add plan button
          _buildAddPlanButton(),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanCard plan, int index) {
    return Container(
      decoration: _planCardDecoration(plan.colorType),
      padding: const EdgeInsets.fromLTRB(13, 9, 10, 9),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 2),
              // Time chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  plan.time,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                plan.title,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                plan.desc,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: kMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
          // Delete button
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _deletePlanForSelectedDay(index),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0x0FFFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.close, size: 9, color: kMuted),
                ),
              ),
            ),
          ),
          // Bell button
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: kPanel,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 6)],
              ),
              child: const Center(
                child: Icon(Icons.notifications_none_rounded, size: 13, color: kTextDim),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlanButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showModal = true;
          _selectedEvent = '';
          _selectedEventEmoji = '📅';
          _pickedOutfitIdx = -1;
          _showEventInputPanel = false;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kAccent, kAccent2],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x666B91FF), blurRadius: 16, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 14),
            SizedBox(width: 8),
            Text(
              'Add a Plan',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MODAL OVERLAY ──
  Widget _buildModalOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showModal = false;
        });
      },
      child: Container(
        color: const Color(0xA608111F),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: _buildModalContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildModalContent() {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: kPhoneShell,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(20)),
        border: Border.all(color: kCardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x8C000000), blurRadius: 32, offset: Offset(0, -4)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0x2FFFFFFF),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Plan',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showModal = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: kPanel,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.close, size: 13, color: kMuted),
                        SizedBox(width: 5),
                        Text(
                          'Close',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Field label - Occasion
            const Text(
              'CHOOSE OCCASION',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.16,
                color: kMuted,
              ),
            ),
            const SizedBox(height: 10),
            // Event grid
            _buildEventGrid(),
            const SizedBox(height: 8),
            // Event input panel
            if (_showEventInputPanel) _buildEventInputPanel(),
            // Outfit section
            _buildOutfitSection(),
            // Set Time
            const Text(
              'SET TIME',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.16,
                color: kMuted,
              ),
            ),
            const SizedBox(height: 10),
            _buildTimeRow(),
            const SizedBox(height: 16),
            // Save button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventGrid() {
    final eventDefs = [
      {'label': 'Gym', 'emoji': '💪', 'class': 'gym', 'color': kAccent3},
      {'label': 'Office', 'emoji': '💼', 'class': 'office', 'color': kAccent2},
      {'label': 'Party', 'emoji': '🎊', 'class': 'party', 'color': kAccent4},
      {'label': 'Shopping', 'emoji': '🛍️', 'class': 'shopping', 'color': kAccent5},
      {'label': 'Study', 'emoji': '📖', 'class': 'study', 'color': kAccent},
      {'label': 'Travel', 'emoji': '✈️', 'class': 'travel', 'color': kAccent3},
      {'label': 'Event', 'emoji': '📅', 'class': 'event', 'color': kAccent},
      {'label': 'Date Night', 'emoji': '❤️', 'class': 'datenight', 'color': kAccent4},
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: eventDefs.map((def) {
        final isActive = _selectedEvent == def['label'];
        final color = def['color'] as Color;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEvent = def['label'] as String;
              _selectedEventEmoji = def['emoji'] as String;
              if (def['label'] == 'Event') {
                _showEventInputPanel = !_showEventInputPanel;
              } else {
                _showEventInputPanel = false;
              }
              _pickedOutfitIdx = -1;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive
                  ? color.withOpacity(0.30)
                  : color.withOpacity(0.15),
              border: Border.all(
                color: isActive ? color.withOpacity(0.55) : const Color(0x1FFFFFFF),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: color.withOpacity(0.20), blurRadius: 20, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(def['emoji'] as String, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 5),
                Text(
                  def['label'] as String,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEventInputPanel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input wrap
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x596B91FF), width: 1.5),
            ),
            child: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _eventNameController,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: kText,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Wedding, Birthday Party, Gala…',
                      hintStyle: TextStyle(color: kTextDim, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    maxLength: 40,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_eventNameController.text.isNotEmpty) {
                      setState(() {
                        _selectedEvent = _eventNameController.text;
                        _showEventInputPanel = false;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [kAccent2, kAccent]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Add ✓',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Event chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['🎂 Birthday Party', '💍 Wedding', '🎓 Graduation', '🥂 Gala', '🎄 Holiday Party', '🌸 Bridal Shower']
                  .map((chip) => GestureDetector(
                onTap: () {
                  _eventNameController.text = chip;
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1F6B91FF),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0x4D6B91FF)),
                  ),
                  child: Text(
                    chip,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kAccent,
                    ),
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitSection() {
    final eventOutfits = outfits[_selectedEvent];
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedEvent.isNotEmpty ? '$_selectedEventEmoji $_selectedEvent — Outfit Ideas' : 'OUTFIT SUGGESTIONS',
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.16,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 10),
          if (eventOutfits == null || _selectedEvent.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x478D7DFF), width: 1.5),
              ),
              child: const Text(
                'Select an occasion above to see outfit ideas ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13,
                  color: kTextDim,
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: eventOutfits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final outfit = eventOutfits[idx];
                  final isPicked = _pickedOutfitIdx == idx;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _pickedOutfitIdx = idx;
                      });
                    },
                    child: Container(
                      width: 165,
                      padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: isPicked ? const Color(0x248D7DFF) : kPanel,
                        border: Border.all(
                          color: isPicked ? kAccent2 : kCardBorder,
                          width: isPicked ? 1.5 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                outfit.vibe.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.12,
                                  color: kAccent,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                outfit.desc,
                                style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: kText,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(top: 7),
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: kCardBorder)),
                                ),
                                child: Text(
                                  outfit.tip,
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 11,
                                    color: kMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isPicked)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [kAccent, kAccent2]),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text(
                                  'PICK',
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.04,
                                  ),
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildTimeRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCardBorder),
        boxShadow: const [BoxShadow(color: Color(0x0FFFFFFF), blurRadius: 0, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: kTextDim, size: 15),
          const SizedBox(width: 8),
          // Hour input
          SizedBox(
            width: 44,
            child: TextField(
              controller: _hourController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
              decoration: const InputDecoration(
                hintText: 'HH',
                hintStyle: TextStyle(color: Color(0x38E6EBFF), fontSize: 22),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 22,
              color: kTextDim,
            ),
          ),
          // Min input
          SizedBox(
            width: 44,
            child: TextField(
              controller: _minController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
              decoration: const InputDecoration(
                hintText: 'MM',
                hintStyle: TextStyle(color: Color(0x38E6EBFF), fontSize: 22),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 7),
            color: kCardBorder,
          ),
          // AM/PM
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x0FFFFFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: ['AM', 'PM'].map((label) {
                final isActive = _selectedAMPM == label;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAMPM = label;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? kBg2 : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.06,
                        color: isActive ? kText : kMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _savePlanForSelectedDay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [kAccent, kAccent2],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x24FFFFFF)),
          boxShadow: const [
            BoxShadow(color: Color(0x596B91FF), blurRadius: 22, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_today_outlined, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'Save to Calendar',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.02,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CHAT PAGE ──
  Widget _buildChatPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chat header
        _buildChatHeader(),
        // Chat messages
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
            itemCount: _chatMessages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final msg = _chatMessages[idx];
              final isUser = msg['role'] == 'user';
              return _buildBubbleRow(msg['text'] ?? '', isUser);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showChat = false;
                    _chatMessages.clear();
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kCardBorder),
                    boxShadow: const [
                      BoxShadow(color: Color(0x4D000000), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.chevron_left_rounded, color: kText, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_activeOccasion — Style Chat',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kAccent3,
                          boxShadow: [BoxShadow(color: Color(0xCC04D7C8), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Ask anything about your outfit.',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: kMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleRow(String text, bool isUser) {
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kPanel,
              shape: BoxShape.circle,
              border: Border.all(color: kCardBorder),
            ),
            child: const Center(child: Text('✨', style: TextStyle(fontSize: 13))),
          ),
          const SizedBox(width: 8),
        ],
        Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? null : kPanel,
                gradient: isUser
                    ? const LinearGradient(colors: [kAccent, kAccent2])
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(5),
                  bottomRight: isUser ? const Radius.circular(5) : const Radius.circular(18),
                ),
                border: Border.all(
                  color: isUser ? const Color(0x596B91FF) : kCardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser ? const Color(0x266B91FF) : const Color(0x40000000),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13.5,
                  color: kText,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '12:00 PM',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 10,
                  color: kTextDim,
                ),
              ),
            ),
          ],
        ),
        if (isUser) ...[
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: kPanel,
              shape: BoxShape.circle,
              border: Border.all(color: kCardBorder),
            ),
            child: const Center(child: Text('👤', style: TextStyle(fontSize: 13))),
          ),
        ],
      ],
    );
  }

  // ── CHAT INPUT BAR ──
  Widget _buildChatInputBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Suggestion chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  'What should I wear today?',
                  'Outfit for a date night 🌙',
                  'Casual weekend look',
                  'Work-appropriate outfit',
                  'What to pack for a trip?',
                  'Summer party outfit 🎉',
                ].map((chip) => GestureDetector(
                  onTap: () {
                    _chatInputController.text = chip;
                    _sendChatMessage();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: kPanel,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: const Color(0x4D6B91FF), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A6B91FF), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kAccent,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Input inner
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: kPanel2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kCardBorder),
                boxShadow: const [
                  BoxShadow(color: Color(0x59000000), blurRadius: 24, offset: Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputController,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: kText,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ask about your outfit…',
                        hintStyle: TextStyle(color: kTextDim, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 5),
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mic button
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPanel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x338D7DFF)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.mic_none_rounded, color: kAccent2, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  GestureDetector(
                    onTap: _sendChatMessage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [kAccent, kAccent2]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Color(0x666B91FF), blurRadius: 12, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendChatMessage() {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add({'role': 'user', 'text': text});
      _chatInputController.clear();
      // Simulate AI response
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'role': 'ai',
              'text': 'Great choice! For $_activeOccasion, I\'d suggest a stylish and comfortable outfit that matches the occasion perfectly. Let me put together a complete look for you! 👗✨',
            });
          });
        }
      });
    });
  }
}
