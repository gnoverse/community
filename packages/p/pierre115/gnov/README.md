# GNOV Scatterplot

The `gnov` package allows you to render a scatter plot as an SVG image. It takes a list of `(x, y)` points and draws them as circles on a 2D canvas. You can also apply optional flags to display regression lines or curves.

## Function

```go
Testscatter(POINTS, "TITLE", "X_AXIS_TITLE", "Y_AXIS_TITLE", "FLAG")
```

## ARGS

`POINTS` strcuture is set with the following arguments :
 ```go
	X, Y  float64
	Color string
	Label string
```

`TITLE` is a string

`X_AXIS_TITLE` is a string

`Y_AXIS_TITLE` is a string


## Structure

`Usecase`

```go
ScatterPlot{
        Points: []Point{
            {X: 100, Y: 00, Label: "A"},
            {X: 101, Y: 20, Label: "B"},
            {X: 102, Y: 40, Label: "C"},
			{X: 103, Y: 60, Label: "D"},
        },
        Title: "Evolution of sales",
        XAxis: "Années",
        YAxis: "Ventes",
        Flag:  "re",
    }
```


## Flags

Actually there is one existing flags : `Lineary Regression flag` that display the `regression line` of the scatterplot can be actived by the flag `re`.
Each flag shows the `equation` of the regression in the top left of the Scatterplot.
