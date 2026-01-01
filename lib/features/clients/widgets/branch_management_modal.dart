import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:choice_lux_cars/app/theme.dart';
import 'package:choice_lux_cars/features/clients/models/client_branch.dart';
import 'package:choice_lux_cars/features/clients/data/clients_repository.dart';
import 'package:choice_lux_cars/core/logging/log.dart';

class BranchManagementModal extends ConsumerStatefulWidget {
  final int clientId;
  final String clientName;

  const BranchManagementModal({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  ConsumerState<BranchManagementModal> createState() =>
      _BranchManagementModalState();
}

class _BranchManagementModalState
    extends ConsumerState<BranchManagementModal> {
  List<ClientBranch> _branches = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final result = await repository.fetchBranchesByClientId(widget.clientId);

      if (result.isSuccess) {
        setState(() {
          _branches = result.data!;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading branches: ${result.error!.message}'),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.e('Error loading branches: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading branches: ${e.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBranch() async {
    final branchNameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isValid = branchNameController.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: ChoiceLuxTheme.charcoalGray,
            title: const Text(
              'Add Branch',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: branchNameController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: ChoiceLuxTheme.softWhite),
              decoration: InputDecoration(
                labelText: 'Branch Name',
                labelStyle: const TextStyle(color: ChoiceLuxTheme.platinumSilver),
                hintText: 'Enter branch name',
                hintStyle: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: ChoiceLuxTheme.charcoalGray.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ChoiceLuxTheme.platinumSilver),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ChoiceLuxTheme.platinumSilver),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ChoiceLuxTheme.richGold,
                    width: 2,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
                ),
              ),
              ElevatedButton(
                onPressed: isValid
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && branchNameController.text.trim().isNotEmpty) {
      await _saveBranch(branchNameController.text.trim());
    }
  }

  Future<void> _editBranch(ClientBranch branch) async {
    final branchNameController =
        TextEditingController(text: branch.branchName);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isValid = branchNameController.text.trim().isNotEmpty;
          return AlertDialog(
            backgroundColor: ChoiceLuxTheme.charcoalGray,
            title: const Text(
              'Edit Branch',
              style: TextStyle(
                color: ChoiceLuxTheme.softWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: TextField(
              controller: branchNameController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: ChoiceLuxTheme.softWhite),
              decoration: InputDecoration(
                labelText: 'Branch Name',
                labelStyle: const TextStyle(color: ChoiceLuxTheme.platinumSilver),
                hintText: 'Enter branch name',
                hintStyle: TextStyle(
                  color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.6),
                ),
                filled: true,
                fillColor: ChoiceLuxTheme.charcoalGray.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ChoiceLuxTheme.platinumSilver),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ChoiceLuxTheme.platinumSilver),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: ChoiceLuxTheme.richGold,
                    width: 2,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
                ),
              ),
              ElevatedButton(
                onPressed: isValid
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChoiceLuxTheme.richGold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && branchNameController.text.trim().isNotEmpty) {
      await _updateBranch(branch.id!, branchNameController.text.trim());
    }
  }

  Future<void> _deleteBranch(ClientBranch branch) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChoiceLuxTheme.charcoalGray,
        title: const Text(
          'Delete Branch',
          style: TextStyle(
            color: ChoiceLuxTheme.softWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${branch.branchName}"?',
          style: const TextStyle(color: ChoiceLuxTheme.platinumSilver),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ChoiceLuxTheme.platinumSilver),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ChoiceLuxTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _performDeleteBranch(branch.id!);
    }
  }

  Future<void> _saveBranch(String branchName) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final result = await repository.createBranch(
        clientId: widget.clientId,
        branchName: branchName,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Branch added successfully'),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
        }
        await _loadBranches();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding branch: ${result.error!.message}'),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      Log.e('Error adding branch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding branch: ${e.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateBranch(int branchId, String branchName) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final result = await repository.updateBranch(
        branchId: branchId,
        branchName: branchName,
      );

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Branch updated successfully'),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
        }
        await _loadBranches();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating branch: ${result.error!.message}'),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      Log.e('Error updating branch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating branch: ${e.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _performDeleteBranch(int branchId) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(clientsRepositoryProvider);
      final result = await repository.deleteBranch(branchId);

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Branch deleted successfully'),
              backgroundColor: ChoiceLuxTheme.successColor,
            ),
          );
        }
        await _loadBranches();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting branch: ${result.error!.message}'),
              backgroundColor: ChoiceLuxTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      Log.e('Error deleting branch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting branch: ${e.toString()}'),
            backgroundColor: ChoiceLuxTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: screenHeight * 0.85,
        ),
        child: Container(
          width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 600,
          decoration: BoxDecoration(
            gradient: ChoiceLuxTheme.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ChoiceLuxTheme.richGold.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ChoiceLuxTheme.richGold,
                      ChoiceLuxTheme.richGold.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: Colors.black,
                      size: isMobile ? 20 : 24,
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Branches',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.clientName,
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: isMobile ? 20 : 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: ChoiceLuxTheme.richGold,
                          ),
                        ),
                      )
                    : _branches.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.business_outlined,
                                    size: 64,
                                    color: ChoiceLuxTheme.platinumSilver
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No branches yet',
                                    style: TextStyle(
                                      color: ChoiceLuxTheme.platinumSilver,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add a branch to get started',
                                    style: TextStyle(
                                      color: ChoiceLuxTheme.platinumSilver
                                          .withValues(alpha: 0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(isMobile ? 12 : 16),
                            itemCount: _branches.length,
                            itemBuilder: (context, index) {
                              final branch = _branches[index];
                              return Card(
                                margin: EdgeInsets.only(
                                  bottom: isMobile ? 8 : 12,
                                ),
                                color: ChoiceLuxTheme.charcoalGray
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: ChoiceLuxTheme.richGold
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 12 : 16,
                                    vertical: isMobile ? 8 : 12,
                                  ),
                                  leading: Icon(
                                    Icons.location_on,
                                    color: ChoiceLuxTheme.richGold,
                                    size: isMobile ? 20 : 24,
                                  ),
                                  title: Text(
                                    branch.branchName,
                                    style: TextStyle(
                                      color: ChoiceLuxTheme.softWhite,
                                      fontSize: isMobile ? 14 : 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: _isSaving
                                            ? null
                                            : () => _editBranch(branch),
                                        icon: Icon(
                                          Icons.edit,
                                          color: ChoiceLuxTheme.richGold,
                                          size: isMobile ? 18 : 20,
                                        ),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        onPressed: _isSaving
                                            ? null
                                            : () => _deleteBranch(branch),
                                        icon: Icon(
                                          Icons.delete,
                                          color: ChoiceLuxTheme.errorColor,
                                          size: isMobile ? 18 : 20,
                                        ),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              // Footer with Add Button
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: ChoiceLuxTheme.charcoalGray.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _addBranch,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isSaving ? 'Saving...' : 'Add Branch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ChoiceLuxTheme.richGold,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

