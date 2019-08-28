module Data.SelectedSession exposing
    ( Measurement
    , SelectedSession
    , SelectedSessionForAngular
    , fetch
    , fetchMeasurements
    , formatForAngular
    , measurementBounds
    , times
    , toId
    , updateFetchedTimeRange
    , updateMeasurements
    , view
    )

import Data.EmailForm as EmailForm
import Data.HeatMapThresholds exposing (HeatMapThresholds)
import Data.Page exposing (Page(..))
import Data.Path as Path exposing (Path)
import Data.Session
import Data.Times as Times
import Html exposing (Html, a, button, div, img, p, span, text)
import Html.Attributes exposing (alt, class, href, id, src, target)
import Html.Events as Events
import Http
import Json.Decode as Decode exposing (Decoder(..))
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Popup
import RemoteData exposing (RemoteData(..), WebData)
import Sensor exposing (Sensor)
import Time exposing (Posix)
import Url.Builder


type alias SelectedSession =
    { title : String
    , username : String
    , sensorName : String
    , measurements : List Measurement
    , fetchedStartTime : Maybe Int
    , startTime : Posix
    , endTime : Posix
    , id : Int
    , streamId : Int
    , selectedTimeRange : { start : Int, end : Int }
    , sensorUnit : String
    , averageValue : Float
    , latitude : Float
    , longitude : Float
    , maxLatitude : Float
    , maxLongitude : Float
    , minLatitude : Float
    , minLongitude : Float
    , startLatitude : Float
    , startLongitude : Float
    , notes : List Note
    , isIndoor : Bool
    , lastHourAverage : Float
    }


type alias SelectedSessionForAngular =
    { id : Int
    , notes : List Note
    , stream :
        { average_value : Float
        , max_latitude : Float
        , max_longitude : Float
        , measurements : List Measurement
        , min_latitude : Float
        , min_longitude : Float
        , sensor_name : String
        , start_latitude : Float
        , start_longitude : Float
        , unit_symbol : String
        }
    , is_indoor : Bool
    , last_hour_average : Float
    , latitude : Float
    , longitude : Float
    }


formatForAngular : SelectedSession -> SelectedSessionForAngular
formatForAngular session =
    { id = session.id
    , notes = session.notes
    , stream =
        { average_value = session.averageValue
        , max_latitude = session.maxLatitude
        , max_longitude = session.maxLongitude
        , min_latitude = session.minLatitude
        , min_longitude = session.minLongitude
        , start_latitude = session.startLatitude
        , start_longitude = session.startLongitude
        , measurements = session.measurements
        , unit_symbol = session.sensorUnit
        , sensor_name = session.sensorName
        }
    , is_indoor = session.isIndoor
    , last_hour_average = session.lastHourAverage
    , latitude = session.latitude
    , longitude = session.longitude
    }


type alias Measurement =
    { value : Float
    , time : Int
    , latitude : Float
    , longitude : Float
    }


type alias Note =
    { title : String }


measurementDecoder =
    Decode.succeed Measurement
        |> required "value" Decode.float
        |> required "time" Decode.int
        |> required "latitude" Decode.float
        |> required "longitude" Decode.float


noteDecoder =
    Decode.succeed Note
        |> required "title" Decode.string


times : SelectedSession -> { start : Int, end : Int }
times { startTime, endTime } =
    { start = Time.posixToMillis startTime, end = Time.posixToMillis endTime }


toId : SelectedSession -> Int
toId { id } =
    id


measurementBounds : SelectedSession -> Maybe { min : Float, max : Float }
measurementBounds session =
    let
        maybeMin =
            List.minimum (selectedMeasurements session.measurements session.selectedTimeRange)

        maybeMax =
            List.maximum (selectedMeasurements session.measurements session.selectedTimeRange)
    in
    case ( maybeMin, maybeMax ) of
        ( Just min, Just max ) ->
            Just { min = min, max = max }

        _ ->
            Nothing


millisToPosixDecoder : Decoder Posix
millisToPosixDecoder =
    Decode.int
        |> Decode.map Time.millisToPosix


decoder : Decoder SelectedSession
decoder =
    Decode.succeed SelectedSession
        |> required "title" Decode.string
        |> required "username" Decode.string
        |> required "sensorName" Decode.string
        |> required "measurements" (Decode.list measurementDecoder)
        |> hardcoded Nothing
        |> required "startTime" millisToPosixDecoder
        |> required "endTime" millisToPosixDecoder
        |> required "id" Decode.int
        |> required "streamId" Decode.int
        |> hardcoded { start = 0, end = 0 }
        |> required "sensorUnit" Decode.string
        |> optional "averageValue" Decode.float 0
        |> optional "latitude" Decode.float 0
        |> optional "longitude" Decode.float 0
        |> required "maxLatitude" Decode.float
        |> required "maxLongitude" Decode.float
        |> required "minLatitude" Decode.float
        |> required "minLongitude" Decode.float
        |> optional "startLatitude" Decode.float 0
        |> optional "startLongitude" Decode.float 0
        |> required "notes" (Decode.list noteDecoder)
        |> optional "isIndoor" Decode.bool False
        |> optional "lastHourAverage" Decode.float 0


