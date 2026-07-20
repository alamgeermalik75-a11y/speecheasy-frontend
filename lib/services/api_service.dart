import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_item.dart';


const String kBackendUrl = "http://192.168.18.229:5000";

class ApiService {
  Future<AppContent> fetchContent() async {
    final res = await http.get(Uri.parse("$kBackendUrl/content"));
    if (res.statusCode != 200) {
      throw Exception("Server error: ${res.statusCode}");
    }
    return AppContent.fromJson(jsonDecode(res.body));
  }
}
