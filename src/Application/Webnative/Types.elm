module Webnative.Types exposing (..)

import Codec exposing (Codec)
import Json.Decode as Json
import Json.Encode as E


type State
    = NotAuthorised
    | Authorised { username : String }


type alias Permissions =
    { app : Maybe AppInfo
    , fs : Maybe FileSystemPermissions
    , platform : Maybe PlatformPermissions
    }


type alias AppInfo =
    { name : String
    , creator : String
    }


type alias FileSystemPermissions =
    { private : List Path
    , public : List Path
    }


type Path
    = File (List String)
    | Directory (List String)


type alias PlatformPermissions =
    { apps : PlatformAppsPermissions
    }


type PlatformAppsPermissions
    = AllApps
    | Domains (List String)


decoderState : Json.Decoder ( State, Permissions )
decoderState =
    Json.map2
        (\maybe permissions ->
            case maybe of
                Just username ->
                    ( Authorised { username = username }, permissions )

                Nothing ->
                    ( NotAuthorised, permissions )
        )
        (Json.field "session" <| Json.maybe <| Json.field "username" Json.string)
        (Json.field "permissions" decoderPermissions)


codecPermissions : Codec Permissions
codecPermissions =
    Codec.object Permissions
        |> Codec.maybeField "app" .app codecAppInfo
        |> Codec.maybeField "fs" .fs codecFileSystemPermissions
        |> Codec.maybeField "platform" .platform codecPlatformPermissions
        |> Codec.buildObject


decoderPermissions : Json.Decoder Permissions
decoderPermissions =
    Codec.decoder codecPermissions


encodePermissions : Permissions -> Json.Value
encodePermissions =
    Codec.encoder codecPermissions


codecAppInfo : Codec AppInfo
codecAppInfo =
    Codec.object AppInfo
        |> Codec.field "name" .name Codec.string
        |> Codec.field "creator" .creator Codec.string
        |> Codec.buildObject


codecFileSystemPermissions : Codec FileSystemPermissions
codecFileSystemPermissions =
    let
        nonEmptyList ls =
            case ls of
                [] ->
                    Nothing

                _ ->
                    Just ls

        fromNonEmptyList maybeNonEmpty =
            case maybeNonEmpty of
                Just ls ->
                    ls

                Nothing ->
                    []
    in
    Codec.object
        (\public private ->
            { public = fromNonEmptyList public
            , private = fromNonEmptyList private
            }
        )
        |> Codec.maybeField "public" (nonEmptyList << .public) (Codec.list codecPath)
        |> Codec.maybeField "private" (nonEmptyList << .private) (Codec.list codecPath)
        |> Codec.buildObject


codecPath : Codec Path
codecPath =
    Codec.build
        (\path ->
            case path of
                File pieces ->
                    E.object [ ( "file", E.list E.string pieces ) ]

                Directory pieces ->
                    E.object [ ( "directory", E.list E.string pieces ) ]
        )
        (Json.maybe (Json.field "file" (Json.list Json.string))
            |> Json.andThen
                (\maybePieces ->
                    case maybePieces of
                        Just pieces ->
                            Json.succeed (File pieces)

                        Nothing ->
                            Json.map Directory (Json.field "directory" (Json.list Json.string))
                )
        )


codecPlatformPermissions : Codec PlatformPermissions
codecPlatformPermissions =
    Codec.object PlatformPermissions
        |> Codec.field "apps" .apps codecPlatformAppsPermissions
        |> Codec.buildObject


codecPlatformAppsPermissions : Codec PlatformAppsPermissions
codecPlatformAppsPermissions =
    Codec.build
        encodePlatformAppsPermissions
        decoderPlatformAppsPermissions


decoderPlatformAppsPermissions : Json.Decoder PlatformAppsPermissions
decoderPlatformAppsPermissions =
    Json.maybe Json.string
        |> Json.andThen
            (\result ->
                case result of
                    Just "*" ->
                        Json.succeed AllApps

                    Just _ ->
                        Json.fail "Expected the string \"*\" or a list of strings."

                    Nothing ->
                        Json.map Domains (Json.list Json.string)
            )


encodePlatformAppsPermissions : PlatformAppsPermissions -> Json.Value
encodePlatformAppsPermissions appsPermissions =
    case appsPermissions of
        AllApps ->
            E.string "*"

        Domains list ->
            E.list E.string list
