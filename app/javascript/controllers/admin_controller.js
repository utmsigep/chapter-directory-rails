import { Controller } from '@hotwired/stimulus';

require('datatables.net');
require('datatables.net-bs5');

export default class extends Controller {
  connect() {
    this.table = document.getElementsByClassName('table-admin').DataTable();
  }

  disconnect() {
    if (this.table) {
      this.table.destroy();
    }
  }
}
