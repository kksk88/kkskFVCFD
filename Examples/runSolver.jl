include("fvCFD.jl")
include("shockTube.jl")


### Supersonic Wedge ###
# Freestream Conditions (Mach 2)
# P = 100000
# T = 300
# U = [ 694.44, 0, 0 ]

# meshPath = "test/OFunstructuredWedgeMesh"
# boundaryConditions = [ emptyBoundary, [], supersonicInletBoundary, [P, T, U..., 1005], zeroGradientBoundary, [], symmetryBoundary, [], zeroGradientBoundary, [], wallBoundary, [] ]
# meshPath = "test/OFwedgeMesh"
# boundaryConditions = [ supersonicInletBoundary, [P, T, U..., 1005], zeroGradientBoundary, [], symmetryBoundary, [], zeroGradientBoundary, [], wallBoundary, [], emptyBoundary, [] ]
# meshPath = "test/OFcoarseWedgeMesh"
# boundaryConditions = [ emptyBoundary, [], supersonicInletBoundary, [P, T, U..., 1005], zeroGradientBoundary, [], symmetryBoundary, [], zeroGradientBoundary, [], wallBoundary, [] ]
# meshPath = "test/OFmemesWedgeMesh"
# boundaryConditions = [ symmetryBoundary, [], emptyBoundary, [], supersonicInletBoundary, [P, T, U..., 1005], wallBoundary, [], zeroGradientBoundary, [], zeroGradientBoundary, [] ]

# mesh = OpenFOAMMesh(meshPath)
# cellPrimitives = initializeUniformSolution3D(mesh, P, T, U...)
# solve(mesh, meshPath, cellPrimitives, boundaryConditions, initDt=0.00000001, endTime=0.001, outputInterval=0.005, targetCFL=0.5, silent=false)

### Forward Step ###
# Freestream Conditions (Mach 3)
P = 100000
T = 300
U = [ 1041.66, 0, 0 ]

# meshPath = "test/OFforwardStepMesh"
# boundaryConditions = [ supersonicInletBoundary, [P, T, U..., 1005], zeroGradientBoundary, [], symmetryBoundary, [], symmetryBoundary, [], wallBoundary, [], emptyBoundary, [] ]
meshPath = "test/OFforwardStepFineMesh"
boundaryConditions = [ supersonicInletBoundary, [P, T, U..., 1005], zeroGradientBoundary, [], symmetryBoundary, [], symmetryBoundary, [], wallBoundary, [], emptyBoundary, [] ]

# Solve
mesh = OpenFOAMMesh(meshPath)
cellPrimitives = initializeUniformSolution3D(mesh, P, T, U...)
solve(mesh, meshPath, cellPrimitives, boundaryConditions, ShuOsher, initDt=0.00000001, endTime=0.03, outputInterval=0.000072, targetCFL=0.95, silent=false, restart=false)

#### Simple convection ####
# mesh, cellPrimitives = initializeShockTube3DFVM(10)
# P = 100000
# T = 300
# U = [ 694.26, 0, 0 ]
# boundaryConditions = [ supersonicInletBoundary, [P, T, U..., 1005], zeroGradientBoundary, [], emptyBoundary, [] ]
# P, U, T, rho = solve(mesh, initializeUniformSolution3D(mesh, P, T, U...), boundaryConditions, initDt=0.0000001, endTime=0.00002, targetCFL=0.1, silent=false)
# plotShockTubeResults_PyPlot(P, U, T, rho)



###################################################### FORMERLY RUNSHOCKTUBE ###############################################################

# println("Meshing")
#### FDM or Structured FVM ###
# cellPrimitives = solve(initializeShockTube3DFVM(nCells)..., ShuOsher, initDt=0.00001, endTime=0.14267, targetCFL=0.05, silent=false)
# xVel = U

### UnstructuredFVM from OpenFOAM Meshes ###
# meshPath = "test/OFshockTube_100"
# OFmesh = OpenFOAMMesh(meshPath)
# nCells = size(OFmesh.cells, 1)

