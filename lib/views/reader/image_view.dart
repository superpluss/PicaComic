part of pica_reader;

extension ScrollExtension on ScrollController {
  static double? futurePosition;

  void smoothTo(double value) {
    futurePosition ??= position.pixels;
    futurePosition = futurePosition! + value * 1.2;
    futurePosition = futurePosition!
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    animateTo(futurePosition!,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }
}

const Set<PointerDeviceKind> _kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown
};


extension ImageExt on ComicReadingPage {
  /// build comic image
  Widget buildComicView(
      ComicReadingPageLogic logic, BuildContext context, String target) {
    ScrollExtension.futurePosition = null;

    Widget buildType4() {
      return ScrollablePositionedList.builder(
        itemScrollController: logic.itemScrollController,
        itemPositionsListener: logic.itemScrollListener,
        itemCount: logic.urls.length,
        addSemanticIndexes: false,
        scrollController: logic.scrollController,
        scrollBehavior: const MaterialScrollBehavior()
            .copyWith(scrollbars: false, dragDevices: _kTouchLikeDeviceTypes),
        physics: (logic.noScroll || logic.isCtrlPressed)
            ? const NeverScrollableScrollPhysics()
            : const ClampingScrollPhysics(),
        itemBuilder: (context, index) {
          double width = MediaQuery.of(context).size.width;
          double height = MediaQuery.of(context).size.height;

          double imageWidth = width;

          if (height / width < 1.2 && appdata.settings[43] == "1") {
            imageWidth = height / 1.2;
          }

          precacheComicImage(logic, context, index + 1, target);

          ImageProvider image = createImageProvider(type, logic, index, target);

          return ComicImage(
            filterQuality: FilterQuality.medium,
            image: image,
            width: imageWidth,
            fit: BoxFit.cover,
          );
        },
      );
    }

    Widget buildType123() {
      return PhotoViewGallery.builder(
        key: Key(logic.readingMethod.index.toString()),
        reverse: appdata.settings[9] == "2",
        scrollDirection:
            appdata.settings[9] != "3" ? Axis.horizontal : Axis.vertical,
        itemCount: logic.urls.length + 2,
        builder: (BuildContext context, int index) {
          ImageProvider? imageProvider;
          if (index != 0 && index != logic.urls.length + 1) {
            imageProvider = createImageProvider(type, logic, index - 1, target);
          } else {
            return PhotoViewGalleryPageOptions.customChild(
                scaleStateController: PhotoViewScaleStateController(),
                child: const ColoredBox(
                  color: Colors.black,
                ));
          }

          precacheComicImage(logic, context, index, target);

          BoxFit getFit() {
            switch (appdata.settings[41]) {
              case "1":
                return BoxFit.fitWidth;
              case "2":
                return BoxFit.fitHeight;
              default:
                return BoxFit.contain;
            }
          }

          logic.photoViewControllers[index] ??= PhotoViewController();

          return PhotoViewGalleryPageOptions(
            filterQuality: FilterQuality.medium,
            imageProvider: imageProvider,
            fit: getFit(),
            controller: logic.photoViewControllers[index],
            errorBuilder: (_, error, s, retry) {
              return Center(
                child: SizedBox(
                  height: 300,
                  width: 400,
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            error.toString(),
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Listener(
                          onPointerDown: (details) {
                            TapController.ignoreNextTap = true;
                            retry();
                          },
                          child: const SizedBox(
                            width: 84,
                            height: 36,
                            child: Center(
                              child: Text(
                                "Retry",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
            heroAttributes:
                PhotoViewHeroAttributes(tag: "$index/${logic.urls.length}"),
          );
        },
        pageController: logic.pageController,
        loadingBuilder: (context, event) => DecoratedBox(
          decoration: const BoxDecoration(color: Colors.black),
          child: Center(
            child: SizedBox(
              width: 20.0,
              height: 20.0,
              child: CircularProgressIndicator(
                backgroundColor: Colors.white12,
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded /
                        (event.expectedTotalBytes ?? 1000000000000),
              ),
            ),
          ),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (i) {
          if (i == 0) {
            if (!logic.data.hasEp) {
              logic.pageController.animatedJumpToPage(1);
              return;
            }
            logic.jumpToLastChapter();
          } else if (i == logic.urls.length + 1) {
            if (!logic.data.hasEp) {
              logic.pageController.animatedJumpToPage(i - 1);
              return;
            }
            logic.jumpToNextChapter();
          } else {
            logic.index = i;
            logic.update();
          }
        },
      );
    }

    Widget buildType56() {
      return PhotoViewGallery.builder(
        key: Key(logic.readingMethod.index.toString()),
        itemCount: (logic.urls.length / 2).ceil() + 2,
        reverse: logic.readingMethod == ReadingMethod.twoPageReversed,
        builder: (BuildContext context, int index) {
          if (index == 0 || index == (logic.urls.length / 2).ceil() + 1) {
            return PhotoViewGalleryPageOptions.customChild(
                child: const SizedBox());
          }
          precacheComicImage(logic, context, index * 2 + 1, target);

          logic.photoViewControllers[index] ??= PhotoViewController();

          return PhotoViewGalleryPageOptions.customChild(
              controller: logic.photoViewControllers[index],
              child: Row(
                children: logic.readingMethod == ReadingMethod.twoPage
                    ? [
                        Expanded(
                          child: ComicImage(
                            image: createImageProvider(
                                type, logic, index * 2 - 2, target),
                            fit: BoxFit.contain,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                        Expanded(
                          child: index * 2 - 1 < logic.urls.length
                              ? ComicImage(
                                  image: createImageProvider(
                                      type, logic, index * 2 - 1, target),
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerLeft,
                                )
                              : const SizedBox(),
                        ),
                      ]
                    : [
                        Expanded(
                          child: index * 2 - 1 < logic.urls.length
                              ? ComicImage(
                                  image: createImageProvider(
                                      type, logic, index * 2 - 1, target),
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerRight,
                                )
                              : const SizedBox(),
                        ),
                        Expanded(
                          child: ComicImage(
                            image: createImageProvider(
                                type, logic, index * 2 - 2, target),
                            fit: BoxFit.contain,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ],
              ));
        },
        pageController: logic.pageController,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        onPageChanged: (i) {
          if (i == 0) {
            if (!logic.data.hasEp) {
              logic.pageController.animatedJumpToPage(1);
              return;
            }
            logic.jumpToLastChapter();
          } else if (i == (logic.urls.length / 2).ceil() + 1) {
            if (!logic.data.hasEp) {
              logic.pageController.animatedJumpToPage(i - 1);
              return;
            }
            logic.jumpToNextChapter();
          } else {
            logic.index = i * 2 - 1;
            logic.update();
          }
        },
      );
    }

    Widget body;

    if (["1", "2", "3"].contains(appdata.settings[9])) {
      body = buildType123();
    } else if (appdata.settings[9] == "4") {
      logic.photoViewControllers[0] ??= PhotoViewController();
      body = PhotoView.customChild(
          key: Key(logic.order.toString()),
          minScale: 1.0,
          maxScale: 2.5,
          strictScale: true,
          controller: logic.photoViewControllers[0],
          onScaleEnd: (context, detail, value) {
            var prev = logic.currentScale;
            logic.currentScale = value.scale ?? 1.0;
            if ((prev <= 1.05 && logic.currentScale > 1.05) ||
                (prev > 1.05 && logic.currentScale <= 1.05)) {
              logic.update();
            }
            if (appdata.settings[43] != "1") {
              return false;
            }
            return updateLocation(context, logic.photoViewController);
          },
          child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: buildType4()));
    } else {
      body = buildType56();
    }

    void onPointerSignal(PointerSignalEvent pointerSignal) {
      logic.mouseScroll = pointerSignal is PointerScrollEvent;
      if (pointerSignal is PointerScrollEvent && !logic.isCtrlPressed) {
        if (logic.readingMethod != ReadingMethod.topToBottomContinuously) {
          pointerSignal.scrollDelta.dy > 0
              ? logic.jumpToNextPage()
              : logic.jumpToLastPage();
        } else {
          if ((logic.scrollController.position.pixels ==
                      logic.scrollController.position.minScrollExtent &&
                  pointerSignal.scrollDelta.dy < 0) ||
              (logic.scrollController.position.pixels ==
                      logic.scrollController.position.maxScrollExtent &&
                  pointerSignal.scrollDelta.dy > 0)) {
            logic.photoViewController.updateMultiple(
                position: logic.photoViewController.position -
                    Offset(0, pointerSignal.scrollDelta.dy));
          } else if (!App.isMacOS){
            logic.scrollController.smoothTo(pointerSignal.scrollDelta.dy);
          }
        }
      }
    }

    return Positioned.fill(
      top: App.isDesktop ? MediaQuery.of(context).padding.top : 0,
      child: Listener(
        onPointerSignal: onPointerSignal,
        onPointerPanZoomUpdate: (event) {
          if (event.kind == PointerDeviceKind.trackpad &&
              logic.readingMethod == ReadingMethod.topToBottomContinuously) {
            if (event.scale == 1.0) {
              logic.scrollController.smoothTo(0 - event.panDelta.dy * 1.2);
            }
          }
        },
        onPointerDown: (details) => logic.mouseScroll = false,
        child: NotificationListener<ScrollUpdateNotification>(
          child: body,
          onNotification: (notification) {
            TapController.lastScrollTime = DateTime.now();
            // update floating button
            var length = logic.data.eps?.length ?? 1;
            if (!logic.scrollController.hasClients) return false;
            if (logic.scrollController.position.pixels -
                        logic.scrollController.position.minScrollExtent <=
                    0 &&
                logic.order != 0) {
              logic.showFloatingButton(-1);
            } else if (logic.scrollController.position.pixels -
                        logic.scrollController.position.maxScrollExtent >=
                    0 &&
                logic.order < length) {
              logic.showFloatingButton(1);
            } else {
              logic.showFloatingButton(0);
            }

            // update index
            if (logic.readingMethod == ReadingMethod.topToBottomContinuously) {
              var value =
                  logic.itemScrollListener.itemPositions.value.first.index + 1;
              if (value != logic.index) {
                logic.index = value;
                logic.update();
              }
            }

            return true;
          },
        ),
      ),
    );
  }

  /// create a image provider
  ImageProvider createImageProvider(
      ReadingType type, ComicReadingPageLogic logic, int index, String target) {

    return logic.data.createImageProvider(logic.order, index, logic.urls[index]);
  }

  /// check current location of [PageView], update location when it is out of range.
  bool updateLocation(BuildContext context, PhotoViewController controller) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    if (width / height < 1.2) {
      return false;
    }
    final currentLocation = controller.position;
    final scale = controller.scale ?? 1;
    final imageWidth = height / 1.2;
    final showWidth = width / scale;
    if (showWidth >= imageWidth && currentLocation.dx != 0) {
      controller.updateMultiple(
          position: Offset(controller.initial.position.dx, currentLocation.dy));
      return true;
    }
    if (showWidth < imageWidth) {
      final lEdge = (width - imageWidth) / 2;
      final rEdge = width - lEdge;
      final showLEdge =
          (0 - currentLocation.dx) / scale - showWidth / 2 + width / 2;
      final showREdge =
          (0 - currentLocation.dx) / scale + showWidth / 2 + width / 2;
      final updateValue = (width / 2 - (rEdge - showWidth / 2)) * scale;
      if (lEdge > showLEdge) {
        controller.updateMultiple(
            position: Offset(0 - updateValue, currentLocation.dy));
        return true;
      } else if (rEdge < showREdge) {
        controller.updateMultiple(
            position: Offset(updateValue, currentLocation.dy));
        return true;
      }
    }
    return false;
  }

  /// preload image
  void precacheComicImage(ComicReadingPageLogic logic, BuildContext context,
      int index, String target) {
    if (logic.requestedLoadingItems.length != logic.length) {
      logic.requestedLoadingItems = List.filled(logic.length + 1, false);
    }
    int precacheNum = int.parse(appdata.settings[28]) + index;
    for (; index < precacheNum; index++) {
      if (index >= logic.urls.length || logic.requestedLoadingItems[index]) {
        return;
      }
      precacheImage(createImageProvider(type, logic, index, target), context);
    }
    if (!ImageManager.haveTask) {
      precacheNum += 3;
      for (; index < precacheNum; index++) {
        if (index >= logic.urls.length || logic.requestedLoadingItems[index]) {
          return;
        }
        precacheImage(createImageProvider(type, logic, index, target), context);
      }
    }
  }
}
