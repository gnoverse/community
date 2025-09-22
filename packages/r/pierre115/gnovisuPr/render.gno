package gnov

import (
    "gno.land/p/demo/svg"
)

func Render(_ string) string {

    // Usecase
    canvas := svg.NewCanvas(800, 600).WithViewBox(0, 0, 800, 600)

    canvas.Append(ScatterPlot{
        Points: []Point{
            {X: 100, Y: 00, Label: "A"},
            {X: 101, Y: 20, Label: "B"},
            {X: 102, Y: 40, Label: "C"},
			{X: 103, Y: 60, Label: "D"},
			{X: 104, Y: 80, Label: "D'"},
            {X: 105, Y: 100, Label: "E"},
            {X: 106, Y: 120, Label: "F"},
			{X: 107, Y: 140, Label: "G"},
            {X: 108, Y: 160, Label: "H"},
            {X: 109, Y: 180, Label: "I"},
			{X: 110, Y: 200, Label: "J"},
            {X: 111, Y: 220, Label: "K"},
            {X: 112, Y: 240, Label: "L"},
        },
        Title: "Evolution of sales",
        XAxis: "Années",
        YAxis: "Ventes",
        Flag:  "re",
    })

    return canvas.Render("Scatter Plot")
}