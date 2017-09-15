# Try converting a string into a number
function tryNumberify(tagValue::String)
    outValue = tagValue
    try outValue = float(tagValue)
    catch
        splitTagValue = split(tagValue, " ")
        try outValue = [float(i) for i in splitTagValue]
        end
    end
    return outValue
end

# Parse the header files (i.e. d3proc, reco, visu_pars)
function parseHeaderFile(pathToFile::String)
    file_IO = open(pathToFile)
    hdrText = readstring(file_IO)
    close(file_IO)
    
    hdrElements = replace(hdrText, "\n", "")
    hdrElements = split(hdrElements, "##\$")
    deleteat!(hdrElements,1)
    
    tagNames=[replace(i, r"(.*?)=(.*)", s"\1") for i in hdrElements] # Get tag names/fields
    tagValues=[replace(i, r"(.*?)=(.*)", s"\2") for i in hdrElements] # Get values for each tag name/field
    tagValues=[replace(i, r"\([^\)]+\)\s?", "") for i in tagValues] # Remove parenthesis
    tagValues=[replace(i, r"\$.*", "") for i in tagValues] # Remove the '$$ @vis' endings 
    tagValues=[replace(i, r"[<>]", "") for i in tagValues] # Remove '<' and '>'
    myDict = Dict(zip(tagNames,[tryNumberify(i) for i in tagValues]))
    return myDict
end

# MAIN FUNCTION - loads image data from paravision's d3seq
function load2dseq(pathTo2dseq::String)
    baseDir = dirname(pathTo2dseq)
    
    filesToLookFor = ["d3proc", "reco", "visu_pars"]
    hdrDict = Dict(zip(filesToLookFor,[Dict() for i in filesToLookFor]))    
    for file in filesToLookFor
        if isfile(joinpath(baseDir,file))
           hdrDict[file] = parseHeaderFile(joinpath(baseDir,file))
        end
    end
    
    if length(hdrDict["visu_pars"]) > 0
        visuPars = hdrDict["visu_pars"]
        coreSize = visuPars["VisuCoreSize"]
        coreFrames = visuPars["VisuCoreFrameCount"]
        byteType = visuPars["VisuCoreWordType"]
        slopes = visuPars["VisuCoreDataSlope"]
        offsets = visuPars["VisuCoreDataOffs"]
    elseif length(hdrDict["reco"]) > 0
        visuPars = hdrDict["reco"]
        coreSize = visuPars["RECO_size"]
        slopes = 1 ./ visuPars["RECO_map_slope"] # RECOslope is 1/visuparsSlope
        offsets = visuPars["RECO_map_offset"]
        byteType = visuPars["RECO_wordtype"]
        # Infer number of frames by number of slopes
        coreFrames = length(slopes)
    else
        print("Need visu_pars or reco file to read data")
    end
    
    totalSize = [coreSize; coreFrames]  
    imgData = read(pathTo2dseq, byteDict[byteType], tuple(Int.(totalSize)...))

    # Using a shortcut that assumes that all frames have same slope, so verify that first
    @assert minimum(slopes) == maximum(slopes)
    imgData = imgData .* slopes[1] .+ offsets[1]
    
    return(imgData, hdrDict)
end

byteDict = Dict("_8BIT_UNSGN_INT" => Int8, "_16BIT_SGN_INT" => Int16, "_32BIT_SGN_INT" => Int32, "_32BIT_FLOAT" => Float32)