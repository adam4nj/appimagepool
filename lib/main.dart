import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:adwaita/adwaita.dart' as adwaita;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

import 'package:appimagepool/utils/utils.dart';
import 'package:appimagepool/translations/translations.dart';
import 'package:appimagepool/screens/screens.dart';
import 'package:appimagepool/widgets/widgets.dart';
import 'package:appimagepool/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MyPrefs().init();
  runApp(const ProviderScope(child: MyApp()));

  doWhenWindowReady(() {
    appWindow.alignment = Alignment.center;
    appWindow.title = "Pool";
    appWindow.show();
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      darkTheme: adwaita.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: adwaita.lightTheme,
      themeMode: ref.watch(forceDarkThemeProvider),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulHookWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

Map getSimplifiedCategories(List value) {
  return value.groupBy((m) {
    List categori = m['categories'];
    List newList = [];
    for (var category in categori) {
      if (category != null && category.length > 0) {
        if (doesContain(category, ['Video'])) {
          newList.add('Video');
        } else if (doesContain(category, ['Audio', 'Music'])) {
          newList.add('Audio');
        } else if (doesContain(category, ['Photo'])) {
          newList.add('Graphics');
        } else if (doesContain(category, ['KDE'])) {
          newList.add('Qt');
        } else if (doesContain(category, ['GNOME'])) {
          newList.add('GTK');
        } else if (doesContain(category, [
          'Application',
          'AdventureGame',
          'Astronomy',
          'Chat',
          'InstantMessag',
          'Database',
          'Engineering',
          'Electronics',
          'HamRadio',
          'IDE',
          'News',
          'ProjectManagement',
          'Settings',
          'StrategyGame',
          'TextEditor',
          'TerminalEmulator',
          'Viewer',
          'WebDev',
          'WordProcessor',
          'X-Tool',
        ])) {
          newList.add('Others');
        } else {
          newList.add(category);
        }
      } else {
        newList.add("Others");
      }
    }
    return newList;
  });
}

class _HomePageState extends State<HomePage> {
  bool _isConnected = true;
  void getData() async {
    setState(() => _isConnected = true);
    try {
      allItems = (await Dio().get("https://appimage.github.io/feed.json"))
          .data['items'];
      featured = json.decode((await Dio().get(
              "https://gist.githubusercontent.com/prateekmedia/44c1ea7f7a627d284b9e50d47aa7200f/raw/gistfile1.txt"))
          .data);
    } catch (e) {
      debugPrint(e.toString());
      setState(() => _isConnected = false);
      return;
    }
    categories = (await compute<List, Map>(getSimplifiedCategories, allItems!));
    setState(() {});
  }

  Map? categories;
  List? allItems;
  Map? featured;
  late FlapController _flapController;

  @override
  void initState() {
    getData();
    super.initState();
    _flapController = FlapController();

    _flapController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final navrailIndex = useState<int>(0);
    final searchedTerm = useState<String>("");
    final _currentViewIndex = useState<int>(0);
    final toggleSearch = useState<bool>(false);
    final _controller = PageController();

    void switchSearchBar([bool? value]) {
      if (categories == null && _currentViewIndex.value == 0) return;
      searchedTerm.value = '';
      toggleSearch.value = value ?? !toggleSearch.value;
    }

    return Consumer(
      builder: (ctx, ref, _) => PoolApp(
        center: toggleSearch.value
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                color: Theme.of(context).appBarTheme.backgroundColor,
                constraints: BoxConstraints.loose(const Size(500, 50)),
                child: RawKeyboardListener(
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    autofocus: true,
                    onChanged: (query) => searchedTerm.value = query,
                    style: context.textTheme.bodyText1!.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      fillColor: context.theme.canvasColor,
                      contentPadding: const EdgeInsets.only(top: 8),
                      isCollapsed: true,
                      filled: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event.runtimeType == RawKeyDownEvent &&
                        event.logicalKey.keyId == 4294967323) {
                      switchSearchBar(false);
                    }
                  },
                ),
              )
            : context.width >= mobileWidth
                ? buildViewSwitcher(_currentViewIndex, _controller, ref)
                : null,
        leading: [
          AdwHeaderButton(
            icon: Icon(
              !toggleSearch.value
                  ? LucideIcons.search
                  : LucideIcons.chevronLeft,
              size: 16,
            ),
            onPressed: switchSearchBar,
          ),
        ],
        trailing: !toggleSearch.value
            ? [
                AdwPopupMenu(
                  body: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        dense: true,
                        title: Text(
                          AppLocalizations.of(context)!.preferences,
                          style: context.textTheme.bodyText1,
                        ),
                        onTap: () {
                          context.back();
                          showDialog(
                            context: context,
                            builder: (ctx) => prefsDialog(ctx),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        dense: true,
                        title: Text(
                          AppLocalizations.of(context)!.aboutAppImage,
                          style: context.textTheme.bodyText1,
                        ),
                        onTap: () {
                          context.back();
                          showDialog(
                            context: context,
                            builder: (ctx) => appimageAboutDialog(ctx),
                          );
                        },
                      ),
                      ListTile(
                        dense: true,
                        title: Text(
                          AppLocalizations.of(context)!.aboutApp,
                          style: context.textTheme.bodyText1,
                        ),
                        onTap: () {
                          context.back();
                          showDialog(
                            context: context,
                            builder: (ctx) => aboutDialog(ctx),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ]
            : [],
        body: AdwScaffold(
          flapController: _flapController,
          drawer: Drawer(child: buildSidebar(context, ref, navrailIndex, true)),
          body: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) {
              if (event.runtimeType == RawKeyDownEvent &&
                  event.isControlPressed &&
                  event.logicalKey.keyId == 102) {
                switchSearchBar();
              }
            },
            child: PageView(
              controller: _controller,
              onPageChanged: (index) => _currentViewIndex.value = index,
              children: [
                AdwFlap(
                  flapController: _flapController,
                  flap: buildSidebar(context, ref, navrailIndex),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(builder: (context) {
                              return AdwHeaderButton(
                                isActive: _flapController.isOpen,
                                icon: const Icon(LucideIcons.sidebar, size: 17),
                                onPressed: _flapController.toggle,
                              );
                            }),
                            buildDropdown(
                              context,
                              ref,
                              label: AppLocalizations.of(context)!.viewType,
                              index: ref.watch(viewTypeProvider),
                              onChanged: (value) =>
                                  ref.read(viewTypeProvider.notifier).update(),
                              items: [
                                DropdownMenuItem(
                                    value: 0,
                                    child: Text(
                                      AppLocalizations.of(context)!.grid,
                                    )),
                                DropdownMenuItem(
                                    value: 1,
                                    child: Text(
                                      AppLocalizations.of(context)!.list,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: BrowseView(
                          context: context,
                          toggleSearch: toggleSearch,
                          navrailIndex: navrailIndex,
                          searchedTerm: searchedTerm,
                          switchSearchBar: switchSearchBar,
                          getData: getData,
                          isConnected: _isConnected,
                          featured: featured,
                          categories: categories,
                          allItems: allItems,
                        ),
                      ),
                    ],
                  ),
                ),
                InstalledView(searchedTerm: searchedTerm),
                DownloadsView(searchedTerm: searchedTerm),
              ],
            ),
          ),
          bottomNavigationBar: context.width < mobileWidth &&
                  searchedTerm.value.isEmpty
              ? buildViewSwitcher(
                  _currentViewIndex, _controller, ref, ViewSwitcherStyle.mobile)
              : null,
        ),
      ),
    );
  }

  AdwSidebar buildSidebar(
      BuildContext context, WidgetRef ref, ValueNotifier<int> navrailIndex,
      [bool isSidebar = false]) {
    return AdwSidebar(
      currentIndex: navrailIndex.value,
      onSelected: (index) {
        navrailIndex.value = index;
        if (isSidebar) {
          _flapController.toggle();
        }
      },
      children: [
        AdwSidebarItem(
          label: AppLocalizations.of(context)!.explore,
          leading: const Icon(LucideIcons.trendingUp, size: 17),
        ),
        for (var category
            in (categories ?? {}).entries.toList().asMap().entries)
          AdwSidebarItem(
            label: categoryName(context, category.value.key),
            leading: Icon(
              categoryIcons.containsKey(category.value.key)
                  ? categoryIcons[category.value.key]!
                  : LucideIcons.helpCircle,
              size: 19,
            ),
          ),
      ],
    );
  }

  Row buildDropdown(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required int index,
    required Function(int? value)? onChanged,
    required List<DropdownMenuItem<int>> items,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10)),
          child: DropdownButton<int>(
            value: index,
            onChanged: onChanged,
            items: items,
            icon: const Icon(
              LucideIcons.chevronsUpDown,
              size: 16,
            ),
            underline: const SizedBox(),
          ),
        ),
      ],
    );
  }

  AdwViewSwitcher buildViewSwitcher(ValueNotifier<int> _currentViewIndex,
      PageController _controller, WidgetRef ref,
      [ViewSwitcherStyle viewSwitcherStyle = ViewSwitcherStyle.desktop]) {
    var currentlyDownloading = ref
        .watch(downloadProvider)
        .downloadList
        .where((element) => element.actualBytes != element.totalBytes)
        .length;
    return AdwViewSwitcher(
      currentIndex: _currentViewIndex.value,
      onViewChanged: (index) {
        _controller.jumpToPage(index);
      },
      height: 50,
      tabs: [
        ViewSwitcherData(
          title: AppLocalizations.of(context)!.browse,
          icon: Icons.web,
        ),
        ViewSwitcherData(
          title: AppLocalizations.of(context)!.installed,
          icon: Icons.view_list,
        ),
        ViewSwitcherData(
          title: AppLocalizations.of(context)!.downloads +
              (currentlyDownloading > 0 ? ' ($currentlyDownloading)' : ''),
          icon: Icons.download,
        ),
      ],
      style: viewSwitcherStyle,
    );
  }
}
