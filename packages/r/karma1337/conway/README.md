# Conway's Game of Life

A fully-featured implementation of Conway's Game of Life as a Gno realm (smart contract). This implementation includes multiple coordinate systems, pre-defined patterns, and an intuitive web interface.

## Features

- **Dual Coordinate Systems**: Support for both numeric (x,y) and letter-based (e.g., "F5") coordinates
- **Pre-defined Patterns**: Includes classic patterns like blinker, block, and glider
- **Web Rendering**: Beautiful grid display with column labels and proper formatting
- **Interactive Help**: Built-in documentation and command examples
- **Gas-Optimized**: Efficient state management for blockchain deployment

## Package Path

When deployed to gnoverse, this package will be available at:
```
gno.land/r/karma1337/conway
```

## Usage

### Clearing the Grid

```bash
gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "Clear" -gas-fee 1000000ugnot -gas-wanted 5000000 -send "" --broadcast [your-key]
```

### Setting Individual Cells

**Using numeric coordinates (x, y):**
```bash
gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "SetCell" -args "5" -args "5" -args "true" -gas-fee 1000000ugnot -gas-wanted 5000000 -send "" --broadcast [your-key]
```

**Using letter coordinates (e.g., F5):**
```bash
gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "SetCellAt" -args "F5" -args "true" -gas-fee 1000000ugnot -gas-wanted 5000000 -send "" --broadcast [your-key]
```

### Loading Patterns

**Available patterns:** `blinker`, `block`, `glider`

**Using numeric coordinates:**
```bash
gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "LoadPattern" -args "blinker" -args "5" -args "5" -gas-fee 1000000ugnot -gas-wanted 5000000 -send "" --broadcast [your-key]
```

**Using letter coordinates:**
```bash
gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "LoadPatternAt" -args "glider" -args "C3" -gas-fee 1000000ugnot -gas-wanted 5000000 -send "" --broadcast [your-key]
```

### Advancing the Game

```bash
gnokey maketx call -pkgpath "gno.land/r/karma1337/conway" -func "Step" -gas-fee 2000000ugnot -gas-wanted 20000000 -send "" --broadcast [your-key]
```

**Note:** The Step function requires significant gas due to calculating the next generation for all cells.

### Viewing the Game State

Visit the web interface at:
```
https://gno.land/r/karma1337/conway
```

Or query programmatically:
```bash
gnokey query vm/qrender -data "gno.land/r/karma1337/conway"
```

## API Reference

### Game Management Functions

- `Step()` - Advance the game by one generation
- `Clear()` - Reset the grid to empty state

### Cell Manipulation Functions

#### Numeric Coordinates
- `SetCell(x, y, alive)` - Set cell state using numeric coordinates
- `GetCell(x, y)` - Get cell state using numeric coordinates
- `LoadPattern(pattern, x, y)` - Load pattern at numeric coordinates

#### Letter Coordinates  
- `SetCellAt(coordinate, alive)` - Set cell state using letter coordinates (e.g., "F5")
- `GetCellAt(coordinate)` - Get cell state using letter coordinates
- `LoadPatternAt(pattern, coordinate)` - Load pattern at letter coordinates

### Information Functions

- `GetGeneration()` - Get current generation number
- `GetAvailablePatterns()` - List all available patterns
- `Render()` - Get formatted grid display (called automatically by web interface)

## Coordinate Systems

### Numeric Coordinates
- x: 0-19 (columns, left to right)
- y: 0-19 (rows, top to bottom)
- Example: `(10, 10)` is near the center

### Letter Coordinates
- Columns: A-T (left to right, 20 columns)
- Rows: 0-19 (top to bottom, 20 rows)  
- Example: `"K10"` is near the center
- Case insensitive: `"k10"` and `"K10"` are equivalent

## Available Patterns

### Blinker (Oscillator)
A simple 3-cell pattern that oscillates between horizontal and vertical:
```
.#.    ...
.#. -> ###
.#.    ...
```

### Block (Still Life)
A stable 2x2 pattern that never changes:
```
##
##
```

### Glider (Spaceship)
A 5-cell pattern that moves diagonally across the grid:
```
.#.
..#
###
```

## Game Rules

Conway's Game of Life follows these simple rules:

1. **Underpopulation**: Live cells with fewer than 2 neighbors die
2. **Survival**: Live cells with 2-3 neighbors survive  
3. **Overpopulation**: Live cells with more than 3 neighbors die
4. **Reproduction**: Dead cells with exactly 3 neighbors become alive

## Grid Display

The web interface displays the grid with:
- Capital letters (A-T) for column headers (20 columns)
- Numbers (0-19) for row headers (20 rows)
- `●` for alive cells
- `.` for dead cells
- Proper spacing for readability

Example display:
```
   A B C D E F G H I J K L M N O P Q R S T
0  . . . . . . . . . . . . . . . . . . . .
1  . . . . . . . . . . . . . . . . . . . .
2  . . ● . . . . . . . . . . . . . . . . .
3  . . . ● . . . . . . . . . . . . . . . .
4  . ● ● ● . . . . . . . . . . . . . . . .
5  . . . . . . . . . . . . . . . . . . . .
...
```

## Development

This package consists of several modules:

- **conway.gno**: Main API and coordinate handling
- **grid.gno**: Core game logic and grid management
- **patterns.gno**: Pattern definitions and loading
- **renderer.gno**: Web display and help text
- **game.gno**: Game state management

## Contributing

This package is part of the Gnoverse community repository. To contribute:

1. Fork the [gnoverse/community](https://github.com/gnoverse/community) repository
2. Make your changes in `packages/r/karma1337/conway/`
3. Test your changes locally
4. Submit a pull request

## License

This implementation is part of the Gno ecosystem and follows the same licensing terms.