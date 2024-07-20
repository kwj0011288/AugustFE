import 'package:august/components/ad/ad_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class googleAdMobGridList extends StatefulWidget {
  const googleAdMobGridList({super.key});

  @override
  State<googleAdMobGridList> createState() => _googleAdMobGridListState();
}

class _googleAdMobGridListState extends State<googleAdMobGridList> {
  NativeAd? _nativeAd;
  bool isAdsLoaded = false;

  @override
  void initState() {
    _nativeAd = NativeAd(
      factoryId: 'listTile',
      adUnitId: AdHelper.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!isAdsLoaded) {
            setState(() {
              isAdsLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a native ad: ${err.message}');
          isAdsLoaded = false;
          ad.dispose();
        },
      ),
    );
    _nativeAd!.load();
    super.initState();
  }

  @override
  void dispose() {
    _nativeAd!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isAdsLoaded
        ? Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
            child: Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10,
                    offset: Offset(6, 4),
                  ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              child: AdWidget(ad: _nativeAd!),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(
              bottom: 15,
              left: 15,
              right: 15,
            ),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10,
                    offset: Offset(6, 4),
                  ),
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 10,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'August',
                ),
              ),
            ),
          );
  }
}
