module View.UploadDropzone exposing (..)

import Data.App as App
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute)
import Html.Styled.Events as Events
import Json.Decode as Json
import Maybe.Extra as Maybe


{-| This is a function for rendering the "dashboard-upload-dropzone" custom element.

Keep this code in sync with the javascript definition!

-}
view :
    List (Attribute msg)
    ->
        { onPublishStart : msg
        , onPublishEnd : App.Name -> msg
        , onPublishFail : msg
        , onPublishAction : String -> msg
        , onPublishProgress : { progress : Int, total : Int, info : String } -> msg
        , appName : Maybe App.Name
        }
    -> List (Html msg)
    -> Html msg
view attributes element content =
    node "dashboard-upload-dropzone"
        (List.append attributes
            [ attribute "app-domain" (Maybe.unwrap "" App.toString element.appName)
            , Events.on "publishStart" (Json.succeed element.onPublishStart)
            , Events.on "publishEnd" (Json.map element.onPublishEnd (Json.at [ "detail", "domain" ] App.decoder))
            , Events.on "publishFail" (Json.succeed element.onPublishFail)
            , Events.on "publishAction" (Json.map element.onPublishAction (Json.at [ "detail", "info" ] Json.string))
            , Events.on "publishProgress"
                (Json.field "detail"
                    (Json.map3
                        (\progress total info ->
                            element.onPublishProgress
                                { progress = progress
                                , total = total
                                , info = info
                                }
                        )
                        (Json.field "progress" Json.int)
                        (Json.field "total" Json.int)
                        (Json.field "info" Json.string)
                    )
                )
            ]
        )
        content
