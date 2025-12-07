import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String filePath = 'CATNA_dataset.xlsx';
const String apiUrl = 'https://catna-ai-model.onrender.com/analyze/';

Future<String> uploadCatnaFile() async {
  File file = File(filePath);
  if (!await file.exists()) {
    print('Error: File not found at path: $filePath');
    return '{"error": "File not found"}';
  }

  print('Starting file upload of ${file.path.split('/').last} to $apiUrl...');

  var request = http.MultipartRequest(
    'POST',
    Uri.parse(apiUrl),
  );

  request.files.add(await http.MultipartFile.fromPath(
    'file',
    file.path,
  ));

  try {
    http.StreamedResponse streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    final String responseBody = response.body;

    if (response.statusCode == 200) {
      print('✅ Analysis successful!');

      final timestamp =
          DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
      final outputFileName = 'catna_report_$timestamp.json';
      final outputFile = File(outputFileName);

      await outputFile.writeAsString(responseBody);
      print('💾 Full JSON response saved to: $outputFileName');

      final Map<String, dynamic> responseData = json.decode(responseBody);
      print('\n--- Gemini AI Insights ---');
      print(responseData['gemini_insights']);

      return responseBody;
    } else {
      print('❌ Request failed with status code: ${response.statusCode}');
      print('Response body: $responseBody');

      try {
        final errorData = json.decode(responseBody);
        print('Error Detail: ${errorData['detail']}');
      } catch (e) {
        print(
            'Server responded with non-JSON error. Status: ${response.statusCode}');
      }
      return responseBody;
    }
  } catch (e) {
    print('An error occurred during the request: $e');
    return '{"error": "Network or connection issue: $e"}';
  }
}

void main() async {
  String rawJson = await uploadCatnaFile();
}
