import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ad_service.dart';
import '../models/post_model.dart';
import '../models/state_model.dart';
import '../widgets/post_card.dart';
import 'detail_screen.dart';

class StateWiseScreen extends StatefulWidget {
  const StateWiseScreen({super.key});

  @override
  State<StateWiseScreen> createState() => _StateWiseScreenState();
}

class _StateWiseScreenState extends State<StateWiseScreen> {
  late Future<List<StateModel>> _statesFuture;

  @override
  void initState() {
    super.initState();
    _statesFuture = ApiService().fetchAllStateModels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State Wise Jobs'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      bottomNavigationBar: const BottomAdBanner(),
      body: FutureBuilder<List<StateModel>>(
        future: _statesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No states found'));
          }

          final states = snapshot.data!;

          if (states.isEmpty) {
            return const Center(child: Text('No state jobs found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: states.length,
            itemBuilder: (context, index) {
              final stateItem = states[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: Icon(
                    Icons.location_city,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(
                    stateItem.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: [
                    FutureBuilder<List<PostModel>>(
                      future: ApiService().fetchPostsByState(stateItem.id, altParam: stateItem.name),
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          );
                        } else if (postSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error: ${postSnapshot.error}'),
                          );
                        } else if (!postSnapshot.hasData || postSnapshot.data!.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No jobs in this state'),
                          );
                        }
                        final posts = postSnapshot.data!
                            .where((p) => p.state.isNotEmpty)
                            .toList();

                        if (posts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No jobs in this state'),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          itemBuilder: (context, postIndex) {
                            final card = PostCard(
                              post: posts[postIndex],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(slug: posts[postIndex].slug),
                                  ),
                                );
                              },
                            );
                            if (postIndex > 0 && postIndex % 3 == 0) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const FeedAdBanner(),
                                  card,
                                ],
                              );
                            }
                            return card;
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}