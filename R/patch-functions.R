################################################################################
#' Diffuse values in a world
#'
#' Each patch gives an equal share of a portion of its value to its neighbor patches.
#'
#' @inheritParams fargs
#'
#' @param share      Numeric. Value between 0 and 1 representing the portion of
#'                   the patches values to be diffused among the neighbors.
#'
#' @return NLworlds object with patches values updated.
#'
#' @details What is given is lost for the patches.
#'
#'          Patches on the sides of the \code{world} have less than 4 or 8 neighbors.
#'          Each neighbor still gets 1/4 or 1/8 of the shared amount and the diffusing
#'          patch keeps the leftover.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#diffuse}
#'
#'          \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#diffuse4}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 4, minPycor = 0, maxPycor = 4)
#' w1[] <- runif(length(w1))
#' plot(w1)
#' # Diffuse 50% of each patch value to its 8 neighbors
#' w2 <- diffuse(world = w1, share = 0.5, nNeighbors = 8)
#' plot(w2)
#'
#'
#' @export
#' @docType methods
#' @rdname diffuse
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "diffuse",
  function(world, pVar, share, nNeighbors) {
    standardGeneric("diffuse")
  })

#' @export
#' @rdname diffuse
setMethod(
  "diffuse",
  signature = c("NLworld", "missing", "numeric", "numeric"),
  definition = function(world, share, nNeighbors) {

    worldVal_from <- values(world)
    cellNum <- 1:length(worldVal_from)
    toGive <- (worldVal_from * share) / nNeighbors
    df1 <- cbind.data.frame(cellNum, toGive)
    df2 <- as.data.frame(adjacent(world, cells = cellNum, directions = nNeighbors))
    df3 <- merge(df2, df1, by.x = "from", by.y = "cellNum", all = TRUE)
    loose <- tapply(df3$toGive, FUN = sum, INDEX = df3$from) # how much each patch give
    win <- tapply(df3$toGive, FUN = sum, INDEX = df3$to) # how much each patch receive
    new_worldVal <- worldVal_from - loose + win

    newWorld <- setValues(world, as.numeric(new_worldVal))
    return(newWorld)
  }
)

#' @export
#' @rdname diffuse
setMethod(
  "diffuse",
  signature = c("NLworldStack", "character", "numeric", "numeric"),
  definition = function(world, pVar, share, nNeighbors) {
    pos_l <- which(names(world) == pVar, TRUE) # find the layer
    world_l <- world[[pos_l]]
    newWorld <- diffuse(world = world_l, share = share, nNeighbors = nNeighbors)
    world[[pos_l]]@data@values <- values(newWorld)
    return(world)
  }
)


################################################################################
#' Distances between agents
#'
#' Report the distances between \code{agents} and \code{agents2}.
#'
#' @inheritParams fargs
#'
#' @param allPairs Logical. Only relevant if the number of agents/locations in
#'                 \code{agents} and in \code{agents2} are the same. If \code{allPairs = FALSE},
#'                 the distance between each \code{agents} with the
#'                 corresponding \code{agents2} is returned. If \code{allPairs = TRUE}, a full
#'                 distance matrix is returned. Default is \code{allPairs = FALSE}.
#'
#' @return Numeric. Vector of distances between \code{agents} and \code{agents2} if
#'         \code{agents} and/or \code{agents2} contained
#'         one agent/location, or if \code{agents} and \code{agents2} contained the same
#'         number of agents/locations and \code{allPairs = FALSE}, or
#'
#'         Matrix of distances between \code{agents} (rows) and \code{agents2} (columns)
#'         if \code{agents} and \code{agents2} are of different lengths, or of same length
#'         and \code{allPairs = TRUE}.
#'
#' @details Distances from/to a patch are measured from/to its center.
#'
#'          If \code{torus = TRUE}, a distance around the sides of the \code{world} is
#'          reported only if smaller than the one across the \code{world} (i.e., as calculated
#'          with \code{torus = FALSE}).
#'
#'          Coordinates of \code{agents} and \code{agents2} must be inside the \code{world}'s extent.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#distance}
#'
#'          \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#distancexy}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' NLdist(world = w1, agents = patch(w1, 0, 0), agents2 = patch(w1, c(1, 9), c(1, 9)))
#' NLdist(world = w1, agents = patch(w1, 0, 0), agents2 = patch(w1, c(1, 9), c(1, 9)), torus = TRUE)
#' t1 <- createTurtles(n = 2, coords = randomXYcor(w1, n = 2))
#' NLdist(world = w1, agents = t1, agents2 = patch(w1, c(1,9), c(1,9)), allPairs = TRUE)
#'
#'
#' @export
#' @docType methods
#' @rdname NLdist
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "NLdist",
  function(world, agents, agents2, torus = FALSE, allPairs = FALSE) {
    standardGeneric("NLdist")
  })

