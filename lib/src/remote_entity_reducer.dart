import './entity_state.dart';
import './typedefs.dart';
import './unsorted_entity_state_adapter.dart';
import './remote_entity_actions.dart';
import 'package:redux/redux.dart';

class RemoteEntityState<T> extends EntityState<T> {
  final bool loadingAll;
  final Map<String, bool> loadingIds;
  final bool creating;
  final dynamic error;

  RemoteEntityState({
    // our properties
    this.loadingAll = false,
    this.loadingIds = const {},
    this.creating = false,
    // EntityState properties
    Map<String, T> entities = const {},
    List<String> ids = const [],
    this.error,
  }) : super(ids: ids, entities: entities) {}

  RemoteEntityState<T> copyWith({
    // EntityState properties
    Map<String, T> entities,
    List<String> ids,
    // our properties
    bool loadingAll,
    Map<String, bool> loadingIds,
    bool creating,
    dynamic error,
  }) {
    return RemoteEntityState<T>(
        loadingAll: loadingAll ?? this.loadingAll,
        loadingIds: loadingIds ?? this.loadingIds,
        creating: creating ?? this.creating,
        error: error ?? this.error,
        entities: entities ?? this.entities,
        ids: ids ?? this.ids);
  }
}

class RemoteEntityReducer<T> extends ReducerClass<RemoteEntityState<T>> {
  RemoteEntityReducer({
    IdSelector<T> selectId,
  }) : adapter = UnsortedEntityStateAdapter<T>(selectId: selectId);

  final UnsortedEntityStateAdapter<T> adapter;

  RemoteEntityState<T> call(RemoteEntityState<T> state, action) {
    if (action is RequestCreateOne<T> || action is RequestCreateMany<T>) {
      return RemoteEntityState<T>(creating: true, error: false);
    }
    if (action is FailCreateOne<T> || action is FailCreateMany<T>) {
      return RemoteEntityState<T>(creating: false, error: action.error);
    }
    if (action is SuccessCreateOne<T>) {
      return this
          .adapter
          .addOne(action.entity, state.copyWith(creating: false));
    }
    if (action is SuccessCreateMany<T>) {
      return this
          .adapter
          .addMany(action.entities, state.copyWith(creating: false));
    }
    if (action is RequestRetrieveOne<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      newIds[action.id] = true;
      return state.copyWith(loadingIds: newIds, error: false);
    }
    if (action is RequestUpdateOne<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      newIds[adapter.getId(action.entity)] = true;
      return state.copyWith(loadingIds: newIds, error: false);
    }
    if (action is RequestDeleteOne<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      newIds[action.id] = true;
      return state.copyWith(loadingIds: newIds, error: false);
    }
    if (action is RequestRetrieveAll<T>) {
      return state.copyWith(loadingAll: true, error: false);
    }
    if (action is FailUpdateOne<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      newIds[adapter.getId(action.entity)] = false;
      return state.copyWith(loadingIds: newIds, error: action.error);
    }
    if (action is FailRetrieveOne<T> || action is FailDeleteOne<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      newIds[action.id] = false;
      return state.copyWith(loadingIds: newIds, error: action.error);
    }

    if (action is FailRetrieveAll<T>) {
      return state.copyWith(loadingAll: false, error: action.error);
    }

    if (action is SuccessUpdateOne<T> || action is SuccessRetrieveOne<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      newIds[adapter.getId(action.entity)] = false;
      return this
          .adapter
          .upsertOne(action.entity, state.copyWith(loadingIds: newIds));
    }
    if (action is SuccessRetrieveAll<T>) {
      return this.adapter.upsertMany(action.entities,
          state.copyWith(loadingAll: false, entities: {}, ids: []));
    }
    if (action is RequestUpdateMany<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      for (T entity in action.entities) {
        newIds[adapter.getId(entity)] = true;
      }
      return state.copyWith(loadingIds: newIds, error: false);
    }
    if (action is RequestDeleteMany<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      for (String id in action.ids) {
        newIds[id] = true;
      }
      return state.copyWith(loadingIds: newIds, error: false);
    }
    if (action is FailUpdateMany<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      for (T entity in action.entities) {
        newIds[adapter.getId(entity)] = false;
      }
      return state.copyWith(loadingIds: newIds, error: action.error);
    }
    if (action is FailDeleteMany<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      for (String id in action.ids) {
        newIds[id] = false;
      }
      return state.copyWith(loadingIds: newIds, error: action.error);
    }
    if (action is SuccessUpdateMany<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      for (T entity in action.entities) {
        newIds[adapter.getId(entity)] = false;
      }
      return adapter.updateMany(
          action.entities, state.copyWith(loadingIds: newIds));
    }
    if (action is SuccessDeleteOne<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      newIds[action.id] = false;
      return adapter.removeOne(action.id, state.copyWith(loadingIds: newIds));
    }
    if (action is SuccessDeleteMany<T>) {
      Map<String, bool> newIds = Map<String, bool>.from(state.loadingIds);
      for (String id in action.ids) {
        newIds[id] = false;
      }
      return adapter.removeMany(action.ids, state.copyWith(loadingIds: newIds));
    }

    return state;
  }
}