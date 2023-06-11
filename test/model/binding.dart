import 'package:flutter/foundation.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/store.dart';

import 'test_store.dart';

/// A concrete binding for use in the `flutter test` environment.
///
/// Tests that will mount a [GlobalStoreWidget] should initialize this binding
/// by calling [ensureInitialized] at the start of the `main` method.
///
/// Individual test functions that mount a [GlobalStoreWidget] may then use
/// [globalStore] to access the global store provided to the [GlobalStoreWidget],
/// and [TestGlobalStore.add] to set up test data there.  Such test functions
/// must also call [reset] to clean up the global store.
///
/// The global store returned by [loadGlobalStore], and consequently by
/// [GlobalStoreWidget.of] in application code, will be a [TestGlobalStore].
class TestDataBinding extends DataBinding {
  /// Initialize the binding if necessary, and ensure it is a [TestDataBinding].
  ///
  /// This method is idempotent; calling it repeatedly simply returns the
  /// existing binding.
  ///
  /// If there is an existing binding but it is not a [TestDataBinding],
  /// this method throws an error.
  static TestDataBinding ensureInitialized() {
    if (_instance == null) {
      TestDataBinding();
    }
    return instance;
  }

  /// The single instance of the binding.
  static TestDataBinding get instance => DataBinding.checkInstance(_instance);
  static TestDataBinding? _instance;

  @override
  void initInstance() {
    super.initInstance();
    _instance = this;
  }

  /// The current global store offered to a [GlobalStoreWidget].
  ///
  /// The store is created lazily when accessing this getter, or when mounting
  /// a [GlobalStoreWidget].  The same store will continue to be provided until
  /// a call to [reset].
  ///
  /// Tests that access this getter, or that mount a [GlobalStoreWidget],
  /// should clean up by calling [reset].
  TestGlobalStore get globalStore => _globalStore ??= TestGlobalStore(accounts: []);
  TestGlobalStore? _globalStore;

  bool _debugAlreadyLoaded = false;

  /// Reset all test data to a clean state.
  ///
  /// Tests that mount a [GlobalStoreWidget], or that access [globalStore],
  /// should clean up by calling this method.  Typically this is done using
  /// [addTearDown], like `addTearDown(TestDataBinding.instance.reset);`.
  void reset() {
    _globalStore?.dispose();
    _globalStore = null;
    assert(() {
      _debugAlreadyLoaded = false;
      return true;
    }());
  }

  @override
  Future<GlobalStore> loadGlobalStore() {
    assert(() {
      if (_debugAlreadyLoaded) {
        throw FlutterError.fromParts([
          ErrorSummary('The same test global store was loaded twice.'),
          ErrorDescription(
            'The global store is loaded when a [GlobalStoreWidget] is mounted.  '
            'In the app, only one [GlobalStoreWidget] element is ever mounted, '
            'and the global store is loaded only once.  In tests, after mounting '
            'a [GlobalStoreWidget] and before doing so again, the method '
            '[TestGlobalStore.reset] must be called in order to provide a fresh store.',
          ),
          ErrorHint(
            'Typically this is accomplished using [addTearDown], like '
            '`addTearDown(TestDataBinding.instance.reset);`.',
          ),
        ]);
      }
      _debugAlreadyLoaded = true;
      return true;
    }());
    return Future.value(globalStore);
  }
}
