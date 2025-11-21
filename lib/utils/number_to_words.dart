class NumberToWords {
  static final List<String> _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static final List<String> _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  static String convert(int number) {
    if (number == 0) return 'Zero';
    return _convertRecursive(number).trim();
  }

  static String _convertRecursive(int n) {
    if (n < 20) {
      return _ones[n];
    } else if (n < 100) {
      return '${_tens[n ~/ 10]} ${_ones[n % 10]}';
    } else if (n < 1000) {
      return '${_ones[n ~/ 100]} Hundred ${_convertRecursive(n % 100)}';
    } else if (n < 100000) {
      return '${_convertRecursive(n ~/ 1000)} Thousand ${_convertRecursive(n % 1000)}';
    } else if (n < 10000000) {
      return '${_convertRecursive(n ~/ 100000)} Lakh ${_convertRecursive(n % 100000)}';
    } else {
      return '${_convertRecursive(n ~/ 10000000)} Crore ${_convertRecursive(n % 10000000)}';
    }
  }
}
