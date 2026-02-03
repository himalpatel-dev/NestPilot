import 'package:flutter/material.dart';
import 'package:nest_pilot_mobile/models/community_models.dart';
import 'package:nest_pilot_mobile/services/community_service.dart';
import 'package:nest_pilot_mobile/services/auth_service.dart';
import 'package:nest_pilot_mobile/config/roles.dart';
import '../../../models/user_model.dart';
import '../../secretary/poll_create_screen.dart';

class PollListScreen extends StatefulWidget {
  const PollListScreen({super.key});

  @override
  State<PollListScreen> createState() => _PollListScreenState();
}

class _PollListScreenState extends State<PollListScreen> {
  final CommunityService _service = CommunityService();
  final AuthService _authService = AuthService();

  List<Poll> _polls = [];
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserAndPolls();
  }

  Future<void> _fetchUserAndPolls() async {
    final user = await _authService.getMe();
    if (mounted) {
      setState(() => _currentUser = user);
    }
    _fetchPolls();
  }

  Future<void> _fetchPolls() async {
    try {
      final polls = await _service.getActivePolls();
      if (mounted) {
        setState(() {
          _polls = polls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _vote(int pollId, int optionId) async {
    try {
      await _service.votePoll(pollId, optionId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vote recorded!')));
      _fetchPolls();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showResults(int pollId) async {
    try {
      final data = await _service.getPollResults(pollId);
      final results = (data['results'] as List);
      final totalVotes = results.fold<int>(
        0,
        (sum, item) => sum + (item['count'] as int),
      );
      final totalMembers = data['totalMembers'] ?? 0;
      final participation = totalMembers > 0
          ? (totalVotes / totalMembers * 100).toStringAsFixed(1)
          : '0.0';

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Poll Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['question'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total Votes',
                                totalVotes.toString(),
                              ),
                              _buildStatItem(
                                'Total Members',
                                totalMembers.toString(),
                              ),
                              _buildStatItem(
                                'Participation',
                                '$participation%',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...results.map((r) {
                          final count = r['count'] as int;
                          final percentage = totalVotes > 0
                              ? (count / totalVotes)
                              : 0.0;
                          final percentageText =
                              '${(percentage * 100).toStringAsFixed(1)}%';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      r['option'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      percentageText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Stack(
                                  children: [
                                    Container(
                                      height: 12,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage,
                                      child: Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.blue,
                                              Colors.lightBlueAccent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$count votes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching results: $e')));
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _currentUser?.role == UserRoles.societyAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Polls')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _polls.isEmpty
          ? const Center(child: Text('No active polls'))
          : ListView.builder(
              itemCount: _polls.length,
              itemBuilder: (context, index) {
                final poll = _polls[index];
                final hasVoted = poll.votes != null && poll.votes!.isNotEmpty;

                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poll.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (poll.description != null) ...[
                          const SizedBox(height: 8),
                          Text(poll.description!),
                        ],
                        const SizedBox(height: 16),
                        if (isAdmin) ...[
                          const Text(
                            'Admin View - Monitor Voting',
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showResults(poll.id),
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('View Live Results'),
                          ),
                        ] else if (hasVoted) ...[
                          const Text(
                            'You have voted',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showResults(poll.id),
                            icon: const Icon(Icons.bar_chart),
                            label: const Text('View Results'),
                          ),
                        ] else ...[
                          ...poll.options!.map(
                            (opt) => RadioListTile<int>(
                              title: Text(opt.optionText),
                              value: opt.id,
                              groupValue: null,
                              onChanged: (val) => _vote(poll.id, val!),
                            ),
                          ),
                        ],
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Ends on: ${poll.endDate.split('T')[0]}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PollCreateScreen(),
                  ),
                );
                if (res == true) _fetchPolls();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
