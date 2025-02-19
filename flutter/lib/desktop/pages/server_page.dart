import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/desktop/widgets/tabbar_widget.dart';
import 'package:flutter_hbb/mobile/pages/chat_page.dart';
import 'package:flutter_hbb/models/chat_model.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../common.dart';
import '../../models/platform_model.dart';
import '../../models/server_model.dart';

class DesktopServerPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DesktopServerPageState();
}

class _DesktopServerPageState extends State<DesktopServerPage>
    with WindowListener, AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    gFFI.ffiModel.updateEventListener("");
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    gFFI.serverModel.closeAll();
    gFFI.close();
    super.onWindowClose();
  }

  Widget build(BuildContext context) {
    super.build(context);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gFFI.serverModel),
          ChangeNotifierProvider.value(value: gFFI.chatModel),
        ],
        child: Consumer<ServerModel>(
            builder: (context, serverModel, child) => Container(
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: MyTheme.color(context).border!)),
                  child: Scaffold(
                    backgroundColor: MyTheme.color(context).bg,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(child: ConnectionManager()),
                          SizedBox.fromSize(size: Size(0, 15.0)),
                        ],
                      ),
                    ),
                  ),
                )));
  }

  @override
  bool get wantKeepAlive => true;
}

class ConnectionManager extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ConnectionManagerState();
}

class ConnectionManagerState extends State<ConnectionManager> {
  @override
  void initState() {
    gFFI.serverModel.updateClientState();
    gFFI.serverModel.tabController.onSelected = (index) =>
        gFFI.chatModel.changeCurrentID(gFFI.serverModel.clients[index].id);
    // test
    // gFFI.serverModel.clients.forEach((client) {
    //   DesktopTabBar.onAdd(
    //       gFFI.serverModel.tabs,
    //       TabInfo(
    //           key: client.id.toString(), label: client.name, closable: false));
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);
    return serverModel.clients.isEmpty
        ? Column(
            children: [
              buildTitleBar(Offstage()),
              Expanded(
                child: Center(
                  child: Text(translate("Waiting")),
                ),
              ),
            ],
          )
        : DesktopTab(
            theme: isDarkTheme() ? TarBarTheme.dark() : TarBarTheme.light(),
            showTitle: false,
            showMaximize: false,
            showMinimize: false,
            controller: serverModel.tabController,
            tabType: DesktopTabType.cm,
            pageViewBuilder: (pageView) => Row(children: [
                  Expanded(child: pageView),
                  Consumer<ChatModel>(
                      builder: (_, model, child) => model.isShowChatPage
                          ? Expanded(child: Scaffold(body: ChatPage()))
                          : Offstage())
                ]));
  }

  Widget buildTitleBar(Widget middle) {
    return GestureDetector(
      onPanDown: (d) {
        windowManager.startDragging();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AppIcon(),
          Expanded(child: middle),
          const SizedBox(
            width: 4.0,
          ),
          _CloseButton()
        ],
      ),
    );
  }

  Widget buildTab(Client client) {
    return Tab(
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(
                "${client.name}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              )),
        ],
      ),
    );
  }
}

Widget buildConnectionCard(Client client) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.start,
    key: ValueKey(client.id),
    children: [
      _CmHeader(client: client),
      client.isFileTransfer ? Offstage() : _PrivilegeBoard(client: client),
      Expanded(
          child: Align(
        alignment: Alignment.bottomCenter,
        child: _CmControlPanel(client: client),
      ))
    ],
  ).paddingSymmetric(vertical: 8.0, horizontal: 8.0);
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      child: Image.asset(
        'assets/logo.ico',
        width: 30,
        height: 30,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Ink(
      child: InkWell(
          onTap: () {
            windowManager.close();
          },
          child: Icon(
            Icons.close,
            size: 30,
          )),
    );
  }
}

class _CmHeader extends StatefulWidget {
  final Client client;

  const _CmHeader({Key? key, required this.client}) : super(key: key);

  @override
  State<_CmHeader> createState() => _CmHeaderState();
}

