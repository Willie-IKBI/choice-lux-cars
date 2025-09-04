import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/features/quotes/models/quote.dart';
import 'package:choice_lux_cars/features/quotes/models/quote_transport_detail.dart';
import 'package:choice_lux_cars/features/auth/providers/auth_provider.dart';
import 'package:choice_lux_cars/features/quotes/data/quotes_repository.dart';
import 'package:choice_lux_cars/shared/utils/sa_time_utils.dart';
import 'package:choice_lux_cars/core/logging/log.dart';
import 'package:choice_lux_cars/core/types/result.dart';

/// Notifier for managing quotes state using AsyncNotifier
class QuotesNotifier extends AsyncNotifier<List<Quote>> {
  late final QuotesRepository _quotesRepository;
  late final dynamic currentUser;

  @override
  Future<List<Quote>> build() async {
    _quotesRepository = ref.watch(quotesRepositoryProvider);
    currentUser = ref.watch(currentUserProfileProvider);

    if (currentUser != null) {
      return _fetchQuotes();
    }
    return [];
  }

  // Fetch quotes based on user role
  Future<List<Quote>> _fetchQuotes() async {
    try {
      List<Quote> quotes;

      if (currentUser == null) {
        return [];
      }

      final userRole = currentUser.role?.toLowerCase();
      final userId = currentUser.id;

      if (userRole == 'administrator' || userRole == 'manager') {
        // Admins and managers see all quotes
        final result = await _quotesRepository.fetchQuotes();
        if (result.isSuccess) {
          quotes = result.data!;
        } else {
          Log.e('Error fetching quotes: ${result.error!.message}');
          throw Exception(result.error!.message);
        }
      } else if (userRole == 'driver_manager') {
        // Driver managers see quotes they created
        final result = await _quotesRepository.fetchQuotesByUser(userId);
        if (result.isSuccess) {
          quotes = result.data!;
        } else {
          Log.e('Error fetching quotes by user: ${result.error!.message}');
          throw Exception(result.error!.message);
        }
      } else {
        // Other roles see no quotes
        return [];
      }

      return quotes;
    } catch (error) {
      Log.e('Error fetching quotes: $error');
      rethrow;
    }
  }

  // Get quotes by status
  List<Quote> get openQuotes =>
      (state.value ?? []).where((quote) => quote.isOpen).toList();
  List<Quote> get acceptedQuotes =>
      (state.value ?? []).where((quote) => quote.isAccepted).toList();
  List<Quote> get expiredQuotes =>
      (state.value ?? []).where((quote) => quote.isExpired).toList();
  List<Quote> get closedQuotes =>
      (state.value ?? []).where((quote) => quote.isClosed).toList();

