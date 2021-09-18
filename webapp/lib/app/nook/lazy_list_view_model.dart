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
  Function _onItemAdd;

  /// A DOM element used to pad the height of the scroll list
  /// so that scrolling approximates the list size
  /// without adding all of the individual DOM elements
  final _scrollPad = DivElement();
  static const _scrollPadMinHeight = 30;

  LazyListViewModel(this._listView, {Function onItemAdd}) {
    _listView.onScroll.listen(_updateCachedElements);
    window.onResize.listen(_windowResized);

    _onItemAdd = onItemAdd;
  }

  void addItem(LazyListViewItem item, [int position]) {
    if (position == null || position > _items.length) {
      position = _items.length;
    } else if (position < 0) {
      position = 0;
    }
    _items.insert(position, item);
    if (position < _listView.children.length - 1) {
      // Insert the item's element into the cached/visible DOM elements
      Node refChild = _listView.children[position];
      _listView.insertBefore(item.element, refChild);
    } else {
      _updateCachedElements();
    }
  }

  void appendItems(Iterable<LazyListViewItem> items) {
    _items.addAll(items);
    _updateCachedElements();
  }

  void clearItems() {
    for (var item in _items) {
      item.disposeElement();
    }
    _scrollPad.remove();
    assert(_listView.children.length == 0);
    _items.clear();
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

  void removeItem(LazyListViewItem item) => removeItems([item]);

  void removeItems(List<LazyListViewItem> items) {
    for (var item in items) {
      _items.remove(item);
      item.removeElement();
    }
    _scrollPad.remove();
    _updateScrollPad();
  }

  /// Update the [LazyListViewItem] elements cached/displayed in the DOM
  /// based on the scroll position "scrollTop",
  /// the height of the cached/displayed DOM elements "scrollHeight",
  /// and the height of the scrolling area.
  void _updateCachedElements([_ignored_]) {
    _scrollPad.remove();

    var currentScrollHeight = _listView.scrollHeight;
    var desiredScrollHeight = _listView.scrollTop + 3 * _listView.clientHeight;
    if (currentScrollHeight < desiredScrollHeight && _listView.children.length < _items.length) {
      // Handle special case if no elements are visible - initialise the list with one element
      if (_listView.children.isEmpty) {
        var item = _items[_listView.children.length];
        _listView.append(item.element);
        if (_onItemAdd != null) {
          _onItemAdd(item);
        }
        currentScrollHeight = _listView.scrollHeight;
      }
      // Special case: there are fewer elements visible
      if (_listView.scrollHeight <= _listView.clientHeight) {
        currentScrollHeight = 0;
        for (var child in _listView.children) {
          currentScrollHeight += child.offsetHeight;
        }
      }
      // Compute the average height of the elements so far and use it to calculate how many more elements to add to the view
      double aveItemHeight = currentScrollHeight / _listView.children.length;
      num numDesiredItems = (desiredScrollHeight - currentScrollHeight) / aveItemHeight;
      int maxItems = _items.length - _listView.children.length;
      int numItemsToAdd = numDesiredItems > maxItems ? maxItems : numDesiredItems.ceil();

      for (int i = 0; i < numItemsToAdd; i++) {
        var item = _items[_listView.children.length];
        _listView.append(item.element);
        if (_onItemAdd != null) {
          _onItemAdd(item);
        }
      }
    }
    _updateScrollPad();
  }

  void _updateScrollPad() {
    _scrollPad.remove();
    int padHeight;
    if (_listView.children.length < _items.length && _listView.children.length != 0) {
      // Add a DOM element to pad the height of the scroll list
      // so that scrolling approximates the list size
      // without adding all of the individual DOM elements
      double aveItemHeight = _listView.scrollHeight / _listView.children.length;
      int numItemsInPad = _items.length - _listView.children.length;
      padHeight = aveItemHeight.floor() * numItemsInPad;
    } else {
      padHeight = _scrollPadMinHeight;
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

  /// Remove the DOM element from its parent, but keep the associated DOM element
  void removeElement() {
    if (elementOrNull != null) {
      elementOrNull.remove();
    }
  }
}
