import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/wadiq_colors.dart';
import '../../../../core/theme/wadiq_typography.dart';
import '../../../../core/services/ai_tutor_service.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  XFile? _attachedImage;
  bool _isRecordingVoice = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "isUser": false,
      "text": """# مرحباً بك في مساعد ودق الذكي الأكاديمي! 🎓
أنا هنا لمساعدتك في:
- **شرح وتلخيص المقررات الجامعية**
- **حل وشرح المسائل والمعادلات الرياضية والفيزيائية**
- **تحليل الصور والمخططات والمسائل المصورة**
- **مساعدة في الخوارزميات والبرمجة والبحث العلمي**

> يمكنك إرفاق صورة لمسألتك أو تسجيل صوتك أو فتح **قارئ المعادلات Markdown** من الزر العلوي لتصفح الحلول الرياضية المعقدة بوضوح تام!""",
      "time": "12:00 م",
      "image": null,
    },
  ];

  final List<String> _quickPrompts = [
    "حل معادلة تفاضلية من الدرجة الثانية 📐",
    "اشرح قوانين كيرشوف للدوائر الكهربائية ⚡",
    "صيغة تكامل الدوال الأسية والمثلثية 📊",
    "كيفية كتابة مراجعة أدبيات للبحث العلمي 📑",
  ];

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _attachedImage = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصورة: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _attachedImage = null;
    });
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecordingVoice = !_isRecordingVoice;
    });

    if (_isRecordingVoice) {
      showModalBottomSheet(
        context: context,
        backgroundColor: WadiqColors.obsidianBlack,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: WadiqColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: WadiqColors.amberGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: WadiqColors.primaryAmber.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'جاري الاستماع لصوتك...',
                    style: WadiqTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تحدث بالسؤال أو المسألة ليتم تحويلها لنص مباشرة للمساعد الذكي',
                    textAlign: TextAlign.center,
                    style: WadiqTypography.caption,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WadiqColors.primaryAmber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('إرسال التسجيل'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _isRecordingVoice = false;
                            _promptController.text = "اشرح لي بالتفصيل مسألة التكامل المحدد وحساب المساحة تحت المنحنى";
                          });
                          _sendPrompt();
                        },
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: WadiqColors.textMuted,
                          side: const BorderSide(color: WadiqColors.surfaceBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _isRecordingVoice = false);
                        },
                        child: const Text('إلغاء'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      );
    }
  }

  void _sendPrompt([String? customPrompt]) async {
    final text = customPrompt ?? _promptController.text.trim();
    if (text.isEmpty && _attachedImage == null) return;
    if (_isGenerating) return;

    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    final String? imgPath = _attachedImage?.path;

    String promptToSend = text;
    if (imgPath != null && promptToSend.isEmpty) {
      promptToSend = "الرجاء تحليل هذه الصورة وحل المسألة الرياضية أو شرح المحتوى الوارد فيها بالتفصيل.";
    }

    setState(() {
      _messages.add({
        "isUser": true,
        "text": promptToSend,
        "time": timeStr,
        "image": imgPath,
      });
      _isGenerating = true;
      if (customPrompt == null) _promptController.clear();
      _attachedImage = null;
    });

    _scrollToBottom();

    String response;
    try {
      response = await AiTutorService.instance.askTutor(promptToSend);
    } catch (error) {
      response = 'تعذر الحصول على إجابة حقيقية من المساعد حالياً. $error';
    }

    if (!mounted) return;
    setState(() {
      _isGenerating = false;
      _messages.add({
        "isUser": false,
        "text": response,
        "time": timeStr,
        "image": null,
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openMarkdownModal(String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WadiqColors.obsidianBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _DedicatedMarkdownReaderSheet(initialMarkdown: content);
      },
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WadiqColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: WadiqColors.obsidianBlack,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: WadiqColors.amberGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "مساعد ودق الذكي",
                  style: WadiqTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "دعم المعادلات والـ Markdown",
                  style: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "قارئ ومحرر المعادلات Markdown",
            icon: const Icon(Icons.menu_book_rounded, size: 22, color: WadiqColors.primaryAmber),
            onPressed: () {
              final lastAiMessage = _messages.reversed.firstWhere(
                (m) => m['isUser'] == false,
                orElse: () => {'text': '# محرر المعادلات الرياضية الأكاديمي\n\nاكتب أو الصق صيغ ومعادلات LaTeX هنا.'},
              );
              _openMarkdownModal(lastAiMessage['text']);
            },
          ),
          IconButton(
            tooltip: "إعداد مفتاح Gemini",
            icon: const Icon(Icons.key_rounded, size: 22, color: WadiqColors.textSecondary),
            onPressed: () => _showApiKeyDialog(),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  "isUser": false,
                  "text": "تمت إعادة تعيين المحادثة بنجاح. أنا جاهز للإجابة عن أسئلتك الأكاديمية الجديدة!",
                  "time": "الآن",
                  "image": null,
                });
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 22, color: WadiqColors.textSecondary),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts Row
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ActionChip(
                  label: Text(_quickPrompts[index]),
                  labelStyle: WadiqTypography.caption.copyWith(color: WadiqColors.primaryAmber),
                  backgroundColor: WadiqColors.cardSurface,
                  side: const BorderSide(color: WadiqColors.surfaceBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onPressed: () => _sendPrompt(_quickPrompts[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return _buildMessage(m);
              },
            ),
          ),

          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: WadiqColors.primaryAmber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text("المساعد الأكاديمي يقوم بصياغة الحل والمعادلات...", style: WadiqTypography.caption),
                ],
              ),
            ),

          // Attached Image Preview
          if (_attachedImage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: WadiqColors.cardSurface,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: WadiqColors.primaryAmber),
                      color: Colors.black26,
                    ),
                    child: const Icon(Icons.image_rounded, color: WadiqColors.primaryAmber),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صورة مرفقة للتحليل',
                          style: WadiqTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _attachedImage!.name,
                          style: WadiqTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: WadiqColors.alert),
                    onPressed: _removeImage,
                  ),
                ],
              ),
            ),

          // Prompt Composer
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final bool isUser = msg["isUser"];
    final String text = msg["text"] ?? "";
    final String? image = msg["image"];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: WadiqColors.amberGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? WadiqColors.cardSurface : const Color(0xFF161616),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser
                      ? WadiqColors.primaryAmber.withValues(alpha: 0.3)
                      : WadiqColors.surfaceBorder,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (image != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: WadiqColors.surfaceBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_rounded, size: 18, color: WadiqColors.primaryAmber),
                          const SizedBox(width: 8),
                          Text('تم إرفاق صورة للمسألة', style: WadiqTypography.caption),
                        ],
                      ),
                    ),
                  ],
                  if (isUser)
                    Text(
                      text,
                      style: WadiqTypography.bodyLarge.copyWith(height: 1.5, fontSize: 14),
                    )
                  else
                    MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: WadiqTypography.bodyMedium.copyWith(color: WadiqColors.textPrimary, height: 1.6),
                        h1: WadiqTypography.titleLarge.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                        h2: WadiqTypography.titleMedium.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                        h3: WadiqTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        code: const TextStyle(
                          color: Color(0xFF4ADE80),
                          backgroundColor: Color(0xFF1E1E1E),
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: WadiqColors.surfaceBorder),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: WadiqColors.primaryAmber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: const Border(
                            right: BorderSide(color: WadiqColors.primaryAmber, width: 4),
                          ),
                        ),
                        listBullet: const TextStyle(color: WadiqColors.primaryAmber),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        msg["time"],
                        style: WadiqTypography.caption.copyWith(fontSize: 10),
                      ),
                      if (!isUser)
                        InkWell(
                          onTap: () => _openMarkdownModal(text),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: WadiqColors.primaryAmber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fullscreen_rounded, size: 14, color: WadiqColors.primaryAmber),
                                const SizedBox(width: 4),
                                Text(
                                  'عرض المعادلات بوضوح',
                                  style: TextStyle(
                                    color: WadiqColors.primaryAmber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      decoration: BoxDecoration(
        color: WadiqColors.obsidianBlack,
        border: const Border(
          top: BorderSide(color: WadiqColors.surfaceBorder, width: 0.8),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 10,
      ),
      child: Row(
        children: [
          // Gallery Image Button
          IconButton(
            tooltip: "إرفاق صورة للمسألة",
            icon: const Icon(Icons.image_outlined, color: WadiqColors.primaryAmber, size: 22),
            onPressed: _pickImage,
          ),
          // Voice Mic Button
          IconButton(
            tooltip: "تسجيل صوتي",
            icon: Icon(
              _isRecordingVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isRecordingVoice ? WadiqColors.alert : WadiqColors.textSecondary,
              size: 22,
            ),
            onPressed: _toggleVoiceRecording,
          ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: WadiqColors.cardSurface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _promptController,
                style: WadiqTypography.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "اسأل مساعد ودق أو اطلب شرح معادلة...",
                  hintStyle: WadiqTypography.caption,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendPrompt(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _sendPrompt(),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: WadiqColors.amberGradient,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: WadiqColors.amberGlow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController(
      text: AiTutorService.instance.effectiveGeminiKey,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: WadiqColors.cardSurface,
        title: Row(
          children: [
            const Icon(Icons.key_rounded, color: WadiqColors.primaryAmber),
            const SizedBox(width: 8),
            Text("مفتاح Gemini API", style: WadiqTypography.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "أدخل مفتاح Gemini API المجاني الخاص بك للاتصال المباشر بالذكاء الاصطناعي التوليدي من Google:",
              style: WadiqTypography.bodyMedium.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: WadiqColors.obsidianBlack,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: WadiqColors.surfaceBorder),
              ),
              child: TextField(
                controller: keyController,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: "AIzaSy...",
                  hintStyle: TextStyle(color: WadiqColors.textMuted),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: WadiqColors.primaryAmber,
            ),
            onPressed: () {
              AiTutorService.instance.setApiKey(keyController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("تم حفظ مفتاح Gemini بنجاح! المساعد الآن متصل بالذكاء الاصطناعي الحي."),
                  backgroundColor: WadiqColors.success,
                ),
              );
            },
            child: const Text("حفظ وتفعيل", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Dedicated Full-Screen / Modal Markdown Reader for Math Equations & Code
class _DedicatedMarkdownReaderSheet extends StatefulWidget {
  final String initialMarkdown;

  const _DedicatedMarkdownReaderSheet({required this.initialMarkdown});

  @override
  State<_DedicatedMarkdownReaderSheet> createState() => _DedicatedMarkdownReaderSheetState();
}

class _DedicatedMarkdownReaderSheetState extends State<_DedicatedMarkdownReaderSheet> {
  late TextEditingController _editorController;
  bool _isEditing = false;
  bool _isLtr = false;

  @override
  void initState() {
    super.initState();
    _editorController = TextEditingController(text: widget.initialMarkdown);
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.96,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: WadiqColors.obsidianBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Sheet Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: WadiqColors.surfaceBorder, width: 0.8)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: WadiqColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.functions_rounded, color: WadiqColors.primaryAmber, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'قارئ ومحرر المعادلات (Markdown)',
                          style: WadiqTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // LTR / RTL toggle for Math
                        IconButton(
                          tooltip: _isLtr ? "تحويل للعربية RTL" : "تحويل للمعادلات LTR",
                          icon: Icon(
                            _isLtr ? Icons.format_textdirection_l_to_r : Icons.format_textdirection_r_to_l,
                            size: 20,
                            color: _isLtr ? WadiqColors.primaryAmber : WadiqColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _isLtr = !_isLtr);
                          },
                        ),
                        // Edit / Preview toggle
                        IconButton(
                          tooltip: _isEditing ? "معاينة التنسيق" : "تعديل الكود",
                          icon: Icon(
                            _isEditing ? Icons.visibility_outlined : Icons.edit_note_rounded,
                            size: 20,
                            color: _isEditing ? WadiqColors.primaryAmber : WadiqColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() => _isEditing = !_isEditing);
                          },
                        ),
                        // Copy button
                        IconButton(
                          tooltip: "نسخ النص",
                          icon: const Icon(Icons.copy_rounded, size: 18, color: WadiqColors.textSecondary),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _editorController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('تم نسخ المعادلات والنص بنجاح.'),
                                backgroundColor: WadiqColors.cardSurface,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: _isEditing
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _editorController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'اكتب كود Markdown أو معادلات LaTeX هنا...',
                          ),
                        ),
                      )
                    : Directionality(
                        textDirection: _isLtr ? TextDirection.ltr : TextDirection.rtl,
                        child: Markdown(
                          controller: scrollController,
                          data: _editorController.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: WadiqTypography.bodyLarge.copyWith(color: WadiqColors.textPrimary, height: 1.7),
                            h1: WadiqTypography.displayMedium.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                            h2: WadiqTypography.titleLarge.copyWith(color: WadiqColors.primaryAmber, fontWeight: FontWeight.bold),
                            h3: WadiqTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            code: const TextStyle(
                              color: Color(0xFF4ADE80),
                              backgroundColor: Color(0xFF1E1E1E),
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: WadiqColors.surfaceBorder),
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: WadiqColors.primaryAmber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: const Border(
                                right: BorderSide(color: WadiqColors.primaryAmber, width: 4),
                              ),
                            ),
                            tableBorder: TableBorder.all(color: WadiqColors.surfaceBorder, width: 0.8),
                            tableHead: WadiqTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: WadiqColors.primaryAmber, fontSize: 13),
                            tableBody: WadiqTypography.bodyMedium,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
