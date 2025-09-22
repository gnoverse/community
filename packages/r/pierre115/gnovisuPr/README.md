GNOV SCATTERPLOT

 -Package scatterplot provides functionality to render a scatter plot as an SVG image.
 -It takes a list of points (x,y) and draws them as circles on a 2D canvas.
 -You can also apply Flags.

Function :
 -"Testscatter(POINT, "TITLE", "TITLE_AXE_X", "TITLE_AXE_Y", "FLAG")"

ARGS :
 -1 : The points structure for example : points := []Point{
		{X: 0, Y: 1, Color: "blue", Label: "P0"},
        {X: 1, Y: 3, Color: "blue", Label: "P1"},
        {X: 2, Y: 5, Color: "blue", Label: "P2"},
    }
 -2 : Title of the scatterplot canva -> string

 -3 : Title of the X axe -> string

 -4 : Title of the Y axe -> string

 -5 : Flags *more in the flags part*


FLAGS :

 -"re" : Draw the line as the result of the linear regression
 -"rp" : Draw the curve as the result of the polynomial regression