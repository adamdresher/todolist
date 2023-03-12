$(function() {

  $('form.delete').submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Warning, you cannot undo deletion.  Please click 'OK' to confirm before deleting.")
    if (ok) {
      this.submit();
    };
  });

})
