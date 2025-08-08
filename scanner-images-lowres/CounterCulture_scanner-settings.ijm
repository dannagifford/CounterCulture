// USER SETTINGS FOR SCANNER IMAGES
// COPY/PASTE THESE SETTINGS INTO colonyCountScript.ijm to analyse the images captured by flatbed scanner

// USER SETTINGS //////////////////////////////////////////////////////////////////////
// Define plate layout on image
plates = 3;		// how many plates are present in each image
plateX = newArray(6800, 6800, 6800); 			// X of top-left well of each plate (px)
plateY = newArray(2900, 7100, 11170);			// Y of top-left well of each plate (px)

// For plates with multiple wells (e.g. 6-well plates), define how many and positions)
rows = 1;		// how rows per plate (=1 for whole Petri dishes)
cols = 1;		// how many columns per plate (=1 for whole Petri dishes)
dx = 0;			// horizontal distance between wells
dy = 0;			// vertical distance between wells

// Define diameter of each plate/well to consider
diameter = 3900;    	

// Define detection parameters
thr = 106;		// Bright colony/dark background threshold. Adjust to suit your image.

// Define colony dimension and shape parameters
minSize = 1000;		// lower size limit (px²), higher resolution => larger min. size.
maxSize = 6000000000;	// upper size limit (px²)
minCirc = 0.5;		// circularity lower limit, 1 = perfectly round

// Folder to store results
outputName = "output"

// END USER SETTINGS ///////////////////////////////////////////////////////////////
