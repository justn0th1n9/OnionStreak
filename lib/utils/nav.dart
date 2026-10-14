import 'package:flutter/material.dart';

Future<T?> buka<T>(BuildContext context, Widget layar) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => layar));

Future<bool> konfirmasi(BuildContext context, String judul, String isi,
    {String aksi = 'Ya'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        FilledButton(
            onPressed: () => Navigator.pop(context, true), child: Text(aksi)),
      ],
    ),
  );
  return r ?? false;
}
