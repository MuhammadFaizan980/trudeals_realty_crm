import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:trudeals_realty_crm/src/core/theme/trudeals_colors.dart';

class TrashPage extends StatelessWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 34.px, vertical: 20.px),
      children: [
        Container(
          padding: EdgeInsets.all(13.px),
          decoration: BoxDecoration(
            color: TruDealsColors.sageMist,
            borderRadius: BorderRadius.circular(8.px),
          ),
          child: Text(
            "Profiles are never permanently deleted. Deleted profiles live here with their full history, and only a Super User can restore them.",
            style: TextStyle(fontSize: 12.5.px, color: TruDealsColors.inkSoft),
          ),
        ),
        SizedBox(height: 16.px),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.px),
            border: Border.all(color: TruDealsColors.line),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFFFBFAF7),
                  border: Border(bottom: BorderSide(color: TruDealsColors.line)),
                ),
                children: [
                   _headerCell('Name'),
                   _headerCell('Property'),
                   _headerCell('Deleted'),
                   _headerCell('Deleted By'),
                   _headerCell(''),
                ],
              ),
              // Mock trash data
               TableRow(
                children: [
                  _dataCell(const Text('Old Lead', style: TextStyle(fontWeight: FontWeight.bold))),
                  _dataCell(const Text('456 Old Rd')),
                  _dataCell(const Text('Oct 12, 2:00 PM', style: TextStyle(fontFamily: 'DM Mono'))),
                  _dataCell(const Text('Joe Farmer')),
                  _dataCell(TextButton(onPressed: () {}, child: const Text('Restore'))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String label) {
    return Padding(
      padding: EdgeInsets.all(16.px),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5.px,
          letterSpacing: 0.09,
          fontWeight: FontWeight.w700,
          color: TruDealsColors.inkSoft,
        ),
      ),
    );
  }

  Widget _dataCell(Widget child) {
    return Padding(
      padding: EdgeInsets.all(16.px),
      child: child,
    );
  }
}