#' @export
#' @rdname NLdist
setMethod(
  "NLdist",
  signature = c(world = "NLworlds", agents = "matrix", agents2 = "matrix"),
  definition = function(world, agents, agents2, torus, allPairs) {

    if(min(agents[,1]) < world@extent@xmin | max(agents[,1]) > world@extent@xmax |
       min(agents[,2]) < world@extent@ymin | max(agents[,2]) > world@extent@ymax |
       min(agents2[,1]) < world@extent@xmin | max(agents2[,1]) > world@extent@xmax |
       min(agents2[,2]) < world@extent@ymin | max(agents2[,2]) > world@extent@ymax){
      stop("Given coordinates are outside the world's extent.")
    }

    dist <- pointDistance(p1 = agents, p2 = agents2, lonlat = FALSE, allpairs = allPairs)

    if(torus == TRUE){
      # Need to create coordinates for "agents2" in a wrapped world
      # For all the 8 possibilities of wrapping (to the left, right, top, bottom and 4 corners)
      to1 <- cbind(pxcor = agents2[,1] - (world@extent@xmax - world@extent@xmin), pycor = agents2[,2] + (world@extent@ymax - world@extent@ymin))
      to2 <- cbind(pxcor = agents2[,1], pycor = agents2[,2] + (world@extent@ymax - world@extent@ymin))
      to3 <- cbind(pxcor = agents2[,1] + (world@extent@xmax - world@extent@xmin), pycor = agents2[,2] + (world@extent@ymax - world@extent@ymin))
      to4 <- cbind(pxcor = agents2[,1] - (world@extent@xmax - world@extent@xmin), pycor = agents2[,2])
      to5 <- cbind(pxcor = agents2[,1] + (world@extent@xmax - world@extent@xmin), pycor = agents2[,2])
      to6 <- cbind(pxcor = agents2[,1] - (world@extent@xmax - world@extent@xmin), pycor = agents2[,2] - (world@extent@ymax - world@extent@ymin))
      to7 <- cbind(pxcor = agents2[,1], pycor = agents2[,2] - (world@extent@ymax - world@extent@ymin))
      to8 <- cbind(pxcor = agents2[,1] + (world@extent@xmax - world@extent@xmin), pycor = agents2[,2] - (world@extent@ymax - world@extent@ymin))

      dist1 <- pointDistance(p1 = agents, p2 = to1, lonlat = FALSE, allpairs = allPairs)
      dist2 <- pointDistance(p1 = agents, p2 = to2, lonlat = FALSE, allpairs = allPairs)
      dist3 <- pointDistance(p1 = agents, p2 = to3, lonlat = FALSE, allpairs = allPairs)
      dist4 <- pointDistance(p1 = agents, p2 = to4, lonlat = FALSE, allpairs = allPairs)
      dist5 <- pointDistance(p1 = agents, p2 = to5, lonlat = FALSE, allpairs = allPairs)
      dist6 <- pointDistance(p1 = agents, p2 = to6, lonlat = FALSE, allpairs = allPairs)
      dist7 <- pointDistance(p1 = agents, p2 = to7, lonlat = FALSE, allpairs = allPairs)
      dist8 <- pointDistance(p1 = agents, p2 = to8, lonlat = FALSE, allpairs = allPairs)

      dist <- pmin(dist, dist1, dist2, dist3, dist4, dist5, dist6, dist7, dist8)
    }
    return(dist)
  }
)

