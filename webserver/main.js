var chart, pubnub, stop;

chart = new Highcharts.Chart({
  chart: {
    renderTo: 'gyroscope',
    defaultSeriesType: 'spline',
    animation: false,
    zoomType: 'x'
  },
  title: {
    text: '',
    style: {
      display: 'none'
    }
  },
  xAxis: {
    type: 'datetime',
    tickPixelInterval: 10
  },
  yAxis: {
    minPadding: 0.2,
    maxPadding: 0.2,
    maxZoom: 4
  },
  plotOptions: {
    series: {
      animation: false
    }
  },
  series: [
    {
      name: 'pitch',
      color: 'red',
      data: []
    }, {
      name: 'yaw',
      color: 'green',
      data: []
    }, {
      name: 'roll',
      color: 'blue',
      data: []
    }
  ]
});

pubnub = PUBNUB({
  publish_key: 'pub-c-80f9db95-6c63-4265-90c6-cc3ddc22dddf',
  subscribe_key: 'sub-c-28f51c78-fa8e-11e5-8679-02ee2ddab7fe'
});

pubnub.subscribe({
  channel: 'speed',
  message: function(msg, envelope, channelOrGroup, time, channel) {
    return document.getElementById('speed').innerText = (1 / msg).toFixed(1) + 'Hz';
  }
});

pubnub.subscribe({
  channel: 'status',
  message: function(msg, envelope, channelOrGroup, time, channel) {
    var event, t;
    t = msg[0], event = msg[1];
    if (event === 'start') {
      chart.xAxis[0].addPlotLine({
        value: t,
        color: 'green',
        width: 2
      });
    }
    if (event === 'stop') {
      return chart.xAxis[0].addPlotLine({
        value: t,
        color: 'red',
        width: 2
      });
    }
  }
});

stop = false;

console.log("Subscribing..");

pubnub.subscribe({
  channel: 'gyroscope',
  message: function(msg, envelope, channelOrGroup, time, channel) {
    var ref, shift, t, x, x_series, y, y_series, z, z_series;
    if (!Array.isArray(msg)) {
      return;
    }
    if (stop) {
      return;
    }
    ref = chart.series, x_series = ref[0], y_series = ref[1], z_series = ref[2];
    t = msg[0], x = msg[1], y = msg[2], z = msg[3];
    shift = x_series.data.length > 40;
    x_series.addPoint([t, x], true, shift);
    y_series.addPoint([t, y], true, shift);
    return z_series.addPoint([t, z], true, shift);
  }
});

document.getElementById('stop').addEventListener('click', function() {
  return stop = !stop;
});
