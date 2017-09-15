## Description

This is just a small function for loading images from a 2dseq file into Julia. 
The results between the current code and [this matlab code](http://aedes.uef.fi/browser/aedes_readbruker.m) were identical (aside from a difference in image rotation), 
but it still hasn't been extensively tested, so use at your own risk. 

### Usage:

- Load the functions (either copy/paste or `include("path/to/load2dseq.jl")`).
- To use: `(imgData, hdrs) = load2dseq("path/to/2dseq")`
  + `imgData` is an array (2D, 3D, 4D) of the image data in the 2dseq file
  + `hdrs` contain information from the 'd3proc', 'reco', and 'visu_pars' files
    * d3proc headers = hdrs["d3proc"]
    * reco headers = hdrs["reco"]
    * visu_pars headers = hdrs["visu_pars"]
