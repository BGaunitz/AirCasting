function MobileSessionsMapCtrl($scope, params, heat, map, sensors, expandables, storage, mobileSessions, versioner,
                         storageEvents, singleMobileSession, functionBlocker, $window, $location,
                         rectangles, infoWindow, markersClusterer, sensorsList) {
  sensors.setSensors(sensorsList);
  $scope.setDefaults = function() {
    $scope.versioner = versioner;
    $scope.params = params;
    $scope.storage = storage;
    $scope.storageEvents = storageEvents;
    $scope.sensors = sensors;
    $scope.expandables = expandables;
    $scope.sessions = mobileSessions;
    $scope.singleSession = singleMobileSession;
    $scope.$window = $window;

    functionBlocker.block("selectedId", !!params.get('data').sensorId);
    functionBlocker.block("sessionHeat", !_(params.get('sessionsIds')).isEmpty());

    rectangles.clear();
    infoWindow.hide();
    map.unregisterAll();
    map.removeAllMarkers();
    markersClusterer.clear();

    $($window).resize(function() {
      $scope.$digest();
    });
    _.each(['sensor', 'location', 'usernames'], function(name) {
      $scope.expandables.show(name);
    });

    storage.updateDefaults({
      sensorId: "",
      location: {address: "", distance: "10", limit: false},
      tags: "",
      usernames: ""
    });

    storage.updateFromDefaults();
  };

  $scope.searchSessions = function() {
    storage.updateWithRefresh('location');
    params.update({'didSessionsSearch': true});
  };

  //fix for json null parsing
  $scope.$watch("params.get('data').sensorId", function(newValue) {
    console.log("watch - params.get('data').sensorId - ", newValue);
    if(sensors.sensorChangedToAll(newValue)){
      params.update({data: {sensorId: ""}});
    }

    sensors.onSelectedSensorChange(newValue);
  }, true);

  $scope.$watch("sensors.selectedId()", function(newValue, oldValue) {
    console.log("watch - sensors.selectedId() - ", newValue, " - ", oldValue);
    if(!newValue){
      return;
    }

    params.update({data: {sensorId: newValue}});

    // Possibly this is not needed
    sensors.onSelectedSensorChange(newValue);

    functionBlocker.use("selectedId", function(){
      params.update({sessionsIds: []});
    });
  }, true);

  $scope.heatUpdateCondition = function() {
    return {sensorId:  sensors.anySelectedId(), sessionId: $scope.singleSession.id()};
  };
  $scope.$watch("heatUpdateCondition()", function(newValue, oldValue) {
    console.log("watch - heatUpdateCondition() - ", newValue, " - ", oldValue);
    if(newValue.sensorId && newValue.sessionId){
      functionBlocker.use("sessionHeat", function(){
        $scope.singleSession.updateHeat();
      });
    }
   }, true);

  $scope.$watch("sensors.selectedParameter", function(newValue) { sensors.onSelectedParameterChange(newValue); }, true);

  $scope.setDefaults();
}
MobileSessionsMapCtrl.$inject = ['$scope', 'params', 'heat',
   'map', 'sensors', 'expandables', 'storage', 'mobileSessions', 'versioner',
  'storageEvents', 'singleMobileSession', 'functionBlocker', '$window', "$location",
  "rectangles", "infoWindow", "markersClusterer", 'sensorsList'];
