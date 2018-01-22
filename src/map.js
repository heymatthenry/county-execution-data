const w = 1000;
const h = 600;

const svg = d3.select("body")
              .append("svg")
              .attr("width", w)
              .attr("height", h);

const path = d3.geoPath();

d3.json("/data/us_albers_executions_topo.json", us => {
  svg.append("g")
     .selectAll("path")
     .data(topojson.feature(us, us.objects.us_albers_executions_properties).features)
     .enter()
     .append("path")
     .attr("d", path);
})