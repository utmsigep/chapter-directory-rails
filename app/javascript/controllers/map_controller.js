/* global ImagePaths */

import { Controller } from '@hotwired/stimulus';
import L from 'leaflet';
import GeometryUtil from 'leaflet-geometryutil';

const ChapterIconSVG = ImagePaths.chapterIcon;
const SLCChapterIconSVG = ImagePaths.slcChapterIcon;
const DormantChapterIconSVG = ImagePaths.dormantChapterIcon;
const MAX_ZOOM_LEVEL = 12;
const logger = console;

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    url: String,
    draggable: Boolean,
    clickable: Boolean,
  };

  urlValueChanged() {
    const that = this;

    if (!this.urlValue) {
      return;
    }

    const ChapterIcon = L.Icon.extend({
      options: {
        iconUrl: ChapterIconSVG,
        iconSize: [24, 24],
        shadowUrl: null,
      },
    });

    const SLCChapterIcon = L.Icon.extend({
      options: {
        iconUrl: SLCChapterIconSVG,
        iconSize: [24, 24],
        shadowUrl: null,
      },
    });

    const DormantChapterIcon = L.Icon.extend({
      options: {
        iconUrl: DormantChapterIconSVG,
        iconSize: [16, 16],
        shadowUrl: null,
      },
    });

    const chapterList = document.getElementById('chapter_list');
    if (chapterList) {
      chapterList.innerHTML = '';
    }

    if (this.chaptersLayer) {
      this.chaptersLayer.clearLayers();
    }
    this.chaptersLayer = L.layerGroup();

    // Load data for the markers
    const mapBounds = [];
    fetch(this.urlValue, { accept: 'application/json' })
      .then((response) => response.json())
      .then((parsed) => {
        let data = parsed;
        if (!Array.isArray(parsed)) {
          data = [data];
        }
        data.forEach((record) => {
          const chapter = record;
          if (!chapter.latitude || !chapter.longitude) {
            logger.error(`Cannot plot ${chapter.name} (${chapter.institution_name})`, chapter);
            return;
          }
          let icon = new ChapterIcon();
          if (chapter.slc) {
            icon = new SLCChapterIcon();
          }
          if (!chapter.status) {
            icon = new DormantChapterIcon();
          }
          const marker = L.marker(
            [chapter.latitude, chapter.longitude],
            { icon, draggable: this.draggableValue },
          );
          chapter.district_name = chapter.district && chapter.district.name ? chapter.district.name : '(District Unavailable)';
          chapter.slc = chapter.slc ? `<div><img src="${SLCChapterIconSVG}" style="height:1em; padding-right:0.5em"/><strong>SigEp Learning Community</strong></div>` : '';
          chapter.website = chapter.website ? L.Util.template('<div><a href="{website}" target="_blank">{website}</a></div>', chapter) : '';
          chapter.status = chapter.status ? '' : '<span class="badge text-bg-secondary">Dormant</span>';
          chapter.manpower = chapter.manpower ? `<div>Manpower: ${parseInt(chapter.manpower, 10)}</div>` : '';
          if (!L.Browser.mobile) {
            marker.bindTooltip(L.Util.template('<div><strong>{name}</strong></div>{slc}{status}<div>{institution_name}</div>', chapter));
          }
          marker.bindPopup(L.Util.template('<div class="h5">{name}</div>{slc}{status}<div>{institution_name}</div><div>{location}</div><br />{manpower}<hr />{website}<div>{district_name}</div>', chapter));
          marker.addTo(this.chaptersLayer);
          marker.on('dragend', (event) => {
            const draggedMarker = event.target;
            document.getElementById('chapter_latitude').value = draggedMarker.getLatLng().lat;
            document.getElementById('chapter_longitude').value = draggedMarker.getLatLng().lng;
          });
          marker.on('click', (event) => {
            that.map.flyTo(event.target.getLatLng(), MAX_ZOOM_LEVEL);
          });
          mapBounds.push([chapter.latitude, chapter.longitude]);

          // Add to sidebar
          if (chapterList) {
            const chapterItem = document.createElement('div');
            chapterItem.innerHTML = L.Util.template('<div class="mb-3"><div class="h5">{name}</div>{slc}{status}<div><small>{institution_name}</small></div><div><small>{location}</small></div></div><hr />', chapter);
            chapterItem.onclick = () => {
              document.getElementById('map').scrollIntoView(true);
              that.map.flyTo(marker.getLatLng(), MAX_ZOOM_LEVEL);
              marker.openPopup();
            };
            chapterItem.style.cursor = 'pointer';
            chapterList.appendChild(chapterItem);
          }
        });
        return data;
      })
      .then((data) => {
        this.map.addLayer(this.chaptersLayer);
        if (mapBounds.length) {
          this.map.fitBounds(mapBounds, { padding: [40, 40] });
        }
        if (chapterList) {
          const chapterCount = document.createElement('div');
          chapterCount.innerHTML = '<div class="text-center p-4">No chapters matched your criteria.</div>';
          if (mapBounds.length > 0) {
            chapterCount.innerHTML = `<div class="mt-3 text-center text-muted"> Chapters: ${mapBounds.length}</div>`;
          }
          chapterList.appendChild(chapterCount);
        }
        return data;
      })
      .then((data) => {
        const urlParams = new URLSearchParams(window.location.search);
        if (!urlParams.has('district_borders')) {
          return;
        }
        const grouping = 'district_name';
        const chapterGrouping = {};
        data.forEach((chapter) => {
          if (
            !chapter.latitude
            || !chapter.longitude
            || !chapter.district
          ) {
            return;
          }
          if (typeof chapterGrouping[chapter[grouping]] === 'undefined') {
            chapterGrouping[chapter[grouping]] = [];
          }
          chapterGrouping[chapter[grouping]].push(chapter);
        });
        chapterGrouping.forEach((groupName) => {
          const groupPoints = [];
          chapterGrouping[groupName].forEach((chapter) => {
            groupPoints.push([chapter.latitude, chapter.longitude]);
          });
          const center = L.bounds(groupPoints).getCenter();
          if (Number.isNaN(center.x) || Number.isNaN(center.y)) {
            return;
          }
          chapterGrouping[groupName].forEach((chapter, i) => {
            if (Number.isNaN(chapter.latitude) || Number.isNaN(chapter.longitude)) {
              return;
            }
            const angle = GeometryUtil.angle(
              this.map,
              new L.LatLng(center.x, center.y),
              new L.LatLng(chapter.latitude, chapter.longitude),
            );
            chapterGrouping[groupName][i].angle = angle;
          });
          chapterGrouping[groupName].sort((chapterA, chapterB) => chapterA.angle > chapterB.angle);
          const polygonPoints = [];
          chapterGrouping[groupName].forEach((chapter) => {
            polygonPoints.push(new L.LatLng(chapter.latitude, chapter.longitude));
          });
          const groupPolygon = (new L.Polygon(polygonPoints)).bindTooltip(groupName);
          groupPolygon.addTo(this.map);
        });
      });
  }

  filterDistrict(event) {
    document.getElementById('search').value = '';
    if (this.urlValue.includes('?')) {
      [this.urlValue] = this.urlValue.split('?');
    }
    this.urlValue = `${this.urlValue}?district_id=${event.target.value}`;
  }

  filterSearch(event) {
    const that = this;

    function doneTyping() {
      document.getElementById('district').value = '';
      if (that.urlValue.includes('?')) {
        [that.urlValue] = that.urlValue.split('?');
      }
      that.urlValue = `${that.urlValue}?q=${event.target.value}`;
    }

    let typingTimer;
    const doneTypingInterval = 500;
    event.target.addEventListener('keyup', () => {
      clearTimeout(typingTimer);
      if (event.target.value) {
        typingTimer = setTimeout(doneTyping, doneTypingInterval);
      }
    });
  }

  resetForm() {
    document.getElementById('district').value = '';
    document.getElementById('search').value = '';
    if (this.urlValue.includes('?')) {
      [this.urlValue] = this.urlValue.split('?');
    }
    this.urlValue = `${this.urlValue}?nonce=${Math.random()}`;
    this.map.closePopup();
  }

  connect() {
    // Configure base map
    this.map = L.map(document.getElementById('map'), {
      center: L.latLng(44.967243, -103.771556),
      maxBounds: L.latLngBounds(
        L.latLng(64.858889, -147.835556), // northwest
        L.latLng(18.4643137, -66.105905), // southeast
      ),
      zoom: 4,
      minZoom: 4,
    });
    L.tileLayer('https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom: MAX_ZOOM_LEVEL,
      minZoom: 4,
      attribution: '&copy <a href="http://www.openstreetmap.org/copyright" target="blank">OpenStreetMap</a> &copy <a href="http://cartodb.com/attributions" target="blank">CartoDB</a>',
    }).addTo(this.map);

    // Map is being used to populate form fields
    if (this.clickableValue && !this.urlValue) {
      const marker = L.marker(
        this.map.getCenter(),
        { icon: ChapterIconSVG, draggable: true },
      ).addTo(this.map);
      marker.on('dragend', (event) => {
        const draggedMarker = event.target;
        document.getElementById('chapter_latitude').value = draggedMarker.getLatLng().lat;
        document.getElementById('chapter_longitude').value = draggedMarker.getLatLng().lng;
      });
    }
  }

  disconnect() {
    this.map.remove();
  }
}
