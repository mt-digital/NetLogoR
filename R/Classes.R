#' @export
SpatialPoints2 <- function (coords, proj4string = CRS(as.character(NA)), bbox = NULL)
{
  #coords = coordinates(coords)
  colNames = dimnames(coords)[[2]]
  if (is.null(colNames))
    colNames = paste("coords.x", 1:(dim(coords)[2]), sep = "")
  rowNames = dimnames(coords)[[1]]
  dimnames(coords) = list(rowNames, colNames)
  if (is.null(bbox))
    bbox <- NetLogoR::.bboxCoords(coords)
  new("SpatialPoints", coords = coords, bbox = bbox, proj4string = proj4string)
}

#' Faster .bboxCoords
#'
#' This is a drop in replacement for .bboxCoords in raster package.
#'
#' @importFrom matrixStats colRanges
.bboxCoords <- function(coords) {
    stopifnot(nrow(coords) > 0)
    bbox = colRanges(coords)
    dimnames(bbox)[[2]] = c("min", "max")
    as.matrix(bbox)
}

#' @include NLworlds-class.R
#' @importFrom raster extent
setMethod(
  "extent",
  signature("NLworldMs"),
  definition = function (x, ...) {
    extent(cbind(c(attr(x, "xmin"), attr(x, "ymin")),
          c(attr(x, "xmax"), attr(x, "ymax"))))
  })

#' agentDataTable class
#'
#' This is incomplete.
#'
#'
#' @importClassesFrom data.table data.table
#' @name agentDataTable
#' @rdname agentDataTable
#' @author Eliot McIntire
#' @exportClass agentDataTable
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 4, minPycor = 0, maxPycor = 4)
#' t1 <- createTurtles(world = w1, n = 10, agent = TRUE)
#'
#' library(microbenchmark)
#' N = 1e5
#' microbenchmark(createTurtles(world = w1, n = N, agent = TRUE),
#'               createTurtles(world = w1, n = N, agent = FALSE))
agentDataTable <- function(coords, ..., coords.nrs = numeric(0), proj4string = CRS(as.character(NA)),
                           match.ID, bbox = NULL) {
  dt <- data.table(coords, ...)
  attr(dt, "proj4string") <- proj4string
  attr(dt, "bbox") <- bbox
  attr(dt, "coords.nrs") <- coords.nrs
  class(dt) <- c("agentDataTable", "data.table", "data.frame", "list", "oldClass", "vector")
  dt
}

setOldClass("agentDataTable")



#' agentMatrix class
#'
#' This is incomplete.
#'
#'
#' @name agentMatrix
#' @rdname agentMatrix
#' @author Eliot McIntire
#' @exportClass agentMatrix
#' @examples
#' newAgent <- new("agentMatrix",
#'       coords=cbind(pxcor=c(1,2,5),pycor=c(3,4,6)),
#'       char = letters[c(1,2,6)],
#'       nums2 = c(4.5, 2.6, 2343),
#'       char2 = LETTERS[c(4,24,3)],
#'       nums = 5:7)
#'
#' # compare speeds -- about 5x faster
#' microbenchmark(times = 499,
#'   spdf={
#'      SpatialPointsDataFrame(coords=cbind(pxcor=c(1,2,5),pycor=c(3,4,6)),
#'      data = data.frame(
#'        char = letters[c(1,2,6)],
#'        nums2 = c(4.5, 2.6, 2343),
#'        char2 = LETTERS[c(4,24,3)],
#'        nums = 5:7))},
#'   agentMat = { agentMatrix(
#'      coords=cbind(pxcor=c(1,2,5),
#'      pycor=c(3,4,6)),
#'      char = letters[c(1,2,6)],
#'      nums2 = c(4.5, 2.6, 2343),
#'      char2 = LETTERS[c(4,24,3)],
#'      nums = 5:7)},
#'   agentMatDirect = { new("agentMatrix",
#'      coords=cbind(pxcor=c(1,2,5),
#'      pycor=c(3,4,6)),
#'      char = letters[c(1,2,6)],
#'      nums2 = c(4.5, 2.6, 2343),
#'      char2 = LETTERS[c(4,24,3)],
#'      nums = 5:7)})
#'
setClass("agentMatrix", contains = "matrix",
         slots = c(x = "matrix", levels = "list",
                   bbox = "matrix"),
         prototype = prototype(x = matrix(numeric()), levels = list(),
                               bbox = matrix(numeric()))
         )

