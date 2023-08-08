import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:call_log/call_log.dart';

void main() {
  runApp(const WhatsappAssistant());
}

class WhatsappAssistant extends StatefulWidget {
  const WhatsappAssistant({super.key});
  @override
  _WhatsappAssistantState createState() => _WhatsappAssistantState();
}

class _WhatsappAssistantState extends State<WhatsappAssistant> {
  List<Map<String, String>> _recentNumbers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPhoneCallLogs();
  }

  Future<void> _fetchPhoneCallLogs() async {
    await requestPermission();
    List<Map<String, String>> recentCallLogs = await fetchCallLogs();
    setState(() {
      _recentNumbers = recentCallLogs;
    });
  }

  void _onWhatsAppClicked(String? whatsappNumber) async {
    try {
      Uri uri = Uri.parse("whatsapp://send?phone=$whatsappNumber");
      await launchUrl(uri);
    } catch (f) {
      Fluttertoast.showToast(
        msg: "Cannot send WhatsApp to $whatsappNumber",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsApp Assistant',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WhatsApp Assistant'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Enter phone number...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      _onWhatsAppClicked(_searchController.text);
                    },
                    child: const Text('Chat'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _recentNumbers.length,
                itemBuilder: (context, index) {
                  Map<String, String> entry = _recentNumbers[index];
                  return ListTile(
                    title: Text(entry['number'] ?? ""),
                    subtitle: Text(entry['name'] ?? ""),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _onWhatsAppClicked(_recentNumbers[index]['number']);
                          },
                          icon: const Icon(Icons.messenger_outline_rounded),
                          label: const Text("Chat"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> requestPermission() async {
  var permissionStatus = await Permission.phone.status;
  if (!permissionStatus.isGranted) {
    permissionStatus = await Permission.phone.request();
  }
  if (!permissionStatus.isGranted) {
    Fluttertoast.showToast(
      msg: "Cannot access your phone calls",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}

Future<List<Map<String, String>>> fetchCallLogs() async {
  List<Map<String, String>> uniqueLogs = [];
  Iterable<CallLogEntry> allLogs = await CallLog.query();

  allLogs = allLogs.toList()
    ..sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));

  for (var entry in allLogs) {
    bool isDuplicate = uniqueLogs.any((item) => item['number'] == entry.number);

    if (!isDuplicate) {
      uniqueLogs.add({
        'name': entry.name ?? entry.number ?? "",
        'number': entry.number ?? "",
      });
    }
  }

  return uniqueLogs.sublist(0, 50);
}
