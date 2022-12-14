######################### Global Time Stepping ###########################
function forwardEuler(mesh::Mesh, fluxResidualFn, sln::SolutionState, boundaryConditions, fluid::Fluid, dt)
    sln.fluxResiduals = fluxResidualFn(mesh, sln, boundaryConditions, fluid)
    @fastmath sln.cellState .+= sln.fluxResiduals.*dt
    @fastmath decodeSolution_3D(sln, fluid)

    return sln
end

function RK2_Mid(mesh, fluxResidualFn, sln, boundaryConditions, fluid::Fluid, dt)
    fluxResiduals1 = fluxResidualFn(mesh, sln, boundaryConditions, fluid)
    halfwayEstimate = sln.cellState .+ fluxResiduals1.*dt/2
    solutionState2 = SolutionState(halfwayEstimate, sln.cellFluxes, sln.cellPrimitives, sln.fluxResiduals, sln.faceFluxes)
    decodeSolution_3D(solutionState2, fluid)

    sln.fluxResiduals = fluxResidualFn(mesh, solutionState2, boundaryConditions, fluid)
    sln.cellState .+= sln.fluxResiduals.*dt
    decodeSolution_3D(sln, fluid)

    return sln
end

function RK4(mesh, fluxResidualFn, sln, boundaryConditions, fluid::Fluid, dt)

    fluxResiduals1 = fluxResidualFn(mesh, sln, boundaryConditions, fluid)
    halfwayEstimate = sln.cellState .+ fluxResiduals1*dt/2
    lastSolutionState = SolutionState(halfwayEstimate, sln.cellFluxes, sln.cellPrimitives, sln.fluxResiduals, sln.faceFluxes)
    decodeSolution_3D(lastSolutionState, fluid)

    fluxResiduals2 = fluxResidualFn(mesh, lastSolutionState, boundaryConditions, fluid)
    halfwayEstimate2 = sln.cellState .+ fluxResiduals2*dt/2
    lastSolutionState.cellState = halfwayEstimate2
    decodeSolution_3D(lastSolutionState, fluid)

    fluxResiduals3 = fluxResidualFn(mesh, lastSolutionState, boundaryConditions, fluid)
    finalEstimate1 = sln.cellState .+ fluxResiduals3*dt
    lastSolutionState.cellState = finalEstimate1
    decodeSolution_3D(lastSolutionState, fluid)

    fluxResiduals4 = fluxResidualFn(mesh, lastSolutionState, boundaryConditions, fluid)
    sln.cellState .+= (fluxResiduals1 .+ 2*fluxResiduals2 .+ 2*fluxResiduals3 .+ fluxResiduals4 )*(dt/6)
    decodeSolution_3D(sln, fluid)

    return sln
end

function ShuOsher(mesh, fluxResidualFn, sln, boundaryConditions, fluid::Fluid, dt)

    fluxResiduals1 = fluxResidualFn(mesh, sln, boundaryConditions, fluid)
    endEstimate = sln.cellState .+ fluxResiduals1.*dt
    lastSolutionState = SolutionState(endEstimate, sln.cellFluxes, sln.cellPrimitives, sln.fluxResiduals, sln.faceFluxes)
    decodeSolution_3D(lastSolutionState, fluid)

    fluxResiduals2 = fluxResidualFn(mesh, lastSolutionState, boundaryConditions, fluid)
    estimate2 = (3/4).*sln.cellState .+ (1/4).*(endEstimate .+ fluxResiduals2.*dt)
    lastSolutionState.cellState = estimate2
    decodeSolution_3D(lastSolutionState, fluid)

    fluxResiduals3 = fluxResidualFn(mesh, lastSolutionState, boundaryConditions, fluid)
    sln.cellState .= (1/3).*sln.cellState .+ (2/3).*(estimate2 .+ dt.*fluxResiduals3)
    decodeSolution_3D(sln, fluid)

    return sln
end

######################### Local Time Stepping ###########################
# Incomplete, will be commented more fully once it produces nice solutions and the implementation is finalized
function LTSEuler(mesh, fluxResidualFn, sln, boundaryConditions, fluid::Fluid, dt)
    targetCFL = dt[1]

    fluxResiduals = fluxResidualFn(mesh, sln, boundaryConditions, fluid)

    CFL!(dt, mesh, sln, fluid, 1)
    dt .= targetCFL ./ dt
    smoothTimeStep!(dt, mesh, 0.1)
    smoothTimeStep!(dt, mesh, 0.1)
    sln.cellState .+= fluxResiduals .* dt
    decodeSolution_3D(sln, fluid)

    return sln
end

function smoothTimeStep!(dt, mesh::Mesh, diffusionCoefficient=0.2)
    nCells, nFaces, nBoundaries, nBdryFaces = unstructuredMeshInfo(mesh)

    timeFluxes = zeros(nCells)
    surfaceAreas = zeros(nCells)
    for f in 1:nFaces-nBdryFaces
        ownerCell = mesh.faces[f][1]
        neighbourCell = mesh.faces[f][2]
        timeFlux = (dt[ownerCell] - dt[neighbourCell]) * mag(mesh.fAVecs[f])
        surfaceAreas[ownerCell] += mag(mesh.fAVecs[f])
        surfaceAreas[neighbourCell] += mag(mesh.fAVecs[f])
        timeFluxes[ownerCell] -= timeFlux
        timeFluxes[neighbourCell] += timeFlux
    end

    timeFluxes .*= (diffusionCoefficient ./ surfaceAreas)

    for i in eachindex(timeFluxes)
        timeFluxes[i] = min(0, timeFluxes[i])
    end

    dt .+= timeFluxes
end

#TODO: For implicit methods, need to compute the flux Jacobians at each edge, instead of just the fluxes
    # Use Jacobians as coefficients in matrix representing timestepping equations
    # Then solve with GMRES or some other matrix solver
