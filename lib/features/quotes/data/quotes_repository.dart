import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:choice_lux_cars/core/supabase/supabase_client_provider.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';
import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Repository for quote-related data operations
///
/// Encapsulates all Supabase queries and returns domain models.
/// This layer separates data access from business logic.
class QuotesRepository {
  final SupabaseClient _supabase;

  QuotesRepository(this._supabase);

  /// Fetch all quotes from the database
  Future<Result<List<Quote>>> fetchQuotes() async {
    try {
      Log.d('Fetching quotes from database');

      final response = await _supabase
          .from('quotes')
          .select()
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} quotes from database');

      final quotes = response.map((json) => Quote.fromJson(json)).toList();
      return Result.success(quotes);
    } catch (error) {
      Log.e('Error fetching quotes: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Create a new quote
  Future<Result<Map<String, dynamic>>> createQuote(Quote quote) async {
    try {
      Log.d('Creating quote for client: ${quote.clientId}');

      final response = await _supabase
          .from('quotes')
          .insert(quote.toJson())
          .select()
          .single();

      Log.d('Quote created successfully with ID: ${response['id']}');
      return Result.success(response);
    } catch (error) {
      Log.e('Error creating quote: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update an existing quote
  Future<Result<void>> updateQuote(Quote quote) async {
    try {
      Log.d('Updating quote: ${quote.id}');

      await _supabase.from('quotes').update(quote.toJson()).eq('id', quote.id);

      Log.d('Quote updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating quote: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Delete a quote
  Future<Result<void>> deleteQuote(String quoteId) async {
    try {
      Log.d('Deleting quote: $quoteId');

      await _supabase.from('quotes').delete().eq('id', quoteId);

      Log.d('Quote deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deleting quote: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get quote by ID
  Future<Result<Quote?>> getQuoteById(String quoteId) async {
    try {
      Log.d('Fetching quote by ID: $quoteId');

      final response = await _supabase
          .from('quotes')
          .select()
          .eq('id', quoteId)
          .maybeSingle();

      if (response == null) {
        Log.d('No quote found with ID: $quoteId');
        return const Result.success(null);
      }

      Log.d('Quote fetched successfully');
      final quote = Quote.fromJson(response);
      return Result.success(quote);
    } catch (error) {
      Log.e('Error fetching quote by ID: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch quotes by user ID
  Future<Result<List<Quote>>> fetchQuotesByUser(String userId) async {
    try {
      Log.d('Fetching quotes by user: $userId');

      final response = await _supabase
          .from('quotes')
          .select()
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} quotes by user: $userId');

      final quotes = response.map((json) => Quote.fromJson(json)).toList();
      return Result.success(quotes);
    } catch (error) {
      Log.e('Error fetching quotes by user: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Fetch quote by ID (alias for getQuoteById for consistency)
  Future<Result<Quote?>> fetchQuoteById(String quoteId) async {
    return getQuoteById(quoteId);
  }

  /// Fetch quote transport details
  Future<Result<List<Map<String, dynamic>>>> fetchQuoteTransportDetails(
    String quoteId,
  ) async {
    try {
      Log.d('Fetching transport details for quote: $quoteId');

      final response = await _supabase
          .from('quote_transport_details')
          .select()
          .eq('quote_id', quoteId)
          .order('created_at', ascending: true);

      Log.d('Fetched ${response.length} transport details for quote: $quoteId');

      return Result.success(response);
    } catch (error) {
      Log.e('Error fetching quote transport details: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Create quote transport detail
  Future<Result<Map<String, dynamic>>> createQuoteTransportDetail(
    Map<String, dynamic> transportDetail,
  ) async {
    try {
      Log.d(
        'Creating transport detail for quote: ${transportDetail['quote_id']}',
      );

      final response = await _supabase
          .from('quote_transport_details')
          .insert(transportDetail)
          .select()
          .single();

      Log.d('Transport detail created successfully with ID: ${response['id']}');
      return Result.success(response);
    } catch (error) {
      Log.e('Error creating quote transport detail: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update quote transport detail
  Future<Result<void>> updateQuoteTransportDetail(
    Map<String, dynamic> transportDetail,
  ) async {
    try {
      Log.d('Updating transport detail: ${transportDetail['id']}');

      await _supabase
          .from('quote_transport_details')
          .update(transportDetail)
          .eq('id', transportDetail['id']);

      Log.d('Transport detail updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating quote transport detail: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Delete quote transport detail
  Future<Result<void>> deleteQuoteTransportDetail(
    String transportDetailId,
  ) async {
    try {
      Log.d('Deleting transport detail: $transportDetailId');

      await _supabase
          .from('quote_transport_details')
          .delete()
          .eq('id', transportDetailId);

      Log.d('Transport detail deleted successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error deleting quote transport detail: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get quotes by client
  Future<Result<List<Quote>>> getQuotesByClient(String clientId) async {
    try {
      Log.d('Fetching quotes for client: $clientId');

      final response = await _supabase
          .from('quotes')
          .select()
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} quotes for client: $clientId');

      final quotes = response.map((json) => Quote.fromJson(json)).toList();
      return Result.success(quotes);
    } catch (error) {
      Log.e('Error fetching quotes by client: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Get quotes by status
  Future<Result<List<Quote>>> getQuotesByStatus(String status) async {
    try {
      Log.d('Fetching quotes with status: $status');

      final response = await _supabase
          .from('quotes')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);

      Log.d('Fetched ${response.length} quotes with status: $status');

      final quotes = response.map((json) => Quote.fromJson(json)).toList();
      return Result.success(quotes);
    } catch (error) {
      Log.e('Error fetching quotes by status: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Update quote status
  Future<Result<void>> updateQuoteStatus(String quoteId, String status) async {
    try {
      Log.d('Updating quote status: $quoteId to $status');

      await _supabase
          .from('quotes')
          .update({'status': status})
          .eq('id', quoteId);

      Log.d('Quote status updated successfully');
      return const Result.success(null);
    } catch (error) {
      Log.e('Error updating quote status: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Search quotes by client name or description
  Future<Result<List<Quote>>> searchQuotes(String query) async {
    try {
      Log.d('Searching quotes with query: $query');

      // This would need to be adjusted based on the actual quote table structure
      final response = await _supabase
          .from('quotes')
          .select()
          .or('description.ilike.%$query%')
          .order('created_at', ascending: false);

      Log.d('Found ${response.length} quotes matching query: $query');

      final quotes = response.map((json) => Quote.fromJson(json)).toList();
      return Result.success(quotes);
    } catch (error) {
      Log.e('Error searching quotes: $error');
      return _mapSupabaseError(error);
    }
  }

  /// Map Supabase errors to appropriate AppException types
  Result<T> _mapSupabaseError<T>(dynamic error) {
    if (error is AuthException) {
      return Result.failure(AuthException(error.message));
    } else if (error is PostgrestException) {
      // Check if it's a network-related error
      if (error.message.contains('network') ||
          error.message.contains('timeout') ||
          error.message.contains('connection')) {
        return Result.failure(NetworkException(error.message));
      }
      // Check if it's an auth-related error
      if (error.message.contains('JWT') ||
          error.message.contains('unauthorized') ||
          error.message.contains('forbidden')) {
        return Result.failure(AuthException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else if (error is StorageException) {
      if (error.message.contains('network') ||
          error.message.contains('timeout')) {
        return Result.failure(NetworkException(error.message));
      }
      return Result.failure(UnknownException(error.message));
    } else {
      return Result.failure(UnknownException(error.toString()));
    }
  }
}

/// Provider for QuotesRepository
final quotesRepositoryProvider = Provider<QuotesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return QuotesRepository(supabase);
});
