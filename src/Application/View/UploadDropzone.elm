module View.UploadDropzone exposing (..)

import Css
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute)
import Html.Styled.Events as Events
import Json.Decode as Json


{-| This is a function for rendering the "dashboard-upload-dropzone" custom element.

Keep this code in sync with the javascript definition!

-}
view :
    List (Attribute msg)
    ->
        { onPublishStart : msg
        , onPublishEnd : msg
        , onPublishFail : msg
        , onPublishAction : String -> msg
        , onPublishProgress : { progress : Int, total : Int, info : String } -> msg
        , appName : String
        }
    -> List (Html msg)
    -> Html msg
view attributes element content =
    node "dashboard-upload-dropzone"
        (List.append attributes
            [ attribute "app-name" element.appName
            , Events.on "publishStart" (Json.succeed element.onPublishStart)
            , Events.on "publishEnd" (Json.succeed element.onPublishEnd)
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
