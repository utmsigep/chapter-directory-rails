/* global ImagePaths, MapLibreWorkerUrl */

import { Controller } from '@hotwired/stimulus';
import * as maplibregl from 'maplibre-gl';

const ChapterIconSVG = ImagePaths.chapterIcon;
const SLCChapterIconSVG = ImagePaths.slcChapterIcon;
const DormantChapterIconSVG = ImagePaths.dormantChapterIcon;
const MAX_ZOOM_LEVEL = 12;
const MAP_STYLE = 'https://tiles.openfreemap.org/styles/positron';
const logger = console;

// Webpack bundles the app into a single chunk, so maplibre-gl can't locate its
// worker script relative to itself; point it at the copy we precompile alongside it.
maplibregl.setWorkerUrl(MapLibreWorkerUrl);

function template(str, data) {
  return str.replace(/\{ *([\w_-]+) *\}/g, (match, key) => (
    Object.prototype.hasOwnProperty.call(data, key) ? data[key] : match
  ));
}

function markerElement(iconUrl, size) {
  const el = document.createElement('img');
  el.src = iconUrl;
  el.style.width = `${size}px`;
  el.style.height = `${size}px`;
  el.style.cursor = 'pointer';
  return el;
}

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

    const chapterList = document.getElementById('chapter_list');
    if (chapterList) {
      chapterList.innerHTML = '';
    }

    (this.chapterMarkers || []).forEach((marker) => marker.remove());
    this.chapterMarkers = [];
    if (this.districtBorderLayers) {
      this.districtBorderLayers.forEach((layerId) => {
        if (this.map.getLayer(layerId)) this.map.removeLayer(layerId);
        if (this.map.getSource(layerId)) this.map.removeSource(layerId);
      });
    }
    this.districtBorderLayers = [];

    // Load data for the markers
    const mapBounds = new maplibregl.LngLatBounds();
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
          let el = markerElement(ChapterIconSVG, 24);
          if (chapter.slc) {
            el = markerElement(SLCChapterIconSVG, 24);
          }
          if (!chapter.status) {
            el = markerElement(DormantChapterIconSVG, 16);
          }
          const marker = new maplibregl.Marker({ element: el, draggable: this.draggableValue })
            .setLngLat([chapter.longitude, chapter.latitude]);
          chapter.district_name = chapter.district && chapter.district.name ? chapter.district.name : '(District Unavailable)';
          chapter.slc = chapter.slc ? `<div><img src="${SLCChapterIconSVG}" style="height:1em; padding-right:0.5em"/><strong>SigEp Learning Community</strong></div>` : '';
          chapter.website = chapter.website ? template('<div><a href="{website}" target="_blank">{website}</a></div>', chapter) : '';
          chapter.status = chapter.status ? '' : '<span class="badge text-bg-secondary">Dormant</span>';
          chapter.manpower = chapter.manpower ? `<div>Manpower: ${parseInt(chapter.manpower, 10)}</div>` : '';
          if (!('ontouchstart' in window)) {
            el.title = `${chapter.name} - ${chapter.institution_name}`;
          }
          if (chapter.url) {
            marker.setPopup(new maplibregl.Popup().setHTML(template('<div class="h5"><a href="{url}">{name}</a></div>{slc}{status}<div>{institution_name}</div><div>{location}</div><br />{manpower}<hr />{website}<div>{district_name}</div>', chapter)));
          } else {
            marker.setPopup(new maplibregl.Popup().setHTML(template('<div class="h5">{name}</div>{slc}{status}<div>{institution_name}</div><div>{location}</div><br />{manpower}<hr />{website}<div>{district_name}</div>', chapter)));
          }
          marker.addTo(this.map);
          this.chapterMarkers.push(marker);
          marker.on('dragend', () => {
            const lngLat = marker.getLngLat();
            document.getElementById('chapter_latitude').value = lngLat.lat;
            document.getElementById('chapter_longitude').value = lngLat.lng;
          });
          el.addEventListener('click', () => {
            that.map.flyTo({ center: marker.getLngLat(), zoom: MAX_ZOOM_LEVEL });
          });
          mapBounds.extend([chapter.longitude, chapter.latitude]);

          // Add to sidebar
          if (chapterList) {
            const chapterItem = document.createElement('div');
            if (chapter.url) {
              chapterItem.innerHTML = template('<div class="mb-3"><div class="h5"><a href="{url}">{name}</a></div>{slc}{status}<div><small>{institution_name}</small></div><div><small>{location}</small></div></div><hr />', chapter);
            } else {
              chapterItem.innerHTML = template('<div class="mb-3"><div class="h5">{name}</div>{slc}{status}<div><small>{institution_name}</small></div><div><small>{location}</small></div></div><hr />', chapter);
            }
            chapterItem.onclick = () => {
              document.getElementById('map').scrollIntoView(true);
              that.map.flyTo({ center: marker.getLngLat(), zoom: MAX_ZOOM_LEVEL });
              marker.togglePopup();
            };
            chapterItem.style.cursor = 'pointer';
            chapterList.appendChild(chapterItem);
          }
        });
        return data;
      })
      .then((data) => {
        if (!mapBounds.isEmpty()) {
          this.map.fitBounds(mapBounds, { padding: 40 });
        }
        if (chapterList) {
          const chapterCount = document.createElement('div');
          chapterCount.innerHTML = '<div class="text-center p-4">No chapters matched your criteria.</div>';
          if (this.chapterMarkers.length > 0) {
            chapterCount.innerHTML = `<div class="mt-3 text-center text-muted"> Chapters: ${this.chapterMarkers.length}</div>`;
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
        Object.keys(chapterGrouping).forEach((groupName) => {
          const groupChapters = chapterGrouping[groupName];
          const lngSum = groupChapters.reduce((sum, c) => sum + Number(c.longitude), 0);
          const latSum = groupChapters.reduce((sum, c) => sum + Number(c.latitude), 0);
          const centerLng = lngSum / groupChapters.length;
          const centerLat = latSum / groupChapters.length;
          if (Number.isNaN(centerLng) || Number.isNaN(centerLat)) {
            return;
          }
          groupChapters.forEach((chapter, i) => {
            groupChapters[i].angle = Math.atan2(
              Number(chapter.latitude) - centerLat,
              Number(chapter.longitude) - centerLng,
            );
          });
          groupChapters.sort((chapterA, chapterB) => chapterA.angle - chapterB.angle);
          const polygonPoints = groupChapters.map((chapter) => [
            Number(chapter.longitude), Number(chapter.latitude),
          ]);
          if (polygonPoints.length) {
            polygonPoints.push(polygonPoints[0]);
          }
          const layerId = `district-border-${groupName.replace(/[^a-z0-9]/gi, '_')}`;
          this.map.addSource(layerId, {
            type: 'geojson',
            data: {
              type: 'Feature',
              properties: { name: groupName },
              geometry: { type: 'Polygon', coordinates: [polygonPoints] },
            },
          });
          this.map.addLayer({
            id: layerId,
            type: 'fill',
            source: layerId,
            paint: { 'fill-color': '#3388ff', 'fill-opacity': 0.2 },
          });
          this.districtBorderLayers.push(layerId);
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
    document.querySelectorAll('.maplibregl-popup').forEach((popup) => popup.remove());
  }

  connect() {
    // Configure base map
    this.map = new maplibregl.Map({
      container: document.getElementById('map'),
      style: MAP_STYLE,
      center: [-103.771556, 44.967243],
      maxBounds: [
        [-172.5, 13], // southwest
        [-60, 72], // northeast
      ],
      zoom: 4,
      minZoom: 2,
      maxZoom: MAX_ZOOM_LEVEL,
    });
    this.map.addControl(new maplibregl.NavigationControl());
    this.map.on('load', () => {
      [
        'label_country_1', 'label_country_2', 'label_country_3',
        'waterway_line_label', 'water_name_point_label', 'water_name_line_label',
      ].forEach((layerId) => {
        this.map.setLayoutProperty(layerId, 'visibility', 'none');
      });
      ['label_city', 'label_city_capital', 'label_town'].forEach((layerId) => {
        this.map.setLayerZoomRange(layerId, 7, 24);
      });
      this.map.setLayerZoomRange('boundary_3', 2, 24);
    });

    // Map is being used to populate form fields
    if (this.clickableValue && !this.urlValue) {
      const marker = new maplibregl.Marker({
        element: markerElement(ChapterIconSVG, 24),
        draggable: true,
      })
        .setLngLat(this.map.getCenter())
        .addTo(this.map);
      marker.on('dragend', () => {
        const lngLat = marker.getLngLat();
        document.getElementById('chapter_latitude').value = lngLat.lat;
        document.getElementById('chapter_longitude').value = lngLat.lng;
      });
    }
  }

  disconnect() {
    this.map.remove();
  }
}
