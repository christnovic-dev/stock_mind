import 'package:supabase_flutter/supabase_flutter.dart';

/// Récupère les statistiques réelles du stock sans appeler Gemini.
Future<Map<String, dynamic>> getStockContext({
  required String businessId,
}) async {
  final supabase = Supabase.instance.client;

  if (supabase.auth.currentSession == null) {
    throw Exception('Utilisateur non connecté. Connecte-toi à StockMind.');
  }

  if (businessId.trim().isEmpty) {
    throw Exception('Aucune entreprise sélectionnée.');
  }

  final response = await supabase.rpc(
    'get_stock_ai_context',
    params: {'p_business_id': businessId},
  );

  if (response is! Map) {
    throw Exception('Supabase n’a pas retourné un contexte de stock valide.');
  }

  return Map<String, dynamic>.from(response);
}

/// Envoie une question à Gemini via la fonction Edge bright-api.
Future<Map<String, dynamic>> askStockAi({
  required String businessId,
  required String question,
}) async {
  final supabase = Supabase.instance.client;

  if (supabase.auth.currentSession == null) {
    throw Exception('Utilisateur non connecté. Connecte-toi à StockMind.');
  }

  if (businessId.trim().isEmpty) {
    throw Exception('Aucune entreprise sélectionnée.');
  }

  if (question.trim().isEmpty) {
    throw Exception('Saisis une question avant de continuer.');
  }

  final response = await supabase.functions.invoke(
    'bright-api',
    body: {'business_id': businessId, 'question': question.trim()},
  );

  final data = response.data;

  if (response.status != 200) {
    final message = data is Map ? data['error']?.toString() : null;

    throw Exception(message ?? 'Erreur du service IA (${response.status}).');
  }

  if (data is! Map) {
    throw Exception('Réponse invalide du service IA.');
  }

  final result = Map<String, dynamic>.from(data);

  if (result['success'] != true) {
    throw Exception(
      result['error']?.toString() ??
          'Le service IA n’a pas confirmé la réussite.',
    );
  }

  final answer = result['answer']?.toString();

  if (answer == null || answer.trim().isEmpty) {
    throw Exception('Gemini a retourné une réponse vide.');
  }

  return result;
}