#' @export
#' @rdname NLdist
setMethod(
  "NLdist",
  signature = c(world = "NLworlds", agents = "matrix", agents2 = "SpatialPointsDataFrame"),
  definition = function(world, agents, agents2, torus, allPairs) {
    NLdist(world = world, agents = agents, agents2 = agents2@coords, torus = torus, allPairs = allPairs)
  }
)

#' @export
#' @rdname NLdist
setMethod(
  "NLdist",
  signature = c(world = "NLworlds", agents = "SpatialPointsDataFrame", agents2 = "matrix"),
  definition = function(world, agents, agents2, torus, allPairs) {
    NLdist(world = world, agents = agents@coords, agents2 = agents2, torus = torus, allPairs = allPairs)
  }
)

#' @export
#' @rdname NLdist
setMethod(
  "NLdist",
  signature = c(world = "NLworlds", agents = "SpatialPointsDataFrame", agents2 = "SpatialPointsDataFrame"),
  definition = function(world, agents, agents2, torus, allPairs) {
    NLdist(world = world, agents = agents@coords, agents2 = agents2@coords, torus = torus, allPairs = allPairs)
  }
)


################################################################################
#' Do the patches exist?
#'
#' Report \code{TRUE} if a patch exists in the \code{world}'s extent, report
#' \code{FALSE} otherwise.
#'
#' @inheritParams fargs
#'
#' @return Logical.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#is-of-type}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' pExist(world = w1, pxcor = -1, pycor = 2)
#'
#'
#' @export
#' @docType methods
#' @rdname pExist
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "pExist",
  function(world, pxcor, pycor) {
    standardGeneric("pExist")
  })

#' @export
#' @rdname pExist
setMethod(
  "pExist",
  signature = c("NLworld", "numeric", "numeric"),
  definition = function(world, pxcor, pycor) {

    if(length(pxcor) == 1 & length(pycor) != 1){
      pxcor <- rep(pxcor, length(pycor))
    }
    if(length(pycor) == 1 & length(pxcor) != 1){
      pycor <- rep(pycor, length(pxcor))
    }

    pExist <- c()
    for(i in 1:length(pxcor)){
      pVal <- world[pxcor[i], pycor[i]]
      if(length(pVal) == 0){
        pExist[i] <- FALSE
      } else {
        pExist[i] <- TRUE
      }
    }
    return(pExist)
  }
)

#' @export
#' @rdname pExist
setMethod(
  "pExist",
  signature = c("NLworldStack", "numeric", "numeric"),
  definition = function(world, pxcor, pycor) {
    world_l <- world[[1]]
    pExist(world = world_l, pxcor = pxcor, pycor = pycor)
  }
)


################################################################################
#' Neighbors patches
#'
#' Report the 4 or 8 surrounding patches around the \code{agents}.
#'
#' @inheritParams fargs
#'
#' @return List. Each item is a matrix (ncol = 2) with the first column "pxcor"
#'         and the second column "pycor" representing the coordinates of the neighbors
#'         patches around the \code{agents}. The list items follow the order of the
#'         \code{agents}.
#'
#' @details The patch around which the neighbors are identified, or the patch where
#'          the turtle is located on around which the neighbors are identified, is not
#'          returned.
#'
#'          If \code{torus = FALSE}, \code{agents} located on the edges of the \code{world}
#'          have less than \code{nNeighbors} patches. If \code{torus = FALSE}, all agents
#'          located on the egdes of the \code{world} have \code{nNeighbors} patches, which
#'          some may be on the other sides of the \code{world}.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#neighbors}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' neighbors(world = w1, agents = patch(w1, c(0,9), c(0,7)), nNeighbors = 8)
#' t1 <- createTurtles(n = 3, coords = randomXYcor(w1, n = 3))
#' neighbors(world = w1, agents = t1, nNeighbors = 4)
#'
#'
#' @export
#' @importFrom SpaDES adj
#' @docType methods
#' @rdname neighbors
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "neighbors",
  function(world, agents, nNeighbors, torus = FALSE) {
    standardGeneric("neighbors")
  })

