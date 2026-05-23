import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2.0, end: 3.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final sv = _anim.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _financialCardRow(context, sv, [
              _CardData('Account Balance', Icons.account_balance_wallet, const Color(0xFF3B82F6)),
              _CardData('Net Worth', Icons.trending_up, const Color(0xFF10B981)),
            ]),
            const SizedBox(height: 12),
            _financialCardRow(context, sv, [
              _CardData('Total Assets', Icons.savings, const Color(0xFF10B981)),
              _CardData('Total Liabilities', Icons.warning_rounded, const Color(0xFFEF4444)),
            ]),
            const SizedBox(height: 12),
            _financialCardRow(context, sv, [
              _CardData('Active Loans', Icons.request_quote, const Color(0xFFF59E0B)),
              _CardData('Credit Cards', Icons.credit_card, const Color(0xFF9C27B0)),
            ]),
            const SizedBox(height: 12),
            _financialCardRow(context, sv, [
              _CardData('UPI Transactions', Icons.qr_code_scanner, const Color(0xFF8B5CF6)),
              _CardData('UPI Net', Icons.account_balance_wallet_outlined, const Color(0xFF10B981)),
            ]),
            const SizedBox(height: 16),
            _monthlySummaryCard(context, monthName, sv),
            const SizedBox(height: 16),
            _spendingByCategoryCard(context, sv),
            const SizedBox(height: 16),
            _budgetOverviewCard(context, sv),
            const SizedBox(height: 16),
            _upiBreakdownCard(context, sv),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _financialCardRow(BuildContext context, double sv, List<_CardData> cards) {
    return Row(
      children: [
        Expanded(child: _financialCard(context, sv, cards[0])),
        const SizedBox(width: 12),
        Expanded(child: _financialCard(context, sv, cards[1])),
      ],
    );
  }

  Widget _financialCard(BuildContext context, double sv, _CardData data) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: data.color.withValues(alpha: 0.3), width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              data.color.withValues(alpha: 0.1),
              data.color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(data.icon, color: data.color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ShimmerBox(shimmerValue: sv, width: 80, height: 22, radius: 6),
            const SizedBox(height: 6),
            _ShimmerBox(shimmerValue: sv, width: 60, height: 12, radius: 4),
          ],
        ),
      ),
    );
  }

  Widget _monthlySummaryCard(BuildContext context, String monthName, double sv) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              monthName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _monthStatSkeleton(context, 'Income', const Color(0xFF10B981), sv),
                _monthStatSkeleton(context, 'Expense', const Color(0xFFEF4444), sv),
                _monthStatSkeleton(context, 'Balance', const Color(0xFF3B82F6), sv),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthStatSkeleton(
    BuildContext context,
    String label,
    Color color,
    double sv,
  ) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        _ShimmerBox(shimmerValue: sv, width: 70, height: 22, radius: 6),
      ],
    );
  }

  Widget _spendingByCategoryCard(BuildContext context, double sv) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pie_chart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending by Category',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ShimmerBox(shimmerValue: sv, width: 80, height: 12, radius: 4),
                    ],
                  ),
                ),
                _ShimmerBox(shimmerValue: sv, width: 64, height: 28, radius: 12),
              ],
            ),
            const SizedBox(height: 20),
            _categoryRowSkeleton(sv),
            const SizedBox(height: 16),
            _categoryRowSkeleton(sv),
            const SizedBox(height: 16),
            _categoryRowSkeleton(sv),
          ],
        ),
      ),
    );
  }

  Widget _categoryRowSkeleton(double sv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(shimmerValue: sv, width: 36, height: 36, radius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(shimmerValue: sv, width: 100, height: 15, radius: 4),
                    const SizedBox(height: 6),
                    _ShimmerBox(shimmerValue: sv, width: 70, height: 11, radius: 4),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ShimmerBox(shimmerValue: sv, width: 60, height: 16, radius: 4),
                  const SizedBox(height: 4),
                  _ShimmerBox(shimmerValue: sv, width: 40, height: 20, radius: 8),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ShimmerBox(shimmerValue: sv, width: double.infinity, height: 8, radius: 8),
        ],
      ),
    );
  }

  Widget _budgetOverviewCard(BuildContext context, double sv) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _budgetRowSkeleton(sv),
            _budgetRowSkeleton(sv),
            _budgetRowSkeleton(sv),
          ],
        ),
      ),
    );
  }

  Widget _budgetRowSkeleton(double sv) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShimmerBox(shimmerValue: sv, width: 90, height: 14, radius: 4),
              _ShimmerBox(shimmerValue: sv, width: 80, height: 14, radius: 4),
            ],
          ),
          const SizedBox(height: 4),
          _ShimmerBox(shimmerValue: sv, width: double.infinity, height: 6, radius: 10),
        ],
      ),
    );
  }

  Widget _upiBreakdownCard(BuildContext context, double sv) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'UPI Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _ShimmerBox(shimmerValue: sv, width: 60, height: 28, radius: 12),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _upiStatSkeleton(context, 'Income', const Color(0xFF10B981), sv),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _upiStatSkeleton(context, 'Expense', const Color(0xFFEF4444), sv),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _upiStatSkeleton(context, 'Net', const Color(0xFF3B82F6), sv),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Top UPI Apps',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _upiAppSkeleton(sv),
            const SizedBox(height: 12),
            _upiAppSkeleton(sv),
          ],
        ),
      ),
    );
  }

  Widget _upiStatSkeleton(
    BuildContext context,
    String label,
    Color color,
    double sv,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _ShimmerBox(shimmerValue: sv, width: 60, height: 20, radius: 4),
        ],
      ),
    );
  }

  Widget _upiAppSkeleton(double sv) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code, size: 16, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(shimmerValue: sv, width: 100, height: 14, radius: 4),
                    const SizedBox(height: 4),
                    _ShimmerBox(shimmerValue: sv, width: 70, height: 10, radius: 4),
                  ],
                ),
              ),
              _ShimmerBox(shimmerValue: sv, width: 50, height: 22, radius: 8),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              _ShimmerBox(shimmerValue: sv, width: 60, height: 14, radius: 4),
            ],
          ),
          const SizedBox(height: 4),
          _ShimmerBox(shimmerValue: sv, width: 120, height: 11, radius: 4),
        ],
      ),
    );
  }
}

class _CardData {
  final String label;
  final IconData icon;
  final Color color;
  const _CardData(this.label, this.icon, this.color);
}

class _ShimmerBox extends StatelessWidget {
  final double shimmerValue;
  final double? width;
  final double height;
  final double radius;

  const _ShimmerBox({
    required this.shimmerValue,
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade500 : Colors.grey.shade100;

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(shimmerValue - 1.5, 0),
        end: Alignment(shimmerValue, 0),
        colors: [base, highlight, base],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
