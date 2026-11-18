import 'package:flutter/material.dart';

class DeferredScreen extends StatefulWidget {
  final Future<void> Function() loader;
  final Widget Function() builder;

  const DeferredScreen({
    super.key,
    required this.loader,
    required this.builder,
  });

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Не удалось загрузить раздел.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => setState(() => _loading = widget.loader()),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }
        return widget.builder();
      },
    );
  }
}