class _CmHeaderState extends State<_CmHeader>
    with AutomaticKeepAliveClientMixin {
  Client get client => widget.client;

  var _time = 0.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _time.value = _time.value + 1;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // icon
        Container(
          width: 90,
          height: 90,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: str2color(client.name)),
          child: Text(
            "${client.name[0]}",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white, fontSize: 65),
          ),
        ).marginOnly(left: 4.0, right: 8.0),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                  child: Text(
                "${client.name}",
                style: TextStyle(
                  color: MyTheme.cmIdColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              )),
              FittedBox(
                  child: Text("(${client.peerId})",
                      style:
                          TextStyle(color: MyTheme.cmIdColor, fontSize: 14))),
              SizedBox(
                height: 16.0,
              ),
              FittedBox(
                  child: Row(
                children: [
                  Text("${translate("Connected")}").marginOnly(right: 8.0),
                  Obx(() => Text(
                      "${formatDurationToTime(Duration(seconds: _time.value))}"))
                ],
              ))
            ],
          ),
        ),
        Offstage(
          offstage: client.isFileTransfer,
          child: IconButton(
            onPressed: () => checkClickTime(
                client.id, () => gFFI.chatModel.toggleCMChatPage(client.id)),
            icon: Icon(Icons.message_outlined),
          ),
        )
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _PrivilegeBoard extends StatefulWidget {
  final Client client;

  const _PrivilegeBoard({Key? key, required this.client}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PrivilegeBoardState();
}

class _PrivilegeBoardState extends State<_PrivilegeBoard> {
  late final client = widget.client;
  Widget buildPermissionIcon(bool enabled, ImageProvider icon,
      Function(bool)? onTap, String? tooltip) {
    return Tooltip(
      message: tooltip ?? "",
      child: Ink(
        decoration:
            BoxDecoration(color: enabled ? MyTheme.accent80 : Colors.grey),
        padding: EdgeInsets.all(4.0),
        child: InkWell(
          onTap: () =>
              checkClickTime(widget.client.id, () => onTap?.call(!enabled)),
          child: Image(
            image: icon,
            width: 50,
            height: 50,
            fit: BoxFit.scaleDown,
          ),
        ),
      ).marginSymmetric(horizontal: 4.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            translate("Permissions"),
            style: TextStyle(fontSize: 16),
          ).marginOnly(left: 4.0),
          SizedBox(
            height: 8.0,
          ),
          FittedBox(
              child: Row(
            children: [
              buildPermissionIcon(client.keyboard, iconKeyboard, (enabled) {
                bind.cmSwitchPermission(
                    connId: client.id, name: "keyboard", enabled: enabled);
                setState(() {
                  client.keyboard = enabled;
                });
              }, null),
              buildPermissionIcon(client.clipboard, iconClipboard, (enabled) {
                bind.cmSwitchPermission(
                    connId: client.id, name: "clipboard", enabled: enabled);
                setState(() {
                  client.clipboard = enabled;
                });
              }, null),
              buildPermissionIcon(client.audio, iconAudio, (enabled) {
                bind.cmSwitchPermission(
                    connId: client.id, name: "audio", enabled: enabled);
                setState(() {
                  client.audio = enabled;
                });
              }, null),
              buildPermissionIcon(client.file, iconFile, (enabled) {
                bind.cmSwitchPermission(
                    connId: client.id, name: "file", enabled: enabled);
                setState(() {
                  client.file = enabled;
                });
              }, null),
              buildPermissionIcon(client.restart, iconRestart, (enabled) {
                bind.cmSwitchPermission(
                    connId: client.id, name: "restart", enabled: enabled);
                setState(() {
                  client.restart = enabled;
                });
              }, null),
            ],
          )),
        ],
      ),
    );
  }
}

class _CmControlPanel extends StatelessWidget {
  final Client client;

  const _CmControlPanel({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerModel>(builder: (_, model, child) {
      return client.authorized
          ? buildAuthorized(context)
          : buildUnAuthorized(context);
    });
  }

  buildAuthorized(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Ink(
          width: 200,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
          child: InkWell(
              onTap: () =>
                  checkClickTime(client.id, () => handleDisconnect(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    translate("Disconnect"),
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )),
        )
      ],
    );
  }

  buildUnAuthorized(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Ink(
          width: 100,
          height: 40,
          decoration: BoxDecoration(
              color: MyTheme.accent, borderRadius: BorderRadius.circular(10)),
          child: InkWell(
              onTap: () =>
                  checkClickTime(client.id, () => handleAccept(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    translate("Accept"),
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )),
        ),
        SizedBox(
          width: 30,
        ),
        Ink(
          width: 100,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey)),
          child: InkWell(
              onTap: () =>
                  checkClickTime(client.id, () => handleDisconnect(context)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    translate("Cancel"),
                    style: TextStyle(),
                  ),
                ],
              )),
        )
      ],
    );
  }

  void handleDisconnect(BuildContext context) {
    bind.cmCloseConnection(connId: client.id);
  }

  void handleAccept(BuildContext context) {
    final model = Provider.of<ServerModel>(context, listen: false);
    model.sendLoginResponse(client, true);
  }
}

class PaddingCard extends StatelessWidget {
  PaddingCard({required this.child, this.title, this.titleIcon});

  final String? title;
  final IconData? titleIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final children = [child];
    if (title != null) {
      children.insert(
          0,
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  titleIcon != null
                      ? Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(titleIcon,
                              color: MyTheme.accent80, size: 30))
                      : SizedBox.shrink(),
                  Text(
                    title!,
                    style: TextStyle(
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: MyTheme.accent80,
                    ),
                  )
                ],
              )));
    }
    return Container(
        width: double.maxFinite,
        child: Card(
          margin: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ));
  }
}

Widget clientInfo(Client client) {
  return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Expanded(
                flex: -1,
                child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                        child: Text(client.name[0]),
                        backgroundColor: MyTheme.border))),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(client.name,
                      style: TextStyle(color: MyTheme.idColor, fontSize: 18)),
                  SizedBox(width: 8),
                  Text(client.peerId,
                      style: TextStyle(color: MyTheme.idColor, fontSize: 10))
                ]))
          ],
        ),
      ]));
}

void checkClickTime(int id, Function() callback) async {
  var clickCallbackTime = DateTime.now().millisecondsSinceEpoch;
  await bind.cmCheckClickTime(connId: id);
  Timer(const Duration(milliseconds: 120), () async {
    var d = clickCallbackTime - await bind.cmGetClickTime();
    if (d > 120) callback();
  });
}
