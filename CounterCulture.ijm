// CounterCulture
// Version 0.1
// 2025-08-08
// Author: Danna R. Gifford


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











///////////////////////////////////////////////////////////////
// CODE FOR PERFORMING COLONY COUNTING
// Editing below this line can cause the script to break ... Proceed with caution!

// Clear log file from previous run
close("Log");

// defineWells() --> Defines Regions of Interest (ROIs) of the image containing each well/plate to analyse
function defineWells(np, ncol, nrow, dia, dx, dy) { 
	// Clear existing ROIs
	roiManager("Reset");
	// Define well regions
	for (p = 0; p < np; p++) {
	  baseX = plateX[p];
	  baseY = plateY[p];
	  for (col = 0; col < ncol; col++) {
	      for (row = 0; row < nrow; row++) {
	      col2 = 1 - col;
	      x = baseX + col2 * dx;
	      y = baseY + row * dy;
	      makeOval(x - diameter/2, y - diameter/2, diameter, diameter);
	      idx = row + col*nrow + p*nrow*ncol; // +1 below
	      roiManager("Add");
	      roiManager("Select", idx);
	      roiManager("Rename", "Well_" + (idx + 1));
	    }
	  }
	}
	
	// Allow user to adjust well positions if desired before proceeding
	mauallyAdjusted = "not selected";
	if (adjustWells == 1) {
		roiManager("Show all with labels");
		selectWindow("ROI Manager");
		manuallyAdjusted = "selected";
		waitForUser("Adjust well positions?",
			"You can adjust well positions by selecting them\nin the ROI manager and resizing or dragging their\nposition on the image. \n \n Click OK when ready to proceed.");
		// Reorder the ROI indexes in case the user replaced some wells
		//// Zero-pad all Well_<n> names so lexicographic sorting works
		n = roiManager("count");
		for (i = 0; i < n; i++) {
		    roiManager("Select", i);
		    oldName = Roi.getName;
		    // assume names are exactly "Well_<number>"
		    numStr = substring(oldName, 5);   // from char 5 to end
		    numVal = parseInt(numStr);
		    // only pad the single-digit ones
		    if (numVal < 10) {
		        newName = "Well_0" + numVal;
		        roiManager("Rename", newName);
		    }
		}
		//// Sort lexicographically
		roiManager("Sort");
		
		//// Reinstate old non-zero-padded well names
		for (i = 0; i < n; i++) {
		    roiManager("Select", i);
		    oldName = Roi.getName();
		    numStr = substring(oldName, 6);        // skip "Well_0" (char 0–5), grab the rest
		    numVal = parseInt(numStr);
		    // now rename back to "Well_<numVal>"
		    newName = "Well_" + numVal;
		    roiManager("Rename", newName);
		}
	} else {
		manuallyAdjusted = "not selected";
		}
	print("Well sizes/positions manually adjusted?: " + manuallyAdjusted);
}	

// segregateColonies() --> Apply filters to make colonies distinct from the rest of the image
function segregateColonies(thr){
	// Make image greyscale
	run("8-bit"); 
	
	//Combine well ROIs into one for image segregation
	n = roiManager("Count");
	indices = newArray(n);
	for (i = 0; i < n; i++) {
	    indices[i] = i;
	}
	roiManager("Select", indices);
	roiManager("Combine"); // combines ROIs into a single selection
	
	// Local contrast: this was tried but gives spurious counts when few colonies.
	// Enhance contrast of colonies from agar
		// blocksize: size of the contextual regions (in pixels)  
			// histogram: number of histogram bins per block  
			// maximum: the maximum slope (larger = more contrast)  
			// mask: *None* (no mask) or name of a mask image  
			// fast_(less_accurate): use the faster approximation if you like  
	//run("Enhance Local Contrast (CLAHE)",  
	//    "blocksize=127 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");  
	
	// Enhance distance between colonies and fill gaps
	run("Morphological Filters", "operation=Opening element=Disk radius=2");
	run("Morphological Filters", "operation=Closing element=Disk radius=2");
	
	// Subtract background with rolling ball radius 200  
	run("Subtract Background...", "rolling=200 dark");

	run("Enhance Contrast...", "saturated=0.3");

	// Make image binary
	run("Convert to Mask");

	// Separate touching colonies
	run("Watershed");
}

// identifyColonies() --> Trace colonies as new ROIs
function identifyColonies(minSize, maxSize, minCirc){

	// How many plates/wells are defined as ROIs?
	n = roiManager("Count");
	// Loop over ROIs to identify colonies
	for (i = 0; i < n; i++) {
	    // Select ROI i and apply it
	   	roiManager("Select", i);
	    wellName = "Well_" + (i + 1);
	    
		// Number of ROIs already there, needed to keep track of how many colonies found
		initialCount = roiManager("count");
		
		// Outline colonies as ROIs
		run("Set Measurements...", "area centroid redirect=None decimal=3");
		run("Analyze Particles...", 
			"size=" + minSize + "-" + maxSize + " pixel " + " circularity=" + minCirc + "-1.0 add");
			
		// Count out how many ROIs were just added
		totalCount = roiManager("count");
		newCount   = totalCount - initialCount;

		// Assign each new colony ROI a well name and a number, e.g. Well_1_1, Well_1_2, etc.
		for (k = 0; k < newCount; k++) {
		    idx = initialCount + k;
		    roiManager("Select", idx);
		    roiManager("Rename", wellName + "_" + (k+1));
		}
	}
		if (adjustColonies == 1) {
			roiManager("Show all with labels");
			selectWindow("ROI Manager");
			manuallyColonies = "selected";
			waitForUser("Manually edit colonies?",
				"You can remove spurious colonies by selecting them\nin the ROI Manager and clicking \"Delete\". \nYou can also add missed colonies as a new ROI using Oval or Freehand select, \nand then clicking \"Add [t]\" in the ROI Manager. \n \n Click OK when ready to proceed.");
	    } else{
	    	manuallyColonies = "not selected";
	    }
		print("Colonies manually edited?: " + manuallyColonies);
}

