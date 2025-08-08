// USER SETTINGS FOR PHONE IMAGES
// COPY/PASTE THESE SETTINGS INTO colonyCountScript.ijm to analyse the images captured by mobile phone camera

// USER SETTINGS //////////////////////////////////////////////////////////////////////
// Define plate layout on image
plates = 5;		// how many plates are present in each image
plateX = newArray(1825, 2930, 1175, 2280, 3420);	// X of top-left well of each plate (px)
plateY = newArray(1090, 1090, 2100, 2100, 2100);	// Y of top-left well of each plate (px)

// For plates with multiple wells (e.g. 6-well plates), define how many and positions)
rows = 1;		// how rows per plate (=1 for whole Petri dishes)
cols = 1;		// how many columns per plate (=1 for whole Petri dishes)
dx = 0;			// horizontal distance between wells
dy = 0;			// vertical distance between wells

// Define diameter of each plate/well to consider
diameter = 1000;    	

// Define detection parameters
thr = 106;		// Bright colony/dark background threshold. Adjust to suit your image.

// Define colony dimension and shape parameters
minSize = 1000;		// lower size limit (px²), higher resolution => larger min. size.
maxSize = 6000000000;	// upper size limit (px²)
minCirc = 0.5;		// circularity lower limit, 1 = perfectly round

// Folder to store results
outputName = "output"

// END USER SETTINGS ///////////////////////////////////////////////////////////////

