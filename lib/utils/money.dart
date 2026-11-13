/// Kenyan shilling formatting. Always "KSh 1,240" — one format everywhere,
/// because receipts, statements and the commission ledger all reuse it.
String ksh(int amount) {
  final String digits = amount.abs().toString();
  final StringBuffer out = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    final int remaining = digits.length - i;
    out.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      out.write(',');
    }
  }

  return '${amount < 0 ? '-' : ''}KSh $out';
}
