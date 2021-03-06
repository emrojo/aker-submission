// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .

var field_mapping = {
  position: 'position',
  material: 'supplier_name',
  donor: 'donor_name',
  gender: 'gender',
  common: 'common_name',
  phenotype: 'phenotype'
}

$(document).on('turbolinks:load', function() {

  var table = $('table[data-behavior~=datatable]')
    .DataTable({
      paging: false,
      searching: false,
      ordering: false,
      fixedHeader: {
        header: true,
        footer: false
      }
    })
    .on('drag dragstart dragend dragover dragenter dragleave drop', function(e) {
      e.preventDefault();
      e.stopPropagation();
    })
    .on('dragover dragenter', function() {
      $(this).addClass('is-dragover bg-info').removeClass('table-striped')
    })
    .on('dragleave dragend drop', function() {
      $(this).removeClass('is-dragover bg-info').addClass('table-striped')
    })
    .on('drop', function(e) {
      fillInTableFromFile($(this), e.originalEvent.dataTransfer.files);
    })

  $('form.edit_material_submission input:file').on('change', function() {

    var sample_table = $(this).closest('.well').siblings().find('table.dataTable');

    fillInTableFromFile(sample_table, $(this)[0].files)

    // Clearing the input allows the change event to fire again
    $(this).val(null);
  });

})

function fillInTableFromFile(table, files) {
  if (files.length != 1) {
    return false
  }

  Papa.parse(files[0], {
    complete: function(results) {
      console.log(results)

      if (results.errors.length > 0) {
        return false;
      }

      results.data.forEach(function(row) {
        var wellValue;

        for (var key in row) {
          if (key.toLowerCase().indexOf('position') != -1) {
            wellValue = row[key];
            delete row[key];
            break;
          }
        }

        // No wellValue, no data
        if (!wellValue) return;

        var tableRow = $('td input[name*="position"]', table).filter(function(td) {
          return $(this).val() == wellValue
        }).closest('tr');

        for (var key in row) {
          for (var fieldName in field_mapping) {
            if (key.toLowerCase().indexOf(fieldName) != -1) {
              tableRow.find('input[name*="' + field_mapping[fieldName] + '"]').val(row[key])
            }
          }
        }
      })
    },
    header: true
  })
}