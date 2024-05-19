import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class profileBox extends StatelessWidget {
  final String? svgAsset; // nullable로 변경
  final String text;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  final int? index;

  profileBox({
    this.svgAsset, // 필수가 아님
    required this.text,
    required this.onTap,
    required this.iconColor,
    required this.textColor,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          // SVG 아이콘 컨테이너
          if (svgAsset != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                svgAsset!,
                color: iconColor,
                width: 25,
                height: 25,
              ),
            ),
            SizedBox(width: 20),
          ],
          // 텍스트
          Text(
            index != null ? "$index. $text" : text,
            style: TextStyle(
              fontSize: 20,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
