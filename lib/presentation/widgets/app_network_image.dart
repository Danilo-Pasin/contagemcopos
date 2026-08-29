import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/widgets.dart';

/// Imagem de rede com cache usada em todo o app.
///
/// Centraliza o `CachedNetworkImage` num só lugar para forçar o
/// `ImageRenderMethodForWeb.HttpGet` no web. O default (`HtmlImage`) passa por
/// `ui_web.createImageCodecFromUrl`, que tem a regressão de **fotos pretas**
/// (#191800) em certas versões do Flutter. O `HttpGet` baixa via cliente HTTP,
/// retorna ao cache em disco/memória (`flutter_cache_manager`) e faz a evicção
/// do `ImageCache` funcionar — sem o placeholder preto.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final int? memCacheWidth;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object?)? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.memCacheWidth,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      memCacheWidth: memCacheWidth,
      width: width,
      height: height,
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
