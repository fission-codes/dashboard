module Recovery.Main exposing (main)

import Authenticated
import Browser
import Browser.Navigation as Navigation
import Html.Styled as Html
import Json.Decode as Json
import Json.Encode as E
import Ports
import Recovery.Radix exposing (..)
import Route
import Url exposing (Url)
import View.Common
import Webnative.Types



-- ⛩


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        }



-- 🌳


init : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
init flags url navKey =
    ( { navKey = navKey
      , url = url
      }
    , Cmd.none
    )



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -----------------------------------------
        -- URL
        -----------------------------------------
        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )

        UrlChangedFromOutside str ->
            case Url.fromString str of
                Just url ->
                    ( { model | url = url }
                    , Cmd.none
                    )

                Nothing ->
                    ( model
                    , Ports.log [ E.string "Couldn't parse url:", E.string str ]
                    )

        UrlRequested request ->
            case request of
                Browser.Internal url ->
                    ( { model | url = url }
                    , Navigation.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Navigation.load url
                    )



-- 📰


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Dashboard - Account Recovery"
    , body = []
    }
