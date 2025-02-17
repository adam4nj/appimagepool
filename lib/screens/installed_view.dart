import 'dart:io';

import 'package:libadwaita/libadwaita.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:appimagepool/utils/utils.dart';
import 'package:appimagepool/translations/translations.dart';
import 'package:appimagepool/providers/providers.dart';

class InstalledView extends ConsumerStatefulWidget {
  final ValueNotifier<String> searchedTerm;

  const InstalledView({Key? key, required this.searchedTerm}) : super(key: key);

  @override
  ConsumerState<InstalledView> createState() => _InstalledViewState();
}

class _InstalledViewState extends ConsumerState<InstalledView> {
  @override
  Widget build(context) {
    final downloadPath = ref.watch(downloadPathProvider);
    List<FileSystemEntity> listInstalled = Directory(downloadPath).existsSync()
        ? Directory(downloadPath)
            .listSync()
            .where((element) => element.path.endsWith('.AppImage'))
            .where((element) => path
                .basename(element.path)
                .toLowerCase()
                .contains(widget.searchedTerm.value))
            .toList()
        : [];
    return listInstalled.isNotEmpty
        ? SingleChildScrollView(
            child: Center(
              child: AdwClamp(
                child: AdwPreferencesGroup(
                  children: List.generate(
                    listInstalled.length,
                    (index) {
                      final i = listInstalled[index];

                      void removeItem() async {
                        File(i.path).deleteSync();
                        listInstalled.removeAt(index);
                        setState(() {});
                      }

                      return ListTile(
                        title: Text(
                          path.basenameWithoutExtension(i.path),
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyText1,
                        ),
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        subtitle: Text(i.statSync().size.getFileSize()),
                        trailing: IconButton(
                          onPressed: removeItem,
                          icon: const Icon(LucideIcons.trash),
                        ),
                        onTap: () => runProgram(
                          location: path.dirname(i.path),
                          program: path.basename(i.path),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          )
        : Center(
            child: Text(
                '${AppLocalizations.of(context)!.noAppImageInThisRelease} ' +
                    downloadPath));
  }
}
