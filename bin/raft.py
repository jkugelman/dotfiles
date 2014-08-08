#!/usr/bin/env python

import string, sys, time

verbose = "-q" not in sys.argv

def main():
    print "Forward:"
    solve(raft, pieces, delay=0.002)
    print
    print "Backward:"
    solve(raft, [piece.flipped() for piece in pieces], delay=0.002)

class Piece:
    def __init__(self, sides, letter=None):
        self.sides  = sides
        self.letter = letter

    def flipped(self):
        return Piece(self.sides[3:6] + self.sides[0:3], self.letter)

    def fits_below(self, other): return other is None or self.sides[0] != other.sides[3]
    def fits_above(self, other): return other is None or other.fits_below(self)
    def fits_left (self, other): return other is None or self.sides[1] != other.sides[5] \
                                                     and self.sides[2] != other.sides[4]
    def fits_right(self, other): return other is None or other.fits_left(self)

    def fits_in(self, raft, row, col):
        return self.fits_below(raft[row - 1][col]) \
           and self.fits_above(raft[row + 1][col]) \
           and self.fits_right(raft[row][col - 1]) \
           and self.fits_left (raft[row][col + 1])

    def __str__(self):
        return self.letter

class Raft(list):
    def __init__(self, pieces):
        self[:] = [row[:] for row in pieces]

    @property
    def rows(self):
        return len(self) - 2

    @property
    def cols(self):
        return len(self[0]) - 2

    def show(self):
        sys.stdout.write(".--&--.\n")

        for row in range(1, self.rows + 1):
            sys.stdout.write("(%s)\n" % (" ".join(str(piece) for piece in self[row][1:-1])))

        sys.stdout.write("'-----'\n")

def solve(raft, pieces, delay, solution=[]):
    if len(solution) == len(pieces):
        if verbose:
            sys.stdout.write("\r            \r")

        raft.show()
        return

    row = len(solution) // raft.cols + 1
    col = len(solution) %  raft.cols + 1

    for i, piece in enumerate(pieces):
        if piece is None:
            continue

        if verbose:
            sys.stdout.write(piece.letter)
            sys.stdout.flush()

        if piece.fits_in(raft, row, col):
            solution.append(piece)
            raft[row][col] = piece
            pieces[i]      = None

            solve(raft, pieces, delay, solution)

            pieces[i]      = piece
            raft[row][col] = None
            solution.pop()

        if verbose:
            time.sleep(delay)
            sys.stdout.write("\b \b")
            sys.stdout.flush()

raft = Raft([
    [Piece("------"), Piece("---i--"), Piece("---i--"), Piece("---i--"), Piece("------")],
    [Piece("-io---"), None,            None,            None,            Piece("----oi")],
    [Piece("-io---"), None,            None,            None,            Piece("----io")],
    [Piece("-io---"), None,            None,            None,            Piece("----io")],
    [Piece("-oi---"), None,            None,            None,            Piece("----io")],
    [Piece("------"), Piece("o-----"), Piece("o-----"), Piece("o-----"), Piece("------")],
])
    
pieces = [
    Piece("ioiooi", 'A'),
    Piece("iiooio", 'B'),
    Piece("oioiio", 'C'),
    Piece("ioiioi", 'D'),
    Piece("ooiooi", 'E'),
    Piece("iioioi", 'F'),
    Piece("ooiioi", 'G'),
    Piece("iioooi", 'H'),
    Piece("ooioio", 'I'),
    Piece("oioooi", 'J'),
    Piece("ooiiio", 'K'),
    Piece("ioiiio", 'L'),
]

if __name__ == "__main__":
    main()
