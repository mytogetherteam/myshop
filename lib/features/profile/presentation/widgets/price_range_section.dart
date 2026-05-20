import 'package:flutter/material.dart';
import 'form_section.dart';
import 'price_option.dart';

class PriceRangeSection extends StatefulWidget {
  final int initialPriceRange;
  final ValueChanged<int> onChanged;

  const PriceRangeSection({
    super.key,
    required this.initialPriceRange,
    required this.onChanged,
  });

  @override
  State<PriceRangeSection> createState() => _PriceRangeSectionState();
}

class _PriceRangeSectionState extends State<PriceRangeSection> {
  late int _priceRange;

  @override
  void initState() {
    super.initState();
    _priceRange = widget.initialPriceRange;
  }

  @override
  Widget build(BuildContext context) {
    return FormSection(
      label: 'Price Range',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            PriceOption(
              label: '฿ Budget',
              index: 0,
              selected: _priceRange == 0,
              onTap: () {
                setState(() => _priceRange = 0);
                widget.onChanged(0);
              },
            ),
            PriceOption(
              label: '฿฿ Mid-range',
              index: 1,
              selected: _priceRange == 1,
              onTap: () {
                setState(() => _priceRange = 1);
                widget.onChanged(1);
              },
            ),
            PriceOption(
              label: '฿฿฿ Premium',
              index: 2,
              selected: _priceRange == 2,
              onTap: () {
                setState(() => _priceRange = 2);
                widget.onChanged(2);
              },
            ),
          ],
        ),
      ),
    );
  }
}
