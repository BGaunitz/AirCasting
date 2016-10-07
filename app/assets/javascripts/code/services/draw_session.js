angular.module('aircasting').factory('drawSession',
       ['sensors', 'map', 'heat', 'note',
        function(sensors, map, heat, note) {
  var DrawSession = function() {
  };

  DrawSession.prototype = {
    draw: function(session, bounds) {
      if(!session || !session.loaded || !sensors.anySelected()){
        return;
      }
      this.undoDraw(session, true);
      var suffix = ' ' + sensors.anySelected().unit_symbol;
      session.markers = [];
      session.noteDrawings = [];
      session.lines = [];
      var points = [];
      _(session.measurements).each(function(measurement, idx){
        var value = Math.round(measurement.value);
        var level = heat.getLevel(value);
        if(level){
          session.markers.push(map.drawMarker(measurement, {
            title: parseInt(measurement.value, 10).toString() + suffix,
            zIndex: idx,
            icon: "/assets/marker"+ level + ".png"
          }));
          points.push(measurement);
        }
      });
      _(session.notes || []).each(function(noteItem, idx){
        session.noteDrawings.push(note.drawNote(noteItem, idx));
      });
      session.lines.push(map.drawLine(points));

      session.drawed = true;
      map.appendViewport(bounds);
    },

    undoDraw: function(session, bounds, noMove) {
      if(!session.drawed){
        return;
      }
      _(session.markers || []).each(function(marker){
        map.removeMarker(marker);
      });
      _(session.lines || []).each(function(line){
        map.removeMarker(line);
      });
      _(session.noteDrawings || []).each(function(noteItem){
        map.removeMarker(noteItem);
      });
      session.drawed = false;
      if(!noMove){
        map.appendViewport(bounds);
      }
    },

    redraw: function(sessions) {
      this.clear();
      _(sessions).each(_(this.draw).bind(this));
    },

    clear: function(sessions) {
      _(sessions).each(_(this.undoDraw).bind(this));
    }
  };
  return new DrawSession();
}]);
