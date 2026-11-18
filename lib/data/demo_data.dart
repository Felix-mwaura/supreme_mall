/// Sample **orders** used by the Orders tab until the orders table exists.
///
/// Merchants and products no longer live here — they come from Supabase through
/// `CatalogueRepository`. This file goes away with the cart and checkout
/// milestone, which replaces these rows with real order records.
class DemoOrderLine {
  const DemoOrderLine(this.name, this.quantity);

  final String name;
  final int quantity;
}

class DemoOrder {
  const DemoOrder({
    required this.reference,
    required this.merchantName,
    required this.departmentName,
    required this.totalKsh,
    required this.placedLabel,
    required this.stepIndex,
    required this.lines,
    this.isActive = false,
  });

  final String reference;
  final String merchantName;
  final String departmentName;
  final int totalKsh;
  final String placedLabel;

  /// 0 = received, 1 = preparing, 2 = on the way, 3 = completed.
  final int stepIndex;
  final List<DemoOrderLine> lines;
  final bool isActive;
}

const List<DemoOrder> demoOrders = <DemoOrder>[
  DemoOrder(
    reference: 'SM-1042',
    merchantName: 'Nyeri Fresh Mart',
    departmentName: 'Shopping',
    totalKsh: 1240,
    placedLabel: 'Today, 6:12 PM',
    stepIndex: 2,
    isActive: true,
    lines: <DemoOrderLine>[
      DemoOrderLine('Unga 2kg', 1),
      DemoOrderLine('Milk 500ml', 2),
      DemoOrderLine('Cooking oil 1L', 1),
    ],
  ),
  DemoOrder(
    reference: 'SM-1031',
    merchantName: 'Mama Ngina Cafe',
    departmentName: 'Food',
    totalKsh: 650,
    placedLabel: 'Yesterday, 1:04 PM',
    stepIndex: 3,
    lines: <DemoOrderLine>[
      DemoOrderLine('Nyama choma plate', 1),
      DemoOrderLine('Soda 300ml', 1),
    ],
  ),
  DemoOrder(
    reference: 'SM-1018',
    merchantName: 'Karatina Greens',
    departmentName: 'Fresh',
    totalKsh: 380,
    placedLabel: 'Mon, 9:41 AM',
    stepIndex: 3,
    lines: <DemoOrderLine>[
      DemoOrderLine('Sukuma wiki (bunch)', 2),
      DemoOrderLine('Tomatoes 1kg', 1),
    ],
  ),
];

const List<String> orderStatusLabels = <String>[
  'Received',
  'Preparing',
  'On the way',
  'Delivered',
];