  // Create new quote
  Future<Map<String, dynamic>> createQuote(Quote quote) async {
    try {
      final result = await _quotesRepository.createQuote(quote);
      if (result.isSuccess) {
        ref.invalidateSelf();
        return result.data!;
      } else {
        Log.e('Error creating quote: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error creating quote: $error');
      rethrow;
    }
  }

  // Get single quote
  Future<Quote?> getQuote(String quoteId) async {
    try {
      final result = await _quotesRepository.fetchQuoteById(quoteId);
      if (result.isSuccess) {
        return result.data;
      } else {
        Log.e('Error getting quote: ${result.error!.message}');
        return null;
      }
    } catch (error) {
      Log.e('Error getting quote: $error');
      return null;
    }
  }

  // Update quote
  Future<void> updateQuote(Quote quote) async {
    try {
      final result = await _quotesRepository.updateQuote(quote);
      if (result.isSuccess) {
        ref.invalidateSelf();
      } else {
        Log.e('Error updating quote: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating quote: $error');
      rethrow;
    }
  }

  // Update quote status
  Future<void> updateQuoteStatus(String quoteId, String status) async {
    try {
      final result = await _quotesRepository.updateQuoteStatus(quoteId, status);
      if (result.isSuccess) {
        ref.invalidateSelf();
      } else {
        Log.e('Error updating quote status: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating quote status: $error');
      rethrow;
    }
  }

  // Delete quote
  Future<void> deleteQuote(String quoteId) async {
    try {
      final result = await _quotesRepository.deleteQuote(quoteId);
      if (result.isSuccess) {
        ref.invalidateSelf();
      } else {
        Log.e('Error deleting quote: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error deleting quote: $error');
      rethrow;
    }
  }

  // Check if user can create quotes
  bool get canCreateQuotes {
    if (currentUser == null) return false;
    final userRole = currentUser.role?.toLowerCase();

    return userRole == 'administrator' ||
        userRole == 'manager' ||
        userRole == 'driver_manager';
  }

  // Get transport details for a quote
  Future<List<QuoteTransportDetail>> getQuoteTransportDetails(
    String quoteId,
  ) async {
    try {
      final result = await _quotesRepository.fetchQuoteTransportDetails(
        quoteId,
      );
      if (result.isSuccess) {
        // Convert Map<String, dynamic> to QuoteTransportDetail objects
        return result.data!
            .map((json) => QuoteTransportDetail.fromMap(json))
            .toList();
      } else {
        Log.e(
          'Error getting quote transport details: ${result.error!.message}',
        );
        return [];
      }
    } catch (error) {
      Log.e('Error getting quote transport details: $error');
      return [];
    }
  }

  /// Refresh quotes data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> fetchQuotes() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async => await _fetchQuotes());
  }
}

/// Notifier for managing quote transport details using AsyncNotifier
class QuoteTransportDetailsNotifier
    extends FamilyAsyncNotifier<List<QuoteTransportDetail>, String> {
  late final QuotesRepository _quotesRepository;

  @override
  Future<List<QuoteTransportDetail>> build(String quoteId) async {
    _quotesRepository = ref.watch(quotesRepositoryProvider);
    return _fetchTransportDetails(quoteId);
  }

  // Fetch transport details for a specific quote
  Future<List<QuoteTransportDetail>> _fetchTransportDetails(
    String quoteId,
  ) async {
    try {
      final result = await _quotesRepository.fetchQuoteTransportDetails(
        quoteId,
      );
      if (result.isSuccess) {
        // Convert Map<String, dynamic> to QuoteTransportDetail objects
        final transportDetails = result.data!
            .map((json) => QuoteTransportDetail.fromMap(json))
            .toList();
        return transportDetails;
      } else {
        Log.e(
          'Error fetching quote transport details: ${result.error!.message}',
        );
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error fetching quote transport details: $error');
      rethrow;
    }
  }

  // Add transport detail to quote
  Future<void> addTransportDetail(QuoteTransportDetail transportDetail) async {
    try {
      Log.d('Adding transport detail: ${transportDetail.toMap()}');
      
      final result = await _quotesRepository.createQuoteTransportDetail(
        transportDetail.toMap(),
      );
      
      if (result.isSuccess) {
        Log.d('Transport detail added successfully, invalidating provider');
        ref.invalidateSelf();
      } else {
        Log.e('Error adding quote transport detail: ${result.error!.message}');
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error adding quote transport detail: $error');
      rethrow;
    }
  }

  // Update transport detail
  Future<void> updateTransportDetail(
    QuoteTransportDetail transportDetail,
  ) async {
    try {
      final result = await _quotesRepository.updateQuoteTransportDetail(
        transportDetail.toMap(),
      );
      if (result.isSuccess) {
        ref.invalidateSelf();
      } else {
        Log.e(
          'Error updating quote transport detail: ${result.error!.message}',
        );
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error updating quote transport detail: $error');
      rethrow;
    }
  }

  // Delete transport detail
  Future<void> deleteTransportDetail(String transportDetailId) async {
    try {
      final result = await _quotesRepository.deleteQuoteTransportDetail(
        transportDetailId,
      );
      if (result.isSuccess) {
        ref.invalidateSelf();
      } else {
        Log.e(
          'Error deleting quote transport detail: ${result.error!.message}',
        );
        throw Exception(result.error!.message);
      }
    } catch (error) {
      Log.e('Error deleting quote transport detail: $error');
      rethrow;
    }
  }

  // Calculate total amount
  double get totalAmount {
    return (state.value ?? []).fold(
      0.0,
      (sum, transport) => sum + transport.amount,
    );
  }

  /// Refresh transport details data
  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  /// Fetch transport details manually (for UI refresh)
  Future<void> fetchTransportDetails() async {
    ref.invalidateSelf();
  }
}

/// Provider for QuotesNotifier using AsyncNotifierProvider
final quotesProvider = AsyncNotifierProvider<QuotesNotifier, List<Quote>>(QuotesNotifier.new);

/// Provider for QuoteTransportDetailsNotifier using AsyncNotifierProvider.family
final quoteTransportDetailsProvider =
    AsyncNotifierProvider.family<
      QuoteTransportDetailsNotifier,
      List<QuoteTransportDetail>,
      String
    >(QuoteTransportDetailsNotifier.new);
