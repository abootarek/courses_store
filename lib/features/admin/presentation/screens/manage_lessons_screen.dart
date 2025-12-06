import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/lesson_model.dart';
import '../cubit/admin_cubit.dart';
import '../cubit/admin_state.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ManageLessonsScreen extends StatelessWidget {
  final CourseModel course;

  const ManageLessonsScreen({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminCubit>()..loadLessons(course.id),
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          title: Text('Manage Lessons - ${course.title}'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.push('/add-edit-lesson', extra: {
              'courseId': course.id,
              'lesson': null,
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Lesson'),
        ),
        body: BlocBuilder<AdminCubit, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AdminError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AdminCubit>().loadLessons(course.id);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is LessonsLoaded) {
              if (state.lessons.isEmpty) {
                return const Center(
                  child: Text('No lessons yet. Add your first lesson!'),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<AdminCubit>().loadLessons(course.id),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = state.lessons[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _playVideo(context, lesson.videoUrl),
                        leading: CircleAvatar(
                          child: Text(lesson.title[0]),
                        ),
                        title: Text(lesson.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDuration(lesson.duration)),
                            const SizedBox(height: 4),
                            _ExpandableText(
                              text: lesson.description,
                              maxLines: 2,
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push('/add-edit-lesson', extra: {
                                'courseId': course.id,
                                'lesson': lesson,
                              });
                            } else if (value == 'delete') {
                              _showDeleteDialog(context, lesson);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context, LessonModel lesson) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: Text('Are you sure you want to delete "${lesson.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<AdminCubit>()
                  .deleteLesson(lesson.id, lesson.courseId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _playVideo(BuildContext context, String videoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            _VideoPlayerDialog(videoUrl: videoUrl),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerDialog({required this.videoUrl});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (videoId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
    } else {
      _isYoutube = false;
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube) {
      if (_youtubeController != null) {
        return YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.amber,
          progressColors: const ProgressBarColors(
            playedColor: Colors.amber,
            handleColor: Colors.amberAccent,
          ),
        );
      }
    } else {
      if (_chewieController != null &&
          _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      }
    }

    return const Center(child: CircularProgressIndicator());
  }
}

// Expandable Text Widget for Lesson Descriptions
class _ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const _ExpandableText({
    required this.text,
    this.maxLines = 2,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _isExpanded ? null : widget.maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 50) // Show button only for long text
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? 'See less' : 'See more',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
