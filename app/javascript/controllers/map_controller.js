import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    url: String
  }

  urlValueChanged() {
    const ChapterIcon = L.Icon.extend({
      options: {
        iconUrl: '/assets/chapter.svg',
        iconSize: [24, 24],
        shadowUrl: null
      }
    })
    
    const SLCChapterIcon = L.Icon.extend({
      options: {
        iconUrl: '/assets/chapter-slc.svg',
        iconSize: [24, 24],
        shadowUrl: null
      }
    })

    if (this.chaptersLayer) {
      this.chaptersLayer.clearLayers()
    }
    this.chaptersLayer = L.layerGroup()

    // Load data for the markers
    let mapBounds = []
    fetch(this.urlValue, {acccept: 'application/json'})
      .then((response) => {
        return response.json()
      })
      .then((data) => {
        data.forEach(chapter => {
          let icon = chapter.slc ? new SLCChapterIcon() : new ChapterIcon()
          let marker = L.marker([chapter.latitude, chapter.longitude], {icon: icon });
          chapter['region_name'] = chapter.region.name
          chapter['district_name'] = chapter.district.name
          chapter['slc'] = chapter.slc ? '<div><img src="/assets/chapter-slc.svg" style="height:1em; padding-right:0.5em;"/><strong>SigEp Learning Community</strong></div>' : ''
          marker.bindTooltip(chapter.name + ' - ' + chapter.institution_name)
          marker.bindPopup(L.Util.template('<div class="h5">{name}</div><div>{institution_name}</div>{slc}<hr /><div>{region_name}</div><div>{district_name}</div>', chapter))
          marker.addTo(this.chaptersLayer)
          mapBounds.push([chapter.latitude, chapter.longitude])
        })
      })
      .then((data) => {
        this.map.addLayer(this.chaptersLayer)
        L.control({
          'Chapters': this.chaptersLayer
        })
        this.map.fitBounds(mapBounds, {padding: [40, 40]})
      })
  }

  filterDistrict(event) {
    this.urlValue = '/map/data.json?district_id=' + event.target.value;
  }

  filterRegion(event) {
    this.urlValue = '/map/data.json?region_id=' + event.target.value;
  }

  connect() {
    // Configure base map
    this.map = L.map(document.getElementById('map')).setView([39.828175, -98.5795], 4);
    L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom: 19,
      minZoom: 1,
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright" target="blank">OpenStreetMap</a> &copy; <a href="http://cartodb.com/attributions" target="blank">CartoDB</a>'
    }).addTo(this.map);

    // Fix-up leaflet image paths
    delete L.Icon.Default.prototype._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png').default,
      iconUrl: require('leaflet/dist/images/marker-icon.png').default,
      shadowUrl: require('leaflet/dist/images/marker-shadow.png').default,
    });
  }
 
  disconnect() {
    this.map.remove()
  }
}
