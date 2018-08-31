import _ from 'underscore';
import { debounce } from 'debounce';
import constants from '../constants';

export const mobileSessions = (
  params,
  $http,
  map,
  sensors,
  $rootScope,
  utils,
  sessionsDownloader,
  drawSession,
  boundsCalculator,
  sessionsUtils,
  $location
) => {
  var MobileSessions = function() {
    this.sessions = [];
    this.maxPoints = 30000;
    this.scope = $rootScope.$new();
    this.scope.params = params;
    this.scope.canNotSelectSessionWithSensorSelected = "You are trying to select too many sessions";
    this.scope.canNotSelectSessionWithoutSensorSelected = "Filter by Parameter - Sensor to view many sessions at once";
  };

  MobileSessions.prototype = {
    allSelected: function() { return sessionsUtils.allSelected(this); },

    allSelectedIds: function() { return sessionsUtils.allSelectedIds(); },

    allSessionIds: function() { return sessionsUtils.allSessionIds(this) },

    deselectAllSessions: function() { sessionsUtils.deselectAllSessions(); },

    empty: function() { return sessionsUtils.empty(this); },

    export: function() { sessionsUtils.export(this); },

    find: function(id) { return sessionsUtils.find(this, id); },

    get: function(){ return sessionsUtils.get(this); },

    isSelected: function(session) { return sessionsUtils.isSelected(this, session); },

    measurementsCount: function(session) { return sessionsUtils.measurementsCount(session); },

    noOfSelectedSessions : function() { return sessionsUtils.noOfSelectedSessions(this); },

    onSessionsFetch: function() { sessionsUtils.onSessionsFetch(this); },

    onSessionsFetchError: function(data){ sessionsUtils.onSessionsFetchError(data); },

    reSelectAllSessions: function(){ sessionsUtils.reSelectAllSessions(this); },

    selectAllSessions: function() { sessionsUtils.selectAllSessions(this); },

    sessionsChanged: function (newIds, oldIds) { sessionsUtils.sessionsChanged(this, newIds, oldIds); },

    totalMeasurementsCount: function() { return sessionsUtils.totalMeasurementsCount(this); },

    totalMeasurementsSelectedCount: function() { return sessionsUtils.totalMeasurementsSelectedCount(this); },



    onSingleSessionFetch: function(session, data, allSelected) {
      const draw = () => {
        drawSession.drawMobileSession(session, boundsCalculator(allSelected));
      }
      sessionsUtils.onSingleSessionFetch(session, data, draw);
    },

    deselectSession: function(id) {
      var session = this.find(id);
      if(!session) return;
      session.loaded = false;
      session.$selected = false;
      session.alreadySelected = false;
      drawSession.undoDraw(session, boundsCalculator(this.sessions));
    },

    selectSession: function(id) {
      const callback = (session, allSelected) => (data) => {
        const draw = () => drawSession.drawMobileSession(session, boundsCalculator(allSelected));
        sessionsUtils.onSingleSessionFetch(session, data, draw);
        map.fitBounds(boundsCalculator(allSelected));
      }
      this._selectSession(id, callback);
    },

    reSelectSession: function(id) {
      const callback = (session, allSelected) => (data) => {
        const draw = () => drawSession.drawMobileSession(session, boundsCalculator(allSelected));
        sessionsUtils.onSingleSessionFetch(session, data, draw);
      }
      this._selectSession(id, callback);
    },

    _selectSession: function(id, callback) {
      const allSelected = this.allSelected();
      var session = this.find(id);
      if(!session || session.alreadySelected) return;
      var sensorId = params.get("data", {}).sensorId || sensors.tmpSelectedId();
      var sensor = sensors.sensors[sensorId] || {};
      var sensorName = sensor.sensor_name;
      if (!sensorName) return;
      session.alreadySelected = true;
      session.$selected = true;
      $http.get('/api/sessions/' + id, {
        cache : true,
        params: { sensor_id: sensorName }
      }).success(callback(session, allSelected));
    },

    canSelectThatSession: function(session) {
      return (this.totalMeasurementsSelectedCount() + this.measurementsCount(session)) <= this.maxPoints;
    },

    canSelectAllSessions: function() {
      return this.totalMeasurementsCount() <= this.maxPoints;
    },

    shouldUpdateWithMapPanOrZoom: function() {
      return true;
    },

    _fetch: function(page) {
      // if _fetch is called after the route has changed (eg debounced)
      if ($location.path() !== constants.mobileMapRoute) return;

      var viewport = map.viewport();
      var data = params.get('data');
      var sessionIds = _.values(params.get('sessionsIds') || []);
      if (!data.time) return;
      var reqData = {
        time_from: data.time.timeFrom - utils.timeOffset,
        time_to:  data.time.timeTo - utils.timeOffset,
        day_from:  data.time.dayFrom,
        day_to:  data.time.dayTo,
        year_from:  data.time.yearFrom,
        year_to:  data.time.yearTo,
        tags:  data.tags,
        usernames:  data.usernames,
        session_ids: sessionIds
      };

      _(reqData).extend({
        west: viewport.west,
        east: viewport.east,
        south: viewport.south,
        north: viewport.north
      });

      if(sensors.selected()){
        _(reqData).extend({
          sensor_name:  sensors.selected().sensor_name,
          measurement_type:  sensors.selected().measurement_type,
          unit_symbol:  sensors.selected().unit_symbol,
        });
      }

      _(params).extend({page: page});

      drawSession.clear(this.sessions);

      if (page === 0) {
        this.sessions = [];
        sessionsDownloader('/api/multiple_sessions.json', reqData, this.sessions, params, _(this.onSessionsFetch).bind(this),
          _(this.onSessionsFetchError).bind(this));
      }

      sessionsDownloader('/api/sessions.json', reqData, this.sessions, params, _(this.onSessionsFetch).bind(this),
        _(this.onSessionsFetchError).bind(this));

    },

    fetch: debounce(function(page) { this._fetch(page) }, 750)
  };
  return new MobileSessions();
}
