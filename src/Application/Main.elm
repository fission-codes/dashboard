module Main exposing (main)

import Browser
import Browser.Navigation
import Css.Classes as C
import FeatherIcons
import Html exposing (Html)
import Html.Attributes as A
import Radix exposing (..)
import Url exposing (Url)
import View



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


init : Flags -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init _ _ _ =
    Tuple.pair
        {}
        Cmd.none



-- 📣


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model
    , Cmd.none
    )



-- 📰


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- 🌄


view : Model -> Browser.Document Msg
view model =
    { title = "Fission Dashboard"
    , body =
        View.appShell
            { header = View.appHeader
            , main =
                [ View.sectionUsername
                , View.spacer
                , View.sectionEmail
                , View.spacer
                ]
            , footer = View.appFooter
            }
    }