#' A meta class for agentMatrix and SpatialPointsDataFrame
#'
#' Both these types can be used by NetLogoR to describe turtle agents.
#'
#' @aliases agentClasses
#' @name agentClasses
#' @rdname agentClasses
#' @author Eliot McIntire
#' @importClassesFrom sp SpatialPointsDataFrame SpatialPixelsDataFrame
#' @exportClass agentClasses
setClassUnion(name="agentClasses",
              members=c("SpatialPointsDataFrame", "agentMatrix", "SpatialPixelsDataFrame")
)

#if(getRversion() >= "3.2.0") {
setMethod("initialize",
          "agentMatrix",
          function(.Object="agentMatrix", coords, ...)
  {

    Coords <- TRUE
    if(missing(coords)) {
      coords <- NULL
    }
    if(is.null(coords)) {
      coords <- matrix(c(NA, NA), ncol=2)
      Coords <- FALSE
    }
    dotCols <- list(...)

    if(all(sapply(dotCols, is.numeric))) {
      if(sapply(dotCols, is.matrix)) {
        otherCols <- append(list(xcor=coords[,1],ycor=coords[,2]), dotCols)
        names(otherCols) <- c("xcor", "ycor", colnames(dotCols[[1]]))
      } else {
        otherCols <- append(list(xcor=coords[,1],ycor=coords[,2]), dotCols)
      }
      if(length(otherCols)>0) {
        .Object@.Data <- otherCols
        .Object@levels <- rep(list(NULL), ncol(.Object@.Data))
        names(.Object@levels) <- colnames(otherCols)
        if(Coords) {
          .Object@bbox <- NetLogoR:::.bboxCoords(coords)
        } else {
          .Object@bbox <- matrix(rep(NA_real_, 4), ncol=2)
        }
      }
    } else {

      isDF <- sapply(dotCols, function(x) is(x, "data.frame"))
      if(any(isDF))
        dotCols <- unlist(lapply(dotCols, as.list), recursive=FALSE)
      if(any(names(dotCols)=="stringsAsFactors"))
        dotCols$stringsAsFactors <- NULL

      if(all(sapply(dotCols, is.matrix))) {
        otherCols <- list(xcor=coords[,1],ycor=coords[,2], dotCols[[1]][,1])
        names(otherCols) <- c("xcor", "ycor", colnames(dotCols[[1]]))
      } else {
        otherCols <- append(list(xcor=coords[,1],ycor=coords[,2]), dotCols)
      }
      charCols <- sapply(otherCols, is.character)
      charCols <- names(charCols)[charCols]
      numCols <- sapply(otherCols, is.numeric)
      facCols <- sapply(otherCols, is.factor)
      otherCols[charCols] <- lapply(otherCols[charCols], function(x) {
          factor(x, levels = sort(unique(x)))
        })

      if(length(otherCols)>0) {
        .Object@.Data <- do.call(cbind,otherCols)
        .Object@levels <- lapply(otherCols[charCols], function(x) if(is.factor(x)) levels(x) else NULL)
        if(Coords) {
          .Object@bbox <- NetLogoR:::.bboxCoords(coords)
        } else {
          .Object@bbox <- matrix(rep(NA_real_, 4), ncol=2)
        }
      }
    }
    .Object

})


