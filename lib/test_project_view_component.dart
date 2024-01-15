// 캐릭터, 배경, 대화창을 담는 용도의 컴포넌트
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';
import 'package:jenny_study/constants/customColor.dart';
import 'package:jenny_study/dialogue_overlay.dart';
import 'package:jenny_study/main.dart';
import 'package:jenny_study/main_dialogue_text_component.dart';

class ProjectViewComponent extends PositionComponent
    with DialogueView, HasGameRef<JennyGame> {
  late DialogueTextComponent mainDialogueTextComponent;
  late final DialogueTextComponent nameDialogueTextComponent;
  late final DialogueOverlay mainDialogueOverlay;
  late final DialogueOverlay nameDialogueOverlay;
  final background = SpriteComponent();
  final girl1 = SpriteComponent();
  final girl2 = SpriteComponent();
  late final ButtonComponent forwardButtonComponent; // 대화 넘기는 감지 버튼
  Completer<void> _forwardCompleter = Completer();
  Completer<int> _choiceCompleter = Completer<int>();
  bool isNameComponentRendered = false;

  List<ButtonComponent> optionsList = [];

  final textPaint = TextPaint(
      style: const TextStyle(
    color: CustomColor.brightGray,
    fontSize: 20,
    height: 1.4,
  ));

  @override
  FutureOr<void> onLoad() {
    background
      ..sprite = Sprite(gameRef.images.fromCache('background.png'))
      ..size = gameRef.size;

    girl1
      ..sprite = Sprite(gameRef.images.fromCache('girl1.png'))
      ..size = Vector2(400, 400)
      ..position = Vector2(gameRef.size.x * 0.01, gameRef.size.y * 0.1);

    girl2
      ..sprite = Sprite(gameRef.images.fromCache('girl2.png'))
      ..size = Vector2(400, 400)
      ..position = Vector2(gameRef.size.x * 0.99, gameRef.size.y * 0.1)
      ..anchor = Anchor.topRight;

    forwardButtonComponent = ButtonComponent(
        button: PositionComponent(),
        size: gameRef.size,
        onPressed: () {
          if (mainDialogueTextComponent.checkDialogueFinished()) {
            _forwardCompleter.complete();
          }
        });

    mainDialogueOverlay = DialogueOverlay(
      size: Vector2(gameRef.size.x * .9, gameRef.size.y * .3),
      position: Vector2(
        gameRef.size.x * .05,
        gameRef.size.y * .65,
      ),
    );

    nameDialogueTextComponent = DialogueTextComponent(
      size: Vector2(200, 40),
      align: Anchor.center,
      textRenderer: textPaint.copyWith(
        (p0) => p0.merge(
          const TextStyle(fontSize: 20),
        ),
      ),
      position: Vector2(
        gameRef.size.x * .05,
        gameRef.size.y * .65 - 40,
      ),
      boxConfig: TextBoxConfig(
        maxWidth: gameRef.size.x * .9,
        margins: const EdgeInsets.all(8.0),
        growingBox: false,
        // timePerChar: 0.05,
      ),
    );

    nameDialogueOverlay = DialogueOverlay(
      size: Vector2(200, 40),
      position: Vector2(
        gameRef.size.x * .05,
        gameRef.size.y * .65 - 40,
      ),
    );

    addAll([
      background,
      girl1,
      girl2,
      forwardButtonComponent,
      // mainDialogueTextComponent,
      mainDialogueOverlay,
      nameDialogueTextComponent,
      nameDialogueOverlay,
    ]);
    return super.onLoad();
  }

  @override
  FutureOr<bool> onLineStart(DialogueLine line) async {
    _forwardCompleter = Completer();
    await _advance(line);
    return super.onLineStart(line);
  }

  @override
  FutureOr<void> onLineFinish(DialogueLine line) async {
    remove(mainDialogueTextComponent);
    return super.onLineFinish(line);
  }

  @override
  FutureOr<int?> onChoiceStart(DialogueChoice choice) async {
    _choiceCompleter = Completer<int>();
    forwardButtonComponent.removeFromParent();
    mainDialogueOverlay.removeFromParent();
    nameDialogueOverlay.removeFromParent();
    for (int i = 0; i < choice.options.length; i++) {
      optionsList.add(ButtonComponent(
          position: Vector2(
            gameRef.size.x * .05 + 8,
            gameRef.size.y * .1 + i * 50 + 8,
          ), // position 에 8을 더하는 이유 : `mainDialogueTextComponent` 의 margin 값
          button: TextComponent(
            text: choice.options[i].text,
            textRenderer: textPaint.copyWith(
              (p0) => p0.merge(
                TextStyle(
                  backgroundColor: CustomColor.black.withAlpha(150),
                ),
              ),
            ),
          ),
          onPressed: () {
            if (!_choiceCompleter.isCompleted) {
              _choiceCompleter.complete(i);
            }
          }));
    }
    addAll(optionsList);
    await _getChoice(choice);

    return _choiceCompleter.future;
  }

  @override
  FutureOr<void> onChoiceFinish(DialogueOption option) {
    removeAll(optionsList);
    optionsList = [];
    addAll([
      forwardButtonComponent,
      // mainDialogueTextComponent,
      mainDialogueOverlay,
      nameDialogueTextComponent,
      nameDialogueOverlay,
    ]);
  }

  @override
  FutureOr<void> onNodeStart(Node node) {
    switch (node.title) {
      case 'early_morning':
        background.sprite = Sprite(gameRef.images.fromCache('background2.png'));
      case 'jumpTest':
        background.sprite = Sprite(gameRef.images.fromCache('background3.png'));
        girl1.sprite = Sprite(gameRef.images.fromCache('girl1_other.png'));
    }
    add(mainDialogueOverlay); // 노드 변경되고 mainDialogueOverlay 추가
    return super.onNodeStart(node);
  }

  @override
  FutureOr<void> onNodeFinish(Node node) {
    nameDialogueTextComponent.removeFromParent();
    nameDialogueOverlay.removeFromParent();
    mainDialogueTextComponent.removeFromParent();
    mainDialogueOverlay.removeFromParent();
    // 해당 대화 노드가 끝나고 처리하는 부분
    // this.removeFromParent();
  }

  Future<void> _getChoice(DialogueChoice choice) async {
    return _forwardCompleter.future;
  }

  Future<void> _advance(DialogueLine line) async {
    var characterName = line.character?.name;
    var lineText = line.text;
    // mainDialogueTextComponent.text = lineText;
    nameDialogueTextComponent.text = characterName ?? '';

    if (nameDialogueTextComponent.text == '') {
      nameDialogueTextComponent.removeFromParent();
      nameDialogueOverlay.removeFromParent();
      isNameComponentRendered = false;
    } else {
      if (!isNameComponentRendered) {
        addAll([nameDialogueOverlay, nameDialogueTextComponent]);
        isNameComponentRendered = true;
      }
    }

    mainDialogueTextComponent = DialogueTextComponent(
      size: Vector2(gameRef.size.x * .9, gameRef.size.y * .3),
      textRenderer: textPaint,
      position: Vector2(
        gameRef.size.x * .05,
        gameRef.size.y * .65,
      ),
      boxConfig: TextBoxConfig(
        margins: const EdgeInsets.all(8.0),
        growingBox: false,
        timePerChar: 0.05,
      ),
    )..text = lineText;

    add(mainDialogueTextComponent);

    return _forwardCompleter.future;
  }
}
