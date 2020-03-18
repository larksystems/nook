import 'dart:html';

/// [LazyListViewModel] displays a list of [LazyListViewItem],
/// lazily building DOM elements as they are needed when the list is scrolled.
///
/// Currently, DOM elements are lazily created but not disposed until the
/// list is cleared by calling [clearItems]. A future enhancement
/// would be to discard DOM elements earlier in the list as scrolling proceeds
/// deep into the list.
class LazyListViewModel {
  /// The items to be displayed.
  final _items = <LazyListViewItem>[];

  /// The DOM element used to display the items
  /// and typically displaying only a subset of the items.
  final DivElement _listView;

  /// The vertical scroll distance of the DOM elements in the [_listView] in pixels.
  int _scrollLength = _scollPadMinHeight;

  /// The width of the [_listView] scrolling area in pixels
  /// or `null` if it has not been cached yet.
  int _scrollWidth = 10;

  /// A DOM element used to pad the height of the scroll list
  /// so that scrolling approximates the list size
  /// without adding all of the individual DOM elements
  final _scrollPad = DivElement();
  static const _scollPadMinHeight = 30;

  /// When the width of the scrolling area changes,
  /// a delayed [Future] is created to recalculate [_scrollLength].
  Future _scrollLengthRecalc;

  LazyListViewModel(this._listView) {
    _listView.onScroll.listen(_updateCachedElements);
    window.onResize.listen(_windowResized);
  }

  void addItem(LazyListViewItem item, [int position]) {
    if (position == null || position > _items.length) {
      position = _items.length;
    } else if (position < 0) {
      position = 0;
    }
    _items.insert(position, item);
    if (position < _listView.children.length) {
      // Insert the item's element into the cached/visible DOM elements
      Node refChild = _listView.children[position];
      _listView.insertBefore(item.element, refChild);
      _scrollLength += item.element.clientHeight;
    } else {
      _updateCachedElements();
    }
  }

  void clearItems() {
    for (var item in _items) {
      item.disposeElement();
    }
    _scrollPad.remove();
    assert(_listView.children.length == 0);
    _items.clear();
    _scrollLength = _scollPadMinHeight;
  }

  void selectItem(LazyListViewItem item) {
    var position = _items.indexOf(item);
    // Add additional elements to the DOM as necessary
    // so that the conversation can be selected.
    _scrollPad.remove();
    while (position >= _listView.children.length) {
      _listView.append(_items[_listView.children.length].element);
    }
    if (position >= 0) {
      item.element.scrollIntoView();
    }
    _updateScrollPad();
  }

  /// Update the [LazyListViewItem] elements cached/displayed in the DOM
  /// based on the scroll position "scrollTop",
  /// the length of the cached/displayed DOM elements "scrollLength",
  /// and the height of the scrolling area.
  void _updateCachedElements([_ignored_]) {
    if (_scrollWidth == null) {
      _scrollWidth = _listView.clientWidth;
    } else if (_scrollWidth != _listView.clientWidth) {
      // If the scroll area width changed, then recalculate the scroll length
      // because the item heights and thus the scroll length depends upon the scroll area width.
      _scrollLengthRecalc ??= new Future.delayed(const Duration(seconds: 2), () {
        _scrollLength = _listView.children.fold(0, (len, element)
            => element == _scrollPad ? _scollPadMinHeight : len + element.clientHeight);
        _scrollWidth = _listView.clientWidth;
        _scrollLengthRecalc = null;
      });
    }

    _scrollPad.remove();
    var desiredScrollLength = _listView.scrollTop + 3 * _listView.clientHeight;
    while (_scrollLength < desiredScrollLength && _listView.children.length < _items.length) {
      var item = _items[_listView.children.length];
      _listView.append(item.element);
      _scrollLength += item.element.clientHeight;
    }
    _updateScrollPad();
  }

  void _updateScrollPad() {
    _scrollPad.remove();
    int padHeight;
    if (_listView.children.length < _items.length) {
      // Add a DOM element to pad the height of the scroll list
      // so that scrolling approximates the list size
      // without adding all of the individual DOM elements
      double aveItemHeight = _listView.scrollHeight / _listView.children.length;
      int numItemsInPad = _items.length - _listView.children.length;
      padHeight = aveItemHeight.floor() * numItemsInPad;
    } else {
      padHeight = _scollPadMinHeight;
    }
    _scrollPad.style.height = "${padHeight}px";
    _listView.append(_scrollPad);
  }

  void _windowResized(_ignored_) {
    // Only update the list when it is attached to the DOM
    if (_listView.isConnected) _updateCachedElements();
  }
}

/// An item with a lazily instantiated DOM element for use by [LazyListViewModel].
mixin LazyListViewItem {
  /// The cached DOM element for this item, or `null` if disposed or not yet created
  Element elementOrNull;

  /// Return the DOM element associated with the receiver,
  /// calling [buildElement] to create it if it has not already been created
  Element get element => elementOrNull ??= buildElement();

  /// Build a new DOM element representing this item
  Element buildElement();

  /// Dispose the associated DOM element if there is one
  void disposeElement() {
    if (elementOrNull != null) {
      elementOrNull.remove();
      elementOrNull = null;
    }
  }
}