################################################################################
#' Create a new agentMatrix object
#'
#' This is a fast alternative to the SpatialPointsDataFrame. It is meant to replace
#' that functionality, though there are not as many methods (yet). The object is primarily
#' a numeric matrix. Any character column passed to ... will be converted to a numeric,
#' using \code{as.factor} internally, and stored as a numeric. Methods using this class
#' will automatically convert character queries to the correct numeric alternative.
#'
#' @param coords  A matrix with 2 columns representing x and y coordinates
#' @param ... Vectors or a data.frame or a matrix of extra columns to add to the coordinates
#'
#' @seealso \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#clear-turtles}
#'
#' @examples
#' agentMatrix()
#' newAgent <- agentMatrix(
#'       coords=cbind(pxcor=c(1,2,5),pycor=c(3,4,6)),
#'       char = letters[c(1,2,6)],
#'       nums2 = c(4.5, 2.6, 2343),
#'       char2 = LETTERS[c(4,24,3)],
#'       nums = 5:7)
#'
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 4, minPycor = 0, maxPycor = 4)
#' w1 <- set(world = w1, agents = patches(w1), val = runif(count(patches(w1))))
#' t1 <- createTurtles(n = 10, coords = randomXYcor(w1, n = 10))
#'
#'
#' @export
#' @docType methods
#' @rdname agentMatrix
#'
#' @author Eliot McIntire
#'
setGeneric(
  "agentMatrix",
  function(..., coords) {
    standardGeneric("agentMatrix")
  }
)

#' @export
#' @rdname agentMatrix
setMethod(
  "agentMatrix",
  signature = c(coords="matrix"),
  definition = function(..., coords) {
    new("agentMatrix", coords = coords, ...)
  }
)

#' @export
#' @rdname agentMatrix
setMethod(
  "agentMatrix",
  signature = c(coords="missing"),
  definition = function(...) {
    if(is(..., "SpatialPointsDataFrame")) {
      dots <- list(...)
      new("agentMatrix", coords = coordinates(dots[[1]]), dots[[1]]@data)
    } else {
      new("agentMatrix", coords = NULL, ...)
    }

  }
)

setMethod(
  "coordinates",
  signature("agentMatrix"),
  definition = function (obj, ...) {
    obj@.Data[,1:2]
  })


setAs("matrix", "agentMatrix",
      function(from) {
        tmp <- new("agentMatrix", coords = from[,1:2,drop=FALSE], from[,-(1:2), drop = FALSE])
        tmp
      })


#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "[",
  signature(x="agentMatrix", "numeric", "numeric", "ANY"),
  definition = function(x, i, j, ..., drop) {

    x@.Data <- x@.Data[i,unique(c(1:2,j)),...,drop=drop]
    x@levels <- x@levels[j-2]
    x@bbox <- .bboxCoords(x@.Data[i,1:2])
    x


  }
)

#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "[",
  signature(x="agentMatrix", "missing", "character", "ANY"),
  definition = function(x, j, ..., drop) {

    cols <- match(j, colnames(x@.Data))
    x[,cols,...,drop=FALSE]

  }
)

#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "[",
  signature(x="agentMatrix", "numeric", "character", "ANY"),
  definition = function(x, i, j, ..., drop) {

    cols <- match(j, colnames(x@.Data))
    x[i,cols,...,drop=FALSE]

  }
)

#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "[",
  signature(x="agentMatrix", "missing", "numeric", "ANY"),
  definition = function(x, j, ..., drop) {

    colNames <- colnames(x@.Data)[j]
    levelInd <- match(colNames, names(x@levels))
    x@.Data <- x@.Data[,unique(c(1:2,j)),...,drop=drop]
    if(all(is.na(levelInd))) {
      x@levels <- NULL
    } else {
      x@levels <- x@levels[colNames]
    }
    x@bbox <- .bboxCoords(x@.Data[,1:2])
    x

  }
)


#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "[",
  signature(x="agentMatrix", "numeric", "missing", "ANY"),
  definition = function(x, i, ..., drop) {

    x@.Data <- x@.Data[i,,drop=FALSE]
    x@bbox <- .bboxCoords(x@.Data[,1:2,drop=FALSE])
    x

  }
)

#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "$",
  signature(x="agentMatrix"),
  definition = function(x, name) {
    x[,name]

  }
)

#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "show",
  signature(object="agentMatrix"),
  definition = function(object) {

    if(NROW(object@.Data)>0) {
      tmp <- data.frame(object@.Data)
      colNames <- colnames(tmp[,names(object@levels),drop=FALSE])
      tmp[,names(object@levels)] <-
        sapply(seq_along(names(object@levels)), function(x) {
          curLevels <- sort(unique(tmp[,names(object@levels)[x]]))
          as.character(factor(tmp[,names(object@levels)[x]],
                              curLevels,
                              object@levels[[colNames[x]]][curLevels]) )
        })
    } else {
      tmp <- object@.Data
    }
    show(tmp)

  }
)

