port module Ports exposing
    ( deselectSession
    , drawFixed
    , drawMobile
    , fetchSessions
    , graphRangeSelected
    , isShowingTimeRangeFilter
    , loadMoreSessions
    , locationCleared
    , locationUpdated
    , mapMoved
    , observeSessionsList
    , profileSelected
    , pulseSessionMarker
    , refreshTimeRange
    , saveScrollPosition
    , selectSensorId
    , selectSession
    , setScroll
    , showCopyLinkTooltip
    , tagSelected
    , timeRangeSelected
    , toggleActive
    , toggleCrowdMap
    , toggleIndoor
    , toggleIsSearchOn
    , toggleSessionSelection
    , toggleTheme
    , updateGraphData
    , updateGraphYAxis
    , updateHeatMapThresholds
    , updateHeatMapThresholdsFromAngular
    , updateIsHttping
    , updateParams
    , updateProfiles
    , updateResolution
    , updateSessions
    , updateTags
    )

import Data.GraphData exposing (GraphData, GraphHeatData)
import Data.HeatMapThresholds exposing (HeatMapThresholdValues)
import Data.Markers exposing (SessionMarkerData)
import Data.SelectedSession exposing (Measurement, SelectedSessionForAngular)
import Json.Encode as Encode


port tagSelected : (String -> msg) -> Sub msg


port profileSelected : (String -> msg) -> Sub msg


port timeRangeSelected : (Encode.Value -> msg) -> Sub msg


port locationCleared : (() -> msg) -> Sub msg


port locationUpdated : (String -> msg) -> Sub msg


port showCopyLinkTooltip : String -> Cmd a


port toggleCrowdMap : Bool -> Cmd a


port toggleIndoor : Bool -> Cmd a


port toggleActive : Bool -> Cmd a


port updateResolution : Int -> Cmd a


port selectSensorId : String -> Cmd a


port updateSessions : (Encode.Value -> msg) -> Sub msg


port selectSession : SelectedSessionForAngular -> Cmd msg


port deselectSession : () -> Cmd msg


port loadMoreSessions : () -> Cmd msg


port updateIsHttping : (Bool -> msg) -> Sub msg


port updateTags : List String -> Cmd a


port updateProfiles : List String -> Cmd a


port toggleSessionSelection : (Maybe Int -> msg) -> Sub msg


port refreshTimeRange : () -> Cmd a


port updateHeatMapThresholds : HeatMapThresholdValues -> Cmd a


port updateHeatMapThresholdsFromAngular : (HeatMapThresholdValues -> msg) -> Sub msg


port drawMobile : GraphData -> Cmd a


port drawFixed : GraphData -> Cmd a


port toggleIsSearchOn : Bool -> Cmd a


port mapMoved : (() -> msg) -> Sub msg


port fetchSessions : () -> Cmd a


port pulseSessionMarker : Maybe SessionMarkerData -> Cmd a


port graphRangeSelected : ({ start : Int, end : Int } -> msg) -> Sub msg


port isShowingTimeRangeFilter : (Bool -> msg) -> Sub msg


port saveScrollPosition : Float -> Cmd a


port setScroll : (() -> msg) -> Sub msg


port observeSessionsList : () -> Cmd a


port toggleTheme : String -> Cmd a


port updateGraphYAxis : GraphHeatData -> Cmd a


port updateGraphData : { measurements : List Measurement, times : { start : Int, end : Int } } -> Cmd a


port updateParams : { key : String, value : Bool } -> Cmd a
