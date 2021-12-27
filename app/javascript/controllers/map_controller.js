import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    url: String,
    draggable: Boolean
  }

  urlValueChanged() {
    var that = this;

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

    let chapterList = document.getElementById('chapter_list')
    if (chapterList) {
      chapterList.innerHTML = ''
    }

    if (this.chaptersLayer) {
      this.chaptersLayer.clearLayers()
    }
    this.chaptersLayer = L.layerGroup()

    // Load data for the markers
    let mapBounds = []
    fetch(this.urlValue, {accept: 'application/json'})
      .then((response) => {
        return response.json()
      })
      .then((data) => {
        if (!Array.isArray(data)) {
          data = [data]
        }
        data.forEach(chapter => {
          let icon = chapter.slc ? new SLCChapterIcon() : new ChapterIcon()
          var marker = L.marker([chapter.latitude, chapter.longitude], {icon: icon, draggable: this.draggableValue });
          chapter['region_name'] = chapter.region.name
          chapter['district_name'] = chapter.district.name
          chapter['slc'] = chapter.slc ? '<div><img src="/assets/chapter-slc.svg" style="height:1em; padding-right:0.5em;"/><strong>SigEp Learning Community</strong></div>' : ''
          marker.bindTooltip(L.Util.template('<div><strong>{name}</strong></div>{slc}<div>{institution_name}</div>', chapter))
          marker.bindPopup(L.Util.template('<div class="h5">{name}</div>{slc}<div>{institution_name}</div><div>{location}</div><hr /><div>{region_name} &#8226; {district_name}</div>', chapter))
          marker.addTo(this.chaptersLayer)
          marker.on('dragend', function(event) {
            var draggedMarker = event.target
            console.log(draggedMarker.getLatLng())
            document.getElementById('chapter_latitude').value = draggedMarker.getLatLng().lat
            document.getElementById('chapter_longitude').value = draggedMarker.getLatLng().lng
          })
          marker.on('click', function(event) {
            that.map.flyTo(event.target.getLatLng(), 10);
          })
          mapBounds.push([chapter.latitude, chapter.longitude])

          // Add to sidebar
          if (chapterList) {
            var chapterItem = document.createElement('div')
            chapterItem.innerHTML = L.Util.template('<div class="h5">{name}</div>{slc}<div>{institution_name}</div><div>{location}</div><hr />', chapter)
            chapterItem.onclick = function(_e) {
              that.map.flyTo(marker.getLatLng(), 10);
              marker.openPopup()
            }
            chapterItem.style.cursor = 'pointer'
            chapterList.appendChild(chapterItem)
          }
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
    document.getElementById('region').value = ''
    this.urlValue = '/map/data.json?district_id=' + event.target.value;
  }

  filterRegion(event) {
    document.getElementById('district').value = ''
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
