import 'package:flutter/material.dart';

import '../../../data/demo_data.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../utils/money.dart';
import '../../../widgets/dark_surface.dart';

/// Orders tab — active deliveries plus order history.
///
/// The status ladder (Received → Preparing → On the way → Delivered) is the one
/// from the roadmap §4.2/4.5 workflows; the same widget will later be driven by
/// real rows so the customer, merchant and rider all see one truth.
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final List<DemoOrder> active =
        demoOrders.where((DemoOrder o) => o.isActive).toList();
    final List<DemoOrder> past =
        demoOrders.where((DemoOrder o) => !o.isActive).toList();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Orders',
              style: AppText.screenTitle.copyWith(fontSize: 24, color: AppColors.inkOnDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Track deliveries and reorder in two taps.',
              style: AppText.caption.copyWith(color: AppColors.inkMutedOnDark),
            ),
            const SizedBox(height: 16),
            _Segmented(
              activeLabel: 'Active',
              pastLabel: 'Past',
              showActive: _showActive,
              onChanged: (bool value) => setState(() => _showActive = value),
            ),
            const SizedBox(height: 18),
            if (_showActive) ...<Widget>[
              if (active.isEmpty)
                const DarkEmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'No active orders',
                  message: 'When you place an order, its live status appears here.',
                )
              else
                for (final DemoOrder order in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ActiveOrderCard(order: order),
                  ),
            ] else ...<Widget>[
              if (past.isEmpty)
                const DarkEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No past orders',
                  message: 'Completed orders and receipts will be listed here.',
                )
              else
                for (final DemoOrder order in past)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PastOrderRow(order: order),
                  ),
            ],
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                const Icon(Icons.info_outline, size: 13, color: AppColors.inkMutedOnDark),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sample orders for the navigation build — history syncs with the orders table.',
                    style: AppText.caption.copyWith(fontSize: 10, color: AppColors.inkMutedOnDark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.activeLabel,
    required this.pastLabel,
    required this.showActive,
    required this.onChanged,
  });

  final String activeLabel;
  final String pastLabel;
  final bool showActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: darkSurface(radius: 100),
      child: Row(
        children: <Widget>[
          _segment(activeLabel, showActive, () => onChanged(true)),
          _segment(pastLabel, !showActive, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.goldSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected ? const Color(0x59D4A017) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.gold : AppColors.inkMutedOnDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final DemoOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: darkSurface(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '#${order.reference} · ${order.departmentName}',
                      style: AppText.caption.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.6,
                        color: AppColors.inkMutedOnDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.merchantName,
                      style: AppText.cardTitle.copyWith(fontSize: 14, color: AppColors.inkOnDark),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0x4DD4A017)),
                ),
                child: Text(
                  orderStatusLabels[order.stepIndex],
                  style: AppText.caption.copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatusLadder(stepIndex: order.stepIndex),
          const SizedBox(height: 14),
          Container(height: 1, color: AppColors.hairlineDark),
          const SizedBox(height: 12),
          for (final DemoOrderLine line in order.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: <Widget>[
                  Text(
                    '${line.quantity}×',
                    style: AppText.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkMutedOnDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line.name,
                      style: AppText.caption.copyWith(fontSize: 11, color: AppColors.inkOnDark),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Text(
                'Total',
                style: AppText.caption.copyWith(fontSize: 11, color: AppColors.inkMutedOnDark),
              ),
              const SizedBox(width: 6),
              Text(
                ksh(order.totalKsh),
                style: AppText.cardTitle.copyWith(fontSize: 12.5, color: AppColors.inkOnDark),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0x4DD4A017)),
                ),
                child: Text(
                  'Track order',
                  style: AppText.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusLadder extends StatelessWidget {
  const _StatusLadder({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < orderStatusLabels.length; i++) ...<Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.transparent
                              : (i <= stepIndex ? AppColors.gold : AppColors.hairlineDark),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  orderStatusLabels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.6,
                    fontWeight: i <= stepIndex ? FontWeight.w700 : FontWeight.w500,
                    color: i <= stepIndex ? AppColors.inkOnDark : AppColors.inkMutedOnDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PastOrderRow extends StatelessWidget {
  const _PastOrderRow({required this.order});

  final DemoOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: darkSurface(radius: 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.hairlineDark),
            ),
            child: const Icon(Icons.check_rounded, size: 17, color: AppColors.emerald),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  order.merchantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle.copyWith(fontSize: 12, color: AppColors.inkOnDark),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${order.reference} · ${order.placedLabel}',
                  style: AppText.caption.copyWith(fontSize: 9.5, color: AppColors.inkMutedOnDark),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                ksh(order.totalKsh),
                style: AppText.cardTitle.copyWith(fontSize: 11.5, color: AppColors.inkOnDark),
              ),
              const SizedBox(height: 2),
              Text(
                'Reorder',
                style: AppText.caption.copyWith(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
