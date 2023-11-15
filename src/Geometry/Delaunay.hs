{-|
Module      : Geometry.Delaunay
Description : Delaunay tessellation in arbitrary dimension.
Copyright   : (c) Stéphane Laurent, 2023
License     : GPL-3
Maintainer  : laurent_step@outlook.fr

See README for an example.
-}
module Geometry.Delaunay
  (module X)
  where
import           Geometry.Delaunay.Delaunay as X
import           Geometry.Delaunay.Types    as X
import           Geometry.Qhull.Shared      as X
import           Geometry.Qhull.Types       as X
