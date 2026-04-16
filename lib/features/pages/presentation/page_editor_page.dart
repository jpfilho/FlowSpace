import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/index.dart';
import '../../auth/domain/data_providers.dart';

// ─────────────────────────────────────────────────────────────
// Page Editor
// ─────────────────────────────────────────────────────────────

class PageEditorPage extends ConsumerStatefulWidget {
  final String pageId;
  const PageEditorPage({super.key, required this.pageId});

  @override
  ConsumerState<PageEditorPage> createState() => _PageEditorPageState();
}

class _PageEditorPageState extends ConsumerState<PageEditorPage> {
  late TextEditingController _titleCtrl;
  Timer? _titleDebounce;
  bool _titleLoaded = false;
  // Track focus nodes for each block by blockId
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _titleDebounce?.cancel();
    for (final fn in _focusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  FocusNode _focusFor(String id) {
    return _focusNodes.putIfAbsent(id, FocusNode.new);
  }

  void _onTitleChanged(String value) {
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(pagesProvider.notifier).updatePage(widget.pageId, title: value);
    });
  }

  Future<void> _addBlock(String type, int afterPosition) async {
    await ref.read(blocksProvider(widget.pageId).notifier).insertBlock(
          pageId: widget.pageId,
          type: type,
          position: afterPosition + 1,
        );
  }

  Future<void> _deleteBlock(String blockId) async {
    await ref
        .read(blocksProvider(widget.pageId).notifier)
        .deleteBlock(blockId);
  }

  Future<void> _updateBlockContent(
      String blockId, Map<String, dynamic> content) async {
    await ref
        .read(blocksProvider(widget.pageId).notifier)
        .updateBlock(blockId, content: content);
  }

  Future<void> _changeBlockType(String blockId, String newType) async {
    await ref
        .read(blocksProvider(widget.pageId).notifier)
        .updateBlock(blockId, type: newType);
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(pageMetaProvider(widget.pageId));
    final blocksAsync = ref.watch(blocksProvider(widget.pageId));
    final isDesktop = Responsive.isDesktop(context);
    final maxWidth = isDesktop ? 720.0 : double.infinity;

    return Scaffold(
      backgroundColor: context.cBackground,
      appBar: _EditorAppBar(
        pageId: widget.pageId,
        pageAsync: pageAsync,
        onBack: () => context.go('/pages'),
      ),
      body: blocksAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
            child: Text('Erro: $e', style: context.bodySm)),
        data: (blocks) {
          // Load title once
          if (!_titleLoaded) {
            pageAsync.whenData((page) {
              if (page != null) {
                _titleCtrl.text = page.title == 'Sem título' ? '' : page.title;
                _titleLoaded = true;
              }
            });
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ReorderableListView.builder(
                padding: EdgeInsets.only(
                  left: isDesktop ? AppSpacing.sp32 : AppSpacing.sp16,
                  right: isDesktop ? AppSpacing.sp32 : AppSpacing.sp16,
                  top: AppSpacing.sp32,
                  bottom: 120.0,
                ),
                buildDefaultDragHandles: false,
                header: _TitleSection(
                  controller: _titleCtrl,
                  onChanged: _onTitleChanged,
                  onEnter: () {
                    // Create first block on Enter in title
                    if (blocks.isEmpty) {
                      _addBlock('paragraph', -1);
                    } else {
                      _focusFor(blocks.first.id).requestFocus();
                    }
                  },
                ),
                onReorder: (oldIndex, newIndex) {
                  ref
                      .read(blocksProvider(widget.pageId).notifier)
                      .reorder(oldIndex, newIndex);
                },
                itemCount: blocks.length,
                itemBuilder: (_, i) {
                  final block = blocks[i];
                  final focusNode = _focusFor(block.id);
                  return _BlockWidget(
                    key: ValueKey(block.id),
                    block: block,
                    index: i,
                    focusNode: focusNode,
                    isDesktop: isDesktop,
                    onContentChanged: (content) =>
                        _updateBlockContent(block.id, content),
                    onDelete: () => _deleteBlock(block.id),
                    onAddAfter: (type) => _addBlock(type, block.position),
                    onChangeType: (type) =>
                        _changeBlockType(block.id, type),
                    onEnter: () {
                      // Create new paragraph after this block
                      _addBlock('paragraph', block.position).then((_) {
                        // Focus next block after state updates
                        final updatedBlocks =
                            ref.read(blocksProvider(widget.pageId)).valueOrNull ?? [];
                        final nextIndex = updatedBlocks.indexWhere(
                            (b) => b.position == block.position + 1);
                        if (nextIndex >= 0) {
                          _focusFor(updatedBlocks[nextIndex].id).requestFocus();
                        }
                      });
                    },
                    onFocusPrev: () {
                      if (i > 0) {
                        _focusFor(blocks[i - 1].id).requestFocus();
                      }
                    },
                    onFocusNext: () {
                      if (i < blocks.length - 1) {
                        _focusFor(blocks[i + 1].id).requestFocus();
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
      // Bottom FAB: add block
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBlockMenu(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Bloco'),
        elevation: 2,
      ),
    );
  }

  void _showAddBlockMenu(BuildContext context) {
    final blocksAsync = ref.read(blocksProvider(widget.pageId));
    final blocks = blocksAsync.valueOrNull ?? [];
    final lastPos = blocks.isEmpty ? -1 : blocks.last.position;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlockTypeMenu(
        onSelect: (type) {
          Navigator.pop(context);
          _addBlock(type, lastPos);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────

class _EditorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String pageId;
  final AsyncValue<PageData?> pageAsync;
  final VoidCallback onBack;

  const _EditorAppBar({
    required this.pageId,
    required this.pageAsync,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor:
          context.isDark ? AppColors.surfaceDark : AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: onBack,
        color: context.cTextPrimary,
      ),
      title: pageAsync.when(
        data: (page) => Row(children: [
          if (page?.icon != null && page!.icon!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(page.icon!, style: const TextStyle(fontSize: 16)),
            ),
          Flexible(
            child: Text(
              page?.title.isEmpty ?? true ? 'Sem título' : page!.title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const Text('Página'),
      ),
      actions: [
        pageAsync.maybeWhen(
          data: (page) => page != null
              ? IconButton(
                  icon: Icon(
                    page.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: page.isFavorite
                        ? AppColors.warning
                        : context.cTextMuted,
                  ),
                  tooltip: page.isFavorite
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
                  onPressed: () => ref
                      .read(pagesProvider.notifier)
                      .updatePage(pageId, isFavorite: !page.isFavorite),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Title Section
// ─────────────────────────────────────────────────────────────

class _TitleSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onEnter;

  const _TitleSection({
    required this.controller,
    required this.onChanged,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp24),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            onEnter();
          }
        },
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: null,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          decoration: InputDecoration(
            hintText: 'Sem título',
            hintStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: context.cTextMuted.withValues(alpha: 0.4),
              height: 1.2,
              letterSpacing: -0.5,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Block Widget
// ─────────────────────────────────────────────────────────────

class _BlockWidget extends ConsumerStatefulWidget {
  final BlockData block;
  final int index;
  final FocusNode focusNode;
  final bool isDesktop;
  final ValueChanged<Map<String, dynamic>> onContentChanged;
  final VoidCallback onDelete;
  final ValueChanged<String> onAddAfter;
  final ValueChanged<String> onChangeType;
  final VoidCallback onEnter;
  final VoidCallback onFocusPrev;
  final VoidCallback onFocusNext;

  const _BlockWidget({
    required super.key,
    required this.block,
    required this.index,
    required this.focusNode,
    required this.isDesktop,
    required this.onContentChanged,
    required this.onDelete,
    required this.onAddAfter,
    required this.onChangeType,
    required this.onEnter,
    required this.onFocusPrev,
    required this.onFocusNext,
  });

  @override
  ConsumerState<_BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends ConsumerState<_BlockWidget> {
  late TextEditingController _ctrl;
  bool _hovering = false;
  bool _showSlash = false;
  Timer? _saveDebounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.block.text);
  }

  @override
  void didUpdateWidget(_BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update if block content changed externally (not from typing)
    if (!widget.focusNode.hasFocus &&
        widget.block.text != oldWidget.block.text) {
      _ctrl.text = widget.block.text;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    // Slash command detection
    if (value == '/') {
      setState(() => _showSlash = true);
      return;
    }
    if (_showSlash && !value.startsWith('/')) {
      setState(() => _showSlash = false);
    }

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 500), () {
      final b = widget.block;
      final newContent = Map<String, dynamic>.from(b.content)
        ..['text'] = value;
      widget.onContentChanged(newContent);
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      widget.onEnter();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrl.text.isEmpty) {
      widget.onDelete();
      widget.onFocusPrev();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onFocusPrev();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onFocusNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Drag handle (desktop, visible on hover)
          if (widget.isDesktop)
            Visibility(
              visible: _hovering,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: ReorderableDragStartListener(
                index: widget.index,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  child: Icon(Icons.drag_indicator_rounded,
                      size: 16, color: context.cTextMuted),
                ),
              ),
            )
          else
            const SizedBox(width: 4),

          // Slash-slash menu
          if (_showSlash)
            Expanded(
              child: _SlashMenu(
                onSelect: (type) {
                  setState(() {
                    _showSlash = false;
                    _ctrl.text = '';
                  });
                  widget.onChangeType(type);
                },
                onDismiss: () => setState(() => _showSlash = false),
              ),
            )
          else
            // The actual block content
            Expanded(
              child: _buildBlockContent(context),
            ),

          // Block options (hover)
          if (widget.isDesktop)
            Visibility(
              visible: _hovering,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: _BlockMenu(
                  block: widget.block,
                  onChangeType: widget.onChangeType,
                  onDelete: widget.onDelete,
                  onAddAfter: widget.onAddAfter,
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildBlockContent(BuildContext context) {
    switch (widget.block.type) {
      case 'heading1':
        return _buildTextField(context,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w700, height: 1.3));
      case 'heading2':
        return _buildTextField(context,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, height: 1.3));
      case 'heading3':
        return _buildTextField(context,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, height: 1.3));
      case 'bulleted_list':
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 9, right: 8),
            child: Text('•',
                style: TextStyle(
                    fontSize: 16,
                    color: context.cTextPrimary,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(child: _buildTextField(context)),
        ]);
      case 'numbered_list':
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 9, right: 8),
            child: Text('${widget.index + 1}.',
                style: TextStyle(
                    fontSize: 14,
                    color: context.cTextMuted,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(child: _buildTextField(context)),
        ]);
      case 'checklist':
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: GestureDetector(
              onTap: () {
                final newContent =
                    Map<String, dynamic>.from(widget.block.content)
                      ..['checked'] = !widget.block.checked;
                widget.onContentChanged(newContent);
              },
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.block.checked
                      ? AppColors.success
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.block.checked
                        ? AppColors.success
                        : context.cTextMuted,
                    width: 1.5,
                  ),
                ),
                child: widget.block.checked
                    ? const Icon(Icons.check_rounded,
                        size: 12, color: Colors.white)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _buildTextField(context,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.block.checked
                      ? context.cTextMuted
                      : context.cTextPrimary,
                  decoration: widget.block.checked
                      ? TextDecoration.lineThrough
                      : null,
                )),
          ),
        ]);
      case 'quote':
        return Container(
          padding: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          child: _buildTextField(context,
              style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: context.cTextMuted)),
        );
      case 'divider':
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(thickness: 1, height: 1),
        );
      case 'code':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sp14),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: context.isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: widget.focusNode,
            onChanged: _onTextChanged,
            maxLines: null,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.6,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            keyboardType: TextInputType.multiline,
          ),
        );
      case 'image':
        return _ImageBlock(
          block: widget.block,
          onContentChanged: widget.onContentChanged,
        );
      case 'toggle':
        return _ToggleBlock(
          block: widget.block,
          ctrl: _ctrl,
          focusNode: widget.focusNode,
          onTextChanged: _onTextChanged,
          onContentChanged: widget.onContentChanged,
        );
      case 'table':
        return _TableBlock(
          block: widget.block,
          onContentChanged: widget.onContentChanged,
        );
      default: // paragraph
        return _buildTextField(context);
    }
  }

  Widget _buildTextField(BuildContext context, {TextStyle? style}) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: _ctrl,
        focusNode: widget.focusNode,
        onChanged: _onTextChanged,
        maxLines: null,
        style: style ??
            TextStyle(
              fontSize: 15,
              color: context.cTextPrimary,
              height: 1.65,
            ),
        decoration: InputDecoration(
          hintText: widget.block.type == 'paragraph'
              ? "Escreva algo ou '/' para comandos"
              : null,
          hintStyle: TextStyle(
            fontSize: 15,
            color: context.cTextMuted.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Slash Command Menu
// ─────────────────────────────────────────────────────────────

class _SlashMenu extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final VoidCallback onDismiss;

  const _SlashMenu({required this.onSelect, required this.onDismiss});

  static const _items = [
    ('paragraph', 'Parágrafo', Icons.notes_rounded, 'Texto simples'),
    ('heading1', 'Título 1', Icons.title_rounded, 'Grande título'),
    ('heading2', 'Título 2', Icons.title_rounded, 'Título médio'),
    ('heading3', 'Título 3', Icons.title_rounded, 'Título pequeno'),
    ('bulleted_list', 'Lista', Icons.format_list_bulleted_rounded, 'Lista com marcadores'),
    ('numbered_list', 'Lista numerada', Icons.format_list_numbered_rounded, 'Lista numerada'),
    ('checklist', 'Checklist', Icons.check_box_outlined, 'Lista de tarefas'),
    ('quote', 'Citação', Icons.format_quote_rounded, 'Bloco de citação'),
    ('code', 'Código', Icons.code_rounded, 'Bloco de código'),
    ('divider', 'Divisor', Icons.horizontal_rule_rounded, 'Linha divisória'),
    ('image', 'Imagem', Icons.image_rounded, 'Imagem via URL'),
    ('toggle', 'Toggle', Icons.expand_more_rounded, 'Conteúdo dobrável'),
    ('table', 'Tabela', Icons.table_chart_outlined, 'Grade editável'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Text('Tipos de bloco',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.cTextMuted,
                    letterSpacing: 0.5)),
          ),
          ..._items.map((item) {
            final (type, label, icon, desc) = item;
            return InkWell(
              onTap: () => onSelect(type),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(icon,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.cTextPrimary)),
                      Text(desc,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.cTextMuted)),
                    ],
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms).scale(
          begin: const Offset(0.97, 0.97),
          duration: 150.ms,
        );
  }
}

// ─────────────────────────────────────────────────────────────
// Block Type Picker (bottom sheet)
// ─────────────────────────────────────────────────────────────

class _BlockTypeMenu extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _BlockTypeMenu({required this.onSelect});

  static const _groups = [
    ('Texto', [
      ('paragraph', 'Parágrafo', Icons.notes_rounded),
      ('heading1', 'Título 1', Icons.title_rounded),
      ('heading2', 'Título 2', Icons.title_rounded),
      ('heading3', 'Título 3', Icons.title_rounded),
    ]),
    ('Listas', [
      ('bulleted_list', 'Lista com marcadores', Icons.format_list_bulleted_rounded),
      ('numbered_list', 'Lista numerada', Icons.format_list_numbered_rounded),
      ('checklist', 'Checklist', Icons.check_box_outlined),
    ]),
    ('Outros', [
      ('quote', 'Citação', Icons.format_quote_rounded),
      ('code', 'Código', Icons.code_rounded),
      ('divider', 'Divisor', Icons.horizontal_rule_rounded),
      ('image', 'Imagem', Icons.image_rounded),
      ('toggle', 'Toggle', Icons.expand_more_rounded),
      ('table', 'Tabela', Icons.table_chart_outlined),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sp20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.borderDark
                    : AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sp16),
          Text('Inserir bloco',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sp16),
          ..._groups.map((group) {
            final (groupLabel, items) = group;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupLabel.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: context.cTextMuted,
                        letterSpacing: 0.8)),
                const SizedBox(height: AppSpacing.sp8),
                Wrap(
                  spacing: AppSpacing.sp8,
                  runSpacing: AppSpacing.sp8,
                  children: items.map((item) {
                    final (type, label, icon) = item;
                    return InkWell(
                      onTap: () => onSelect(type),
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: context.isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                          ),
                        ),
                        child: Column(children: [
                          Icon(icon,
                              size: 22, color: AppColors.primary),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: context.cTextPrimary),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.sp16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Block context menu (hover ···)
// ─────────────────────────────────────────────────────────────

class _BlockMenu extends StatelessWidget {
  final BlockData block;
  final ValueChanged<String> onChangeType;
  final VoidCallback onDelete;
  final ValueChanged<String> onAddAfter;

  const _BlockMenu({
    required this.block,
    required this.onChangeType,
    required this.onDelete,
    required this.onAddAfter,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded,
          size: 16, color: context.cTextMuted),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        switch (v) {
          case 'delete':
            onDelete();
            break;
          case 'add_below':
            onAddAfter('paragraph');
            break;
          default:
            onChangeType(v);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'add_below',
          child: Row(children: [
            Icon(Icons.add_rounded, size: 16),
            SizedBox(width: 8),
            Text('Adicionar bloco abaixo'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'paragraph',
          child: Text('↳ Parágrafo'),
        ),
        const PopupMenuItem(
          value: 'heading1',
          child: Text('↳ Título 1'),
        ),
        const PopupMenuItem(
          value: 'heading2',
          child: Text('↳ Título 2'),
        ),
        const PopupMenuItem(
          value: 'bulleted_list',
          child: Text('↳ Lista'),
        ),
        const PopupMenuItem(
          value: 'checklist',
          child: Text('↳ Checklist'),
        ),
        const PopupMenuItem(
          value: 'quote',
          child: Text('↳ Citação'),
        ),
        const PopupMenuItem(
          value: 'code',
          child: Text('↳ Código'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline_rounded,
                size: 16, color: AppColors.error),
            SizedBox(width: 8),
            Text('Excluir bloco',
                style: TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image Block Widget
// ─────────────────────────────────────────────────────────────

class _ImageBlock extends StatefulWidget {
  final BlockData block;
  final ValueChanged<Map<String, dynamic>> onContentChanged;

  const _ImageBlock({required this.block, required this.onContentChanged});

  @override
  State<_ImageBlock> createState() => _ImageBlockState();
}

class _ImageBlockState extends State<_ImageBlock> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _altCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final content = widget.block.content;
    _urlCtrl = TextEditingController(text: content['url'] as String? ?? '');
    _altCtrl = TextEditingController(text: content['alt'] as String? ?? '');
    // If no URL yet, start in editing mode
    _editing = (_urlCtrl.text.isEmpty);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _altCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onContentChanged({
      ...widget.block.content,
      'url': _urlCtrl.text.trim(),
      'alt': _altCtrl.text.trim(),
    });
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.block.content['url'] as String? ?? '';
    final alt = widget.block.content['alt'] as String? ?? '';

    if (_editing || url.isEmpty) {
      // ── URL input mode ──────────────────────────────
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sp16),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: context.isDark ? AppColors.borderDark : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.image_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Inserir imagem',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.cTextPrimary)),
            ]),
            const SizedBox(height: AppSpacing.sp12),
            TextField(
              controller: _urlCtrl,
              autofocus: url.isEmpty,
              decoration: InputDecoration(
                hintText: 'URL da imagem (https://...)',
                isDense: true,
                filled: true,
                fillColor: context.isDark
                    ? AppColors.surfaceDark
                    : AppColors.surface,
                prefixIcon: const Icon(Icons.link_rounded, size: 16),
              ),
              style: TextStyle(fontSize: 13, color: context.cTextPrimary),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.sp8),
            TextField(
              controller: _altCtrl,
              decoration: InputDecoration(
                hintText: 'Texto alternativo (opcional)',
                isDense: true,
                filled: true,
                fillColor: context.isDark
                    ? AppColors.surfaceDark
                    : AppColors.surface,
                prefixIcon: const Icon(Icons.text_fields_rounded, size: 16),
              ),
              style: TextStyle(fontSize: 13, color: context.cTextPrimary),
            ),
            const SizedBox(height: AppSpacing.sp12),
            Row(children: [
              if (url.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _editing = false),
                  child: const Text('Cancelar'),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _urlCtrl.text.trim().isEmpty ? null : _save,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Inserir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ],
        ),
      );
    }

    // ── Image preview mode ────────────────────────────
    return GestureDetector(
      onDoubleTap: () => setState(() => _editing = true),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ImageError(
                onRetry: () => setState(() => _editing = true),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: context.isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 8),
                        Text('Carregando imagem...',
                            style: TextStyle(
                                fontSize: 12, color: context.cTextMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Edit overlay on hover
          Positioned(
            top: 8,
            right: 8,
            child: Tooltip(
              message: 'Duplo clique para editar',
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: () => setState(() => _editing = true),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.edit_rounded,
                        size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          // Alt text caption
          if (alt.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.lg)),
                ),
                child: Text(
                  alt,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  final VoidCallback onRetry;
  const _ImageError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_rounded,
              size: 32, color: AppColors.error),
          const SizedBox(height: 8),
          Text('Não foi possível carregar a imagem',
              style: TextStyle(fontSize: 13, color: context.cTextMuted)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.edit_rounded, size: 14),
            label: const Text('Alterar URL'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Toggle Block Widget (collapsible content)
// ─────────────────────────────────────────────────────────────

class _ToggleBlock extends StatefulWidget {
  final BlockData block;
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<Map<String, dynamic>> onContentChanged;

  const _ToggleBlock({
    required this.block,
    required this.ctrl,
    required this.focusNode,
    required this.onTextChanged,
    required this.onContentChanged,
  });

  @override
  State<_ToggleBlock> createState() => _ToggleBlockState();
}

class _ToggleBlockState extends State<_ToggleBlock> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.block.content['expanded'] == true;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onContentChanged({
      ...widget.block.content,
      'expanded': _expanded,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceVariantDark.withValues(alpha: 0.4)
            : AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Toggle header ──────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: _toggle,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: AppAnimations.fast,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 18,
                      color: context.cTextMuted,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.ctrl,
                  focusNode: widget.focusNode,
                  onChanged: widget.onTextChanged,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.cTextPrimary,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Toggle title...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: context.cTextMuted.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          // ── Collapsible content area ───────────────
          AnimatedCrossFade(
            firstChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(38, 0, 12, 12),
              child: Text(
                widget.block.content['inner_text'] as String? ??
                    'Conteúdo do toggle...',
                style: TextStyle(
                  fontSize: 14,
                  color: context.cTextMuted,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: AppAnimations.fast,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Table Block Widget
// ─────────────────────────────────────────────────────────────

class _TableBlock extends StatefulWidget {
  final BlockData block;
  final ValueChanged<Map<String, dynamic>> onContentChanged;

  const _TableBlock({required this.block, required this.onContentChanged});

  @override
  State<_TableBlock> createState() => _TableBlockState();
}

class _TableBlockState extends State<_TableBlock> {
  late List<List<String>> _rows;
  late int _cols;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final content = widget.block.content;
    final rawRows = content['rows'] as List<dynamic>?;
    if (rawRows != null && rawRows.isNotEmpty) {
      _rows = rawRows
          .map((r) => (r as List<dynamic>).map((c) => c.toString()).toList())
          .toList();
      _cols = _rows[0].length;
    } else {
      // Default 3x2 table
      _cols = 3;
      _rows = [
        ['', '', ''],
        ['', '', ''],
      ];
    }
  }

  void _save() {
    widget.onContentChanged({
      ...widget.block.content,
      'rows': _rows,
      'cols': _cols,
    });
  }

  void _addRow() {
    setState(() => _rows.add(List.filled(_cols, '')));
    _save();
  }

  void _addCol() {
    setState(() {
      _cols++;
      for (final row in _rows) {
        row.add('');
      }
    });
    _save();
  }

  void _removeRow(int i) {
    if (_rows.length <= 1) return;
    setState(() => _rows.removeAt(i));
    _save();
  }

  void _removeCol(int j) {
    if (_cols <= 1) return;
    setState(() {
      _cols--;
      for (final row in _rows) {
        row.removeAt(j);
      }
    });
    _save();
  }

  void _updateCell(int row, int col, String val) {
    _rows[row][col] = val;
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final isHeader = widget.block.content['has_header'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Table grid ─────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicWidth(
            child: Table(
              border: TableBorder.all(
                color: context.isDark ? AppColors.borderDark : AppColors.border,
                width: 1,
              ),
              defaultColumnWidth: const FixedColumnWidth(140),
              children: _rows.asMap().entries.map((rowEntry) {
                final ri = rowEntry.key;
                final row = rowEntry.value;
                final isHeaderRow = isHeader && ri == 0;
                return TableRow(
                  decoration: BoxDecoration(
                    color: isHeaderRow
                        ? (context.isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant)
                        : (ri.isEven
                            ? Colors.transparent
                            : (context.isDark
                                ? Colors.white.withValues(alpha: 0.02)
                                : Colors.black.withValues(alpha: 0.01))),
                  ),
                  children: row.asMap().entries.map((cellEntry) {
                    final ci = cellEntry.key;
                    return TableCell(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: TextField(
                          controller: TextEditingController(
                              text: _rows[ri][ci]),
                          onChanged: (v) => _updateCell(ri, ci, v),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isHeaderRow
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: context.cTextPrimary,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          maxLines: null,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
        // ── Control buttons ─────────────────────────
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _TableActionButton(
              icon: Icons.add_rounded,
              label: '+ Linha',
              onTap: _addRow,
            ),
            _TableActionButton(
              icon: Icons.add_rounded,
              label: '+ Coluna',
              onTap: _addCol,
            ),
            if (_rows.length > 1)
              _TableActionButton(
                icon: Icons.remove_rounded,
                label: '- Linha',
                onTap: () => _removeRow(_rows.length - 1),
                danger: true,
              ),
            if (_cols > 1)
              _TableActionButton(
                icon: Icons.remove_rounded,
                label: '- Col',
                onTap: () => _removeCol(_cols - 1),
                danger: true,
              ),
            _TableActionButton(
              icon: Icons.table_rows_outlined,
              label: isHeader ? 'Sem cabeçalho' : 'Com cabeçalho',
              onTap: () {
                widget.onContentChanged({
                  ...widget.block.content,
                  'has_header': !isHeader,
                  'rows': _rows,
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _TableActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _TableActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
