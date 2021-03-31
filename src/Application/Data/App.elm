module Data.App exposing (Name, decoder, encode, nameOnly, rename, route, toString, toUrl)

import Json.Decode as D
import Json.Encode as E
import Url.Parser as Url


{-| For results from webnative.apps.index()

E.g.

    Name
        { name = "long-junior-narrow-queen"
        , rest = ".fissionapp.net"
        }

or

    Name
        { name = "long-tulip"
        , rest = ".fission.app"
        }

-}
type Name
    = Name
        { name : String
        , rest : String
        }


decoder : D.Decoder Name
decoder =
    D.string
        |> D.andThen
            (\str ->
                case fromString str of
                    Just name ->
                        D.succeed name

                    Nothing ->
                        D.fail ("Couldn't parse app domain name (expecting something like \"long-tulip.fission.app\"): " ++ str)
            )


encode : Name -> E.Value
encode app =
    E.string (toString app)


{-| Returns things like <https://long-tulip.fission.app>
-}
toUrl : Name -> String
toUrl (Name { name, rest }) =
    "https://" ++ name ++ rest


{-| Returns things like long-tulip.fission.app
-}
toString : Name -> String
toString (Name { name, rest }) =
    name ++ rest


nameOnly : Name -> String
nameOnly (Name { name }) =
    name


route : Url.Parser (Name -> a) a
route =
    Url.custom "APPNAME" fromString


{-| Rename only the name part of the App.

For an app like `long-tulip.fission.app` it works like this:

    toString (rename "my-app-name" app)
    --> "my-app-name.fission.app"

-}
rename : String -> Name -> Name
rename newName (Name { rest }) =
    Name { name = newName, rest = rest }



-- Local


fromString : String -> Maybe Name
fromString str =
    case String.split "." str of
        name :: rest ->
            Name { name = name, rest = "." ++ String.join "." rest }
                |> Just

        [] ->
            Nothing
