import { Elm } from '../elm/src/Main.elm';

document.addEventListener('DOMContentLoaded', () => {
  fetch('/api/sensors.json').then(x => x.json()).then(sensors => {
    window.__sensors = sensors;
    const params = window.location.hash
      .slice(2)
      .split('&')
      .filter(x => x.length !== 0)
      .map(x => x.split('='))
      .map(([k, v]) => [k, decodeURIComponent(v)])
      .map(([k, v]) => [k, JSON.parse(v)])
      .reduce((acc, [k, v]) => ({ ...acc, [k]: v }), {});
    const defaultData = { location: "", tags: "", usernames: "", crowdMap: false, gridResolution: 25, isIndoor: false, sensorId: "particulate matter-airbeam2-pm2.5 (µg/m³)" };
    const data = { ...defaultData, ...params.data };

    console.warn(params);
    console.warn(data);

    const flags = {
      sensors: window.__sensors,
      selectedSensorId: data.sensorId,
      location: data.location,
      isCrowdMapOn: data.crowdMap,
      crowdMapResolution: data.gridResolution,
      tags: data.tags.split(', ').filter((tag) => tag !== ""),
      profiles: data.usernames.split(', ').filter((tag) => tag !== ""),
      selectedSessionId: params.selectedSessionIds ? params.selectedSessionIds[0] ? params.selectedSessionIds[0] : null : null,
      timeRange: {
        timeFrom: data.timeFrom,
        timeTo: data.timeTo
      },
      isIndoor: data.isIndoor
    };

    console.warn(flags);

    window.__elmApp = Elm.Main.init({ flags });
  });
});