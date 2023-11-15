module Geometry.Delaunay.Delaunay
  ( delaunay
  , vertexNeighborFacets
  , sandwichedFacet
  , facetOf
  , facetFamilies
  , facetCenters
  , facetOf'
  , facetFamilies'
  , facetCenters'
    ) 
  where
import           Control.Monad               ( unless, when )
import           Data.IntMap.Strict          ( IntMap )
import qualified Data.IntMap.Strict          as IM
import qualified Data.IntSet                 as IS
import           Data.List.Unique            ( allUnique )
import           Data.Maybe                  ( fromMaybe )
import           Geometry.Delaunay.CDelaunay ( c_tessellation
                                             , cTessellationToTessellation 
                                             )
import           Geometry.Delaunay.Types     ( Tessellation(_tilefacets, _sites, _tiles),
                                               Tile,
                                               TileFacet(_facetOf),
                                               Site(_neighfacetsIds) )
import           Foreign.C.Types             ( CDouble, CUInt )
import           Foreign.Marshal.Alloc       ( free, mallocBytes )
import           Foreign.Marshal.Array       ( pokeArray )
import           Foreign.Storable            ( peek, sizeOf )
import           Geometry.Qhull.Types        ( HasCenter(_center), 
                                               HasFamily(_family), 
                                               Family, 
                                               Index )

delaunay :: [[Double]]     -- ^ sites (vertex coordinates)
         -> Bool           -- ^ whether to add a point at infinity
         -> Bool           -- ^ whether to include degenerate tiles
         -> Maybe Double   -- ^ volume threshold
         -> IO Tessellation -- ^ Delaunay tessellation
delaunay sites atinfinity degenerate vthreshold = do
  let n     = length sites
      dim   = length (head sites)
  when (dim < 2) $
    error "dimension must be at least 2"
  when (n <= dim+1) $
    error "insufficient number of points"
  unless (all (== dim) (map length (tail sites))) $
    error "the points must have the same dimension"
  unless (allUnique sites) $
    error "some points are duplicated"
  let vthreshold' = fromMaybe 0 vthreshold 
  sitesPtr <- mallocBytes (n * dim * sizeOf (undefined :: CDouble))
  pokeArray sitesPtr (concatMap (map realToFrac) sites)
  exitcodePtr <- mallocBytes (sizeOf (undefined :: CUInt))
  resultPtr <- c_tessellation sitesPtr
               (fromIntegral dim) (fromIntegral n)
               (fromIntegral $ fromEnum atinfinity)
               (fromIntegral $ fromEnum degenerate)
               (realToFrac vthreshold') exitcodePtr
  exitcode <- peek exitcodePtr
  free exitcodePtr
  free sitesPtr
  if exitcode /= 0
    then do
      free resultPtr
      error $ "qhull returned an error (code " ++ show exitcode ++ ")"
    else do
      result <- peek resultPtr
      out <- cTessellationToTessellation sites result
      free resultPtr
      return out

-- | tile facets a vertex belongs to, vertex given by its index;
-- the output is the empty map if the index is not valid
vertexNeighborFacets :: Tessellation -> Index -> IntMap TileFacet
vertexNeighborFacets tess i = IM.restrictKeys (_tilefacets tess) ids
  where
    ids = maybe IS.empty _neighfacetsIds (IM.lookup i (_sites tess))

-- | whether a tile facet is sandwiched between two tiles
sandwichedFacet :: TileFacet -> Bool
sandwichedFacet tilefacet = IS.size (_facetOf tilefacet) == 2

-- | the tiles a facet belongs to
facetOf :: Tessellation -> TileFacet -> IntMap Tile
facetOf tess tilefacet = IM.restrictKeys (_tiles tess) (_facetOf tilefacet)

-- | the families of the tiles a facet belongs to
facetFamilies :: Tessellation -> TileFacet -> IntMap Family
facetFamilies tess tilefacet = IM.map _family (facetOf tess tilefacet)

-- | the circumcenters of the tiles a facet belongs to
facetCenters :: Tessellation -> TileFacet -> IntMap [Double]
facetCenters tess tilefacet =
  IM.map _center (facetOf tess tilefacet)

funofFacetToFunofInt :: (Tessellation -> TileFacet -> IntMap a)
                     -> (Tessellation -> Int -> IntMap a)
funofFacetToFunofInt f tess i =
  maybe IM.empty (f tess) (IM.lookup i (_tilefacets tess))

-- | the tiles a facet belongs to, facet given by its id
facetOf' :: Tessellation -> Int -> IntMap Tile
facetOf' = funofFacetToFunofInt facetOf

-- | the families of the tiles a facet belongs to, facet given by its id
facetFamilies' :: Tessellation -> Int -> IntMap Family
facetFamilies' = funofFacetToFunofInt facetFamilies

-- | the circumcenters of the tiles a facet belongs to, facet given by its id
facetCenters' :: Tessellation -> Int -> IntMap [Double]
facetCenters' = funofFacetToFunofInt facetCenters
