/******************************************* 
 * LIGHTBOX PLUGIN by Masaki Haruka 2017
 * 
 * USAGE:
 *  - Load this script on your HTML.
 *  - Wrap your main article with box with #MainArticle ID.
 *  - Put lightbox modal window on your HTML.
 *  - Put target image into figure.
 *  - Puts image files .../thumb/* to thumbnail and .../full/* to fullsized.
 *    (you should be able to get fullsize image path with s@/thumb/@/full/@ replacement.)
 * 
*******************************************/

(function() {
  if (! document.addEventListener ) { return false; }
  Element.prototype._tn = Element.prototype.getElementsByTagName
  
  var wrapper = document.getElementById("WrapWindow") /* ModalWindow */
  var fadingTimer = false /* IntervalTimer */
  var alpha = 0.0 /* ModalWindows's alpha number */
  var lboxImage = document.getElementById("LBoxImage") /* target img object */
  
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
  
    /* Set next image */
    lboxImage.src = e.currentTarget.src.replace("/thumb/", "/full/")
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
  
  var art = document.getElementById("MainArticle")
  var figs = art._tn("figure")
  for(var i=0,l=figs.length; i<l; i++) {
    var fi = figs[i]._tn("img").item(0)
    if ( fi.src.indexOf("/thumb/") >= 0 ) {
      fi.addEventListener("click", setLightboxTrigger, false)
    }
  }
  
})()
