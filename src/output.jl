using DelimitedFiles
using WriteVTK

#### Read / Write Restart Files ####
function writeRestartFile(cellPrimitives, path="FvCFDRestart.txt")
    writedlm(path, cellPrimitives)
end

function readRestartFile(path="FvCFDRestart.txt")
    cellPrimitives = readdlm(path)
end

function outputVTK(meshPath, cellPrimitives, fileName="solution")
    points, cellIndices = OpenFOAMMesh_findCellPts(meshPath)
    points = transpose(points)
    cells = Array{MeshCell, 1}(undef, 0)

    cellType = [ 1, 3, 5, 10, 14, 13, "ERROR", 12 ] # This array maps from number of points in a cell to the .vtk numeric cell type. Example: 8 pts -> "12", which is .vtk code for "VTK_HEXAHEDRON"
    # Corresponding .vtk cell types: [ "VTK_VERTEX", "VTK_LINE", "VTK_TRIANGLE", "VTK_TETRA", "VTK_PYRAMID", "VTK_WEDGE", "ERROR", "VTK_HEXAHEDRON" ]

    for i in eachindex(cellIndices)
        nPoints = length(cellIndices[i].pointIndices)
        cT = cellType[nPoints]
        cell = MeshCell(VTKCellType(cT), cellIndices[i].pointIndices)
        push!(cells, cell)
    end

    file = vtk_grid(fileName, points, cells)
    file["P"] = cellPrimitives[:,1]
    file["T"] = cellPrimitives[:,2]
    file["U"] = transpose(cellPrimitives[:,3:5])
    
    return vtk_save(file)
end

#=
    Calls above functions to output restart and .vtk files, if desired.

    Inputs:
        cellPrimitives: should come from sln.cellPrimitives
        restartFile: (string) path to which to write restart file
        meshPath: (string) path to OpenFOAM mesh FOLDER
        createRestartFile: (bool)
        createVTKOutput: (bool)

    Will overwrite existing restart files
    Will not overwrite existing .vtk files
=#
function writeOutput(cellPrimitives, restartFile, meshPath, createRestartFile, createVTKOutput)
    if createRestartFile
        println("Writing Restart File: $restartFile")
        writeRestartFile(cellPrimitives, restartFile)
    end

    if createVTKOutput
        # Check for next available filename
        files = readdir()
        maxNum = 0
        for item in files
            if occursin("solution", item)
                slnNumber = parse(Int, item[10:end-4])
                maxNum = max(maxNum, slnNumber)
            end
        end
        vtkCounter = maxNum + 1

        # Write vtk file
        solnName = "solution.$vtkCounter"
        println("Writing $solnName")
        outputVTK(meshPath, cellPrimitives, solnName)
    end
end
