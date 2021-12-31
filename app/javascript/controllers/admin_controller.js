import { Controller } from "@hotwired/stimulus"

const $ = require('jquery');
global.$ = global.jQuery = $;
require('datatables.net')
require('datatables.net-bs5')

export default class extends Controller {
  connect() {
    this.table = $('.table-admin').DataTable();
  }

  disconnect() {
    if (this.table) {
      this.table.destroy()
    }
  }
}
