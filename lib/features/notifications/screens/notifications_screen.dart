import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digiluk/common/utils/api_client.dart';
import 'package:digiluk/common/utils/colors.dart';
import 'package:digiluk/common/widgets/empty_state.dart';
import 'package:digiluk/common/widgets/cloudinary_image.dart';
import 'package:digiluk/common/widgets/loader.dart';
import 'package:digiluk/features/auth/controller/auth_controller.dart';
import 'package:digiluk/features/trust/controller/trust_controller.dart';
import 'package:digiluk/models/transaction_model.dart';
import 'package:digiluk/models/trust_model.dart';
import 'package:digiluk/common/utils/utils.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDataAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Archived'),
            Tab(text: 'My Alerts'),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null || user.trustIds.isEmpty) {
            return const EmptyState(
              title: 'No Alerts',
              subtitle:
                  'Notifications about pending approvals and new transactions will appear here',
              icon: Icons.notifications_none,
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildPendingTab(user.trustIds),
              _buildArchivedTab(user.trustIds),
              _buildMyAlertsTab(user.uid),
            ],
          );
        },
        error: (err, trace) => Center(child: Text(err.toString())),
        loading: () => const Loader(),
      ),
    );
  }

  Widget _buildPendingTab(List<String> trustIds) {
    final trustCtrl = ref.watch(trustControllerProvider);
    return StreamBuilder<List<TrustModel>>(
      stream: trustCtrl.getUserTrusts(trustIds),
      builder: (context, trustSnapshot) {
        if (!trustSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final trusts = trustSnapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trusts.length,
          itemBuilder: (context, index) {
            final trust = trusts[index];
            return _buildPendingRequests(context, trust);
          },
        );
      },
    );
  }

  Widget _buildPendingRequests(BuildContext context, TrustModel trust) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trusts')
          .doc(trust.trustId)
          .collection('notifications')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
              child: Text(
                trust.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: digilukSubTextColor,
                ),
              ),
            ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildJoinRequestTile(
                trust.trustId,
                doc.id,
                data,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildJoinRequestTile(
      String trustId, String notifId, Map<String, dynamic> data) {
    final userName = data['userName'] ?? '';
    final userPic = data['userProfilePic'] ?? '';
    final userId = data['userId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CloudinaryCircleAvatar(
              imageUrl: userPic,
              radius: 22,
              backgroundColor: digilukPrimary.withOpacity(0.1),
              tapForFullScreen: false,
              fallback: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: const TextStyle(color: digilukPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const Text('Requested to join',
                      style: TextStyle(
                          fontSize: 12, color: digilukSubTextColor)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () async {
                final success = await ApiClient.approveRequest(
                    trustId, notifId, userId);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to approve')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () async {
                final success = await ApiClient.rejectRequest(
                    trustId, notifId, userId);
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to reject')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivedTab(List<String> trustIds) {
    final trustCtrl = ref.watch(trustControllerProvider);
    return StreamBuilder<List<TrustModel>>(
      stream: trustCtrl.getUserTrusts(trustIds),
      builder: (context, trustSnapshot) {
        if (!trustSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final trusts = trustSnapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trusts.length,
          itemBuilder: (context, index) {
            final trust = trusts[index];
            return _buildArchivedRequests(context, trust);
          },
        );
      },
    );
  }

  Widget _buildArchivedRequests(BuildContext context, TrustModel trust) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('trusts')
          .doc(trust.trustId)
          .collection('notifications')
          .where('status', whereIn: ['approved', 'rejected'])
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
              child: Text(
                trust.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: digilukSubTextColor,
                ),
              ),
            ),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? '';
              final userName = data['userName'] ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    status == 'approved' ? Icons.check_circle : Icons.cancel,
                    color: status == 'approved' ? Colors.green : Colors.red,
                  ),
                  title: Text('$userName - $status',
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    formatTimeAgo(DateTime.fromMillisecondsSinceEpoch(
                        data['decidedAt'] ?? DateTime.now().millisecondsSinceEpoch)),
                    style: const TextStyle(
                        fontSize: 11, color: digilukSubTextColor),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMyAlertsTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const EmptyState(
            title: 'No Alerts',
            subtitle: 'You will be notified when your join requests are approved or rejected',
            icon: Icons.notifications_none,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] ?? '';
            final trustName = data['trustName'] ?? '';
            final isApproved = type == 'join_approved';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: isApproved ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  isApproved
                      ? 'Approved: $trustName'
                      : 'Rejected: $trustName',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  formatTimeAgo(DateTime.fromMillisecondsSinceEpoch(
                      data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch)),
                  style: const TextStyle(
                      fontSize: 11, color: digilukSubTextColor),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
