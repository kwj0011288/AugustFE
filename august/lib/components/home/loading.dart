// ignore_for_file: depend_on_referenced_packages, use_super_parameters, use_key_in_widget_constructors, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:skeleton_text/skeleton_text.dart';

class SkeletonContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final BorderRadius borderRadius;

  const SkeletonContainer._({
    this.width,
    this.height,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(0)),
    Key? key,
  }) : super(key: key);

  const SkeletonContainer.rounded({
    double? width,
    double? height,
    Color? color,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) : this._(
          width: width,
          height: height,
          color: color,
          borderRadius: borderRadius,
        );

  const SkeletonContainer.circular({
    double? width,
    double? height,
    Color? color,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(80)),
  }) : this._(
          width: width,
          height: height,
          color: color,
          borderRadius: borderRadius,
        );

  const SkeletonContainer.schedule({
    double? width,
    double? height,
    Color? color,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
  }) : this._(
          width: width,
          height: height,
          color: color,
          borderRadius: borderRadius,
        );

  @override
  Widget build(BuildContext context) {
    return SkeletonAnimation(
      shimmerColor:
          color ?? Theme.of(context).colorScheme.tertiary, // Adjust this line
      borderRadius: borderRadius,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.tertiary,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

Widget GroupLoading1(BuildContext context) {
  return Stack(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Skelton(height: 100, width: MediaQuery.of(context).size.width),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 23, horizontal: 34),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonContainer.rounded(height: 25, width: 95),
                SizedBox(
                  height: 5,
                ),
                SkeletonContainer.rounded(height: 25, width: 140),
                SizedBox(
                  width: 28,
                ),
              ],
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: SkeletonContainer.circular(
                height: 30,
                width: 30,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget GroupLoading2(BuildContext context) {
  return Stack(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
        child: Skelton(height: 105, width: MediaQuery.of(context).size.width),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonContainer.rounded(
                    color: Theme.of(context).colorScheme.tertiary,
                    height: 25,
                    width: 95),
                const SizedBox(
                  height: 5,
                ),
                SkeletonContainer.rounded(
                    color: Theme.of(context).colorScheme.tertiary,
                    height: 25,
                    width: 140),
                const SizedBox(
                  width: 28,
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SkeletonContainer.circular(
                color: Theme.of(context).colorScheme.tertiary,
                height: 30,
                width: 30,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget GroupLoading3(BuildContext context) {
  return Stack(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
        child: SkeletonContainer.schedule(
            color: Theme.of(context).colorScheme.tertiary,
            height: 450,
            width: MediaQuery.of(context).size.width),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            Spacer(),
          ],
        ),
      ),
    ],
  );
}

Widget GroupLoading4(BuildContext context) {
  return Stack(
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
        child: SkeletonContainer.rounded(
            color: Theme.of(context).colorScheme.tertiary,
            height: MediaQuery.of(context).size.height - 250,
            width: MediaQuery.of(context).size.width),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 25),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
            Spacer(),
          ],
        ),
      ),
    ],
  );
}

class Skelton extends StatelessWidget {
  const Skelton({
    super.key,
    this.height,
    this.width,
  });
  final double? height, width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(
        bottom: 15.0,
      ),
    );
  }
}
