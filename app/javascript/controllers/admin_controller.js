/* eslint-disable no-unused-vars */
import { Controller } from '@hotwired/stimulus';
import $ from 'jquery';
import DataTable from 'datatables.net-bs5';

export default class extends Controller {
  connect() {
    this.initializeDataTable();
  }

  initializeDataTable() {
    $(this.element).find('.table-admin').DataTable({
      pageLength: 50,
    });
  }

  destroy() {
    $(this.element).find('.table-admin').DataTable().destroy();
  }
}
