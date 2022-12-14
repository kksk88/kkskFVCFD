######################### Initialization #######################
function checkPRatio(Pratio)
    if Pratio < 0
        throw(ArgumentError("Pratio must be positive"))
    end
    if Pratio > 1
        Pratio = 1/Pratio
    end

    return Pratio
end

function initializeShockTubeFDM(nCells=100; domainLength=1, Pratio=10)
    Pratio = checkPRatio(Pratio)

    # Create arrays to store data (cell # = position in array)
    dx = Array{Float64, 1}(undef, nCells)
    U = Array{Float64, 1}(undef, nCells)
    P = Array{Float64, 1}(undef, nCells)
    T = Array{Float64, 1}(undef, nCells)

    # Apply initial conditions (Fig. 1 in Henry's paper)
    for i in 1:nCells
        if i <= (nCells/2)
            T[i] = 0.00348432
            P[i] = 1
        else
            T[i] = 0.00278746
            P[i] = Pratio
        end
        U[i] = 0

        # dx = Distance between cell centers i and i+1
        dx[i] = domainLength / nCells
    end

    return dx, P, T, U
end

function initializeShockTube_StructuredFVM(nCells=100; domainLength=1, Pratio=10, silent=true)
    if !silent
        println("Meshing shock tube, $nCells cells")
    end
    dx, P, T, U = initializeShockTubeFDM(nCells, domainLength=domainLength, Pratio=Pratio)

    cellPrimitives = Array{Float64, 2}(undef, nCells, 3)
    for c in 1:nCells
        cellPrimitives[c,:] = [ P[c], T[c], U[c] ]
    end

    return dx, cellPrimitives
end
#
# Wrapper for FDM initialization function, adding a mesh definition suitable for FVM and vector-format velocity
function initializeShockTubeFVM(nCells=100; domainLength=1, Pratio=10, silent=true)
    if !silent
        println("Meshing shock tube, $nCells cells")
    end
    dx, P, T, U = initializeShockTubeFDM(nCells, domainLength=domainLength, Pratio=Pratio)
    U = []

    #Shock tube dimensions
    h = 0.1
    w = 0.1

    cells = []
    faces = []
    fAVecs = []
    fCenters = []
    boundaryFaces = [ [nCells,], [nCells+1,] ]
    cVols = []
    cCenters = []

    fAVec = [h*w, 0, 0]
    cV = h*w*domainLength/nCells
    dx = dx[1]
    for i in 1:nCells
        # Modify natural face numbering to have boundary faces numbered last
        if i == 1
            push!(cells, [nCells, 1])
            push!(faces, [i, i+1])
        elseif i == nCells
            push!(cells, [nCells-1, nCells+1])
        else
            push!(cells, [i-1, i])
            push!(faces, [i, i+1])
        end

        push!(U, [0.0, 0.0, 0.0] )
        push!(cVols, cV)
        push!(fAVecs, fAVec)
        push!(cCenters, [ (i-0.5)*dx, 0.0, 0.0 ])

        # Face centers also adjusted to have boundaries last
        if i != nCells
            push!(fCenters, [ i*dx, 0.0, 0.0 ])
        else
            # Left boundary face
            push!(fCenters, [ 0.0, 0.0, 0.0 ])
        end
    end

    # Last face
    push!(fAVecs, fAVec)
    # Boundary faces
    push!(faces, [-1,1])
    push!(faces, [nCells, -1])
    push!(fCenters, [ nCells*dx, 0.0, 0.0 ])

    # Returns in mesh format
    mesh = [ cells, cVols, cCenters, faces, fAVecs, fCenters, boundaryFaces ]
    return mesh, P, T, U
end

