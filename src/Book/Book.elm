module Book exposing (main)

import Chapter.Common
import Css.Global
import ElmBook exposing (withChapters, withThemeOptions)
import ElmBook.ElmCSS exposing (Book, book)
import ElmBook.ThemeOptions
import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (href, rel)
import Tailwind.Utilities


externalCss : String -> Html msg
externalCss href_ =
    node "link"
        [ rel "stylesheet"
        , href href_
        ]
        []


main : Book ()
main =
    book "Book"
        |> withThemeOptions
            [ ElmBook.ThemeOptions.globals
                [ externalCss "./build/application.css"
                , Css.Global.global Tailwind.Utilities.globalStyles
                ]
            ]
        |> withChapters
            [ Chapter.Common.it
            ]
