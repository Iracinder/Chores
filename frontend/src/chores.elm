module Main exposing (Chore, Model(..), Msg(..), Schedule, choreDecoder, choresDecoder, displayCell, displayChore, displayChores, getChoreConf, init, main, prettyPrintDuration, subscriptions, update, updateChore, updateTimer, view)

import Browser
import Dict exposing (Dict)
import Duration exposing (Duration)
import Html exposing (..)
import Html.Attributes exposing (style)
import Http
import Json.Decode exposing (Decoder, dict, field, int, map2)
import Material.Button exposing (buttonConfig, textButton)
import Material.Elevation as Elevation
import Material.LayoutGrid exposing (layoutGrid, layoutGridCell, layoutGridInner)
import Time


type Model
    = Loading
    | Error Http.Error
    | Success Schedule


type alias Schedule =
    { chores : Dict String Chore, timer : Time.Posix }


type alias Chore =
    { start : Int, threshold : Int }


type Msg
    = Tick Time.Posix
    | Reset String
    | ChoreReset (Result Http.Error ())
    | ChoreConf (Result Http.Error (Dict String Chore))


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading, getChoreConf )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick posix ->
            case model of
                Loading ->
                    ( model, Cmd.none )

                Error _ ->
                    ( model, Cmd.none )

                Success schedule ->
                    ( Success (updateTimer posix schedule), Cmd.none )

        Reset chore_name ->
            ( model, updateChore chore_name )

        ChoreConf result ->
            case result of
                Ok chores ->
                    ( Success (Schedule chores (Time.millisToPosix 0)), Cmd.none )

                Err error ->
                    ( Error error, Cmd.none )

        ChoreReset _ ->
            ( model, getChoreConf )



-- UPDATE HELPERS


updateTimer : Time.Posix -> Schedule -> Schedule
updateTimer posix schedule =
    { schedule | timer = posix }


getChoreConf : Cmd Msg
getChoreConf =
    Http.get
        { url = "http://127.0.0.1:8000/chores/list"
        , expect = Http.expectJson ChoreConf choresDecoder
        }


choresDecoder : Decoder (Dict String Chore)
choresDecoder =
    dict choreDecoder


choreDecoder : Decoder Chore
choreDecoder =
    map2 Chore
        (field "start_time" int)
        (field "threshold" int)


updateChore : String -> Cmd Msg
updateChore chore_name =
    Http.post
        { url = "http://127.0.0.1:8000/chores/" ++ chore_name
        , body = Http.emptyBody
        , expect = Http.expectWhatever ChoreReset
        }



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick



-- VIEW


view : Model -> Html Msg
view model =
    case model of
        Loading ->
            div [] [ text "Loading" ]

        Error error ->
            case error of
                Http.BadUrl string ->
                    div [] [ text ("BadURL: " ++ string) ]

                Http.Timeout ->
                    div [] [ text "Timeout" ]

                Http.NetworkError ->
                    div [] [ text "Network Error" ]

                Http.BadStatus int ->
                    div [] [ text ("BadStatus: " ++ String.fromInt int) ]

                Http.BadBody string ->
                    div [] [ text ("BadBody: " ++ string) ]

        Success schedule ->
            div [] (displayChores schedule)



-- VIEW HELPER


displayCell : List (Attribute msg)
displayCell =
    [ Elevation.z6
    , style "text-align" "center"
    , style "display" "flex"
    , style "justify-content" "center"
    , style "align-items" "center"
    ]


prettyPrintDuration : Duration -> Html Msg
prettyPrintDuration duration =
    text (String.fromInt (round (Duration.inDays duration)) ++ " days")


displayChore : Time.Posix -> String -> Chore -> Html Msg
displayChore timer name chore =
    layoutGrid []
        [ layoutGridInner []
            [ layoutGridCell displayCell [ text name ]
            , layoutGridCell displayCell [ prettyPrintDuration (Duration.milliseconds (toFloat (Time.posixToMillis timer - chore.start))) ]
            , layoutGridCell displayCell [ textButton { buttonConfig | onClick = Just (Reset name) } "Reset" ]
            ]
        ]


displayChores : Schedule -> List (Html Msg)
displayChores schedule =
    Dict.values (Dict.map (displayChore schedule.timer) schedule.chores)
