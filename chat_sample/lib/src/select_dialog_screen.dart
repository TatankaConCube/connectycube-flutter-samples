import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'package:connectycube_sdk/connectycube_sdk.dart';

import 'new_dialog_screen.dart';
import '../src/utils/api_utils.dart';
import '../src/utils/consts.dart';

class SelectDialogScreen extends StatelessWidget {
  static const String TAG = "SelectDialogScreen";
  final CubeUser currentUser;

  SelectDialogScreen(this.currentUser);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onBackPressed(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Logged in as ${currentUser.fullName}',
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () => _openSettings(context),
              icon: Icon(
                Icons.settings,
                color: Colors.white,
              ),
            ),
          ],
        ),
        body: BodyLayout(currentUser),
      ),
    );
  }

  Future<bool> _onBackPressed() {
    return Future.value(true);
  }

  _openSettings(BuildContext context) {
    Navigator.pushNamed(context, 'settings',
        arguments: {USER_ARG_NAME: currentUser});
  }
}

class BodyLayout extends StatefulWidget {
  final CubeUser currentUser;

  BodyLayout(this.currentUser);

  @override
  State<StatefulWidget> createState() {
    return _BodyLayoutState(currentUser);
  }
}

class _BodyLayoutState extends State<BodyLayout> {
  static const String TAG = "_BodyLayoutState";

  final CubeUser currentUser;
  List<ListItem<CubeDialog>> dialogList = [];
  var _isDialogContinues = true;

  StreamSubscription<CubeMessage>? msgSubscription;
  final ChatMessagesManager? chatMessagesManager =
      CubeChatConnection.instance.chatMessagesManager;

