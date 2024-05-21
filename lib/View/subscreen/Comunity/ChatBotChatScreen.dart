import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bubble/bubble.dart';

import '../../../Controller/ChatScreen/ChatController.dart';
import '../../../Resource/color_handler.dart';
import '../../../Resource/icon_handler.dart';

import 'package:get/get.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:keyboard_height_plugin/keyboard_height_plugin.dart';

class ChatController extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  var messages = <types.Message>[].obs;
  final user =
      types.User(id: FirebaseAuth.instance.currentUser?.uid ?? '').obs; //!
  //User who get messages

  final keyboardOpen = RxBool(false);

  late final String getUser;
  ChatController(this.getUser);

  DateTime now = DateTime.now();
  late DateTime date = DateTime(now.year, now.month, now.day);

  @override
  void onInit() {
    super.onInit();

    print("get user");
    print(getUser);
    loadMessages();
  }

  void loadMessages() async {
    var loadMessage;
    var sendMessage;

    try {
      // Load sent messages
      await firestore
          .collection('Messages')
          .doc(getUser)
          .collection("messages")
          .doc(auth.currentUser?.uid)
          .collection(date.toString())
          .get()
          .then((QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          sendMessage = types.TextMessage(
            author: types.User.fromJson(doc['author'] as Map<String, dynamic>),
            createdAt: doc["createdAt"],
            id: doc["id"],
            text: doc["text"],
            //metadata: doc["metadata"]
          );
          print(sendMessage);
          messages.add(sendMessage);
        }
      });
    } catch (e) {
      // Handle error
    }

    try {
      // Load response messages
      await firestore
          .collection('Messages')
          .doc(auth.currentUser?.uid)
          .collection("messages")
          .doc(getUser)
          .collection(date.toString())
          .get()
          .then((QuerySnapshot querySnapshot) {
        for (var doc in querySnapshot.docs) {
          loadMessage = types.TextMessage(
            author: types.User.fromJson(doc['author'] as Map<String, dynamic>),
            createdAt: doc["createdAt"],
            id: doc["id"],
            text: doc["text"],
            //metadata: doc["metadata"]
          );
          messages.add(loadMessage);
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  void addMessage(types.Message message) {
    messages.add(message);
  }

  void sendTextMessage(String text) {
    final textMessage = types.TextMessage(
      author: user.value,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
    );
    addMessageToFirestore(textMessage);
  }

  void addMessageToFirestore(types.TextMessage message) async {
    final messageData = {
      "author": message.author.toJson(),
      // "metadata": message.metadata,
      'text': message.text,
      'createdAt': message.createdAt,
      "id": message.id,
    };

    await firestore
        .collection('Messages')
        .doc(getUser)
        .collection("messages")
        .doc(message.author.id)
        .collection(date.toString())
        .doc(message.id)
        .set(messageData);

    addMessage(message);
  }

  void updateMessage(int index, types.Message updatedMessage) {}
}

class ChatScreenHandler extends StatefulWidget {
  const ChatScreenHandler({
    super.key,
    this.isComunityPage = true,
    this.Uid = '',
    this.FriendName = '',
    this.ImgSrc = '',
  });

  final bool isComunityPage;
  final String Uid;
  final String FriendName;
  final String ImgSrc;

  @override
  State<ChatScreenHandler> createState() => _ChatScreenHandlerState();
}

class _ChatScreenHandlerState extends State<ChatScreenHandler> {
  double _keyboardHeight1 = 0;
  final KeyboardHeightPlugin _keyboardHeightPlugin = KeyboardHeightPlugin();

  @override
  Widget build(BuildContext context) {
    final ChatController controller =
        Get.put(ChatController(widget.Uid), tag: widget.Uid);

    @override
    void initState() {
      super.initState();
      _keyboardHeightPlugin.onKeyboardHeightChanged((double height) {
        setState(() {
          _keyboardHeight1 = height;
          print("my keyboard height is $_keyboardHeight1");
        });
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: ColorHandler.bgColor,
      appBar: widget.isComunityPage
          ? AppBar(
              centerTitle: true,
              backgroundColor: ColorHandler.bgColor,
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  IconHandler.angle_left,
                  color: ColorHandler.normalFont,
                ),
              ),
              title: Row(
                children: [
                  SizedBox(
                    width: 35.sp,
                    height: 35.sp,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100.sp),
                      child: Image.network(
                        widget.ImgSrc,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    widget.FriendName,
                    style: TextStyle(
                      color: ColorHandler.normalFont,
                      fontWeight: FontWeight.normal,
                      fontSize: 20.sp,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            )
          : null,
      body:

          // Container(
          //   color: Color.fromARGB(255, 242, 90, 145),
          //   child: Text("data bfbfiuef iuwfwgfiuwg fiuwg fugwfiugwfgjhgfsghfjdsfhhgj gisg iusgisugviu bjfwjwsggdfiusgfygwefygwuegf wygfyuw wgfywgfuyw wg fuwgfwyg fywge fjgdhfgsjgf\sghfsjghf hsg fhsgf jsghfwyegwe fgjhgfhs gdfhgsdhfgshgfbvueugyugsgviusg viugsdviugsvgshdgvjhdgv hjgfvdg vjd gvdy gvjdygfugeugfgvegvjhdgfjgvdygvyugfvehvjshd herika ", style: TextStyle(fontSize: 35),)),

          Builder(builder: (context) {
        return SingleChildScrollView(
          child:
              KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
            return SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height - 175,
              child: Obx(
                () => Padding(
                  //padding: EdgeInsets.only(bottom: isKeyboardOpen ? 6000.0 : 0), // Adjust padding as needed),
                  padding: EdgeInsets.only(
                      bottom:
                          isKeyboardVisible ? 210.sp : 0.0), // Adjust as needed,
                  child: Chat(
                    messages: controller.messages.reversed.toList(),
                    bubbleBuilder: _bubbleBuilder,
                    onAttachmentPressed: () =>
                        _handleAttachmentPressed(context, controller),
                    onMessageTap: _handleMessageTap,
                    onPreviewDataFetched: _handlePreviewDataFetched,
                    onSendPressed: (types.PartialText message) =>
                        controller.sendTextMessage(message.text),
                    scrollToUnreadOptions: const ScrollToUnreadOptions(
                      lastReadMessageId: 'lastReadMessageId',
                      scrollOnOpen: true,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    showUserAvatars: false,
                    showUserNames: false,
                    isLeftStatus: true,
                    user: controller.user.value,
                    theme: const DefaultChatTheme(
                      backgroundColor: ColorHandler.bgColor,
                      seenIcon: Text(
                        'read',
                        style: TextStyle(
                          fontSize: 10.0,
                        ),
                      ),
                    ),
                    messageWidthRatio: 0.80,
                  ),
                ),
              ),
            );
          }),
        );
      }),

      //  Obx(
      //       () => Chat(
      //     messages: controller.messages.reversed.toList(),
      //     bubbleBuilder: _bubbleBuilder,
      //     onAttachmentPressed: () =>
      //         _handleAttachmentPressed(context, controller),
      //     onMessageTap: _handleMessageTap,
      //     onPreviewDataFetched: _handlePreviewDataFetched,
      //     onSendPressed: (types.PartialText message) =>
      //         controller.sendTextMessage(message.text),
      //     scrollToUnreadOptions: const ScrollToUnreadOptions(
      //       lastReadMessageId: 'lastReadMessageId',
      //       scrollOnOpen: true,
      //     ),
      //     keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      //     showUserAvatars: false,
      //     showUserNames: false,
      //     isLeftStatus: true,
      //     user: controller.user.value,
      //     theme: const DefaultChatTheme(
      //       backgroundColor: ColorHandler.bgColor,
      //       seenIcon: Text(
      //         'read',
      //         style: TextStyle(
      //           fontSize: 10.0,
      //         ),
      //       ),
      //     ),
      //     messageWidthRatio: 0.80,
      //   ),
      // ),
    );
  }

  void _handleAttachmentPressed(
      BuildContext context, ChatController controller) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Container(
          color: ColorHandler.bgColor.withOpacity(0.8),
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection(controller);
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection(controller);
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection(ChatController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: controller.user.value,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path ?? ''), //!
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path ?? '', //!
      );

      controller.addMessage(message);
    }
  }

  void _handleImageSelection(ChatController controller) async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: controller.user.value,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      controller.addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    final ChatController controller = Get.find<ChatController>();
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = controller.messages
              .indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (controller.messages[index] as types.FileMessage)
                  .copyWith(isLoading: true);

          controller.updateMessage(index, updatedMessage);

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          // if (!File(localPath).existsSync()) {
          //   final file = File(localPath);
          //   await file.writeAsBytes(bytes);
          // }
        } finally {
          final index = controller.messages
              .indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (controller.messages[index] as types.FileMessage)
                  .copyWith(isLoading: null);

          controller.updateMessage(index, updatedMessage);
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message, types.PreviewData previewData) {
    final ChatController controller = Get.find<ChatController>();

    final index =
        controller.messages.indexWhere((element) => element.id == message.id);

    final updatedMessage = (controller.messages[index] as types.TextMessage)
        .copyWith(previewData: previewData);

    controller.updateMessage(index, updatedMessage);
  }

  Widget _bubbleBuilder(Widget child,
      {required types.Message message, required bool nextMessageInGroup}) {
    final ChatController controller =
        Get.put(ChatController(widget.Uid), tag: widget.Uid);

    return Bubble(
      color: controller.user.value.id != message.author.id ||
              message.type == types.MessageType.image
          ? const Color(0xffa29ae1)
          : const Color(0xff6f61e8),
      margin: nextMessageInGroup
          ? const BubbleEdges.symmetric(horizontal: 0)
          : null,
      nip: nextMessageInGroup
          ? BubbleNip.no
          : controller.user.value.id != message.author.id
              ? BubbleNip.leftTop
              : BubbleNip.rightTop,
      alignment: controller.user != message.author
          ? Alignment.bottomLeft
          : Alignment.bottomRight,
      padding: const BubbleEdges.all(8), // Padding for the bubble
      radius: const Radius.circular(20),
      child: child,
    );
  }
}
