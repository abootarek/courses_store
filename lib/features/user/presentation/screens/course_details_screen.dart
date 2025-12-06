import 'package:chewie/chewie.dart';
import 'package:course_store/core/constants/app_constants.dart';
import 'package:course_store/data/models/lesson_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/widgets/base64_image.dart';
import '../../../../data/models/course_model.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  Future<void> _handlePurchase(BuildContext context) async {
    try {
      final authRepo = getIt<AuthRepository>();
      final currentUser = await authRepo.getCurrentUser();

      if (currentUser == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create order in Firestore
      final order = OrderModel(
        id: const Uuid().v4(),
        userId: currentUser.id,
        userEmail: currentUser.email,
        courseId: widget.course.id,
        courseTitle: widget.course.title,
        coursePrice: widget.course.discountedPrice, // Use discounted price
        status: 'pending',
        createdAt: DateTime.now(),
      );

      if (context.mounted) {
        await context.read<HomeCubit>().createOrder(order);
        
        // WhatsApp message
        final message = Uri.encodeComponent(
            'مرحبًا، أريد شراء كورس "${widget.course.title}" بسعر ${widget.course.discountedPrice.toStringAsFixed(2)}.\n\nالبريد الإلكتروني: ${currentUser.email}');

        // WhatsApp number (YOUR NUMBER)
        final whatsappUrl = 'https://wa.me/201150171656?text=$message';

        final uri = Uri.parse(whatsappUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not open WhatsApp'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        // Refresh details to show pending status
        if (context.mounted) {
          context.read<HomeCubit>().loadCourseDetails(widget.course.id);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..loadCourseDetails(widget.course.id),
      child: Scaffold(
        body: BlocConsumer<HomeCubit, HomeState>(
          listener: (context, state) {
            if (state is OrderCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order created! Opening WhatsApp...'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            bool isPurchased = false;
            bool isPending = false;
            bool isRejected = false;
            List<LessonModel> lessons = [];
            bool isLoading = true;

            if (state is CourseDetailsLoaded) {
              isPurchased = state.isPurchased;
              isPending = state.isPending;
              isRejected = state.isRejected;
              lessons = state.lessons;
              isLoading = false;
            } else if (state is HomeError) {
              isLoading = false;
            }

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                // App Bar with Course Image
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: widget.course.imageBase64.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Base64Image(
                                base64String: widget.course.imageBase64,
                                fit: BoxFit.cover,
                              ),
                              // Dark gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 80),
                          ),
                  ),
                ),
                // Course Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Price
                        Text(
                          widget.course.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$${widget.course.price.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const Spacer(),
                            Icon(Icons.play_circle_outline,
                                color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.course.lessonsCount} lessons',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Description
                        Text(
                          'About this course',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ExpandableText(
                          text: widget.course.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        // Preview Video (if available)
                        if (widget.course.videoUrl.isNotEmpty) ...[
                          Text(
                            'Preview',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _VideoPreview(
                                  videoUrl: widget.course.videoUrl),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        // Purchase Button or Status
                        if (isPurchased)
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green, width: 2),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'You own this course',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (lessons.isNotEmpty)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _playVideo(context, lessons.first.videoUrl);
                                    },
                                    icon: const Icon(Icons.play_circle_fill, size: 28),
                                    label: const Text(
                                      'Start Watching',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        else if (isRejected)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel,
                                    color: Colors.red, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  'Order Rejected',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isPending)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange, width: 2),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty,
                                    color: Colors.orange, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  'Request Pending Approval',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _handlePurchase(context),
                              icon: const Icon(Icons.shopping_cart,
                                  size: 24, color: Colors.white),
                              label: Text(
                                'Buy via WhatsApp (\$${widget.course.discountedPrice.toStringAsFixed(2)})',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                        // Lessons
                        Text(
                          'Course Content',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        if (lessons.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('No lessons available yet.'),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: lessons.length,
                            itemBuilder: (context, index) {
                              final lesson = lessons[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isPurchased
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    lesson.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: ExpandableText(
                                      text: lesson.description,
                                      maxLines: 2,
                                    ),
                                  ),
                                  trailing: Icon(
                                    isPurchased
                                        ? Icons.play_circle_filled
                                        : Icons.lock,
                                    color: isPurchased
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    size: 32,
                                  ),
                                  onTap: () {
                                    if (isPurchased) {
                                      _playVideo(context, lesson.videoUrl);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please purchase the course to watch lessons'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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

// Video Preview Widget
class _VideoPreview extends StatefulWidget {
  final String videoUrl;

  const _VideoPreview({required this.videoUrl});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  YoutubePlayerController? _youtubeController;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    if (videoId != null) {
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutube && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
      );
    }
    return const Center(
      child: Text(
        'Preview not available',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

// Video Player Dialog
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

  bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Future<void> _initializePlayer() async {
    if (_isYoutubeUrl(widget.videoUrl)) {
      _isYoutube = true;
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        );
        if (mounted) setState(() {});
      }
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

      if (mounted) setState(() {});
    }
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
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      if (_chewieController != null &&
          _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }
  }
}

// Expandable Text Widget
class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle? style;

  const ExpandableText({
    super.key,
    required this.text,
    this.maxLines = 2,
    this.style,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _isExpanded ? null : widget.maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (widget.text.length > 100) // Show button only for long text
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
                ),
              ),
            ),
          ),
      ],
    );
  }
}