  _BodyLayoutState(this.currentUser);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(bottom: 16, top: 16),
        child: Column(
          children: [
            Visibility(
              visible: _isDialogContinues && dialogList.isEmpty,
              child: Container(
                margin: EdgeInsets.all(40),
                alignment: FractionalOffset.center,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
            Expanded(
              child: _getDialogsList(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "New dialog",
        child: Icon(
          Icons.chat,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
        onPressed: () => _createNewDialog(context),
      ),
    );
  }

  void _createNewDialog(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateChatScreen(currentUser),
      ),
    ).then((value) => refresh());
  }

  void _processGetDialogError(exception) {
    log("GetDialog error $exception", TAG);
    setState(() {
      _isDialogContinues = false;
    });
    showDialogError(exception, context);
  }

  Widget _getDialogsList(BuildContext context) {
    if (_isDialogContinues) {
      getDialogs().then((dialogs) {
        _isDialogContinues = false;
        log("getDialogs: $dialogs", TAG);
        setState(() {
          dialogList.clear();
          dialogList.addAll(
              dialogs!.items.map((dialog) => ListItem(dialog)).toList());
        });
      }).catchError((exception) {
        _processGetDialogError(exception);
      });
    }
    if (_isDialogContinues && dialogList.isEmpty)
      return SizedBox.shrink();
    else if (dialogList.isEmpty)
      return FittedBox(
        fit: BoxFit.contain,
        child: Text("No dialogs yet"),
      );
    else
      return ListView.separated(
        itemCount: dialogList.length,
        itemBuilder: _getListItemTile,
        separatorBuilder: (context, index) {
          return Divider(thickness: 2, indent: 40);
        },
      );
  }

  Widget _getListItemTile(BuildContext context, int index) {
    getDialogIcon() {
      var dialog = dialogList[index].data;
      if (dialog.type == CubeDialogType.PRIVATE)
        return Icon(
          Icons.person,
          size: 40.0,
          color: greyColor,
        );
      else {
        return Icon(
          Icons.group,
          size: 40.0,
          color: greyColor,
        );
      }
    }

    getDialogAvatarWidget() {
      var dialog = dialogList[index].data;
      if (dialog.photo == null) {
        return CircleAvatar(
            radius: 25, backgroundColor: greyColor3, child: getDialogIcon());
      } else {
        return CachedNetworkImage(
          placeholder: (context, url) => Container(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
            width: 40.0,
            height: 40.0,
            padding: EdgeInsets.all(70.0),
            decoration: BoxDecoration(
              color: greyColor2,
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
            ),
          ),
          imageUrl: dialogList[index].data.photo!,
          width: 45.0,
          height: 45.0,
          fit: BoxFit.cover,
        );
      }
    }

    return Container(
      child: TextButton(
        child: Row(
          children: <Widget>[
            Material(
              child: getDialogAvatarWidget(),
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              clipBehavior: Clip.hardEdge,
            ),
            Flexible(
              child: Container(
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Text(
                        '${dialogList[index].data.name ?? 'Not available'}',
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 1,
                      ),
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                    ),
                    Container(
                      child: Text(
                        '${dialogList[index].data.lastMessage ?? 'Not available'}',
                        style: TextStyle(
                            color: primaryColor,
                            overflow: TextOverflow.ellipsis),
                        maxLines: 2,
                      ),
                      alignment: Alignment.centerLeft,
                      margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                    ),
                  ],
                ),
                margin: EdgeInsets.only(left: 20.0),
              ),
            ),
            Visibility(
              child: IconButton(
                iconSize: 25.0,
                icon: Icon(
                  Icons.delete,
                  color: themeColor,
                ),
                onPressed: () {
                  _deleteDialog(context, dialogList[index].data);
                },
              ),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: dialogList[index].isSelected,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dialogList[index].data.lastMessageDateSent != null ? DateFormat('MMM dd').format(DateTime.fromMillisecondsSinceEpoch(dialogList[index].data.lastMessageDateSent! * 1000)) : 'Not available'}',
                  style: TextStyle(color: primaryColor),
                ),
                if (dialogList[index].data.unreadMessageCount != null &&
                    dialogList[index].data.unreadMessageCount != 0)
                  Container(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10.0)),
                      child: Text(
                        dialogList[index].data.unreadMessageCount.toString(),
                        style: TextStyle(color: Colors.white),
                      )),
              ],
            ),
          ],
        ),
        onLongPress: () {
          setState(() {
            dialogList[index].isSelected = !dialogList[index].isSelected;
          });
        },
        onPressed: () {
          _openDialog(context, dialogList[index].data);
        },
      ),
      margin: EdgeInsets.only(left: 5.0, right: 5.0),
    );
  }

  void _deleteDialog(BuildContext context, CubeDialog dialog) async {
    log("_deleteDialog= $dialog");
    Fluttertoast.showToast(msg: 'Coming soon');
  }

  void _openDialog(BuildContext context, CubeDialog dialog) async {
    Navigator.pushNamed(context, 'chat_dialog',
        arguments: {USER_ARG_NAME: currentUser, DIALOG_ARG_NAME: dialog});
  }

  void refresh() {
    setState(() {
      _isDialogContinues = true;
    });
  }

  @override
  void initState() {
    super.initState();
    msgSubscription =
        chatMessagesManager!.chatMessagesStream.listen(onReceiveMessage);
  }

  @override
  void dispose() {
    super.dispose();
    log("dispose", TAG);
    msgSubscription?.cancel();
  }

  void onReceiveMessage(CubeMessage message) {
    log("onReceiveMessage global message= $message");
    updateDialog(message);
  }

  updateDialog(CubeMessage msg) {
    ListItem<CubeDialog>? dialogItem =
        dialogList.firstWhereOrNull((dlg) => dlg.data.dialogId == msg.dialogId);
    if (dialogItem == null) return;

    setState(() {
      dialogItem.data.lastMessage = msg.body;
      dialogItem.data.unreadMessageCount =
          dialogItem.data.unreadMessageCount == null
              ? 1
              : dialogItem.data.unreadMessageCount! + 1;
      dialogItem.data.lastMessageDateSent = msg.dateSent;
      dialogList.sort((a, b) {
        DateTime dateA;
        if (a.data.lastMessageDateSent != null) {
          dateA = DateTime.fromMillisecondsSinceEpoch(
              a.data.lastMessageDateSent! * 1000);
        } else {
          dateA = a.data.createdAt!;
        }

        DateTime dateB;
        if (b.data.lastMessageDateSent != null) {
          dateB = DateTime.fromMillisecondsSinceEpoch(
              b.data.lastMessageDateSent! * 1000);
        } else {
          dateB = b.data.createdAt!;
        }

        if (dateA.isAfter(dateB)) {
          return -1;
        } else if (dateA.isBefore(dateB)) {
          return 1;
        } else {
          return 0;
        }
      });
    });
  }
}
