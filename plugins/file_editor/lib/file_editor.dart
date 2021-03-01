library file_editor;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'langagues.dart';
import 'loading.dart';
import 'menu.dart';
import 'modal.dart';
import 'tool_item.dart';
import 'package:path/path.dart' as pathLib;

class FileEditorPage extends StatefulWidget {
  final String path;
  final Color fontColor;
  final Color backgroundColor;
  final Color bottomNavColor;
  // if return true will save  return false will prevent save
  final bool Function(dynamic) onSave;
  final Function() onEditStart;
  final Function(dynamic) onSaveError;
  final Color itemColor;
  final EdgeInsetsGeometry padding;
  final Map<String, TextStyle> highlightTheme;
  final String language;
  final TextStyle textStyle;
  final Color dialogBgColor;
  final Color selectItemColor;
  final Color popMenuColor;

  const FileEditorPage({
    Key key,
    this.fontColor = Colors.black54,
    this.backgroundColor = Colors.white,
    this.bottomNavColor,
    this.path,
    this.onSave,
    this.onEditStart,
    this.onSaveError,
    this.itemColor = const Color(0xFF007AFF),
    this.padding = const EdgeInsets.only(left: 15, right: 15),
    this.highlightTheme,
    this.language = '',
    this.textStyle = const TextStyle(fontSize: 14, fontFamily: 'monospace'),
    this.dialogBgColor,
    this.selectItemColor,
    this.popMenuColor,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _FileEditorPageState();
  }
}

class _FileEditorPageState extends State<FileEditorPage> {
  TextEditingController _textEditingController;
  bool _isEditing;
  bool _mutex;
  String _text;
  File _file;
  bool _hasError;
  TextStyle _textStyle;
  String _language;
  String _encoding;
  List<String> _charsets;

  List<ToolItem> toolBar() {
    return [
      ToolItem(
        press: () => insertIntoTextField("\t"),
        symbol: 'tab',
      ),
      ToolItem(
        press: () => insertIntoTextField("<"),
        symbol: '<',
      ),
      ToolItem(
        press: () => insertIntoTextField(">"),
        symbol: '>',
      ),
      ToolItem(
        press: () => insertIntoTextField('""', diff: -1),
        symbol: '""',
      ),
      ToolItem(
        press: () => insertIntoTextField(":"),
        symbol: ":",
      ),
      ToolItem(
        press: () => insertIntoTextField("#"),
        symbol: "#",
      ),
      ToolItem(
        press: () => insertIntoTextField("@"),
        symbol: "@",
      ),
      ToolItem(
        press: () => insertIntoTextField("%"),
        symbol: "%",
      ),
      ToolItem(
        press: () => insertIntoTextField("&"),
        symbol: "&",
      ),
      ToolItem(
        press: () => insertIntoTextField("\$"),
        symbol: "\$",
      ),
      ToolItem(
        press: () => insertIntoTextField(";"),
        symbol: ";",
      ),
      ToolItem(
        press: () => insertIntoTextField('()', diff: -1),
        symbol: "()",
      ),
      ToolItem(
        press: () => insertIntoTextField('{}', diff: -1),
        symbol: "{}",
      ),
      ToolItem(
        press: () => insertIntoTextField('[]', diff: -1),
        symbol: "[]",
      ),
      ToolItem(press: () => insertIntoTextField("-"), symbol: '-'),
      ToolItem(press: () => insertIntoTextField("="), symbol: '='),
      ToolItem(press: () => insertIntoTextField("+"), symbol: '+'),
      ToolItem(press: () => insertIntoTextField("/"), symbol: '/'),
      ToolItem(press: () => insertIntoTextField("*"), symbol: '*'),
    ];
  }

  void placeCursor(int pos) {
    try {
      _textEditingController.selection = TextSelection.fromPosition(
        TextPosition(offset: pos),
      );
    } catch (e) {
      throw Exception("code_editor : placeCursor(int pos), pos is not valid.");
    }
  }

  void insertIntoTextField(String str, {int diff = 0}) {
    int pos = _textEditingController.selection.baseOffset;

    String baseText = _textEditingController.text;

    String begin = baseText.substring(0, pos) + str;

    if (baseText.length == pos) {
      _textEditingController.text = begin;
    } else {
      String end = baseText.substring(pos, baseText.length);
      _textEditingController.text = begin + end;
    }

    // newValue = _textEditingController.text;
    placeCursor(pos + str.length + diff);
  }

