module Route exposing (..)

import Url exposing (Url)
import Url.Parser exposing (..)



-- 🌳


type Route
    = Index
    | AppList



-- 🛠


fromUrl : Url -> Maybe Route
fromUrl =
    parse route



-- ㊙️


route : Parser (Route -> a) a
route =
    oneOf
        [ top
            </> fragment
                    (\f ->
                        case f of
                            Just "developers/app-list" ->
                                AppList

                            _ ->
                                Index
                    )
        , map Index top
        ]


toUrl : Route -> String
toUrl r =
    case r of
        Index ->
            "/"

        AppList ->
            "/#developers/app-list"
