# delaunayNd

<!-- badges: start -->
[![Stack-lts](https://github.com/stla/delaunayNd/actions/workflows/Stack-lts.yml/badge.svg)](https://github.com/stla/delaunayNd/actions/workflows/Stack-lts.yml)
[![Stack-lts-Mac](https://github.com/stla/delaunayNd/actions/workflows/Stack-lts-Mac.yml/badge.svg)](https://github.com/stla/delaunayNd/actions/workflows/Stack-lts-Mac.yml)
[![Stack-nightly](https://github.com/stla/delaunayNd/actions/workflows/Stack-nightly.yml/badge.svg)](https://github.com/stla/delaunayNd/actions/workflows/Stack-nightly.yml)
<!-- badges: end -->

Delaunay tessellation in arbitrary dimension. 
Based on the `qhull` C library.

___

Consider this list of vertices (actually these are the vertices of a
polyhedron):

```haskell
vertices :: [[Double]]
vertices = [
            [ -5, -5,  16 ]  -- 0
          , [ -5,  8,   3 ]  -- 1
          , [  4, -1,   3 ]  -- 2
          , [  4, -5,   7 ]  -- 3
          , [  4, -1, -10 ]  -- 4
          , [  4, -5, -10 ]  -- 5
          , [ -5,  8, -10 ]  -- 6
          , [ -5, -5, -10 ]  -- 7
                           ]
```

The `delaunay` function splits the polyhedron into simplices, the *tiles* of the
tesselation:

```haskell
> import Geometry.Delaunay
> d <- delaunay vertices False False Nothing
> _tiles d
fromList
  [ ( 0
    , Tile
        { _simplex =
            Simplex
              { _vertices' =
                  fromList
                    [ ( 2 , [ 4.0 , -1.0 , 3.0 ] )
                    , ( 4 , [ 4.0 , -1.0 , -10.0 ] )
                    , ( 5 , [ 4.0 , -5.0 , -10.0 ] )
                    , ( 7 , [ -5.0 , -5.0 , -10.0 ] )
                    ]
              , _circumcenter =
                  [ -0.5000000000000009 , -3.0 , -3.499999999999999 ]
              , _circumradius = 8.154753215150047
              , _volume' = 78.0
              }
        , _neighborsIds = fromList [ 1 , 3 ]
        , _facetsIds = fromList [ 0 , 1 , 2 , 3 ]
        , _family' = None
        , _toporiented = False
        }
    )
  , ( 1
    , Tile
  ......
```

The field `_tiles` is a map of `Tile` objects. The keys of the map are
the tiles identifiers. A `Tile` object has five fields:

-   `_simplex`, a `Simplex` object;

-   `_neighborsIds`, a set of tiles identifiers, the neighbors of the tile;

-   `facetsIds`, a set of facets identifiers, the facets of the tile;

-   `family'`, two tiles of the same family share the same circumcenter;

-   `toporiented`, Boolean, whether the tile is top-oriented.

A `Simplex` object has four fields:

-   `_vertices`, the vertices of the simplex, actually a map of the vertices
identifiers to their coordinates;

-   `_circumcenter`, the coordinates of the circumcenter of the simplex;

-   `_circumradius`, the circumradius;

-   `_volume'`, the volume of the simplex (the area in dimension 2, the
  length in dimension 1).

Another field of the output of `delaunay` is `_tilefacets`:

```haskell
> _tilefacets d
fromList
  [ ( 0
    , TileFacet
        { _subsimplex =
            Simplex
              { _vertices' =
                  fromList
                    [ ( 4 , [ 4.0 , -1.0 , -10.0 ] )
                    , ( 5 , [ 4.0 , -5.0 , -10.0 ] )
                    , ( 7 , [ -5.0 , -5.0 , -10.0 ] )
                    ]
              , _circumcenter = [ -0.5000000000000009 , -3.0 , -10.0 ]
              , _circumradius = 4.924428900898053
              , _volume' = 36.0
              }
        , _facetOf = fromList [ 0 ]
        , _normal' = [ 0.0 , 0.0 , -1.0 ]
        , _offset = -10.0
        }
    )
  , ( 1
    , TileFacet
        { _subsimplex =
  ......
```

This is a map of `TileFacet` objects. A tile facet is a subsimplex. The keys of
the map are the identifiers of the facets.
A `TileFacet` object has four fields: `_subsimplex`, a `Simplex` object,
`_facetOf`, the identifiers of the tiles this facet belongs to (a set of one
or two integers), `_normal'`, the normal of the facet, and `offset`, the offset
of the facet.

The output of `delaunay` also has a `_sites` field, the vertices with
additional information:

```haskell
> _sites d
fromList
  [ ( 0
    , Site
        { _point = [ -5.0 , -5.0 , 16.0 ]
        , _neighsitesIds = fromList [ 1 , 3 , 7 ]
        , _neighfacetsIds = fromList [ 15 , 16 , 17 ]
        , _neightilesIds = fromList [ 5 ]
        }
    )
  , ( 1
    , Site
  ......
```

This is a map of `Site` objects. The keys of the map are the identifiers of
the vertices. A `Site` object has four fields:

-   `_point`, the coordinates of the vertex;

-   `_neighsitesIds`, the identifiers of the connected vertices;

-   `_neighfacetsIds`, a set of integers, the identifiers of the facets the
vertex belongs to;

-   `_neightilesIds`, the set of the identifiers of the tiles the vertex belongs
to.

Finally, the output of `delaunay` has the `_edges'` field, providing the 
edges: 

```haskell
 _edges' d
fromList
  [ ( Pair 0 1 , ( [ -5.0 , -5.0 , 16.0 ] , [ -5.0 , 8.0 , 3.0 ] ) )
  , ( Pair 0 3 , ( [ -5.0 , -5.0 , 16.0 ] , [ 4.0 , -5.0 , 7.0 ] ) )
  , ......
```