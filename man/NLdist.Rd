% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/patch-functions.R
\docType{methods}
\name{NLdist}
\alias{NLdist}
\alias{dist}
\alias{NLdist,matrix,matrix-method}
\title{Distances between agents}
\usage{
NLdist(agents, agents2, world, torus = FALSE, allPairs = FALSE)

\S4method{NLdist}{matrix,matrix}(agents, agents2, world, torus = FALSE,
  allPairs = FALSE)
}
\arguments{
\item{agents}{Matrix (\code{ncol} = 2) with the first column \code{pxcor} and the second
              column \code{pycor} representing the \code{patches} coordinates, or

              \code{AgentMatrix} object representing the moving \code{agents}.}

\item{agents2}{Matrix (\code{ncol} = 2) with the first column \code{pxcor} and the second
               column \code{pycor} representing the \code{patches} coordinates, or

               \code{AgentMatrix} object representing the moving \code{agents}, or

               Matrix (\code{ncol} = 2) with the first column \code{x} and the second column
               \code{y} representing locations coordinates.}

\item{world}{\code{WorldMatrix} or \code{worldArray} object.}

\item{torus}{Logical to determine if the \code{world} is wrapped. Default is
\code{torus = FALSE}.}

\item{allPairs}{Logical. Only relevant if the number of agents/locations in
\code{agents} and in \code{agents2} are the same. If
\code{allPairs = FALSE},
the distance between each \code{agents} with the
corresponding \code{agents2} is returned. If
\code{allPairs = TRUE}, a full
distance matrix is returned. Default is \code{allPairs = FALSE}.}
}
\value{
Numeric. Vector of distances between \code{agents} and \code{agents2} if
        \code{agents} and/or \code{agents2} contained
        one agent/location, or if \code{agents} and \code{agents2} contained the same
        number of agents/locations and \code{allPairs = FALSE}, or

        Matrix of distances between \code{agents} (rows) and
        \code{agents2} (columns)
        if \code{agents} and \code{agents2} are of different lengths,
        or of same length
        and \code{allPairs = TRUE}.
}
\description{
Report the distances between \code{agents} and \code{agents2}.
}
\details{
Distances from/to a patch are measured from/to its center.

         If \code{torus = FALSE}, \code{world} does not need to be provided.

         If \code{torus = TRUE}, a distance around the sides of the \code{world} is
         reported only if smaller than the one across the \code{world}.
}
\examples{
w1 <- createWorld(minPxcor = 0, maxPxcor = 9, minPycor = 0, maxPycor = 9)
NLdist(agents = patch(w1, 0, 0), agents2 = patch(w1, c(1, 9), c(1, 9)))
NLdist(agents = patch(w1, 0, 0), agents2 = patch(w1, c(1, 9), c(1, 9)),
       world = w1, torus = TRUE)
t1 <- createTurtles(n = 2, coords = randomXYcor(w1, n = 2))
NLdist(agents = t1, agents2 = patch(w1, c(1,9), c(1,9)), allPairs = TRUE)


}
\references{
Wilensky, U. 1999. NetLogo. \url{http://ccl.northwestern.edu/netlogo/}.
            Center for Connected Learning and Computer-Based Modeling,
            Northwestern University. Evanston, IL.
}
\seealso{
\url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#distance}

         \url{https://ccl.northwestern.edu/netlogo/docs/dictionary.html#distancexy}
}
\author{
Sarah Bauduin
}
