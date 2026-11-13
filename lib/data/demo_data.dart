/// Local sample data for the navigation milestone.
///
/// Everything here is replaced by Supabase queries when the catalogue and
/// orders tables land. Keeping it in one file means the screens never hard-code
/// merchant or order details inline.
class DemoMerchant {
  const DemoMerchant({
    required this.name,
    required this.departmentId,
    required this.area,
    required this.rating,
    required this.deliveryMinutes,
    required this.isOpen,
    this.priceNote,
  });

  final String name;

  /// Matches an id in `supremeDepartments`.
  final String departmentId;
  final String area;
  final double rating;
  final int deliveryMinutes;
  final bool isOpen;

  /// e.g. "From KSh 60/kg"
  final String? priceNote;
}

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

const List<DemoMerchant> demoMerchants = <DemoMerchant>[
  DemoMerchant(
    name: 'Nyeri Fresh Mart',
    departmentId: 'shopping',
    area: 'Kimathi Way',
    rating: 4.7,
    deliveryMinutes: 20,
    isOpen: true,
    priceNote: 'Groceries · household',
  ),
  DemoMerchant(
    name: 'Chieni Supermarket',
    departmentId: 'shopping',
    area: 'Town centre',
    rating: 4.5,
    deliveryMinutes: 30,
    isOpen: true,
    priceNote: 'Groceries · electronics',
  ),
  DemoMerchant(
    name: 'Mama Ngina Cafe',
    departmentId: 'food',
    area: 'Town centre',
    rating: 4.8,
    deliveryMinutes: 25,
    isOpen: true,
    priceNote: 'Kenyan · breakfast',
  ),
  DemoMerchant(
    name: 'Hotel Nokras Grill',
    departmentId: 'food',
    area: 'Ruring\u2019u',
    rating: 4.6,
    deliveryMinutes: 35,
    isOpen: true,
    priceNote: 'Grill · full menu',
  ),
  DemoMerchant(
    name: 'Karatina Greens',
    departmentId: 'fresh',
    area: 'Market day',
    rating: 4.6,
    deliveryMinutes: 40,
    isOpen: true,
    priceNote: 'From KSh 40/kg',
  ),
  DemoMerchant(
    name: 'Kamakwa Farm Produce',
    departmentId: 'fresh',
    area: 'Kamakwa',
    rating: 4.4,
    deliveryMinutes: 45,
    isOpen: false,
    priceNote: 'From KSh 55/kg',
  ),
];

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

List<DemoMerchant> merchantsFor(String departmentId) {
  return demoMerchants
      .where((DemoMerchant m) => m.departmentId == departmentId)
      .toList();
}

const List<String> orderStatusLabels = <String>[
  'Received',
  'Preparing',
  'On the way',
  'Delivered',
];
