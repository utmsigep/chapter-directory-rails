import { Controller } from '@hotwired/stimulus';
import 'chartkick/chart.js';
import Chartkick from 'chartkick';

require('datatables.net');
require('datatables.net-bs5');

export default class extends Controller {
  static targets = [];

  static values = {
    type: String,
    data: Array,
    options: Object,
  };

  chart = null;

  connect() {
    this.table = document.getElementsByClassName('table-admin').DataTable();
    this.chart = new Chartkick[this.typeValue](
      this.element.id,
      this.dataValue,
      this.optionsValue,
    );
  }

  disconnect() {
    if (this.table) {
      this.table.destroy();
    }
  }
}
