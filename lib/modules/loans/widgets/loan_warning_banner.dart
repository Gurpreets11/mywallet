import 'package:flutter/material.dart';

class LoanWarningBanner
    extends StatelessWidget {

  final String message;

  const LoanWarningBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding:
      const EdgeInsets.all(14),

      decoration: BoxDecoration(

        color:
        Colors.red.withOpacity(
          0.1,
        ),

        borderRadius:
        BorderRadius.circular(
          12,
        ),

        border: Border.all(
          color:
          Colors.red.shade300,
        ),
      ),

      child: Row(

        children: [

          const Icon(
            Icons.warning_amber,
            color: Colors.red,
          ),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              message,

              style: const TextStyle(
                color: Colors.red,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}