fetch : List Sensor -> String -> Page -> Int -> (Result Http.Error SelectedSession -> msg) -> Cmd msg
fetch sensors sensorId page id toCmd =
    let
        maybeSensorName =
            Sensor.nameForSensorId sensorId sensors
    in
    case maybeSensorName of
        Just sensorName ->
            Http.get
                { url =
                    if page == Mobile then
                        Url.Builder.absolute
                            [ "api", "mobile", "sessions", String.fromInt id ++ ".json" ]
                            [ Url.Builder.string "sensor_name" sensorName ]

                    else
                        Url.Builder.absolute
                            [ "api", "fixed", "sessions", String.fromInt id ++ ".json" ]
                            [ Url.Builder.string "sensor_name" sensorName
                            , Url.Builder.int "measurements_limit" 1440
                            ]
                , expect = Http.expectJson toCmd decoder
                }

        Nothing ->
            Cmd.none


updateFetchedTimeRange : SelectedSession -> SelectedSession
updateFetchedTimeRange session =
    { session | fetchedStartTime = session.measurements |> List.map .time |> List.minimum }


fetchMeasurements : SelectedSession -> { start : Int, end : Int } -> (Result Http.Error (List Measurement) -> msg) -> Cmd msg
fetchMeasurements session timeBounds toCmd =
    let
        newStartTime =
            timeBounds.start
    in
    case session.fetchedStartTime of
        Nothing ->
            fetchMeasurementsCall session.streamId toCmd newStartTime timeBounds.end

        Just fetchedStartTime ->
            if newStartTime < fetchedStartTime then
                fetchMeasurementsCall session.streamId toCmd newStartTime fetchedStartTime

            else
                Cmd.none


fetchMeasurementsCall : Int -> (Result Http.Error (List Measurement) -> msg) -> Int -> Int -> Cmd msg
fetchMeasurementsCall streamId toCmd startTime endTime =
    Http.get
        { url =
            Url.Builder.absolute
                [ "api", "measurements" ]
                [ Url.Builder.string "stream_ids" (String.fromInt streamId)
                , Url.Builder.int "start_time" startTime
                , Url.Builder.int "end_time" endTime
                ]
        , expect = Http.expectJson toCmd (Decode.list measurementDecoder)
        }


updateMeasurements : List Measurement -> SelectedSession -> SelectedSession
updateMeasurements measurements session =
    { session
        | measurements = List.append measurements session.measurements
    }


selectedMeasurements allMeasurements selectedTimeRange =
    allMeasurements
        |> List.filter (\measurement -> measurement.time >= selectedTimeRange.start && measurement.time <= selectedTimeRange.end)
        |> List.map (\measurement -> measurement.value)


view : SelectedSession -> WebData HeatMapThresholds -> Path -> (String -> msg) -> msg -> Popup.Popup -> Html msg -> Html msg
view session heatMapThresholds linkIcon toMsg showExportPopup popup emailForm =
    let
        tooltipId =
            "graph-copy-link-tooltip"

        measurements =
            selectedMeasurements session.measurements session.selectedTimeRange
    in
    div [ class "single-session__info" ]
        [ div [ class "session-data" ]
            [ div [ class "session-data__left" ]
                [ p [ class "single-session__name" ] [ text session.title ]
                , p [ class "single-session__username" ] [ text session.username ]
                , p [ class "single-session__sensor" ] [ text session.sensorName ]
                ]
            , case measurements of
                [] ->
                    div [ class "single-session__placeholder" ] []

                _ ->
                    let
                        min =
                            List.minimum measurements |> Maybe.withDefault -1

                        max =
                            List.maximum measurements |> Maybe.withDefault -1

                        average =
                            List.sum measurements / toFloat (List.length measurements)
                    in
                    div [ class "session-data__right" ]
                        [ div []
                            [ div [ class "single-session__avg-color", class <| Data.Session.classByValue (Just average) heatMapThresholds ] []
                            , span [] [ text "avg. " ]
                            , span [ class "single-session__avg" ] [ text <| String.fromInt <| round average ]
                            , span [] [ text <| " " ++ session.sensorUnit ]
                            ]
                        , div [ class "session-numbers-container" ]
                            [ div [ class "session-min-max-container" ]
                                [ div [ class "single-session__color", class <| Data.Session.classByValue (Just min) heatMapThresholds ] []
                                , span [] [ text "min. " ]
                                , span [ class "single-session__min" ] [ text <| String.fromFloat min ]
                                ]
                            , div [ class "session-min-max-container" ]
                                [ div [ class "single-session__color", class <| Data.Session.classByValue (Just max) heatMapThresholds ] []
                                , span [] [ text "max. " ]
                                , span [ class "single-session__max" ] [ text <| String.fromFloat max ]
                                ]
                            ]
                        , div [ class "single-session__date" ]
                            [ text <| Times.format session.startTime session.endTime ]
                        ]
            ]
        , div [ class "action-buttons" ]
            [ button [ class "button button--primary action-button action-button--export", Popup.clickWithoutDefault showExportPopup ] [ text "export session" ]
            , button [ class "button button--primary action-button action-button--copy-link", Events.onClick <| toMsg tooltipId, id tooltipId ] [ img [ src (Path.toString linkIcon), alt "Link icon" ] [] ]
            , if Popup.isEmailFormPopupShown popup then
                emailForm

              else
                text ""
            ]
        ]
