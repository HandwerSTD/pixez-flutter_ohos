/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pixez/component/list_indicator.dart';
import 'package:pixez/component/md2_tab_indicator.dart';
import 'package:pixez/component/null_hero.dart';
import 'package:pixez/component/painter_avatar.dart';
import 'package:pixez/component/pixiv_image.dart';
import 'package:pixez/document_plugin.dart';
import 'package:pixez/er/hoster.dart';
import 'package:pixez/exts.dart';
import 'package:pixez/i18n.dart';
import 'package:pixez/lighting/lighting_store.dart';
import 'package:pixez/main.dart';
import 'package:pixez/models/illust.dart';
import 'package:pixez/network/api_client.dart';
import 'package:pixez/page/follow/follow_list.dart';
import 'package:pixez/page/report/report_items_page.dart';
import 'package:pixez/page/shield/shield_page.dart';
import 'package:pixez/page/user/bookmark/bookmark_page.dart';
import 'package:pixez/page/user/detail/user_detail.dart';
import 'package:pixez/page/user/user_store.dart';
import 'package:pixez/page/user/works/works_page.dart';
import 'package:share_plus/share_plus.dart';

class UsersPage extends StatefulWidget {
  final int id;
  final UserStore? userStore;
  final String? heroTag;

  const UsersPage({Key? key, required this.id, this.userStore, this.heroTag})
      : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with TickerProviderStateMixin {
  late UserStore userStore;
  late TabController _tabController;
  late ScrollController _scrollController;
  bool backToTopVisible = false;

  late LightingStore _workStore;
  late LightingStore _bookmarkStore;

  String restrict = 'public';

  @override
  void initState() {
    _workStore = LightingStore(ApiForceSource(
        futureGet: (bool e) => apiClient.getUserIllusts(widget.id, 'illust')));
    _bookmarkStore = LightingStore(ApiForceSource(
        futureGet: (e) =>
            apiClient.getBookmarksIllust(widget.id, restrict, null)));
    userStore = widget.userStore ?? UserStore(widget.id);
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.offset > 100) {
          if (!backToTopVisible) {
            setState(() {
              backToTopVisible = true;
            });
          }
        } else {
          if (backToTopVisible) {
            setState(() {
              backToTopVisible = false;
            });
          }
        }
      }
    });
    super.initState();
    userStore.firstFetch();
    muteStore.fetchBanUserIds();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      if (muteStore.banUserIds.isNotEmpty) {
        if (muteStore.banUserIds
            .map((element) => int.parse(element.userId!))
            .contains(widget.id)) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0.0,
            ),
            extendBodyBehindAppBar: true,
            extendBody: true,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('X_X'),
                  Text('${widget.id}'),
                  MaterialButton(
                    color: Theme.of(context).colorScheme.secondary,
                    textColor: Colors.white,
                    child: Text(I18n.of(context).shielding_settings),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => ShieldPage()));
                    },
                  )
                ],
              ),
            ),
          );
        }
      }

      if (userStore.errorMessage != null && userStore.user != null) {
        if (userStore.errorMessage!.contains("404"))
          return Scaffold(
            appBar: AppBar(),
            body: Container(
                child: Center(
              child: Text('404 not found'),
            )),
          );
        return Scaffold(
          appBar: AppBar(),
          body: Container(
              child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Http error\n${userStore.errorMessage}',
                    maxLines: 5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      userStore.errorMessage = null;
                      userStore.firstFetch();
                    },
                    child: Text(I18n.of(context).refresh),
                  ),
                )
              ],
            ),
          )),
        );
      }
      if (userStore.user == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Container(
              child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          )),
        );
      }
      return _buildBody(context);
    });
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          body: TabBarView(controller: _tabController, children: [
            WorksPage(
              id: widget.id,
              store: _workStore,
              portal: "Work",
            ),
            BookMarkNestedPage(
              id: widget.id,
              store: _bookmarkStore,
              portal: "Book",
            ),
            UserDetailPage(
              key: PageStorageKey('Tab2'),
              userDetail: userStore.userDetail,
              isNewNested: true,
            ),
          ]),
          headerSliverBuilder:
              (BuildContext context, bool? innerBoxIsScrolled) {
            return _HeaderSlivers(innerBoxIsScrolled, context);
          },
        ),
      ),
    );
  }

  List<Widget> _HeaderSlivers(bool? innerBoxIsScrolled, BuildContext context) {
    return [
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: SliverAppBar(
          pinned: true,
          elevation: 0.0,
          forceElevated: innerBoxIsScrolled ?? false,
          expandedHeight: 280,
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.share),
                onPressed: () =>
                    Share.share('https://www.pixiv.net/users/${widget.id}')),
            _buildPopMenu(context)
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              color: Theme.of(context).cardColor,
              child: Stack(
                children: <Widget>[
                  _buildBackground(context),
                  _buildFakeBg(context),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildHeader(context),
                        Container(
                          color: Theme.of(context).cardColor,
                          child: Column(
                            children: <Widget>[
                              _buildNameFollow(context),
                              _buildComment(context),
                              Tab(
                                text: " ",
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          bottom: ColoredTabBar(
            Theme.of(context).cardColor,
            TabBar(
              controller: _tabController,
              indicator: MD2Indicator(
                  indicatorHeight: 3,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorSize: MD2IndicatorSize.normal),
              onTap: (index) {
                setState(() {
                  _tabIndex = index;
                });
              },
              labelColor: Theme.of(context).textTheme.bodyText1!.color,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                GestureDetector(
                  onDoubleTap: () {
                    if (_tabIndex == 0) _scrollController.position.jumpTo(0);
                  },
                  child: Tab(
                    text: I18n.of(context).works,
                  ),
                ),
                GestureDetector(
                  onDoubleTap: () {
                    if (_tabIndex == 1) _scrollController.position.jumpTo(0);
                  },
                  child: Tab(
                    text: I18n.of(context).bookmark,
                  ),
                ),
                GestureDetector(
                  onDoubleTap: () {
                    if (_tabIndex == 2) _scrollController.position.jumpTo(0);
                  },
                  child: Tab(
                    text: I18n.of(context).detail,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // SliverPersistentHeader(
      //   delegate: StickyTabBarDelegate(
      //       child: TabBar(
      //     controller: _tabController,
      //     indicator: MD2Indicator(
      //         indicatorHeight: 3,
      //         indicatorColor: Theme.of(context).colorScheme.primary,
      //         indicatorSize: MD2IndicatorSize.normal),
      //     onTap: (index) {
      //       setState(() {
      //         _tabIndex = index;
      //       });
      //     },
      //     labelColor: Theme.of(context).textTheme.bodyText1!.color,
      //     indicatorSize: TabBarIndicatorSize.label,
      //     tabs: [
      //       GestureDetector(
      //         onDoubleTap: () {
      //           if (_tabIndex == 0) _scrollController.position.jumpTo(0);
      //         },
      //         child: Tab(
      //           text: I18n.of(context).works,
      //         ),
      //       ),
      //       GestureDetector(
      //         onDoubleTap: () {
      //           if (_tabIndex == 1) _scrollController.position.jumpTo(0);
      //         },
      //         child: Tab(
      //           text: I18n.of(context).bookmark,
      //         ),
      //       ),
      //       GestureDetector(
      //         onDoubleTap: () {
      //           if (_tabIndex == 2) _scrollController.position.jumpTo(0);
      //         },
      //         child: Tab(
      //           text: I18n.of(context).detail,
      //         ),
      //       ),
      //     ],
      //   )),
      //   pinned: true,
      // ),
    ];
  }

  //为什么会需要这段？因为外部Column无法使子元素贴紧，子元素之间在真机上总是有spacing，所以底部又需要一个cardColor来填充
  Widget _buildFakeBg(BuildContext context) {
    return Align(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 55,
            color: Theme.of(context).cardColor,
          ),
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              children: <Widget>[
                _buildFakeNameFollow(context),
                Container(
                  height: 60,
                ),
                Tab(
                  text: " ",
                )
              ],
            ),
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).padding.top + 160,
        child: userStore.userDetail != null
            ? userStore.userDetail!.profile.background_image_url != null
                ? InkWell(
                    onLongPress: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(I18n.of(context).save),
                              actions: [
                                TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(I18n.of(context).cancel)),
                                TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await _saveUserBg(userStore.userDetail!
                                          .profile.background_image_url!);
                                    },
                                    child: Text(I18n.of(context).ok)),
                              ],
                            );
                          });
                    },
                    child: CachedNetworkImage(
                      imageUrl:
                          userStore.userDetail!.profile.background_image_url!,
                      fit: BoxFit.fitWidth,
                      cacheManager: pixivCacheManager,
                      httpHeaders: Hoster.header(
                          url: userStore
                              .userDetail!.profile.background_image_url),
                    ),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.secondary,
                  )
            : Container());
  }

  PopupMenuButton<int> _buildPopMenu(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: (index) async {
        switch (index) {
          case 0:
            userStore.follow(needPrivate: true);
            break;
          case 1:
            {
              final result = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('${I18n.of(context).block_user}?'),
                      actions: <Widget>[
                        TextButton(
                          child: Text("OK"),
                          onPressed: () {
                            Navigator.of(context).pop("OK");
                          },
                        ),
                        TextButton(
                          child: Text("CANCEL"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  });
              if (result == "OK") {
                await muteStore.insertBanUserId(
                    widget.id.toString(), userStore.userDetail!.user.name);
                Navigator.of(context).pop();
              }
            }
            break;
          case 2:
            {
              Clipboard.setData(ClipboardData(
                  text:
                      'painter:${userStore.userDetail?.user.name ?? ''}\npid:${widget.id}'));
              BotToast.showText(text: I18n.of(context).copied_to_clipboard);
              break;
            }
          case 3:
            {
              Reporter.show(
                  context,
                  () async => await muteStore.insertBanUserId(
                      widget.id.toString(), userStore.userDetail!.user.name));
              break;
            }
          default:
        }
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<int>(
            value: 0,
            child: Text(I18n.of(context).quietly_follow),
          ),
          PopupMenuItem<int>(
            value: 1,
            child: Text(I18n.of(context).block_user),
          ),
          PopupMenuItem<int>(
            value: 2,
            child: Text(I18n.of(context).copymessage),
          ),
          PopupMenuItem<int>(
            value: 3,
            child: Text(I18n.of(context).report),
          ),
        ];
      },
    );
  }

  Align _topVert(BuildContext context) {
    return Align(
      child: Visibility(
        visible: backToTopVisible,
        child: ListIndicator(
          onTop: () {
            if (_scrollController.hasClients)
              _scrollController.position.jumpTo(0);
          },
        ),
      ),
      alignment: Alignment.bottomCenter,
    );
  }

  Widget _buildFakeNameFollow(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                userStore.user?.name ?? "",
                style: Theme.of(context).textTheme.headline6,
              ),
              Text(
                userStore.userDetail == null
                    ? ""
                    : '${userStore.userDetail!.profile.total_follow_users} ${I18n.of(context).follow}',
                style: Theme.of(context).textTheme.caption,
              )
            ]),
      ),
    );
  }

  Widget _buildNameFollow(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NullHero(
                tag: userStore.user?.name ?? "" + widget.heroTag.toString(),
                child: Text(
                  userStore.user?.name ?? "",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (BuildContext context) {
                    return Scaffold(
                      appBar: AppBar(
                        title: Text(I18n.of(context).followed),
                      ),
                      body: FollowList(id: widget.id),
                    );
                  }));
                },
                child: Text(
                  userStore.userDetail == null
                      ? ""
                      : '${userStore.userDetail!.profile.total_follow_users} ${I18n.of(context).follow}',
                  style: Theme.of(context).textTheme.caption,
                ),
              )
            ]),
      ),
    );
  }

  Widget _buildComment(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      width: MediaQuery.of(context).size.width,
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: SelectionContainer.disabled(
          child: SingleChildScrollView(
            child: Text(
              userStore.userDetail == null
                  ? ""
                  : '${userStore.userDetail!.user.comment}',
              style: Theme.of(context).textTheme.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    Widget w = _buildAvatarFollow(context);
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(top: 25),
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 55.0,
            child: Container(
              color: Theme.of(context).cardColor,
            ),
          ),
        ),
        Align(
          child: w,
          alignment: Alignment.bottomCenter,
        )
      ],
    );
  }

  Container _buildAvatarFollow(BuildContext context) {
    return Container(
      child: Observer(
        builder: (_) => Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              child: NullHero(
                tag: userStore.user!.profileImageUrls.medium +
                    widget.heroTag.toString(),
                child: PainterAvatar(
                  url: userStore.user!.profileImageUrls.medium,
                  size: Size(80, 80),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(I18n.of(context).save_painter_avatar),
                            actions: [
                              TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(I18n.of(context).cancel)),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _saveUserC();
                                  },
                                  child: Text(I18n.of(context).ok)),
                            ],
                          );
                        });
                  },
                  id: userStore.user!.id,
                ),
              ),
            ),
            Container(
              child: userStore.userDetail == null
                  ? Container(
                      padding: const EdgeInsets.only(right: 16.0, bottom: 4.0),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 16.0, bottom: 4.0),
                      child: userStore.isFollow
                          ? MaterialButton(
                              textColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 0),
                              color: Theme.of(context).colorScheme.secondary,
                              onPressed: () {
                                if (accountStore.now != null) {
                                  if (int.parse(accountStore.now!.userId) !=
                                      widget.id) {
                                    userStore.follow(needPrivate: false);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Who is the most beautiful person in the world?')));
                                  }
                                }
                              },
                              child: Text(I18n.of(context).followed),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20))),
                            )
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                  side: BorderSide(),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.0, vertical: 0)),
                              onPressed: () {
                                if (accountStore.now != null) {
                                  if (int.parse(accountStore.now!.userId) !=
                                      widget.id) {
                                    userStore.follow(needPrivate: false);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Who is the most beautiful person in the world?')));
                                  }
                                }
                              },
                              child: Text(
                                I18n.of(context).follow,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .color),
                              ),
                            ),
                    ),
            )
          ],
        ),
      ),
    );
  }

  _saveUserBg(String url) async {
    try {
      final result = await pixivCacheManager.downloadFile(url, authHeaders: {
        'referer': 'https://app-api.pixiv.net/',
      });
      final bytes = await result.file.readAsBytes();
      await DocumentPlugin.save(bytes, "${widget.id}_bg.jpg");
      BotToast.showText(text: I18n.of(context).saved);
    } catch (e) {
      print(e);
    }
  }

  Future _saveUserC() async {
    var url = userStore.userDetail!.user.profileImageUrls.medium;
    String meme = url.split(".").last;
    if (meme.isEmpty) meme = "jpg";
    var replaceAll = userStore.userDetail!.user.name
        .replaceAll("/", "")
        .replaceAll("\\", "")
        .replaceAll(":", "")
        .replaceAll("*", "")
        .replaceAll("?", "")
        .replaceAll(">", "")
        .replaceAll("|", "")
        .replaceAll("<", "");
    String fileName = "${replaceAll}_${userStore.userDetail!.user.id}.${meme}";
    try {
      String tempFile = (await getTemporaryDirectory()).path + "/$fileName";
      final dio = Dio(BaseOptions(headers: Hoster.header(url: url)));
      if (!userSetting.disableBypassSni) {
        dio.httpClientAdapter = IOHttpClientAdapter()
          ..onHttpClientCreate = (client) {
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
            return client;
          };
      }
      await dio.download(url.toTrueUrl(), tempFile, deleteOnError: true);
      File file = File(tempFile);
      if (file != null && file.existsSync()) {
        await saveStore.saveToGallery(
            file.readAsBytesSync(),
            Illusts(
              user: User(
                id: userStore.userDetail!.user.id,
                name: replaceAll,
                profileImageUrls: userStore.userDetail!.user.profileImageUrls,
                isFollowed: userStore.userDetail!.user.isFollowed,
                account: userStore.userDetail!.user.account,
                comment: userStore.userDetail!.user.comment,
              ),
              metaPages: [],
              type: '',
              width: 0,
              series: Object(),
              totalBookmarks: 0,
              visible: false,
              isMuted: false,
              sanityLevel: 0,
              tags: [],
              caption: '',
              pageCount: 0,
              metaSinglePage: MetaSinglePage(originalImageUrl: ''),
              tools: [],
              height: 0,
              restrict: 0,
              createDate: '',
              id: 0,
              xRestrict: 0,
              imageUrls: ImageUrls(squareMedium: '', medium: '', large: ''),
              title: '',
              isBookmarked: false,
              totalView: 0,
              illustAIType: 1,
            ),
            fileName);
        BotToast.showText(text: I18n.of(context).complete);
      } else
        BotToast.showText(text: I18n.of(context).failed);
    } catch (e) {
      print(e);
    }
  }
}

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  StickyTabBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      child: this.child,
      color: Theme.of(context).cardColor,
    );
  }

  @override
  double get maxExtent => this.child.preferredSize.height;

  @override
  double get minExtent => this.child.preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class ColoredTabBar extends Container implements PreferredSizeWidget {
  ColoredTabBar(this.color, this.tabBar);

  final Color color;
  final TabBar tabBar;

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        child: tabBar,
      );
}
