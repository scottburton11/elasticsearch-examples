function initialize() {
  var mapOptions = {
    center: new google.maps.LatLng(33.92, -118),
    zoom: 10
  };
  var map = new google.maps.Map(document.getElementById("map-canvas"),
      mapOptions);

  google.maps.event.addListener(map, 'dragend', boundsChanged)
  google.maps.event.addListener(map, 'tilesloaded', boundsChanged)

  window.map = map;

  var search = new Search(window.map, $("input#search_for"));

  window.search = search;

  $("input#search_for").typeahead({
    hint: true,
    highlight: true,
    minLength: 1
  }, {
    source: function(q, callback) {
      var request = $.getJSON("/suggest", {q: q})
      request.done(function(response){
        var suggestions = response.provider[0].options
        callback(suggestions);
      })
    },
    displayKey: "text"
  })
}

google.maps.event.addDomListener(window, 'load', initialize);

function boundsChanged(e){
  return true;
}

// function(){
//   var polygons = []

//   function boundsChanged(e) {
//     // getNeighborhoods();
//   }

//   function getNeighborhoods(name) {
//     var bounds = window.map.getBounds();

//     var coordinates = bounds.toUrlValue();
    
//     var request = $.getJSON('/shapes', {
//       coordinates: coordinates,
//       q: name
//     });

//     request.success(function(shapes){

//       console.log("Drawing", shapes.length, "neighborhoods")

//       for (var p = 0; p < polygons.length; p++) {
//         polygons[p].setMap(null);
//       };

//       for (var i = 0; i < shapes.length; i++) {
//         var shape = shapes[i];

//         if (true) {
//           var path = []

//           for (var j = 0; j < shape.location.coordinates[0][0].length; j++) {
//             var pair = shape.location.coordinates[0][0][j];
//             var ll = new google.maps.LatLng(pair[1], pair[0]);
//             path.push(ll);
//           };

//           var polygon = new google.maps.Polygon({
//             paths: path
//           });

//           polygons.push(polygon)

//           polygon.setMap(map);
//         };
//       };
//     });
//   }
  
//   var handleResponse = function(response) {
//     drawResults(response.hits.hits);
//   }

//   var handleKeyup = function(event) {
//     var query = $(this).val();
//     if (query.length > 0) {
//       search(query).done([logResponse, handleResponse]);
//     };
//   }

//   $("input#search_for").keyup(handleKeyup);

// }();
// $(function(){
//   getNeighborhoods();
// })

var Search, s,
__bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Search = (function(){

  function Search(map, el){
    this.map = map;
    this.el  = el;
    this.handleKeyup = __bind(this.handleKeyup, this);
    this.handleResponse = __bind(this.handleResponse, this);
    this.handleSuggestions = __bind(this.handleSuggestions, this);
    $(document).on('keyup', el, this.handleKeyup);
    return this;
  };

  Search.prototype.markers = [];

  Search.prototype.search = function(q) {
    return $.getJSON("/search", {
      q: q
    })
  }
  
  Search.prototype.suggest = function(q) {
    return $.getJSON("/suggest", {
      q: q
    })
  }

  Search.prototype.attributesFrom = function(result){
    return result._source;
  }

  Search.prototype.drawResults = function(results) {
    this.removeMarkers(this.markers);
    for (var i = 0; i < results.length; i++) {
      var attributes = this.attributesFrom(results[i]);
      this.markers.push(this.dropMarker(attributes));
    };
    return this.markers;
  }

  Search.prototype.showResultsList = function(response) {
    var headTemplate = "<div class='meta'><ul><li>Took: <%= took %></li><li>Max: <%= hits.max_score %></li><li>Count: <%= hits.total %></li></ul></div>"
    var resultTemplate = "<div class='result'><div class='score'><%= _score %></div><div class='name'><%= _source.company_name %></div><div class='address'><%= _source.street_address %></div></div>"

    var html = "";

    html += _.template(headTemplate, response);

    for (var i = 0; i < response.hits.hits.length; i++) {
      var result = response.hits.hits[i];
      html += _.template(resultTemplate, result);
    };

    $("#results").html(html);
  }

  Search.prototype.dropMarker = function(data) {
    var latLng = new google.maps.LatLng(data.location.coordinates[1], data.location.coordinates[0])
    var marker = new google.maps.Marker({
      position: latLng
    });
    marker.setMap(this.map);
    return marker;
  }

  Search.prototype.removeMarkers = function(markers){
    for (var i = 0; i < markers.length; i++) {
      markers[i].setMap(null);
    };
  }

  // Search.prototype.showSuggestions = function(suggestions) {
  //   $("#suggestions").empty();
  //   for (var i = 0; i < suggestions.length; i++) {
  //     var suggestion = suggestions[i];
  //     $("#suggestions").append("<div class='suggestion'>" + suggestion.text + "</div>")
  //   };
  // }

  // Search.prototype.handleSuggestions = function(response) {
  //   if (response.provider.length > 0) {
  //     this.showSuggestions(response.provider[0]['options'])
  //   }
  // }

  Search.prototype.logResponse = function(response) {
    console.log(response);
  }

  Search.prototype.handleKeyup = function(event) {
    var query = $(event.target).val();
    if (query.length > 0) {
      if (event.keyCode == 13) {
        this.search(query).done([this.logResponse, this.handleResponse]);
      };
    };
  }

  Search.prototype.handleResponse = function(response) {
    this.drawResults(response.hits.hits);
    this.showResultsList(response);
  }


  return Search;
})()