#' @export
#' @rdname neighbors
setMethod(
  "neighbors",
  signature = c(world = "NLworlds", agents = "matrix", nNeighbors = "numeric"),
  definition = function(world, agents, nNeighbors, torus) {

    cellNum <- cellFromPxcorPycor(world = world, pxcor = agents[,1], pycor = agents[,2])
    neighbors_df <- adj(world, cells = cellNum, directions = nNeighbors, torus = torus)

    pCoords <- PxcorPycorFromCell(world = world, cellNum = neighbors_df[,2])
    listAgents <- list()
    for(i in 1:length(cellNum)) {
      listAgents[[i]] <- pCoords[neighbors_df[,1] == cellNum[i],]
    }

    return(listAgents)
  }
)

#' @export
#' @rdname neighbors
setMethod(
  "neighbors",
  signature = c(world = "NLworlds", agents = "SpatialPointsDataFrame", nNeighbors = "numeric"),
  definition = function(world, agents, nNeighbors, torus) {
    pTurtles <- patch(world = world, x = agents@coords[,1], y = agents@coords[,2], duplicate = TRUE)
    neighbors(world = world, agents = pTurtles, nNeighbors = nNeighbors, torus = torus)
  }
)


################################################################################
#' Patches coordinates
#'
#' Report the patches coordinates at the given \code{[x, y]} locations.
#'
#' @inheritParams fargs
#'
#' @param x          Numeric. Vector of x coordinates. Must be of same
#'                   length as \code{y}.
#'
#' @param y          Numeric. Vector of y coordinates. Must be of same
#'                   length as \code{x}.
#'
#' @param duplicate  Logical. If more than one location \code{[x, y]}
#'                   fall into the same patch and \code{duplicate == TRUE}, the
#'                   patch coordinates are returned the number of times the locations.
#'                   If \code{duplicate == FALSE}, the patch coordinates
#'                   are only returned once.
#'                   Default is \code{duplicate == FALSE}.
#'
#' @param out        Logical. If \code{out = FALSE}, no patch coordinates are returned
#'                   for patches outside of the \code{world}'s extent, if \code{out = TRUE},
#'                   \code{NA} are returned.
#'                   Default is \code{out = FALSE}.
#'
#' @return Matrix (ncol = 2) with the first column "pxcor" and the second column
#'         "pycor" representing the patches coordinates at \code{[x, y]}.
#'
#' @details If a location \code{[x, y]} is outside the \code{world}'s extent and
#'          \code{torus = FALSE} and \code{out = FALSE}, no patch coordinates are returned;
#'          if \code{torus = FALSE} and \code{out = TRUE}, \code{NA} are returned;
#'          if \code{torus = TRUE}, the patch coordinates from a wrapped \code{world} are
#'          returned.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#patch}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' patch(world = w1, x = c(0, 9.1, 8.9, 5, 5.3), y = c(0, 0, -0.1, 12.4, 12.4))
#' patch(world = w1, x = c(0, 9.1, 8.9, 5, 5.3), y = c(0, 0, -0.1, 12.4, 12.4), duplicate = TRUE)
#' patch(world = w1, x = c(0, 9.1, 8.9, 5, 5.3), y = c(0, 0, -0.1, 12.4, 12.4), torus = TRUE)
#' patch(world = w1, x = c(0, 9.1, 8.9, 5, 5.3), y = c(0, 0, -0.1, 12.4, 12.4), torus = TRUE, duplicate = TRUE)
#'
#'
#' @export
#' @importFrom SpaDES wrap
#' @docType methods
#' @rdname patch
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "patch",
  function(world, x, y, duplicate = FALSE, torus = FALSE, out = FALSE) {
    standardGeneric("patch")
  })

