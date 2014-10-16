<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Feature Selector</title>

    <!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">

<!-- Optional theme -->
<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css">
<!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
    <!-- Latest compiled and minified JavaScript -->
    <script src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>  
  </head>
  <body>
  <div class="container">

    <div class="content">
        <h5> Please select features that you want to be enabled at startup:</h5>
        <form id="selectFeatures" role="form">
        <c:forEach var="item" items="${features}">
            <div class="form-group"><input type="checkbox" value="${item}">   ${item}</input></div>
        </c:forEach>

            <div class="form-group">
                <button type="submit" class="btn btn-primary">Submit</button>
                <a href="#" id="download_dist" class="btn btn-default hidden">Download</a>
            </div>
        </form>
    </div>



  </div>


<script type="text/javascript">


jQuery("form").on( "submit", function( event ) {
	  event.preventDefault();
	  jQuery("#download_dist").addClass("hidden");
	  var count = jQuery( "input:checked" ).length;
	  if(count < 1) {
	    alert("Please select a feature");
	    return;
	  }
	  var features = "";
	  for(i=0; i < count; i++) {
	      features = features + "," + jQuery( "input:checked" )[i].value;
	  }
	  var formData = '{"selectedFeatures":"' + features + '"}';

	  jQuery.ajax({
		  url: "/feature-selector/selectFeatures",
		  type: "POST",
		  data: "selectedFeatures=" + features,
		  success: function(data) {
              jQuery("#download_dist").attr("href", data).removeClass("hidden");
			  console.log("success");
		  },
		  error : function(){ console.log("Error");}
	  });

	});
</script>
    
  </body>
</html>