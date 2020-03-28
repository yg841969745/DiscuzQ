import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:discuzq/models/attachmentsModel.dart';
import 'package:discuzq/models/threadModel.dart';
import 'package:discuzq/widgets/common/discuzContextMenu.dart';
import 'package:discuzq/widgets/common/discuzToast.dart';
import 'package:discuzq/widgets/share/shareNative.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class DiscuzImage extends StatefulWidget {
  ///
  /// 是否允许分享
  /// 允许分享的时候，要同时传入threadModel thread 否则将无法分享
  final bool enbleShare;

  ///
  /// 附件
  final AttachmentsModel attachment;

  ///
  /// 主题
  /// 关联的主题，当enable Share的时候要传入
  final ThreadModel thread;

  ///
  /// 是否是缩略图模式
  /// 否则将返回原图
  final bool isThumb;

  ///
  /// 查看原图
  /// 请求查看原图
  final Function onWantOriginalImage;

  const DiscuzImage({
    @required this.attachment,
    this.thread,
    this.onWantOriginalImage,
    this.isThumb = true,
    this.enbleShare = false,
  });
  @override
  _DiscuzImageState createState() => _DiscuzImageState();
}

class _DiscuzImageState extends State<DiscuzImage> {
  @override
  Widget build(BuildContext context) {
    return _buildImage(
        attachment: widget.attachment,
        context: context,
        onWantOriginalImage: widget.onWantOriginalImage);
  }

  ///
  /// 生成被缓存的图片，这个图片将被context Menu包裹
  ///
  Widget _buildImage(
      {BuildContext context,
      @required AttachmentsModel attachment,
      @required Function onWantOriginalImage}) {
    final double imageSize = (MediaQuery.of(context).size.width * .3) - 4;

    return CupertinoContextMenu(
      previewBuilder:
          (BuildContext context, Animation<double> animation, Widget child) {
        return FittedBox(
          fit: BoxFit.cover,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4 * animation.value),
            child: child,
          ),
        );
      },
      actions: <Widget>[
        DiscuzContextMenuAction(
          child: const Text('保存原图'),
          trailingIcon: SFSymbols.tray_arrow_down,
          onPressed: () async {
            final Response response = await Dio().get(attachment.attributes.url,
                options: Options(responseType: ResponseType.bytes));
            final result = await ImageGallerySaver.saveImage(
                Uint8List.fromList(response.data));
            if (result) {
              DiscuzToast.success(context: context, message: '保存成功');
              Navigator.pop(context);
              return;
            }
            DiscuzToast.failed(context: context, message: '保存失败');
            Navigator.pop(context);
          },
        ),
        !widget.enbleShare
            ? const SizedBox()
            : DiscuzContextMenuAction(
                child: const Text('分享'),
                trailingIcon: SFSymbols.square_arrow_up,
                onPressed: () async {
                  await ShareNative.shareThread(thread: widget.thread);
                  Navigator.pop(context);
                },
              ),
      ],
      child: GestureDetector(
        onTap: () => onWantOriginalImage(attachment.attributes.url),
        child: CachedNetworkImage(
          imageUrl: widget.isThumb
              ? attachment.attributes.thumbUrl
              : attachment.attributes.url,
          fit: BoxFit.cover,
          width: widget.isThumb ? imageSize : null,
          height: widget.isThumb ? imageSize : null,
          errorWidget: (context, url, error) => Image.asset(
            'assets/images/errimage.png',
            width: widget.isThumb ? imageSize : null,
            height: widget.isThumb ? imageSize : null,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