#' @export
#' @rdname patch
setMethod(
  "patch",
  signature = c(world = "NLworlds", x = "numeric", y = "numeric"),
  definition = function(world, x, y, duplicate, torus, out) {

    pxcor_ <- round(x)
    pycor_ <- round(y)

    if(torus == TRUE){
      pCoords <- wrap(cbind(x = pxcor_, y = pycor_), extent(world))
      pxcor_ <- pCoords[,1]
      pycor_ <- pCoords[,2]
    }

    pxcorNA <- ifelse(pxcor_ < minPxcor(world) | pxcor_ > maxPxcor(world), NA, pxcor_)
    pycorNA <- ifelse(pycor_ < minPycor(world) | pycor_ > maxPycor(world), NA, pycor_)
    pxcorNA[is.na(pycorNA)] <- NA
    pycorNA[is.na(pxcorNA)] <- NA

    if(out == FALSE){
      pxcor = pxcorNA[!is.na(pxcorNA)]
      pycor = pycorNA[!is.na(pycorNA)]
    } else {
      pxcor = pxcorNA
      pycor = pycorNA
    }

    pCoords <- matrix(data = cbind(pxcor, pycor), ncol = 2, nrow = length(pxcor), dimnames = list(NULL, c("pxcor", "pycor")))

    if(duplicate == FALSE){
      pCoords <- unique(pCoords)
    }
    return(pCoords)
  }
)


################################################################################
#' No patches
#'
#' Report an empty patch agentset.
#'
#' @return Matrix (ncol = 2, nrow = 0) with the first column "pxcor" and the
#'         second column "pycor".
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#no-patches}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' p1 <- noPatches()
#' nrow(p1)
#'
#'
#' @export
#' @docType methods
#' @rdname noPatches
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "noPatches",
  function(x) {
    standardGeneric("noPatches")
  })

#' @export
#' @rdname noPatches
setMethod(
  "noPatches",
  signature = "missing",
  definition = function() {
    return(matrix(, nrow = 0, ncol = 2, dimnames = list(NULL, c("pxcor", "pycor"))))
  }
)


################################################################################
#' Patches at
#'
#' Report the patches coordinates at \code{(dx, dy)} distances of the \code{agents}.
#'
#' @inheritParams fargs
#'
#' @return Matrix (ncol = 2) with the first column "pxcor" and the second column
#'         "pycor" representing the coordinates of the patches at \code{(dx, dy)}
#'         distances of the \code{agents}. The order of the patches follows the order
#'         of the \code{agents}.
#'
#' @details If \code{torus = FALSE} and the patch at distance \code{(dx, dy)}
#'          of an agent is outside of the \code{world}'s extent, \code{NA} are returned
#'          for the patc coordinates.
#'          If \code{torus = TRUE}, the patch coordinates from a wrapped \code{world} are
#'          returned.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#patch-at}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' patchCorner <- patchAt(world = w1, agents = patch(w1, 0, 0), dx = 1, dy = 1)
#' t1 <- createTurtles(n = 1, coords = cbind(xcor = 0, ycor = 0))
#' patchCorner <- patchAt(world = w1, agents = t1, dx = 1, dy = 1)
#'
#'
#' @export
#' @docType methods
#' @rdname patchAt
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "patchAt",
  function(world, agents, dx, dy, torus = FALSE) {
    standardGeneric("patchAt")
  })

#' @export
#' @rdname patchAt
setMethod(
  "patchAt",
  signature = c(world = "NLworlds", agents = "matrix", dx = "numeric", dy = "numeric"),
  definition = function(world, agents, dx, dy, torus) {

    pxcor <- agents[,1] + dx
    pycor <- agents[,2] + dy
    pAt <- patch(world = world, x = pxcor, y = pycor, duplicate = TRUE, torus = torus, out = TRUE)

    return(pAt)
  }
)

