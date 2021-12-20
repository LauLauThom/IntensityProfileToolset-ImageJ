/* This macro should be placed in the ImageJ>macro>toolsets folder so as to appear in the toolbar >> section.
* It is inspired byJerome Mutterer X/Y Intensity profile tool from https://gist.github.com/mutterer/d81b22739f2526640d8955dff46568fc
* and from Nicolas de Francesco X/Y Intensity Profile panels tool from https://forum.image.sc/t/display-vertical-and-horizontal-intensity-profiles/59837/3?u=lthomas
* Requires at least Image 1.53b to have the tool icon read from a png file working.
*/

var pre_margin   = 75;
var post_margin  = 20;
var title_height = 32; // works in windows 10

macro "X/Y intensity profiles panels Action Tool - icon:Logo-Intensity-panels.png" {
    
    title = getTitle();
    img_height = getHeight();
    getLocationAndSize(orig_x, orig_y, orig_width, orig_height);

    run("Select All");
    run("Plot Profile");
    wait(50);
    getLocationAndSize(x, y, width, height);
    //setLocation(x, y, orig_width + pre_margin + post_margin, height/2); //not needed
    run("Duplicate...", "title=[horizontal plot]"); // plot as an image
    setLocation(orig_x - pre_margin, orig_y + orig_height);
    close("Plot of " + File.getNameWithoutExtension(title)); // close original plot window

    selectWindow(title);
    setKeyDown("alt"); 
    run("Plot Profile");
    wait(50);
    getLocationAndSize(x, y, width, height);
    //setLocation(x, y, orig_height - title_height + pre_margin + post_margin, height/2); // not needed
    run("Duplicate...", "title=[vertical plot]"); // plot as an image (for rotation)
    run("Rotate 90 Degrees Left");
    setLocation(orig_x + orig_width, orig_y - post_margin);
    close("Plot of " + File.getNameWithoutExtension(title)); // close original plot window
    selectWindow(title);
    run("Select None");
	}

macro "X/Y intensity profiles panels Action Tool Options" {
    
    pre_margin  = call("ij.Prefs.get", "panels.pre_margin", 75); // default 75
	post_margin = call("ij.Prefs.get", "panels.post_margin", 20);  
    title_height = call("ij.Prefs.get", "panels.title_height", 32); // works in windows 10

    Dialog.create("Intensity profile options");
    Dialog.addNumber("Pre-margin (pixels)", 75);
    Dialog.addNumber("Post-margin (pixels)", 20);
    Dialog.addNumber("Title height (pixels)", 32);
    Dialog.show();

    pre_margin   = Dialog.getNumber();
	post_margin  = Dialog.getNumber();
    title_height = Dialog.getNumber();
    
    // Save entered value
	call("ij.Prefs.set", "panels.pre_margin", pre_margin);
	call("ij.Prefs.set", "panels.post_margin", post_margin);
    call("ij.Prefs.set", "panels.title_height", title_height);
}


 /*
 * Define the scale for the intensity profile in pixel per gray-level
 * This scale is define by right clicking the tool icon, which GUI is defined in the "XXX - Options" function below 
 */
var scale = 1; 
macro "X/Y Line Profiles Tool - icon:InteractiveMouseProfiles.png" {
  
  getCursorLoc(x, y, z, flags);
  
  while (flags&16>0) {
    Overlay.clear;
    getCursorLoc(x, y, z, flags);
    
    drawVerticalProfile(x, scale);
    Overlay.show();

    drawHorizontalProfile(y, scale);
    Overlay.show();
    
    wait(30);
  }
}

macro "X/Y Line Profiles Tool Options" {

	Dialog.create("Line profile options");
    Dialog.addNumber("Scale (pixel/gray level)", call("ij.Prefs.get", "lineProfile.scale", 1)); // default scale to 1 pixel/gray level
    Dialog.show();

    scale = Dialog.getNumber();

    // Save entered value
	call("ij.Prefs.set", "lineProfile.scale", scale);
}

/*
 * This function draws a vertical red line across the full image height, at the given x coordinate (thickness 1). 
 * It also draws the intensity profile along this line in blue (thickness 2)
 * Call Overlay.show() to see the resulting line
 */
function drawVerticalProfile(x0, scale){
	
    height = getHeight();
    
	makeLine(x0, 0, x0, height);
	profile = getProfile();
	run("Select None"); // clear the ROI
	Array.getStatistics(profile, min, max, mean, stdDev);

	// Draw vertical reference line in red
	Overlay.drawLine(x0, 0, x0, height);
    setColor("red");  

	// Draw profile
	Overlay.moveTo(x0 + scale * (profile[0] - mean), 0) // start drawing 
	setColor("blue"); 
	setLineWidth(2);
	
	for (i=1; i<profile.length; i++){
		Overlay.lineTo(x0 + scale * (profile[i] - mean), i); // subtract the mean to have the line at about the ref line, ie like background subtraction
	}
}


/*
 * This function draws a horizontal red line across the full image width, at the given y coordinate (thickness 1). 
 * It also draws the intensity profile along this line in blue (thickness 2)
 * Call Overlay.show() to see the resulting line
 */
function drawHorizontalProfile(y0, scale) {

	width = getWidth();
	
	makeLine(0, y0, width, y0);
	profile = getProfile();
	run("Select None"); // clear the ROI
	Array.getStatistics(profile, min, max, mean, stdDev);

	// Draw horizontal reference line in red
	Overlay.drawLine(0, y0, width, y0); // shouldnt it be width-1
    setColor("red");  
    
	// Draw profile point-by-point
	Overlay.moveTo(0, y0 - scale * (profile[0] - mean) ); // start drawing 
	setColor("magenta"); // not working for some reason
    setLineWidth(2);
    
	for (i=1; i<profile.length; i++){
		Overlay.lineTo(i, y0 - scale * (profile[i] - mean)); // subtract the mean to have the line at about the ref line AND use - profile to have Y-axis for profile up-side ie oppoiste than the image Y-axis 
	}
}


/*
 * This function draws a straight line in red between (x1,y1) and (x2,y2) as an overlay on the image
 * additionally, it plots a second overlay line corresponding to the intensity profile along this line. 
 * The profile line has the given color.
 */
function overlayLineProfile(x1, y1, x2, y2, color, scale) {
   
   // Roi line used to get the intensity profile
   makeLine(x1, y1, x2, y2);
   profile = getProfile();
   run("Select None");
   
   Array.getStatistics(profile, min, max, mean, stdDev);
   setLineWidth(1);
   
   // The straight lines for the "cross-over"
   Overlay.drawLine(x1, y1, x2, y2);
   setColor("red");  
   
   Overlay.moveTo(x1, y1); // set the starting point for drawing
   setColor(color); 
   setLineWidth(2);
   
   // draw subsequent points by connecting to the previous point 
   xs = (x2-x1)/profile.length; // s for step ?
   ys = (y1-y2)/profile.length;
   //IJ.log("xs : " + xs + ", ys :" + ys);
   //(xs,ys) is either (1,0) or (0,-1) depending if horizontal or vertical profile
   
   for (i=0;i<profile.length;i++) {
      d = scale * (100 - 100 * profile[i]/max); // some kind of scaling by maxima
      a = atan ((y2-y1)/(x2-x1));
      Overlay.lineTo(x1 + i*xs - d*sin(a), y1 - i*ys + d*cos(a)); // lineTo -> understand connect line from current point to these new coordinates
   }
   Overlay.lineTo(x2, y2); // last point
   Overlay.show;
}