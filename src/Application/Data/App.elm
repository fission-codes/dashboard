module Data.App exposing (Name, decoder, encode, nameOnly, toString, toUrl)

import Json.Decode as D
import Json.Encode as E


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
                case String.split "." str of
                    name :: rest ->
                        Name { name = name, rest = "." ++ String.join "." rest }
                            |> D.succeed

                    [] ->
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
