import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Connects to data-controller="map"
export default class extends Controller {
  connect() {
    // Configure base map
    this.map = L.map(this.element).setView([39.828175, -98.5795], 4);
    L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom: 19,
      minZoom: 1,
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright" target="blank">OpenStreetMap</a> &copy; <a href="http://cartodb.com/attributions" target="blank">CartoDB</a>'
    }).addTo(this.map);
    L.control.scale().addTo(this.map);

    // Fix-up leaflet image paths
    delete L.Icon.Default.prototype._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png').default,
      iconUrl: require('leaflet/dist/images/marker-icon.png').default,
      shadowUrl: require('leaflet/dist/images/marker-shadow.png').default,
    });

    // Load data for the markers
    fetch('/chapters.json', {acccept: 'application/json'})
      .then((response) => {
        return response.json()
      })
      .then((data => {
        data.forEach(chapter => {
          var marker = L.marker([chapter.latitude, chapter.longitude]).addTo(this.map);
          marker.bindTooltip(chapter.name)
        });
      })
    );

  }

  disconnect() {
    this.map.remove()
  }
}
