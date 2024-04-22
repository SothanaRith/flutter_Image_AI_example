import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';

class ImageAIController extends GetxController {

  String? uid;
  String? transId;
  Uint8List? imageResult;
  bool loading = false;

  Future<String> getImageFilePath(String imageName) async {
    final ByteData assetByteData = await rootBundle.load('assets/$imageName');
    final List<int> byteData = assetByteData.buffer.asUint8List();
    final String tempDir = (await getTemporaryDirectory()).path;
    final String filePath = '$tempDir/$imageName';
    await File(filePath).writeAsBytes(byteData);
    return filePath;
  }


  Future<void> uploadImage ({required File file}) async {
    try{
      loading = true;
      update();
      var request = http.MultipartRequest('POST', Uri.parse('https://api-service.vanceai.com/web_api/v1/upload'));
      request.fields.addAll({
        'api_token': 'dbec22910a8645f214f2ae27e5206054'
      });
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        uid = data['data']['uid'].toString();
        update();
        imageTransform(uid: uid ?? "", name: "img2anime", module: 'img2anime');
      }
      else {
        if(kDebugMode){
          print(response.reasonPhrase);
        }
      }
    }catch(e){
      loading = false;
      debugPrint("error ====== $e");
    }finally{
      update();
    }
  }


  Future<void> imageTransform ({required String uid, required String name, required String module, String modelName = "style1", String description = "", String controlModel = "0", String styleStrength = "11"}) async {
    try{
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      };
      var request = http.Request('POST', Uri.parse('https://api-service.vanceai.com/web_api/v1/transform'));
      request.bodyFields = {
        'api_token': 'dbec22910a8645f214f2ae27e5206054',
        'uid': uid,
        'jconfig': '{\n  "name":$name,\n  "config":{\n    "module":$module,\n    "module_params":{\n        "model_name":$modelName,\n        "description":$description,\n        "control_mode": $controlModel,\n        "style_strength": $styleStrength\n    }\n  }\n}'
      };
      request.headers.addAll(headers);
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        transId = data["data"]["trans_id"].toString();
        update();
        progressImage(transId: transId ?? "");
      }
      else {
        if(kDebugMode){
          print(response.reasonPhrase);
        }
      }
    }catch(e){
      loading = false;
      debugPrint("error ====== $e");
    }finally{
      update();
    }
  }


  Future<void> progressImage ({required String transId}) async {
    try {
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      };
      var request = http.Request('POST', Uri.parse('https://api-service.vanceai.com/web_api/v1/progress'));
      request.bodyFields = {
        'api_token': 'dbec22910a8645f214f2ae27e5206054',
        'trans_id': transId
      };
      request.headers.addAll(headers);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if(kDebugMode){
          print("Progress status : ${data["data"]["status"]}");
        }
        downloadResult(transId: transId);
      }
      else {
        if(kDebugMode){
          print(response.reasonPhrase);
        }
      }
    }catch (e){
      loading = false;
      debugPrint("error ====== $e");
    }finally{
      update();
    }
  }


  Future<dynamic> downloadResult ({required String transId}) async {
    try{
      var headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      };
      var request = http.Request('POST', Uri.parse('https://api-service.vanceai.com/web_api/v1/download'));
      request.bodyFields = {
        'api_token': 'dbec22910a8645f214f2ae27e5206054',
        'trans_id': transId
      };
      request.headers.addAll(headers);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        imageResult = response.bodyBytes;
        update();
      }
      else {
        if(kDebugMode){
          print(response.reasonPhrase);
        }
      }
    }catch(e){
      loading = false;
      debugPrint("error ====== $e");
    }finally{
      update();
      loading = false;
      debugPrint("already download");
    }
  }
}