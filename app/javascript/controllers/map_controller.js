import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

const MAX_ZOOM_LEVEL = 12

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    url: String,
    draggable: Boolean,
    clickable: Boolean
  }

  urlValueChanged() {
    var that = this

    if (!this.urlValue) {
      return
    }

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
          if (!chapter.latitude || !chapter.longitude) {
            console.error(`Cannot plot ${chapter.name} (${chapter.institution_name})`)
            return
          }
          let icon = chapter.slc ? new SLCChapterIcon() : new ChapterIcon()
          var marker = L.marker([chapter.latitude, chapter.longitude], {icon: icon, draggable: this.draggableValue })
          chapter['region_name'] = chapter.region.name
          chapter['district_name'] = chapter.district.name
          chapter['slc'] = chapter.slc ? '<div><img src="/assets/chapter-slc.svg" style="height:1em; padding-right:0.5em"/><strong>SigEp Learning Community</strong></div>' : ''
          chapter['website'] = chapter.website ? L.Util.template('<div><a href="{website}" target="_blank">{website}</a></div>', chapter) : ''
          if (!L.Browser.mobile) {
            marker.bindTooltip(L.Util.template('<div><strong>{name}</strong></div>{slc}<div>{institution_name}</div>', chapter))
          }
          marker.bindPopup(L.Util.template('<div class="h5">{name}</div>{slc}<div>{institution_name}</div><div>{location}</div><hr />{website}<div>{region_name} &#8226 {district_name}</div>', chapter))
          marker.addTo(this.chaptersLayer)
          marker.on('dragend', function(event) {
            var draggedMarker = event.target
            document.getElementById('chapter_latitude').value = draggedMarker.getLatLng().lat
            document.getElementById('chapter_longitude').value = draggedMarker.getLatLng().lng
          })
          marker.on('click', function(event) {
            that.map.flyTo(event.target.getLatLng(), MAX_ZOOM_LEVEL)
          })
          mapBounds.push([chapter.latitude, chapter.longitude])

          // Add to sidebar
          if (chapterList) {
            var chapterItem = document.createElement('div')
            chapterItem.innerHTML = L.Util.template('<div class="row mb-3"><div class="h5">{name}</div>{slc}<div><small>{institution_name}</small></div><div><small>{location}</small></div></div><hr />', chapter)
            chapterItem.onclick = function(_e) {
              document.getElementById('map').scrollIntoView(true)
              that.map.flyTo(marker.getLatLng(), MAX_ZOOM_LEVEL)
              marker.openPopup()
            }
            chapterItem.style.cursor = 'pointer'
            chapterList.appendChild(chapterItem)
          }
        })
      })
      .then(() => {
        this.map.addLayer(this.chaptersLayer)
        if (mapBounds.length) {
          this.map.fitBounds(mapBounds, {padding: [40, 40]})
        }
        if (chapterList) {
          var chapterCount = document.createElement('div')
          chapterCount.innerHTML = `<div class="mt-3 text-center text-muted"> Chapters: ${mapBounds.length}</div>`
          chapterList.appendChild(chapterCount)
        }
      })
  }

  filterDistrict(event) {
    document.getElementById('region').value = ''
    document.getElementById('search').value = ''
    this.urlValue = '/map/data.json?district_id=' + event.target.value
  }

  filterRegion(event) {
    document.getElementById('district').value = ''
    document.getElementById('search').value = ''
    this.urlValue = '/map/data.json?region_id=' + event.target.value
  }

  filterSearch(event) {
    var that = this;
    let typingTimer;
    let doneTypingInterval = 500;
    event.target.addEventListener('keyup', () => {
      clearTimeout(typingTimer);
        if (event.target.value) {
            console.log('has a value')
            typingTimer = setTimeout(doneTyping, doneTypingInterval);
        }
    });
    function doneTyping () {
      console.log('done typing')
      document.getElementById('region').value = ''
      document.getElementById('district').value = ''
      that.urlValue = '/map/data.json?q=' + event.target.value
    }
  }

  resetForm(event) {
    document.getElementById('region').value = ''
    document.getElementById('district').value = ''
    document.getElementById('search').value = ''
    this.urlValue = '/map/data.json?nonce=' + Math.random()
    this.map.closePopup()
  }

  connect() {
    // Configure base map
    this.map = L.map(document.getElementById('map'), {
      center: L.latLng(44.967243, -103.771556),
      maxBounds: L.latLngBounds(
        L.latLng(64.858889, -147.835556), // northwest
        L.latLng(18.4643137, -66.105905) // southeast
      ),
      zoom: 4,
      minZoom: 4
    })
    L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom: MAX_ZOOM_LEVEL,
      minZoom: 4,
      attribution: '&copy <a href="http://www.openstreetmap.org/copyright" target="blank">OpenStreetMap</a> &copy <a href="http://cartodb.com/attributions" target="blank">CartoDB</a>'
    }).addTo(this.map)

    // Fix-up leaflet image paths
    delete L.Icon.Default.prototype._getIconUrl
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png').default,
      iconUrl: require('leaflet/dist/images/marker-icon.png').default,
      shadowUrl: require('leaflet/dist/images/marker-shadow.png').default,
    })
  
    // Map is being used to populate form fields
    if (this.clickableValue && !this.urlValue) {
      var marker = L.marker(this.map.getCenter(), {draggable: true}).addTo(this.map)
      marker.on('dragend', function(event) {
        var draggedMarker = event.target
        document.getElementById('chapter_latitude').value = draggedMarker.getLatLng().lat
        document.getElementById('chapter_longitude').value = draggedMarker.getLatLng().lng
      })
    }
  }
 
  disconnect() {
    this.map.remove()
  }
}
