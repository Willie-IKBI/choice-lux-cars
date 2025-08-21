import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../models/quote_transport_detail.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/supabase_service.dart';

final quotesProvider = StateNotifierProvider<QuotesNotifier, List<Quote>>((ref) {
  final currentUser = ref.watch(currentUserProfileProvider);
  return QuotesNotifier(currentUser);
});

final quoteTransportDetailsProvider = StateNotifierProvider.family<QuoteTransportDetailsNotifier, List<QuoteTransportDetail>, String>((ref, quoteId) {
  return QuoteTransportDetailsNotifier(quoteId);
});

class QuotesNotifier extends StateNotifier<List<Quote>> {
  final currentUser;
  
  QuotesNotifier(this.currentUser) : super([]) {
    if (currentUser != null) {
      fetchQuotes();
    }
  }

  // Fetch quotes based on user role
  Future<void> fetchQuotes() async {
    try {
      List<Map<String, dynamic>> quoteMaps;
      
      if (currentUser == null) {
        state = [];
        return;
      }

      final userRole = currentUser.role?.toLowerCase();
      final userId = currentUser.id;

      if (userRole == 'administrator' || userRole == 'manager') {
        // Admins and managers see all quotes
        quoteMaps = await SupabaseService.instance.getQuotes();
      } else if (userRole == 'driver_manager') {
        // Driver managers see quotes they created
        quoteMaps = await SupabaseService.instance.getQuotesByUser(userId);
      } else {
        // Other roles see no quotes
        if (!mounted) return;
        state = [];
        return;
      }

      if (!mounted) return;
      state = quoteMaps.map((map) => Quote.fromMap(map)).toList();
    } catch (error) {
      print('Error fetching quotes: $error');
      if (!mounted) return;
      state = [];
    }
  }

  // Get quotes by status
  List<Quote> get openQuotes => state.where((quote) => quote.isOpen).toList();
  List<Quote> get acceptedQuotes => state.where((quote) => quote.isAccepted).toList();
  List<Quote> get expiredQuotes => state.where((quote) => quote.isExpired).toList();
  List<Quote> get closedQuotes => state.where((quote) => quote.isClosed).toList();

  // Create new quote
  Future<Map<String, dynamic>> createQuote(Quote quote) async {
    try {
      final createdQuote = await SupabaseService.instance.createQuote(quote.toMap());
      if (mounted) {
        await fetchQuotes();
      }
      return createdQuote;
    } catch (error) {
      print('Error creating quote: $error');
      rethrow;
    }
  }

  // Get single quote
  Future<Quote?> getQuote(String quoteId) async {
    try {
      final data = await SupabaseService.instance.getQuote(quoteId);
      if (data != null) {
        return Quote.fromMap(data);
      }
      return null;
    } catch (error) {
      print('Error getting quote: $error');
      return null;
    }
  }

  // Update quote
  Future<void> updateQuote(Quote quote) async {
    try {
      await SupabaseService.instance.updateQuote(
        quoteId: quote.id, 
        data: quote.toMap()
      );
      if (mounted) {
        await fetchQuotes();
      }
    } catch (error) {
      print('Error updating quote: $error');
      rethrow;
    }
  }

  // Update quote status
  Future<void> updateQuoteStatus(String quoteId, String status) async {
    try {
      await SupabaseService.instance.updateQuote(
        quoteId: quoteId, 
        data: {
          'quote_status': status,
          'updated_at': DateTime.now().toIso8601String(),
        }
      );
      if (mounted) {
        await fetchQuotes();
      }
    } catch (error) {
      print('Error updating quote status: $error');
      rethrow;
    }
  }

  // Delete quote
  Future<void> deleteQuote(String quoteId) async {
    try {
      await SupabaseService.instance.deleteQuote(quoteId);
      if (mounted) {
        await fetchQuotes();
      }
    } catch (error) {
      print('Error deleting quote: $error');
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
  Future<List<QuoteTransportDetail>> getQuoteTransportDetails(String quoteId) async {
    try {
      final transportMaps = await SupabaseService.instance.getQuoteTransportDetails(quoteId);
      return transportMaps.map((map) => QuoteTransportDetail.fromMap(map)).toList();
    } catch (error) {
      print('Error getting quote transport details: $error');
      return [];
    }
  }
}

class QuoteTransportDetailsNotifier extends StateNotifier<List<QuoteTransportDetail>> {
  final String quoteId;
  
  QuoteTransportDetailsNotifier(this.quoteId) : super([]) {
    fetchTransportDetails();
  }

  // Fetch transport details for a specific quote
  Future<void> fetchTransportDetails() async {
    try {
      final transportMaps = await SupabaseService.instance.getQuoteTransportDetails(quoteId);
      if (!mounted) return;
      state = transportMaps.map((map) => QuoteTransportDetail.fromMap(map)).toList();
    } catch (error) {
      print('Error fetching quote transport details: $error');
      if (!mounted) return;
      state = [];
    }
  }

  // Add transport detail to quote
  Future<void> addTransportDetail(QuoteTransportDetail transportDetail) async {
    try {
      await SupabaseService.instance.createQuoteTransportDetail(transportDetail.toMap());
      await fetchTransportDetails();
    } catch (error) {
      print('Error adding quote transport detail: $error');
      rethrow;
    }
  }

  // Update transport detail
  Future<void> updateTransportDetail(QuoteTransportDetail transportDetail) async {
    try {
      await SupabaseService.instance.updateQuoteTransportDetail(
        transportDetailId: transportDetail.id, 
        data: transportDetail.toMap()
      );
      await fetchTransportDetails();
    } catch (error) {
      print('Error updating quote transport detail: $error');
      rethrow;
    }
  }

  // Delete transport detail
  Future<void> deleteTransportDetail(String transportDetailId) async {
    try {
      await SupabaseService.instance.deleteQuoteTransportDetail(transportDetailId);
      await fetchTransportDetails();
    } catch (error) {
      print('Error deleting quote transport detail: $error');
      rethrow;
    }
  }

  // Calculate total amount
  double get totalAmount {
    return state.fold(0.0, (sum, transport) => sum + transport.amount);
  }
}
