import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:august/provider/user_info_provider.dart';

class ProfileWidget extends StatefulWidget {
  final bool isBottomBar;
  final bool isProfilePage;
  const ProfileWidget({
    Key? key,
    required this.isBottomBar,
    this.isProfilePage = false,
  }) : super(key: key);

  @override
  _ProfileWidgetState createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserInfoProvider>(
      builder: (context, userProvider, child) {
        var userDetails = userProvider.userInfo;

        // Check if userDetails is null and handle the UI accordingly
        if (userDetails == null) {
          return CircularProgressIndicator();
        }

        // Ensure the profile image URL is not null using null-aware operators
        var profileImageUrl = userDetails.profileImage ??
            'https://augustapp.one/media/institution_logos/umd.png';

        return Padding(
          padding:
              widget.isBottomBar ? const EdgeInsets.all(5.0) : EdgeInsets.zero,
          child: ClipOval(
            child: widget.isProfilePage
                ? SizedBox(
                    width: 200,
                    height: 200,
                    child: CircleAvatar(
                      backgroundColor: Colors.grey,
                      foregroundColor: Theme.of(context).colorScheme.background,
                      backgroundImage: profileImageUrl == null
                          ? null
                          : CachedNetworkImageProvider(profileImageUrl),
                    ),
                  )
                : CachedNetworkImage(
                    width: 50,
                    height: 50,
                    imageUrl: profileImageUrl,
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => CircleAvatar(
                      maxRadius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
