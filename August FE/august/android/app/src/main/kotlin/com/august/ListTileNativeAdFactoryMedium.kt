package com.august.android

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin


class ListTileNativeAdFactoryMedium(val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = LayoutInflater.from(context)
            .inflate(R.layout.list_tile_native_ad_medium, null) as NativeAdView



        with(nativeAdView) {
            val mediaView = findViewById<MediaView>(R.id.native_ad_media)
            mediaView.setMediaContent(nativeAd.mediaContent)

            val iconView = findViewById<ImageView>(R.id.native_ad_icon)
            nativeAd.icon?.let {
                iconView.setImageDrawable(it.drawable)
                iconView.visibility = View.VISIBLE
            } ?: run {
                iconView.visibility = View.GONE
            }

            val ratingBar = findViewById<RatingBar>(R.id.native_ad_rating)
            nativeAd.starRating?.let {
                ratingBar.rating = it.toFloat()
                ratingBar.visibility = View.VISIBLE
            } ?: run {
                ratingBar.visibility = View.GONE
            }

            val headlineView = findViewById<TextView>(R.id.native_ad_headline)
            headlineView.text = nativeAd.headline

            val advertiserView = findViewById<TextView>(R.id.native_ad_advertiser)
            nativeAd.advertiser?.let {
                advertiserView.text = it
                advertiserView.visibility = View.VISIBLE
            } ?: run {
                advertiserView.visibility = View.GONE
            }

            val bodyView = findViewById<TextView>(R.id.native_ad_body)
            nativeAd.body?.let {
                bodyView.text = it
                bodyView.visibility = View.VISIBLE
            } ?: run {
                bodyView.visibility = View.GONE
            }

            val callToActionView = findViewById<Button>(R.id.native_ad_button)
            callToActionView.text = nativeAd.callToAction

            setNativeAd(nativeAd)
        }

        return nativeAdView
    }
}