import 'package:flutter/material.dart';
import 'package:bump_ai/data/prompt.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file_image/cross_file_image.dart';

class TextImageInput extends StatefulWidget {
  final String hint;
  final Function(Prompt prompt)? onChanged;
  final PromptEditingController controller;

  const TextImageInput({
    super.key,
    this.onChanged,
    required this.controller,
    required this.hint,
  });

  @override
  State<TextImageInput> createState() => _TextImageInputState();
}

class _TextImageInputState extends State<TextImageInput> {
  late final textController = TextEditingController(text: widget.controller.text);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      textController.text = widget.controller.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...widget.controller.files.map(
                  (file) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ImagePreview(
                      file,
                      onDelete: () => setState(() {
                        widget.controller.files =
                            widget.controller.files.where((newFile) => !widget.controller.files.map((oldFile) => oldFile.name).contains(newFile.name)).toList();
                        if (widget.onChanged != null) {
                          widget.onChanged!(widget.controller.prompt);
                        }
                      }),
                    ),
                  ),
                )
              ],
            ),
          ),
          TextField(
            controller: textController,
            onChanged: (value) {
              widget.controller.text = value;
              if (widget.onChanged != null) {
                widget.onChanged!(widget.controller.prompt);
              }
            },
            minLines: 1,
            maxLines: 3,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.labelLarge,
            decoration: InputDecoration(
              isDense: true,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 2,
                minHeight: 2,
              ),
              border: InputBorder.none,
              suffixIcon: GestureDetector(
                onTap: () async {
                  final picked = await ImagePicker().pickMultipleMedia();
                  setState(() {
                    final newFiles = picked.where(
                      (newFile) => !widget.controller.files.map((oldFile) => oldFile.name).contains(newFile.name),
                    );
                    if (newFiles.isNotEmpty) {
                      setState(() => widget.controller.files = [
                            ...widget.controller.files,
                            ...newFiles,
                          ]);
                      if (widget.onChanged != null) {
                        widget.onChanged!(widget.controller.value);
                      }
                    }
                  });
                },
                child: const Icon(
                  Icons.add_photo_alternate,
                  size: 32,
                ),
              ),
              hintText: widget.hint,
              hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  final XFile file;
  final Function()? onDelete;
  final size = 80.0;
  const ImagePreview(this.file, {super.key, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: size / 8, right: size / 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image(
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              image: XFileImage(file),
              width: size,
              height: size,
            ),
          ),
          Positioned(
            right: -size / 8,
            top: -size / 8,
            child: SizedBox(
              width: size / 3,
              height: size / 3,
              child: IconButton.filled(
                onPressed: onDelete,
                iconSize: size / 4,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