#' @export
#' @rdname patchAt
setMethod(
  "patchAt",
  signature = c(world = "NLworlds", agents = "SpatialPointsDataFrame", dx = "numeric", dy = "numeric"),
  definition = function(world, agents, dx, dy, torus) {

    patchAt(world = world, agents = agents@coords, dx = dx, dy = dy, torus = torus)

  }
)


################################################################################
#' Patches at certain distances and certain directions
#'
#' Report the coordinates of the patches which are at certain
#' distances and certain directions from the \code{agents}.
#'
#' @inheritParams fargs
#'
#' @param dist   Numeric. Distances from the \code{agents}. \code{dist} must be
#'               of length 1 or of the same length as the number of \code{agents}.
#'
#' @param angle  Numeric. Absolute directions from the \code{agents}. \code{angle}
#'               must be of length 1 or of the same length as the number of
#'               \code{agents}. Angles are in degrees with 0 being North.
#'
#' @return Matrix (ncol = 2) with the first column "pxcor" and the second column
#'         "pycor" representing the coordinates of the patches at the distances \code{dist}
#'         and directions \code{angle}
#'         of \code{agents}. The order of the patches follows the order of the \code{agents}.
#'
#' @details If \code{torus = FALSE} and the patch at distance \code{dist} and
#'          direction \code{angle} of an agent is outside the \code{world}'s extent, \code{NA}
#'          are returned for the patch coordinates. If \code{torus = TRUE}, the patch
#'          coordinates from a wrapped \code{world} are returned.
#'
#'          If \code{agents} are turtles, their headings are not taken into account; the
#'          given directions \code{angle} are used. To find a patch at certain
#'          distance from a turtle using the turtle's heading, look at \code{pacthAhead()},
#'          \code{patchLeft()} or \code{patchRight()}.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#patch-at-heading-and-distance}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' p1 <- patchDistDir(world = w1, agents = patch(w1, 0, 0), dist = 1, angle = 45)
#' t1 <- createTurtles(n = 1, coords = cbind(xcor = 0, ycor = 0), heading = 315)
#' p2 <- patchDistDir(world = w1, agents = t1, dist = 1, angle = 45)
#'
#'
#' @export
#' @importFrom CircStats rad
#' @docType methods
#' @rdname patchDistDir
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "patchDistDir",
  function(world, agents, dist, angle, torus = FALSE) {
    standardGeneric("patchDistDir")
  })

#' @export
#' @rdname patchDistDir
setMethod(
  "patchDistDir",
  signature = c(world = "NLworlds", agents = "matrix", dist = "numeric", angle = "numeric"),
  definition = function(world, agents, dist, angle, torus) {

    pxcor <- agents[,1] + sin(rad(angle)) * dist
    pycor <- agents[,2] + cos(rad(angle)) * dist
    pDistHead <- patch(world = world, x = pxcor, y = pycor, torus = torus, duplicate = TRUE, out = TRUE)

    return(pDistHead)
  }
)

#' @export
#' @rdname patchDistDir
setMethod(
  "patchDistDir",
  signature = c(world = "NLworlds", agents = "SpatialPointsDataFrame", dist = "numeric", angle = "numeric"),
  definition = function(world, agents, dist, angle, torus) {

    patchDistDir(world = world, agents = agents@coords, dist = dist, angle = angle, torus = torus)

    }
)


################################################################################
#' All the patches in a world
#'
#' Report the pacthes coordinates for all the patches in the \code{world}.
#'
#' @inheritParams fargs
#'
#' @return Matrix (ncol = 2) with the first column "pxcor" and the second column
#'         "pycor" representing the patches coordinates. The order of the patches
#'         follows the order of the cells numbers as defined for a \code{Raster*}.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#patches}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9) # 100 patches
#' allPatches <- patches(world = w1)
#' nrow(allPatches)
#'
#'
#' @export
#' @docType methods
#' @rdname patches
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "patches",
  function(world) {
    standardGeneric("patches")
  })

