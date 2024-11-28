(function() {
  if (! document.addEventListener ) { return false; }
  var $e = function(id) { return document.getElementById(id) }
  Element.prototype._tn = Element.prototype.getElementsByTagName
  
  var wrapper = $e("WrapWindow") /* ModalWindow */
  var fadingTimer = false /* IntervalTimer */
  var alpha = 0.0 /* ModalWindows's alpha number */
  var lboxImage = $e("LBoxImage") /* target img object */
  
  /* fading out (interval callback) */
  var fadeout = function() {
    if (alpha < 0.8) {
      alpha = alpha + 0.05
      wrapper.style.backgroundColor = "rgba(0,0,0," + alpha + ")"
    } else {
      clearInterval(fadingTimer)
      fadingTimer = false
    }
  }
  
  /* set this for event callback */
  var setLightboxTrigger = function(e) {
    var imgsrc
  
    /* Set next image */
    imgsrc = e.currentTarget.src.replace("/thumb/", "/full/")
    if (e.currentTarget.dataset?.fullext) {
      imgsrc = imgsrc.replace(/\.[^./]+$/, ("." + e.currentTarget.dataset.fullext))
    }
    lboxImage.src = imgsrc
    lboxImage.style.maxHeight = window.innerHeight || document.documentElement.clientHeight
    lboxImage.style.maxWidth = window.innerWidth || document.documentElement.clientWidth
  
    wrapper.style.visibility = "visible"
    fadingTimer = setInterval(fadeout, 30)
  }

  /* Return from lightbox */
  wrapper.addEventListener("click", function(e) {
    if (fadingTimer) {
      clearInterval(fadingTimer)
    }
    wrapper.style.backgroundColor = "transparent"
    wrapper.style.visibility = "hidden"
    alpha = 0.0
    lboxImage.src = ""
  }, false)

  
  /***** Set event listener *****/
  
  var art = $e("MainArticle")
  var figs = art._tn("figure")
  for(var i=0,l=figs.length; i<l; i++) {
    var fi = figs[i]._tn("img").item(0)
    if ( fi.src.indexOf("/thumb/") >= 0 ) {
      fi.addEventListener("click", setLightboxTrigger, false)
    }
  }
  
})()
