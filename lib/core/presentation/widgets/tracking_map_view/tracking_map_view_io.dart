import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TrackingMapView extends StatefulWidget {
  final String url;

  const TrackingMapView({super.key, required this.url});

  @override
  State<TrackingMapView> createState() => _TrackingMapViewState();
}

class _TrackingMapViewState extends State<TrackingMapView> {
  WebViewController? _controller;

  @override
  Widget build(BuildContext context) {
    _controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));

    return WebViewWidget(controller: _controller!);
  }
}
