import 'package:equatable/equatable.dart';

/// Semantic resolution result returned from Appwrite VectorsDB (`resolutions_vector`).
class ResolutionResult extends Equatable {
  const ResolutionResult({
    required this.id,
    required this.title,
    required this.symptom,
    this.observation = '',
    required this.fixProcedure,
    required this.requiredSku,
    this.similarity = 1.0,
  });

  final String id;
  final String title;
  final String symptom;
  final String observation;
  final String fixProcedure;
  final String requiredSku;
  final double similarity;

  /// Whether confidence is high enough (>= 60%) to be considered a strong diagnostic match.
  bool get isHighConfidence => similarity >= 0.60;

  /// Percentage formatted representation (e.g., "94% Match")
  String get similarityPercentage => '${(similarity * 100).toInt()}% Match';

  factory ResolutionResult.fromJson(Map<String, dynamic> json) {
    // Appwrite document returns attributes in $id and data fields
    final id = json['\$id']?.toString() ?? json['id']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    final symptom = json['symptom']?.toString() ?? '';
    final observation = json['observation']?.toString() ?? '';
    final fixProcedure = json['fix_procedure']?.toString() ?? '';
    final requiredSku = json['required_sku']?.toString() ?? '';
    final similarityRaw = json['similarity_score'] ?? json['similarity'];
    final similarity = similarityRaw is num ? similarityRaw.toDouble() : 1.0;

    return ResolutionResult(
      id: id,
      title: title,
      symptom: symptom,
      observation: observation,
      fixProcedure: fixProcedure,
      requiredSku: requiredSku,
      similarity: similarity,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'symptom': symptom,
        'observation': observation,
        'fix_procedure': fixProcedure,
        'required_sku': requiredSku,
        'similarity_score': similarity,
      };

  ResolutionResult copyWith({
    String? id,
    String? title,
    String? symptom,
    String? observation,
    String? fixProcedure,
    String? requiredSku,
    double? similarity,
  }) {
    return ResolutionResult(
      id: id ?? this.id,
      title: title ?? this.title,
      symptom: symptom ?? this.symptom,
      observation: observation ?? this.observation,
      fixProcedure: fixProcedure ?? this.fixProcedure,
      requiredSku: requiredSku ?? this.requiredSku,
      similarity: similarity ?? this.similarity,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        symptom,
        observation,
        fixProcedure,
        requiredSku,
        similarity,
      ];
}