  @override
  void initState() {
    super.initState();
    _isEditing = false;
    _hasError = false;
    _mutex = true;
    _encoding = 'UTF-8';
    _textEditingController = TextEditingController();
    _textStyle = widget.textStyle;
    _language = widget.language;
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (_mutex) {
      _mutex = false;
      try {
        _file = File(widget.path);
        _text = await readFile(_file, _encoding);
        _charsets = await CharsetConverter.availableCharsets();
        setState(() {});
      } catch (e) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<String> convertTo(String from, String to, dynamic text) async {
    Uint8List encoded = await CharsetConverter.encode(from, text);
    return CharsetConverter.decode(to, encoded);
  }

  Widget buildContent() {
    return _isEditing
        ? Container(
            padding: widget.padding,
            child: CupertinoTextField(
              controller: _textEditingController,
              decoration: BoxDecoration(),
              maxLines: null,
              autofocus: true,
              style: _textStyle,
            ),
          )
        : Scrollbar(
            child: SingleChildScrollView(
              child: Container(
                padding: widget.padding,
                child: HighlightView(
                  _text,
                  language: _language,
                  theme: widget.highlightTheme,
                  tabSize: 4,
                  textStyle: _textStyle,
                ),
              ),
            ),
          );
  }

  Future<String> readFile(File file, encoding) async {
    Uint8List content = await file.readAsBytes();
    return CharsetConverter.decode(encoding, content);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: widget.backgroundColor,
        elevation: 0,
        toolbarHeight: 50,
        title: Container(
          child: Text(
            pathLib.basename(_file?.path ?? ''),
            style: TextStyle(
              color: widget.fontColor,
              fontSize: 20,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            child: Container(
              constraints: BoxConstraints(maxWidth: 50),
              alignment: Alignment.center,
              child: Text(
                _encoding,
                style: TextStyle(color: widget.itemColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            onTap: () async {
              await showSelectModal(
                context,
                itemFontColor: widget.fontColor,
                dialogBgColor: widget.dialogBgColor,
                selectItemColor: widget.selectItemColor,
                popPreviousWindow: true,
                options: _charsets,
                title: '选择编码',
                onSelected: (index) async {
                  print(_encoding);
                  _text = await convertTo(_encoding, _charsets[index], _text);
                  _encoding = _charsets[index];
                  setState(() {});

                  Navigator.pop(context);
                },
              );
            },
          ),
          FocusedMenuHolder(
            backgroundColor: widget.popMenuColor,
            menuWidth: MediaQuery.of(context).size.width * 0.4,
            blurSize: 5.0,
            menuItemExtent: 45,
            duration: Duration(milliseconds: 100),
            animateMenuItems: true,
            menuY: -10,
            menuX: 10,
            bottomOffsetHeight: 80.0,
            menuItems: <FocusedMenuItem>[
              FocusedMenuItem(
                backgroundColor: widget.popMenuColor,
                title: Text(
                  '语法',
                  textScaleFactor: 1,
                  style: TextStyle(color: widget.fontColor),
                ),
                onPressed: () async {
                  await showSelectModal(
                    context,
                    itemFontColor: widget.fontColor,
                    dialogBgColor: widget.dialogBgColor,
                    selectItemColor: widget.selectItemColor,
                    popPreviousWindow: true,
                    options: allLanguages,
                    title: '选择语法',
                    onSelected: (index) {
                      if (mounted) {
                        setState(() {
                          _language = allLanguages[index];
                        });
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              FocusedMenuItem(
                backgroundColor: widget.popMenuColor,
                title: Text(
                  '字体大小',
                  textScaleFactor: 1,
                  style: TextStyle(color: widget.fontColor),
                ),
                onPressed: () async {
                  await showTextFieldModal(
                    context,
                    title: '字号大小',
                    itemFontColor: widget.fontColor,
                    dialogBgColor: widget.dialogBgColor,
                    popPreviousWindow: true,
                    onOk: (val) async {
                      setState(() {
                        _textStyle = TextStyle(
                            fontSize: double.tryParse(val?.trim()) ?? 14,
                            fontFamily: 'monospace');
                      });
                      Navigator.pop(context);
                    },
                    onCancel: () async {},
                  );
                },
              ),
            ],
            child: Container(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.more_horiz,
                color: widget.itemColor,
              ),
            ),
          ),
        ],
      ),
      body: _hasError
          ? Center(
              child:
                  Icon(Icons.error_outline, size: 28, color: widget.itemColor),
            )
          : _text != null
              ? buildContent()
              : Center(
                  child: LoadingDoubleFlipping.square(
                    size: 30,
                    backgroundColor: widget.itemColor,
                  ),
                ),
      bottomNavigationBar: AnimatedPadding(
        duration: Duration(milliseconds: 100),
        padding: MediaQuery.of(context).viewInsets,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              height: 50,
              color: widget.bottomNavColor,
              width: screenWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: screenWidth - 100,
                    child: _isEditing
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: toolBar()
                                  .map(
                                    (e) => IconButton(
                                      icon: Text(
                                        e.symbol,
                                        style: TextStyle(
                                          color: widget.fontColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "monospace",
                                        ),
                                      ),
                                      onPressed: e.press,
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                        : null,
                  ),
                  Container(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: widget.itemColor),
                          onPressed: () {
                            if (_hasError) {
                              return;
                            }
                            _textEditingController.text = _text;
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.save,
                              color: _isEditing ? null : Colors.grey),
                          onPressed: () async {
                            if (!_isEditing || _hasError) {
                              return;
                            }

                            if (widget.onSave != null) {
                              if (!widget.onSave(_textEditingController.text)) {
                                return;
                              }
                            }

                            await _file
                                .writeAsString(_textEditingController.text)
                                .catchError((err) {
                              if (widget.onSaveError != null) {
                                widget.onSaveError(err);
                              }
                              return false;
                            });

                            _text = await readFile(_file, _encoding);

                            setState(() {
                              _isEditing = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
