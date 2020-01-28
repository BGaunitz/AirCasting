import { keysToLowerCase } from "./utils";
import moment from "moment";
import { getQ } from "./http";

const sessionsDownloader = () => {
  var fetch = function(
    url,
    reqData,
    sessions,
    params,
    refreshSessionsCallback
  ) {
    var successCallback = function(data) {
      preprocessData(data.sessions, sessions, params);
      refreshSessionsCallback(data.fetchableSessionsCount);
    };
    fetchPage(url, reqData, successCallback);
  };

  var fetchPage = function(url, reqData, success) {
    getQ(url, reqData).then(success);
  };

  var preprocessData = function(data, sessions, params) {
    var times;

    _(data).each(function(session) {
      if (session.start_time_local && session.end_time_local) {
        session.startTime = moment(session.start_time_local)
          .utc()
          .valueOf();
        session.endTime = moment(session.end_time_local)
          .utc()
          .valueOf();
      }

      session.streams = keysToLowerCase(session.streams);

      session.shortTypes = _(session.streams)
        .chain()
        .map(function(stream) {
          return {
            name: stream.measurement_short_type,
            type: stream.sensor_name
          };
        })
        .sortBy(function(shortType) {
          return shortType.name.toLowerCase();
        })
        .value();
    });
    sessions.push.apply(sessions, data);

    sessions = sessions.sort((a, b) =>
      a.end_time_local.localeCompare(b.end_time_local)
    );

    if (!params.isSessionSelected()) {
      params.update({ fetchedSessionsCount: sessions.length });
    }
  };

  return fetch;
};

export default sessionsDownloader();
