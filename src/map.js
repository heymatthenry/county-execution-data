const w = 1000;
const h = 600;
const mapFill = "#cfcfcf"
const mapStroke = "#999"

const svg = d3.select("body")
              .append("svg")
              .attr("width", w)
              .attr("height", h);

const path = d3.geoPath();

const animateMap = function(){
  d3.select(".counties")
    .on("click", function() {
      let timer;
      const years =                                           [1977, 1978, 1979, 
                     1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987, 1988, 1989,
                     1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
                     2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009,
                     2010, 2011, 2012, 2013, 2014, 2015, 2016];

      let currentYear = 0;

      timer = setInterval(function(){
        if (currentYear < years.length) {
          setMapColors(years[currentYear]);
          updateYear(years[currentYear]);
          currentYear++;
        }
      }, 1000)
    })
}

const setMapColors = function(year) {
  svg.selectAll(".county")
      .transition()
      .style("fill", function(d){
        return getColor(d.properties, year);
    })
}

const updateYear = function(year) {
  d3.select("#yearLabel")
    .text(year)
}

const getColor = function(county, year) {
  let color = d3.scaleOrdinal()
      .domain([1,11])
      .range(d3.schemeReds[4])

  yearStr = "year" + year;

  if (("ExecutionsPerYear" in county) && 
      (yearStr in county.ExecutionsPerYear)) { 
    return color(county.ExecutionsPerYear[yearStr])
  } else {
    return mapFill;
  }
};

d3.json("/data/executions_quantized_topo.json", us => {
  const counties = topojson.feature(us, us.objects.us_albers_executions_properties).features;
  svg.append("g")
     .attr("class", "counties")
     .selectAll("path")
     .data(counties)
     .enter()
     .append("path")
     .attr("class", "county")
     .attr("fill", mapFill)
     .attr("stroke", mapStroke)
     .attr("d", path);
  
  svg.append("text")
     .attr("id", "yearLabel")
     .attr("x", w/2)
     .attr("y", h - 100)
     .attr("style", "font-family: 'Helvetica'; color: " + mapStroke + "; font-size: 68px;")
     .attr("fill", mapStroke)
     .text("1977");

  animateMap()
})