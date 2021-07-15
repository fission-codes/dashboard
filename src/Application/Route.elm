module Route exposing (..)

import Data.App as App
import Maybe.Extra as Maybe
import Url exposing (Url)
import Url.Parser exposing (..)



-- 🌳


type Route
    = Index
    | RecoveryKit
    | DeveloperAppList DeveloperAppListRoute


type DeveloperAppListRoute
    = DeveloperAppListIndex
    | DeveloperAppListApp App.Name



-- 🛠


fromUrl : Url -> Maybe Route
fromUrl =
    parse route


{-| Due to lacking SPA-mode support on fission apps, we
have to use fragment-based SPA routing for now.
-}
route : Parser (Route -> a) a
route =
    oneOf
        [ top
            </> fragment
                    (\f ->
                        parse routeParser
                            { protocol = Url.Https
                            , host = ""
                            , port_ = Nothing
                            , path =
                                f
                                    |> Maybe.map (\frag -> "/" ++ frag)
                                    |> Maybe.withDefault "/"
                            , query = Nothing
                            , fragment = Nothing
                            }
                            |> Maybe.withDefault Index
                    )
        , map Index top
        ]


routeParser : Parser (Route -> a) a
routeParser =
    oneOf
        [ map DeveloperAppList (top </> s "developers" </> s "apps" </> developerAppListParser)

        -- backwards compatibility
        , map RecoveryKit (s "backup")
        , map RecoveryKit (s "recovery-kit")
        , map Index top
        ]


developerAppListParser : Parser (DeveloperAppListRoute -> a) a
developerAppListParser =
    oneOf
        [ map DeveloperAppListIndex top
        , map DeveloperAppListApp App.route
        ]


toUrl : Route -> String
toUrl r =
    case r of
        Index ->
            "/"

        RecoveryKit ->
            "/#recovery-kit"

        DeveloperAppList DeveloperAppListIndex ->
            "/#developers/apps"

        DeveloperAppList (DeveloperAppListApp app) ->
            "/#developers/apps/" ++ Url.percentEncode (App.toString app)


isSameFirstLevel : Route -> Route -> Bool
isSameFirstLevel routeOne routeTwo =
    case ( routeOne, routeTwo ) of
        ( Index, Index ) ->
            True

        ( Index, _ ) ->
            False

        ( RecoveryKit, RecoveryKit ) ->
            True

        ( RecoveryKit, _ ) ->
            False

        ( DeveloperAppList _, DeveloperAppList _ ) ->
            True

        ( DeveloperAppList _, _ ) ->
            False



-- Recovery routes


isRecovery : Url -> Bool
isRecovery url =
    url
        |> parse (map () (top </> s "recover"))
        |> Maybe.isJust
