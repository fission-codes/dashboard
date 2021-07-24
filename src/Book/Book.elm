module Book exposing (main)

import ChapterCommon exposing (chapterCommon)
import Css.Global
import ElmBook exposing (withChapters, withThemeOptions)
import ElmBook.ElmCSS exposing (Book, book)
import ElmBook.ThemeOptions
import Tailwind.Utilities


main : Book ()
main =
    book "Book"
        |> withThemeOptions
            [ ElmBook.ThemeOptions.globals
                [ Css.Global.global Tailwind.Utilities.globalStyles ]
            ]
        |> withChapters
            [ chapterCommon
            ]
