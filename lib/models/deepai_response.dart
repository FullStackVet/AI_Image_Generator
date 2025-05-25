// AI response model
class DeepAiResponse {
  final String outputUrl;
  final String id;

  DeepAiResponse({required this.outputUrl, required this.id});

  factory DeepAiResponse.fromJson(Map<String, dynamic> json) {
    return DeepAiResponse(outputUrl: json['output_url'], id: json['id']);
  }
}
