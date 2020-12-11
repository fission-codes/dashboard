module Route exposing (..)

import Url exposing (Url)
import Url.Parser exposing (..)



-- 🌳


type Route
    = Index



-- 🛠


fromUrl : Url -> Maybe Route
fromUrl =
    parse route



-- ㊙️


route : Parser (Route -> a) a
route =
    oneOf
        [ map Index top ]