# Wrapper for FDM initialization function, adding a mesh definition suitable for FVM and vector-format velocity
function initializeShockTube3DFVM(nCells=100; domainLength=1, Pratio=10, silent=true)
    if !silent
        println("Meshing shock tube, $nCells cells")
    end
    dx, P, T, U = initializeShockTubeFDM(nCells, domainLength=domainLength, Pratio=Pratio)

    cellPrimitives = Array{Float64, 2}(undef, nCells, 5)
    for c in 1:nCells
        cellPrimitives[c,:] = [ P[c], T[c], 0.0, 0.0, 0.0 ]
    end

    #Shock tube dimensions
    h = 0.1
    w = 0.1

    cells = []
    faces = []
    fAVecs = []
    fCenters = []
    boundaryFaces = [ [nCells,], [nCells+1,], [] ]
    cVols = []
    cCenters = []
    cellSizes = zeros(nCells, 3)

    fAVec = [h*w, 0, 0]
    cV = h*w*domainLength/nCells
    dx = dx[1]
    for i in 1:nCells
        # Modify natural face numbering to have boundary faces numbered last
        if i == 1
            push!(cells, [nCells, 1])
            push!(faces, [i, i+1])
            push!(fAVecs, fAVec)
        elseif i == nCells
            push!(cells, [nCells-1, nCells+1])
        else
            push!(cells, [i-1, i])
            push!(faces, [i, i+1])
            push!(fAVecs, fAVec)
        end

        push!(cVols, cV)
        push!(cCenters, [ (i-0.5)*dx, 0.0, 0.0 ])

        # Face centers also adjusted to have boundaries last
        if i != nCells
            push!(fCenters, [ i*dx, 0.0, 0.0 ])
        end

        cellSizes[i, :] = [dx, h, w]
    end

    # Boundary faces
    push!(faces, [1,-1])
    push!(fAVecs, -fAVec)
    push!(fCenters, [ 0.0, 0.0, 0.0 ])

    push!(faces, [nCells, -1])
    push!(fAVecs, fAVec)
    push!(fCenters, [ nCells*dx, 0.0, 0.0 ])

    # Add the empty faces on the sides
    for c in 1:nCells
        push!(faces, [c, -1])
        push!(faces, [c, -1])
        push!(faces, [c, -1])
        push!(faces, [c, -1])
        push!(fCenters, [ (c-0.5)*dx, 0.05, 0.0 ])
        push!(fCenters, [ (c-0.5)*dx, -0.05, 0.0 ])
        push!(fCenters, [ (c-0.5)*dx, 0.0, 0.05 ])
        push!(fCenters, [ (c-0.5)*dx, 0.0, -0.05 ])
        push!(boundaryFaces[3], nCells+1+c)
        push!(boundaryFaces[3], nCells+2+c)
        push!(boundaryFaces[3], nCells+3+c)
        push!(boundaryFaces[3], nCells+4+c)
        push!(cells[c], nCells+1+c)
        push!(cells[c], nCells+2+c)
        push!(cells[c], nCells+3+c)
        push!(cells[c], nCells+4+c)
        push!(fAVecs, [0, h*w, 0])
        push!(fAVecs, [0, -h*w, 0])
        push!(fAVecs, [0, 0, h*w])
        push!(fAVecs, [0, 0, -h*w])
    end

    # Returns in mesh format
    mesh = Mesh(cells, cVols, cCenters, cellSizes, faces, fAVecs, fCenters, boundaryFaces)
    return mesh, cellPrimitives
end

############################ Plotting ############################
function plotShockTubeResults_Plotly(P, U, T, rho)
    plots = []
    xAxis = Array{Float64, 1}(undef, nCells)
    for i in 1:nCells
        xAxis[i] = i/nCells - 1/(2*nCells)
    end

    pPlot = plot(xAxis, P, label="P (Pa)", title="Pressure", xlabel="x (m)", bottom_margin=15mm, left_margin=10mm)
    rhoPlot = plot(xAxis, rho, label="rho (kg/m3)", title="Density", xlabel="x (m)", bottom_margin=15mm, left_margin=10mm)
    uPlot = plot(xAxis, U, label="Velocity (m/s)", title="Velocity", xlabel="x (m)", bottom_margin=15mm, left_margin=10mm)
    TPlot = plot(xAxis, T, label="T (K)", title="Temperature", xlabel="x (m)", bottom_margin=15mm, left_margin=10mm)
    plots = [pPlot, rhoPlot, uPlot, TPlot]
    plot(plots..., layout=(2, 2), size=(1720, 880), window_title="Euler1D_Draft_Henry", legend=false)
    gui()
end

function plotShockTubeResults_PyPlot(P, U, T, rho)
    plots = []
    xAxis = Array{Float64, 1}(undef, nCells)
    for i in 1:nCells
        xAxis[i] = i/nCells - 1/(2*nCells)
    end

    pPlot = plot(xAxis, P, label="P (Pa)", title="Pressure", xlabel="x (m)")
    rhoPlot = plot(xAxis, rho, label="rho (kg/m3)", title="Density", xlabel="x (m)")
    uPlot = plot(xAxis, U, label="Velocity (m/s)", title="Velocity", xlabel="x (m)")
    TPlot = plot(xAxis, T, label="T (K)", title="Temperature", xlabel="x (m)")
    plots = [pPlot, rhoPlot, uPlot, TPlot]
    plot(plots..., layout=(2, 2), size=(860, 600), window_title="Euler1D_Draft_Henry", legend=false)
    gui()
end
