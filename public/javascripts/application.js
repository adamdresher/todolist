// console.log("This is a test.");
// confirm("Are you sure?");

$(function() {

  $('form.delete').submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure?")
    if (ok) {
      this.submit();
    };
  });
  // $('#destructive_button').on('click', function() {
  //   if (confirm("Are you sure?")) {
  //     console.log("Confirmation affirmed.");
  //   } else {
  //     console.log("Confirmation rejected.");
  //   }
  // });

})