#' @export
#' @rdname patches
setMethod(
  "patches",
  signature = "NLworld",
  definition = function(world) {
    return(cbind(pxcor = world@pxcor, pycor = world@pycor))
  }
)

#' @export
#' @rdname patches
setMethod(
  "patches",
  signature = "NLworldStack",
  definition = function(world) {
    world_l <- world[[1]]
    patches(world = world_l)
  }
)


################################################################################
#' Patch set
#'
#' Report a patch agentset as the coordinates of all patches contained in the inputs.
#'
#' @param ... Matrices (ncol = 2) of patches coordinates with the first column
#'            "pxcor" and the second column "pycor".
#'
#' @return Matrix (ncol = 2) with the first column "pxcor" and the second column
#'         "pycor" representing the patches coordinates.
#'
#' @details Duplicate patches among the inputs are removed in the returned matrix.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#patch-set}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' p1 <- patchAt(world = w1, agents = patch(w1, c(0,1,2), c(0,0,0)), dx = 1, dy = 1)
#' p2 <- patchDistDir(world = w1, agents = patch(w1, 0, 0), dist = 1, angle = 45)
#' p3 <- patch(world = w1, x = 4.3, y = 8)
#' p4 <- patchSet(p1, p2, p3)
#'
#'
#' @export
#' @docType methods
#' @rdname patchSet
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "patchSet",
  function(...) {
    standardGeneric("patchSet")
  })

#' @export
#' @rdname patchSet
setMethod(
  "patchSet",
  signature = "matrix",
  definition = function(...) {

    dots <-list(...)
    pCoords <- unique(do.call(rbind, dots))
    return(pCoords)
  }
)


################################################################################
#' Random pxcor
#'
#' Report \code{n} random pxcor coordinates within the \code{world}'s extent.
#'
#' @inheritParams fargs
#'
#' @return Integer. Vector of length \code{n} of pxcor coordinates.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#random-pcor}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' pxcor_ <- randomPxcor(world = w1, n = 10)
#'
#'
#' @export
#' @docType methods
#' @rdname randomPxcor
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "randomPxcor",
  function(world, n) {
    standardGeneric("randomPxcor")
  })

#' @export
#' @rdname randomPxcor
setMethod(
  "randomPxcor",
  signature = c("NLworlds", "numeric"),
  definition = function(world, n) {
    minPxcor <- minPxcor(world)
    maxPxcor <- maxPxcor(world)
    pxcor <- sample(minPxcor:maxPxcor, size = n, replace = TRUE)
    return(pxcor)
  }
)


################################################################################
#' Random pycor
#'
#' Report \code{n} random pycor coordinates within the \code{world}'s extent.
#'
#' @inheritParams fargs
#'
#' @return Integer. Vector of length \code{n} of pycor coordinates.
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#random-pcor}
#'
#' @references Wilensky, U. 1999. NetLogo. http://ccl.northwestern.edu/netlogo/.
#'             Center for Connected Learning and Computer-Based Modeling,
#'             Northwestern University. Evanston, IL.
#'
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
#' pycor_ <- randomPycor(world = w1, n = 10)
#'
#'
#' @export
#' @docType methods
#' @rdname randomPycor
#'
#' @author Sarah Bauduin
#'
setGeneric(
  "randomPycor",
  function(world, n) {
    standardGeneric("randomPycor")
  })

#' @export
#' @rdname randomPycor
setMethod(
  "randomPycor",
  signature = c("NLworlds", "numeric"),
  definition = function(world, n) {
    minPycor <- minPycor(world)
    maxPycor <- maxPycor(world)
    pycor <- sample(minPycor:maxPycor, size = n, replace = TRUE)
    return(pycor)
  }
)