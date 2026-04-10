import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';


class AvatarImageWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final bool isCircle;

  const AvatarImageWidget({
    super.key,
    required this.imageUrl,
    this.width = 80.0,
    this.height = 80.0,
    this.fit = BoxFit.cover,
    this.isCircle = true,
  });

  bool _isSvgUrl(String url) {
    return url.contains('.svg') || url.contains('svg?');
  }

  @override
  Widget build(BuildContext context) {
    final isSvg = _isSvgUrl(imageUrl);

    Widget imageWidget;
    if (isSvg) {
     
      imageWidget = SvgPicture.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholderBuilder: (context) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.person),
        ),
      );
    } else {
     
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            Container(color: Colors.grey[200], child: const Icon(Icons.person)),
        errorWidget: (context, url, error) =>
            Container(color: Colors.grey[200], child: const Icon(Icons.error)),
      );
    }

    if (!isCircle) {
      return imageWidget;
    }

    return ClipOval(child: imageWidget);
  }
}