# @export
# @name [
# @docType methods
# @rdname agentMatrix
# setMethod(
#   "NROW",
#   signature(x="agentMatrix"),
#   definition = function(x) {
#     NROW(x@.Data)
#   }
# )

#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "nrow",
  signature(x="agentMatrix"),
  definition = function(x) {
    nrow(x@.Data)
  }
)

#' @export
#' @name head
#' @docType methods
#' @rdname agentMatrix
head.agentMatrix <- function(x, n = 6L, ...) {
  x[seq_len(n),,drop=FALSE]
}

#' @export
#' @name tail
#' @docType methods
#' @rdname agentMatrix
tail.agentMatrix <- function(x, n = 6L, ...) {
  len <- NROW(x@.Data)
  ind <- (len - n + 1):len
  out <- x[ind,,drop=FALSE]
  rownames(out@.Data) <- ind
  out

}


#' @export
#' @name cbind
#' @docType methods
#' @rdname agentMatrix
setGeneric("cbind", signature="...")

#' @export
#' @name cbind
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "cbind",
  "agentMatrix",
  definition = function(..., deparse.level) {

    tmp <- list(...)
    if(length(tmp) != 2) stop("cbind for agentMatrix is only defined for 2 agentMatrices")
    notAM <- sapply(tmp, function(x) all(is.na(x@.Data[,1:2])))

    if(NROW(tmp[[2]]@.Data) == 1) {
      tmp[[2]]@.Data <- tmp[[2]]@.Data[rep_len(1, length.out=NROW(tmp[[1]]@.Data)),]
    }

    if(any(colnames(tmp[[1]]@.Data)[-(1:2)] %in% colnames(tmp[[2]]@.Data)[-(1:2)])) {
      stop("There are duplicate columns in the two agentMatrix objects. Please remove duplicates.")
    }
    newMat <- cbind(tmp[[1]]@.Data, tmp[[2]]@.Data[,-(1:2),drop=FALSE])
    tmp[[1]]@.Data <- newMat
    colnames(newMat)
    tmp[[1]]@levels <- SpaDES::updateList(tmp[[2]]@levels, tmp[[1]]@levels)

    tmp[[1]]

  }
)

#' @export
#' @name [
#' @docType methods
#' @rdname agentMatrix
setMethod(
  "length",
  signature(x="agentMatrix"),
  definition = function(x) {
    length(x@.Data)
  }
)

#' Extract coordinates from agentDataTable
#'
#' This is incomplete
#'
#' @export
#' @rdname coordinates
#' @examples
#' w1 <- createNLworld(minPxcor = 0, maxPxcor = 4, minPycor = 0, maxPycor = 4)
#' t1 <- createTurtles(world = w1, n = 10, agent = TRUE)
#' coordinates(t1)
#'
#' library(microbenchmark)
#' N = 1e4
#' coords <-  cbind(xcor=runif(N, xmin(w1), xmax(w1)),
#'                  ycor = runif(N, ymin(w1), ymax(w1)))
#' turtlesDT <- createTurtles(coords = coords, n = N, agent = TRUE)
#' turtlesDF <- createTurtles(coords = coords, n = N, agent = FALSE)
#' microbenchmark(coordinates(turtlesDT), coordinates(turtlesDF))
#' microbenchmark(coordinates(turtlesDT) <- coords)
setMethod(
  "coordinates",
  signature("agentDataTable"),
  definition = function (obj, ...) {
    #cbind(x=obj$x, y=obj$y)
    obj[,list(xcor,ycor)]
  })

#' @importFrom data.table ':='
setReplaceMethod(
  "coordinates",
  signature("agentDataTable"),
  definition = function (object, value) {
    #cbind(x=obj$x, y=obj$y)
    object[,`:=`(xcor=value[,"xcor"],ycor=value[,"ycor"])]
  })