// saveColonies() --> Save colony ROIs to (1) a zip file, (2) a TSV to use in R to get counts, (3) on to each image for later checking.
function saveColonies(outputDir, imageName) {
	baseName = replace(imageName, "\\.(tiff|tif|png|jpg|jpeg)","");
	// Build the output path
	outFile = outputDir + baseName + "_roi.zip";

	// Save the colony ROIs to a zip file
	roiManager("save", outFile);
	print("Saved colony ROIs to: " + outFile);
		
	// Save a list of the colony ROIs to TSV
	outList = outputDir + baseName + "_roi_list.tsv";
	roiManager("List");
	saveAs("Results", outList);
	print("Wrote colony ROI properties to: " + outList);
	
	// Close ROI output TSV list
	openWindows = getList("window.titles");
	for (i = 0; i < openWindows.length; i++) {
	    if(matches(openWindows[i],".+\\.tsv")){
			close(openWindows[i]);
		}
	}
	
	// Save image with colony ROIs for later inspection
	selectWindow(imageName);
	roiManager("Show All");
	
	// Flatten the ROIs into the image (merges the overlay into the pixel data)
	run("Flatten");
	//close(imageName);

	// Save image
	colonyImage = outputDir + baseName + "_colonies.png";
	saveAs("Png", colonyImage);
	roiManager("Reset");	
	close(imageName);

}



//////////////////////////////////////
// INITIALISE ENVIRONMENT
//////////////////////////////////////

// Close all open windows
run("Close All");

// Log file header
print("================================");
print("=== Colony counting Analysis ===");
print("================================");
timeNow = call("java.time.Instant.now");
timeNowString = "" + timeNow;
print("Begin: " + timeNowString);

// Ask user to select input folder
inputDir  = getDirectory("Choose input folder");
outputDir = inputDir + outputName + "/";
File.makeDirectory(outputDir);

print("Input files taken from: " + inputDir);
print("Output files saved in: "  + outputDir);

// Ask user for file extension
extension = getString("Please enter image file extension (e.g. tiff, png, jpg, etc.)", "tiff");
print("Looking for image files with extension: " + extension + "...");

// Get a list of all files in that folder
fileList = getFileList(inputDir);

// Print all files found in folder
print("Found these files:");
	for (i=0; i<fileList.length; i++) {
		if(endsWith(fileList[i], extension)) {
			print("      Found: " + fileList[i] );
		}
	}


// Print settings to log file
plateXj = String.join(plateX);
plateYj = String.join(plateY);
print("Analysis settings:\n" +
"    plate diameter = " + diameter + " (px)" + "\n" +
"    dx = " + dx + " (px)" + "\n" +
"    dy = " + dx + " (px)" + "\n" +
"    plates = " + plates + "\n" +
"    plateX = " + plateXj + "\n" +
"    plateY = " + plateYj + "\n" +
"    thr = " + thr + " (threshold for binarisation step)" + "\n" +
"    minSize = " + minSize + " (px)" + "\n" +
"    maxSize = " + maxSize + " (px)" + "\n" +
"    rows = " + rows + " (per plate)" + "\n" +
"    cols = " + cols + " (per plate)" + "\n" +
"    minCirc = " + minCirc + " (minimum circularity) \n")


// Ask if user wants to adjust well positions manually
adjustWells = getBoolean("Do you want to manually adjust well positions for each image?");
adjustColonies = getBoolean("Do you want to manually edit detected colonies?");

/////////////////////////////////////
// RUN ANALYSIS
/////////////////////////////////////

// Loop over images in the chosen folder with chosen extension
for (i = 0; i < fileList.length; i++) {
	imageName = fileList[i];
	// Skip non-images
	if (!endsWith(imageName, extension)) {
		//print("File " + imageName + " is not an image. Skipping...");
		continue;
	}
	print("==========");
	print("Analysing: " + imageName);
	open(inputDir + imageName);
	close("\\Others");
	
	// Call image analysis functions defined above
	defineWells(plates, cols, rows, diameter, dx, dy);
	segregateColonies(thr);
	identifyColonies(minSize, maxSize, minCirc);
	saveColonies(outputDir, imageName);
}

// Close all remaining open image files
run("Close All");

/////////////////////////////////////
// SAVE LOG FILE
/////////////////////////////////////

print("================================");
print("Analysis completed successfully!");
timeNow = call("java.time.Instant.now");
timeNowString = "" + timeNow;
print("End: " + timeNowString);
print("================================");
selectWindow("Log");
saveAs("text", outputDir + "log.txt");
close("ROI Manager");
//close("Log");

//////////////////////////////////////
