module DisplayGraph exposing (Graph, Vertex, graphDisplay)

{-| DisplayGraph provides tools for constructing graphs and
rendering them into SVG.

@docs Graph, Vertex, graphDisplay

-}

import Vector exposing (Vector)
import List.Extra
import Shape exposing (..)
import ColorRecord exposing (..)
import LineSegment exposing (..)
import Svg exposing (Svg)


{-| A graph is s record with two fields - list of vertices
and a list of edges.
-}
type alias Graph =
    { vertices : List Vertex, edges : List Edge }


{-| A vertex is s record with two fields, an integer id and a string label.
-}
type alias Vertex =
    { id : Int, label : String }


{-| A an edge is a tupe of integers, where the two elements
are the ids of vertices.
-}
type alias Edge =
    ( Int, Int )


vertexColor =
    ColorRecord 0 50 255 0.8


lineSegmentColor =
    ColorRecord 0 0 0 1.0


boundingBoxColor =
    ColorRecord 0 0 255 0.15


getPoints : Graph -> List Vector
getPoints graph =
    let
        points =
            []

        n =
            List.length graph.vertices

        theta =
            2 * 3.14159265 / (toFloat n)

        point =
            rotate (Vector 1 0) theta
    in
        List.range 0 (n - 1)
            |> List.foldl (\k acc -> (acc ++ [ point k ])) []


rotate : Vector -> Float -> Int -> Vector
rotate vector angle k =
    Vector.rotate ((toFloat k) * angle) vector


getIndexedPoints : Graph -> List ( Int, Vector )
getIndexedPoints graph =
    let
        points =
            getPoints graph

        ids =
            graph.vertices |> List.map .id
    in
        List.Extra.zip ids points


getPoint : List ( Int, Vector ) -> Int -> Maybe Vector
getPoint indexedPoints id =
    indexedPoints
        |> List.filter (\item -> (Tuple.first item) == id)
        |> List.head
        |> Maybe.map Tuple.second


edgeToSegment : List ( Int, Vector ) -> Edge -> Maybe Vector.DirectedSegment
edgeToSegment indexedPoints edge =
    let
        maybeA =
            getPoint indexedPoints (Tuple.first edge)

        maybeB =
            getPoint indexedPoints (Tuple.second edge)
    in
        case ( maybeA, maybeB ) of
            ( Just a, Just b ) ->
                Just (Vector.DirectedSegment a b)

            _ ->
                Nothing


renderPoints : List Vector -> List Shape
renderPoints centers =
    let
        size =
            0.5 / (toFloat (List.length centers))
    in
        centers |> List.map (\center -> makeCircle size center)


renderSegments : List Vector.DirectedSegment -> List LineSegment
renderSegments directedSegments =
    directedSegments |> List.map (\edge -> makeLine edge)


makeCircle : Float -> Vector -> Shape
makeCircle size center =
    let
        shapeData =
            ShapeData center (Vector size size) vertexColor vertexColor
    in
        Ellipse shapeData


makeLine : Vector.DirectedSegment -> LineSegment
makeLine segment =
    LineSegment segment.a segment.b 2.5 lineSegmentColor lineSegmentColor


{-| graphDisplay takes a number and a graph as arguments
and returns an SVG representation of the graph. The number is
a scale factor. If the scale is 1, the graph is centered in a 2x2 square.
-}
graphDisplay : Float -> Graph -> List (Svg msg)
graphDisplay scale graph =
    let
        k =
            -- make figure smaller by a scale factor than boudning box
            0.8

        kk =
            -- adjustment for size of circles (not good code)
            0.92

        points =
            getPoints graph

        indexedPoints =
            getIndexedPoints graph

        segments =
            List.map (edgeToSegment indexedPoints) graph.edges
                |> List.filterMap identity

        renderedPoints =
            renderPoints points
                |> List.map (Shape.scaleBy (k * scale))
                |> List.map (Shape.moveBy (Vector (kk * scale) scale))
                |> List.map Shape.draw

        renderedSegments =
            segments
                |> renderSegments
                |> List.map (LineSegment.scaleBy (k * scale))
                |> List.map (LineSegment.moveBy (Vector (kk * scale) scale))
                |> List.map LineSegment.draw
    in
        renderedSegments ++ renderedPoints ++ [ boundingBox scale ]


boundingBoxData =
    { center = (Vector 0 0)
    , dimensions = (Vector 2 2)
    , strokeColor = lineSegmentColor
    , fillColor = boundingBoxColor
    }


boundingBox scale =
    Rect boundingBoxData
        |> Shape.scaleBy (1.2 * scale)
        |> (Shape.moveBy (Vector (scale) (scale)))
        |> Shape.draw
