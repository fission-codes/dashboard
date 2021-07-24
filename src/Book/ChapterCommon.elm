module ChapterCommon exposing (..)

import ElmBook.Chapter exposing (chapter, render, withComponent)
import ElmBook.ElmCSS exposing (Chapter)
import View.Common


chapterCommon : Chapter x
chapterCommon =
    chapter "Common Components"
        |> withComponent
            (View.Common.button
                { label = "Primary Button"
                , icon = Nothing
                , disabled = False
                , isLoading = False
                , onClick = Nothing
                , style = View.Common.primaryButtonStyle
                , spinnerStyle = []
                }
            )
        |> render content


content : String
content =
    """
# It all starts with a chapter

Oh, look – A wild real component!

<component />

Woof! Moving on...
"""