# _, cellPrimitives = initializeShockTube3DFVM(nCells...)

# boundaryConditions = [ zeroGradientBoundary, [], emptyBoundary, [] ]
# cellPrimitives = solve(OFmesh, meshPath, cellPrimitives, boundaryConditions, LTSEuler, initDt=0.0001, endTime=0.14267, outputInterval=0.14267, targetCFL=0.1, silent=false, createVTKOutput=true)
# @profview solve(OFmesh, meshPath, cellPrimitives, boundaryConditions, initDt=0.00001, endTime=0.14267, outputInterval=0.14267, targetCFL=0.1, silent=true)
# @btime solve(OFmesh, meshPath, cellPrimitives, boundaryConditions, initDt=0.00001, endTime=0.005, outputInterval=0.14267, targetCFL=0.01, silent=true, createRestartFile=false, createVTKOutput=false)
# @code_warntype solve(OFmesh, meshPath, cellPrimitives, boundaryConditions, initDt=0.00001, endTime=0.00001, outputInterval=0.14267, targetCFL=0.01, silent=true, createRestartFile=false, createVTKOutput=false)

# P = cellPrimitives[:,1]
# T = cellPrimitives[:,2]
# xVel = cellPrimitives[:,3]
# rho = zeros(nCells)
# for i in 1:nCells
#     rho[i] = idealGasRho(T[i], P[i])
# end
#
# println("Plotting results")
# plotShockTubeResults_PyPlot(P, xVel, T, rho)


###################################################### FORMERLY RUNAIRFOIL ###############################################################
# Freestream Conditions
# P = 100000
# T = 300
# U = [ 277.7091, 6.059633, 0 ]
# UunitVec = normalize(U)
# gamma = 1.4
# R = 287.05
# Cp = 1005

# a = sqrt(gamma*R*T)
# machNum = mag(U)/a
# Pt = P*(1 + ((gamma-1)/2)*machNum^2)^(gamma/(gamma-1))
# Tt = T*(1 + ((gamma-1)/2)*machNum^2)

# Choose a mesh
# meshPath = "test/OFairfoilMesh"
# meshPath = "test/OFmemesAirfoilMesh"
# boundaryConditions = [ wallBoundary, [], emptyBoundary, [], subsonicInletBoundary, [Pt, Tt, UunitVec..., gamma, R, Cp], pressureOutletBoundary, P ]
#
# Solve
# mesh = OpenFOAMMesh(meshPath)
# cellPrimitives = initializeUniformSolution3D(mesh, P, T, U...)
# solve(mesh, meshPath, cellPrimitives, boundaryConditions, LTSEuler, initDt=0.0000001, endTime=100, outputInterval=25, targetCFL=0.5, silent=false)
# solve(mesh, meshPath, cellPrimitives, boundaryConditions, initDt=0.0000001, endTime=0.00008, outputInterval=0.00002, targetCFL=0.5, silent=false)


# ### Delta Wing ###
# # Freestream Conditions
# P = 7669
# T = 180
# U = [ 539, 0, 0 ]
#
# # Choose a mesh
# meshPath = "test/OFmemesDeltaMesh"
# boundaryConditions = [ supersonicInletBoundary, [P, T, U...], zeroGradientBoundary, [], symmetryBoundary, [], wallBoundary, [] ]

### Cone Flare ###
# Freestream Conditions
# P = 100000
# T = 300
# U = [ 694.26, 0, 0 ]
#
# # Choose a mesh
# meshPath = test/OFflaredConeMesh"
# boundaryConditions = [ supersonicInletBoundary, [P, T, U...], zeroGradientBoundary, [], wallBoundary, [] ]

# Solve
# mesh = OpenFOAMMesh(meshPath)
# cellPrimitives = initializeUniformSolution3D(mesh, P, T, U...)
# solve(mesh, meshPath, cellPrimitives, boundaryConditions, LTSEuler, initDt=0.00000001, endTime=18000, outputInterval=9.3, targetCFL=0.1, silent=false, restart=false)
