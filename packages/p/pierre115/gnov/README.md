# GNOV Scatterplot

The `gnov` package allows you to render a scatter plot as an SVG image. It takes a list of `(x, y)` points and draws them as circles on a 2D canvas. You can also apply optional flags to display regression lines or curves.

## API references

```go
Testscatter(POINTS, "TITLE", "X_AXIS_TITLE", "Y_AXIS_TITLE", "FLAG")
```

`POINTS` strcuture is set with the following arguments :
 ```go
	type Point struct {
	    X, Y  float64 //Coordinate of the point
	    Color string // Color of the point
	    Label string // Associate a label to the point
    }
```
`TITLE`, `X_AXIS_TITLE`, `Y_AXIS_TITLE` are strings.

`FlagRe` is a `Boolean` value: `true` to enable and false by default.

`Maxticks` is an `int` n used to divide the axis into n graduation marks.

`Width` and `height` are `int` to personalize the size of the scatterplot.

## Usage

`Usecase`

```go
ScatterPlot{
        Points: []Point{
            {X: 100, Y: 00, Label: "A"},
            {X: 101, Y: 20, Label: "B"},
            {X: 102, Y: 40, Label: "C"},
			{X: 103, Y: 60, Label: "D"},
        },
        Title: "Sales Growth",
        XAxis: "Years",
        YAxis: "Sales",
        FlagRe:  true,
        maxticks: 20,
        width: 800,
        height: 800,
    }
```

## Flags

`Lineary Regression flag` that display the `regression line` of the scatterplot can be actived by the bool `true`.
Each flag shows the `equation` of the regression in the top left of the Scatterplot.
